import 'dart:math' as math;

import '../../core/linear_regression.dart';
import '../models/trajectory_point.dart';

/// インパクト直前のクラブヘッド世界座標列(X(t),Y(t),Z(t))を線形回帰し、
/// クラブパス角度・アタック角度を推定する(純粋関数)。
///
/// ダウンスイング〜インパクト直前はモーションブラー等により検出が欠測しうるため、
/// 取得できた観測点数(2点以上)だけで成立する実装とする。
class ClubPathEstimator {
  const ClubPathEstimator._();

  static ({double clubPathDegrees, double attackAngleDegrees}) estimate(
    List<TrajectoryPoint> points,
  ) {
    if (points.length < 2) {
      throw ArgumentError.value(points, 'points', 'クラブパスの推定には2点以上の観測点が必要です');
    }

    final vx = LinearRegression.slope(points.map((p) => (p.t, p.x)).toList());
    final vy = LinearRegression.slope(points.map((p) => (p.t, p.y)).toList());
    final vz = LinearRegression.slope(points.map((p) => (p.t, p.z)).toList());

    final horizontalSpeed = math.sqrt(vx * vx + vz * vz);
    final clubPathDegrees = math.atan2(vx, vz) * 180 / math.pi;
    final attackAngleDegrees = math.atan2(vy, horizontalSpeed) * 180 / math.pi;

    return (
      clubPathDegrees: clubPathDegrees,
      attackAngleDegrees: attackAngleDegrees,
    );
  }
}
