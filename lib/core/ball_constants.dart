import 'dart:math' as math;

/// ゴルフボールの物理定数(目安値)。
class BallConstants {
  const BallConstants._();

  /// ボール直径(メートル)。実機での画角検証と合わせて算出済みの前提値。
  static const double diameterMeters = 0.0427;

  static const double radiusMeters = diameterMeters / 2;

  /// ボール質量(キログラム)。USGA規定の上限値を採用。
  static const double massKg = 0.04593;

  static const double gravityMetersPerSecondSquared = 9.80665;

  static final double crossSectionAreaSquareMeters =
      math.pi * radiusMeters * radiusMeters;
}
