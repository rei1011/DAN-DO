import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/models/raw_ball_detection.dart';

/// [FrameCropper.crop]の結果。[bytes]はクロップ後のPNGバイト列、[offsetPx]は
/// 元フレーム座標系におけるクロップ範囲の左上原点。
class CroppedFrame {
  const CroppedFrame({required this.bytes, required this.offsetPx});

  final Uint8List bytes;
  final ui.Offset offsetPx;
}

/// 元フレームから指定中心・サイズの矩形を切り出す。切り出しにより検出モデルに
/// 渡す画像内でのボールの相対的な大きさ(実効解像度)が上がり、極小の被写体を
/// 検出しやすくなる。
class FrameCropper {
  const FrameCropper._();

  static Future<CroppedFrame> crop(
    Uint8List frameBytes, {
    required ui.Offset centerPx,
    required double cropSizePx,
  }) async {
    final codec = await ui.instantiateImageCodec(frameBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final frameWidth = image.width.toDouble();
    final frameHeight = image.height.toDouble();

    final width = math.min(cropSizePx, frameWidth);
    final height = math.min(cropSizePx, frameHeight);
    final left = (centerPx.dx - width / 2).clamp(0.0, frameWidth - width);
    final top = (centerPx.dy - height / 2).clamp(0.0, frameHeight - height);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(left, top, width, height),
      ui.Rect.fromLTWH(0, 0, width, height),
      ui.Paint(),
    );
    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(width.round(), height.round());
    final byteData = await croppedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return CroppedFrame(
      bytes: byteData!.buffer.asUint8List(),
      offsetPx: ui.Offset(left, top),
    );
  }

  /// クロップ画像内座標系の[detection]を、元フレーム座標系に変換する。
  static RawBallDetection translateDetection(
    RawBallDetection detection,
    ui.Offset offsetPx,
  ) {
    return detection.copyWith(centerPx: detection.centerPx + offsetPx);
  }
}
