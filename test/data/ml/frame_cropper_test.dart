import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dan_do/data/ml/frame_cropper.dart';
import 'package:dan_do/domain/models/raw_ball_detection.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FrameCropper.crop', () {
    test('中心座標周辺を指定サイズで切り出し、切り出し原点を返す', () async {
      final frameBytes = await _makeTestFramePng();

      final cropped = await FrameCropper.crop(
        frameBytes,
        centerPx: const ui.Offset(45, 35),
        cropSizePx: 20,
      );

      expect(cropped.offsetPx, const ui.Offset(35, 25));

      final codec = await ui.instantiateImageCodec(cropped.bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 20);
      expect(frame.image.height, 20);
    });

    test('中心座標がフレーム端に寄っている場合、範囲内に収まるようクランプする', () async {
      final frameBytes = await _makeTestFramePng(width: 100, height: 80);

      final cropped = await FrameCropper.crop(
        frameBytes,
        centerPx: const ui.Offset(5, 5),
        cropSizePx: 20,
      );

      expect(cropped.offsetPx.dx, greaterThanOrEqualTo(0));
      expect(cropped.offsetPx.dy, greaterThanOrEqualTo(0));
    });
  });

  group('FrameCropper.translateDetection', () {
    test('クロップ内座標にオフセットを加算し元フレーム座標系に戻す', () {
      const detection = RawBallDetection(
        frameTimeMs: 100,
        centerPx: ui.Offset(10, 8),
        diameterPx: 6,
        confidence: 0.8,
      );

      final translated = FrameCropper.translateDetection(
        detection,
        const ui.Offset(35, 25),
      );

      expect(translated.centerPx, const ui.Offset(45, 33));
      expect(translated.frameTimeMs, 100);
      expect(translated.diameterPx, 6);
      expect(translated.confidence, 0.8);
    });
  });
}
