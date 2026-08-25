import 'package:dan_do/features/ball_position/tap_position_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapDisplayPositionToImagePx', () {
    test('displaySizeが画像と同アスペクト比なら等倍スケールでマップする', () {
      final result = mapDisplayPositionToImagePx(
        localPosition: const Offset(100, 50),
        displaySize: const Size(200, 100),
        imageSize: const Size(400, 200),
      );

      expect(result, const Offset(200, 100));
    });

    test('displaySizeが画像より横長の場合、左右の余白を差し引いてマップする', () {
      // imageSize 100x200(縦長)をdisplaySize 300x200にcontainで収めると、
      // 高さ基準でスケールされ幅150、左右75pxずつ余白ができる。
      final result = mapDisplayPositionToImagePx(
        localPosition: const Offset(75, 0),
        displaySize: const Size(300, 200),
        imageSize: const Size(100, 200),
      );

      expect(result.dx, closeTo(0, 0.001));
      expect(result.dy, closeTo(0, 0.001));
    });

    test('画像範囲外のタップはクランプされる', () {
      final result = mapDisplayPositionToImagePx(
        localPosition: const Offset(-50, -50),
        displaySize: const Size(200, 100),
        imageSize: const Size(400, 200),
      );

      expect(result, const Offset(0, 0));
    });
  });

  group('mapImagePxToDisplayPosition', () {
    test('mapDisplayPositionToImagePxの逆変換になる', () {
      const displaySize = Size(200, 100);
      const imageSize = Size(400, 200);
      const imagePx = Offset(200, 100);

      final displayPosition = mapImagePxToDisplayPosition(
        imagePx: imagePx,
        displaySize: displaySize,
        imageSize: imageSize,
      );

      expect(displayPosition, const Offset(100, 50));
    });
  });
}
