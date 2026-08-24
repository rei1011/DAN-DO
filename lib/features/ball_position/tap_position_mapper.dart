import 'package:flutter/rendering.dart' show BoxFit, applyBoxFit;
import 'package:flutter/material.dart' show Offset, Size;

/// [BoxFit.contain]で[imageSize]の画像を[displaySize]の領域に表示したときの、
/// 実際の描画サイズと余白(レターボックス)を返す。
({Size renderedSize, Offset topLeft}) _fittedLayout(
  Size displaySize,
  Size imageSize,
) {
  final fitted = applyBoxFit(BoxFit.contain, imageSize, displaySize);
  final renderedSize = fitted.destination;
  final topLeft = Offset(
    (displaySize.width - renderedSize.width) / 2,
    (displaySize.height - renderedSize.height) / 2,
  );
  return (renderedSize: renderedSize, topLeft: topLeft);
}

/// 画面上の表示座標([localPosition])を、[BoxFit.contain]で表示された画像の
/// ピクセル座標系に変換する。画像範囲外は端にクランプする。
Offset mapDisplayPositionToImagePx({
  required Offset localPosition,
  required Size displaySize,
  required Size imageSize,
}) {
  final layout = _fittedLayout(displaySize, imageSize);
  final localInImage = localPosition - layout.topLeft;
  final scale = imageSize.width / layout.renderedSize.width;
  final dx = (localInImage.dx * scale).clamp(0.0, imageSize.width);
  final dy = (localInImage.dy * scale).clamp(0.0, imageSize.height);
  return Offset(dx, dy);
}

/// [mapDisplayPositionToImagePx]の逆変換。画像ピクセル座標を画面上の表示座標に
/// 変換する(マーカー描画に使う)。
Offset mapImagePxToDisplayPosition({
  required Offset imagePx,
  required Size displaySize,
  required Size imageSize,
}) {
  final layout = _fittedLayout(displaySize, imageSize);
  final scale = layout.renderedSize.width / imageSize.width;
  return layout.topLeft + imagePx * scale;
}
