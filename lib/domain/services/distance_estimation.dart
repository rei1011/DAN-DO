import 'dart:math' as math;
import 'dart:ui';

import '../../core/ball_constants.dart';

/// ピンホールカメラモデルによる距離・3D位置推定(純粋関数)。
///
/// 撮影時の実カメラ画角メタデータが取得できないため、呼び出し側は
/// `AssumedCameraIntrinsics` 等の仮定画角から算出した焦点距離を渡す想定。
class DistanceEstimation {
  const DistanceEstimation._();

  /// フレーム幅(px)と画角(度)から焦点距離(px)を算出する。
  static double focalLengthPx({
    required double frameWidthPx,
    required double fovDegrees,
  }) {
    final halfFovRad = _degreesToRadians(fovDegrees) / 2;
    return (frameWidthPx / 2) / math.tan(halfFovRad);
  }

  /// ボールの実直径・画像上の直径・焦点距離から、カメラからの奥行き(m)を算出する。
  static double estimateDepthMeters({
    required double diameterPx,
    required double focalLengthPx,
    double ballDiameterMeters = BallConstants.diameterMeters,
  }) {
    return ballDiameterMeters * focalLengthPx / diameterPx;
  }

  /// 基準点(originPx, referenceDepthMeters)からの相対位置として、
  /// ボール中心のワールド座標(m)を算出する。
  ///
  /// 画像のV座標は下向きが正のため、Y(高さ)算出時に符号を反転する。
  static ({double x, double y, double z}) estimateWorldPosition({
    required Offset centerPx,
    required double diameterPx,
    required Offset originPx,
    required double referenceDepthMeters,
    required double focalLengthPx,
    double ballDiameterMeters = BallConstants.diameterMeters,
  }) {
    final depth = estimateDepthMeters(
      diameterPx: diameterPx,
      focalLengthPx: focalLengthPx,
      ballDiameterMeters: ballDiameterMeters,
    );
    final x = (centerPx.dx - originPx.dx) * depth / focalLengthPx;
    final y = -(centerPx.dy - originPx.dy) * depth / focalLengthPx;
    final z = depth - referenceDepthMeters;
    return (x: x, y: y, z: z);
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}
