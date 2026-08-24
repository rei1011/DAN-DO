import 'dart:convert';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:dan_do/data/video/first_frame_reader.dart';
import 'package:dan_do/features/ball_position/ball_position_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// 1x1透明PNG(最小の有効なPNGバイナリ)。ui.instantiateImageCodecでデコード可能。
final _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

class _CountingFirstFrameReader implements FirstFrameReader {
  int readCallCount = 0;

  @override
  Future<Uint8List> read(XFile video) async {
    readCallCount++;
    return _onePixelPng;
  }
}

void main() {
  testWidgets(
    'タップしてもフレーム取得・画像デコードが再実行されず、スピナーに戻らない',
    (tester) async {
      final fakeReader = _CountingFirstFrameReader();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firstFrameReaderProvider.overrideWithValue(fakeReader),
          ],
          child: MaterialApp(
            home: BallPositionPickerScreen(video: XFile('fixture.mp4')),
          ),
        ),
      );

      // dart:uiの実画像デコードはFakeAsyncのタイマーでは進まない実処理(engine側の
      // 非同期処理)を含むため、runAsyncで実時間の非同期処理を許可しつつポーリングする。
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        if (find.byKey(const Key('ballPositionImage')).evaluate().isNotEmpty) {
          break;
        }
      }

      expect(fakeReader.readCallCount, 1);
      expect(find.byKey(const Key('ballPositionImage')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byKey(const Key('ballPositionImage')));
      // setStateの直後(非同期の隙間を待たない)1フレームだけpumpする。
      // future:に毎回新しいFutureを渡すバグが再発した場合、FutureBuilderは
      // 同期的にローディング状態へリセットされ、この1フレーム目で
      // スピナーが表示されてしまう。
      await tester.pump();

      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'タップ後にスピナーへ戻ってはいけない(フレーム取得/デコードFutureの再生成疑い)',
      );
      expect(fakeReader.readCallCount, 1);

      await tester.pump(const Duration(milliseconds: 200));

      expect(fakeReader.readCallCount, 1);
      final confirmButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('confirmBallPositionButton')),
      );
      expect(confirmButton.onPressed, isNotNull);
    },
  );
}
