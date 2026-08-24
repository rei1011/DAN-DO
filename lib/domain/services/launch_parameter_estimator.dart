import 'dart:math' as math;

import '../models/trajectory_point.dart';

/// インパクト直後の観測点列(X(t),Y(t),Z(t))を線形回帰し、
/// 打ち出しパラメータ(初速V0・打ち出し角θ・打ち出し方向φ)を推定する(純粋関数)。
///
/// 観測窓が短い前提のもと、各軸の位置を時刻に対する線形回帰で近似する
/// (重力によるY(t)の曲がりは考慮しない簡易モデル)。
class LaunchParameterEstimator {
  const LaunchParameterEstimator._();

  static ({double v0, double launchAngleDegrees, double launchDirectionDegrees})
  estimate(List<TrajectoryPoint> points) {
    if (points.length < 2) {
      throw ArgumentError.value(
        points,
        'points',
        '打ち出しパラメータの推定には2点以上の観測点が必要です',
      );
    }

    final vx = _linearRegressionSlope(
      points.map((p) => (p.t, p.x)).toList(),
    );
    final vy = _linearRegressionSlope(
      points.map((p) => (p.t, p.y)).toList(),
    );
    final vz = _linearRegressionSlope(
      points.map((p) => (p.t, p.z)).toList(),
    );

    final v0 = math.sqrt(vx * vx + vy * vy + vz * vz);
    final horizontalSpeed = math.sqrt(vx * vx + vz * vz);
    final launchAngleDegrees =
        math.atan2(vy, horizontalSpeed) * 180 / math.pi;
    final launchDirectionDegrees = math.atan2(vx, vz) * 180 / math.pi;

    return (
      v0: v0,
      launchAngleDegrees: launchAngleDegrees,
      launchDirectionDegrees: launchDirectionDegrees,
    );
  }

  /// 最小二乗法による単回帰の傾き(=速度)を算出する。
  static double _linearRegressionSlope(List<(double, double)> samples) {
    final n = samples.length;
    final sumT = samples.fold<double>(0, (sum, s) => sum + s.$1);
    final sumV = samples.fold<double>(0, (sum, s) => sum + s.$2);
    final meanT = sumT / n;
    final meanV = sumV / n;

    var numerator = 0.0;
    var denominator = 0.0;
    for (final (t, v) in samples) {
      numerator += (t - meanT) * (v - meanV);
      denominator += (t - meanT) * (t - meanT);
    }

    if (denominator == 0) return 0;
    return numerator / denominator;
  }
}
