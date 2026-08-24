import 'package:cross_file/cross_file.dart';
import 'package:dan_do/data/video/image_picker_video_picker.dart';
import 'package:dan_do/data/video/video_player_duration_reader.dart';
import 'package:dan_do/domain/services/ball_trajectory_analysis_service.dart';
import 'package:dan_do/features/result/result_screen.dart';
import 'package:dan_do/features/video_select/video_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../fakes/fake_shot_analysis_service.dart';
import '../fakes/fake_video_duration_reader.dart';
import '../fakes/fake_video_picker.dart';

void main() {
  testWidgets('動画選択→解析中→結果画面まで遷移する', (tester) async {
    final fixtureVideo = XFile('fixture.mp4');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoPickerProvider.overrideWith(
            (ref) => FakeVideoPicker(fixtureVideo),
          ),
          videoDurationReaderProvider.overrideWith(
            (ref) => FakeVideoDurationReader(const Duration(seconds: 5)),
          ),
          shotAnalysisServiceProvider.overrideWith(
            (ref) async => FakeShotAnalysisService(),
          ),
        ],
        child: const MaterialApp(home: VideoSelectScreen()),
      ),
    );

    await tester.tap(find.byKey(const Key('pickVideoButton')));

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
}
