// test/widget/video_analysis_flow_test.dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:dan_do/data/video/first_frame_reader.dart';
import 'package:dan_do/data/video/image_picker_video_picker.dart';
import 'package:dan_do/data/video/video_player_duration_reader.dart';
import 'package:dan_do/domain/models/shot_result.dart';
import 'package:dan_do/domain/services/ball_trajectory_analysis_service.dart';
import 'package:dan_do/domain/services/shot_analysis_service.dart';
import 'package:dan_do/features/result/result_screen.dart';
import 'package:dan_do/features/video_select/video_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../fakes/fake_first_frame_reader.dart';
import '../fakes/fake_shot_analysis_service.dart';
import '../fakes/fake_video_duration_reader.dart';
import '../fakes/fake_video_picker.dart';

class _ThrowingShotAnalysisService implements ShotAnalysisService {
  @override
  Future<ShotResult> analyze(
    XFile video, {
    required Offset initialBallPositionPx,
  }) async {
    throw Exception('解析エラーのテスト用');
  }
}

Future<Uint8List> _makeTestFramePng({int width = 100, int height = 80}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF000000),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

Future<void> _pickVideoAndTapBallPosition(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('pickVideoButton')));

  // 動画選択→動画長チェック→画面遷移(MaterialPageRouteのトランジション)までは
  // フェイクの非同期処理のみのため、有限回のpumpで進む。
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  // BallPositionPickerScreen内の画像デコードはdart:uiの実処理
  // (ui.instantiateImageCodec/codec.getNextFrame())であり、FakeAsyncの
  // タイマーでは進まないため、pumpAndSettleは使わずrunAsyncで実時間の
  // 非同期処理を許可しつつballPositionImageが現れるまでポーリングする。
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    if (find.byKey(const Key('ballPositionImage')).evaluate().isNotEmpty) {
      break;
    }
  }

  await tester.tap(find.byKey(const Key('ballPositionImage')));
  await tester.pump();

  await tester.tap(find.byKey(const Key('confirmBallPositionButton')));
}

void main() {
  testWidgets('動画選択→ボール位置指定→解析中→結果画面まで遷移する', (tester) async {
    final fixtureVideo = XFile('fixture.mp4');
    // _makeTestFramePngはdart:uiの実処理(toImage/toByteData)を使うため、
    // FakeAsyncのテストゾーン内では直接呼ばずrunAsyncで実行する。
    final frameBytes = (await tester.runAsync(_makeTestFramePng))!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoPickerProvider.overrideWith(
            (ref) => FakeVideoPicker(fixtureVideo),
          ),
          videoDurationReaderProvider.overrideWith(
            (ref) => FakeVideoDurationReader(const Duration(seconds: 5)),
          ),
          firstFrameReaderProvider.overrideWith(
            (ref) => FakeFirstFrameReader(frameBytes),
          ),
          shotAnalysisServiceProvider.overrideWith(
            (ref) async => FakeShotAnalysisService(),
          ),
        ],
        child: const MaterialApp(home: VideoSelectScreen()),
      ),
    );

    await _pickVideoAndTapBallPosition(tester);

    // ResultScreen は video_player の初期化完了(または失敗)を待ってから
    // CircularProgressIndicator を消すが、テスト環境にはプラットフォーム
    // 実装がないため初期化 Future は例外を投げずに解決もしない
    // (無限アニメーションが残る)。そのため pumpAndSettle は使わず、
    // 画面遷移が完了するまで有限回だけ pump する。
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(ResultScreen).evaluate().isNotEmpty) break;
    }

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.byKey(const Key('carryDistanceText')), findsOneWidget);
  });

  testWidgets('動画が長すぎる場合、VideoSelectScreenにエラーメッセージが表示される', (tester) async {
    final fixtureVideo = XFile('fixture.mp4');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoPickerProvider.overrideWith(
            (ref) => FakeVideoPicker(fixtureVideo),
          ),
          videoDurationReaderProvider.overrideWith(
            (ref) => FakeVideoDurationReader(const Duration(minutes: 2)),
          ),
        ],
        child: const MaterialApp(home: VideoSelectScreen()),
      ),
    );

    await tester.tap(find.byKey(const Key('pickVideoButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('videoSelectErrorText')), findsOneWidget);
  });

  testWidgets('解析が失敗した場合、AnalyzingScreenにエラー画面と「別の動画を選ぶ」ボタンが表示される', (
    tester,
  ) async {
    final fixtureVideo = XFile('fixture.mp4');
    // _makeTestFramePngはdart:uiの実処理(toImage/toByteData)を使うため、
    // FakeAsyncのテストゾーン内では直接呼ばずrunAsyncで実行する。
    final frameBytes = (await tester.runAsync(_makeTestFramePng))!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoPickerProvider.overrideWith(
            (ref) => FakeVideoPicker(fixtureVideo),
          ),
          videoDurationReaderProvider.overrideWith(
            (ref) => FakeVideoDurationReader(const Duration(seconds: 5)),
          ),
          firstFrameReaderProvider.overrideWith(
            (ref) => FakeFirstFrameReader(frameBytes),
          ),
          shotAnalysisServiceProvider.overrideWith(
            (ref) async => _ThrowingShotAnalysisService(),
          ),
        ],
        child: const MaterialApp(home: VideoSelectScreen()),
      ),
    );

    await _pickVideoAndTapBallPosition(tester);

    // AnalyzingScreen はエラー確定後もCircularProgressIndicatorの
    // 無限アニメーションが残り得るため、pumpAndSettle は使わず
    // 画面遷移が完了するまで有限回だけ pump する。
    // analysisControllerProviderはanalysisRetryPolicyによりリトライを3回
    // (200ms+400ms+800ms=1.4秒)に制限しているため、確定失敗までの猶予を
    // 十分に確保する(fake clockのため実時間としては一瞬で進む)。
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find
          .byKey(const Key('backToVideoSelectButton'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const Key('backToVideoSelectButton')), findsOneWidget);
  });
}
