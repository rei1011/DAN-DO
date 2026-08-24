import 'dart:math' as math;

import 'package:dan_do/domain/models/trajectory_point.dart';
import 'package:dan_do/domain/services/launch_parameter_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

List<TrajectoryPoint> _syntheticPoints({
  required double vx,
  required double vy,
  required double vz,
  List<double> times = const [0, 0.033, 0.066, 0.1],
}) {
  return [
    for (final t in times)
      TrajectoryPoint(t: t, x: vx * t, y: vy * t, z: vz * t, isMeasured: true),
  ];
}

void main() {
  group('LaunchParameterEstimator.estimate', () {
    test('直進(左右方向φ=0)・角度既知の点列からV0と打ち出し角を復元する', () {
      const v0 = 50.0;
      const launchAngleDegrees = 15.0;
      final theta = launchAngleDegrees * math.pi / 180;
      final vx = 0.0;
      final vy = v0 * math.sin(theta);
      final vz = v0 * math.cos(theta);

      final result = LaunchParameterEstimator.estimate(
        _syntheticPoints(vx: vx, vy: vy, vz: vz),
      );

      expect(result.v0, closeTo(v0, 0.01));
      expect(result.launchAngleDegrees, closeTo(launchAngleDegrees, 0.01));
      expect(result.launchDirectionDegrees, closeTo(0, 0.01));
    });

    test('打ち出し方向φが非0の点列からlaunchDirectionDegreesを復元する', () {
      const v0 = 40.0;
      const launchAngleDegrees = 10.0;
      const launchDirectionDegrees = 8.0;
      final theta = launchAngleDegrees * math.pi / 180;
      final phi = launchDirectionDegrees * math.pi / 180;
      final vx = v0 * math.cos(theta) * math.sin(phi);
      final vy = v0 * math.sin(theta);
      final vz = v0 * math.cos(theta) * math.cos(phi);

      final result = LaunchParameterEstimator.estimate(
        _syntheticPoints(vx: vx, vy: vy, vz: vz),
      );

      expect(result.v0, closeTo(v0, 0.01));
      expect(result.launchAngleDegrees, closeTo(launchAngleDegrees, 0.01));
      expect(
        result.launchDirectionDegrees,
        closeTo(launchDirectionDegrees, 0.01),
      );
    });

    test('観測点が2点未満の場合はArgumentErrorを投げる', () {
      expect(
        () => LaunchParameterEstimator.estimate([
          const TrajectoryPoint(t: 0, x: 0, y: 0, z: 0, isMeasured: true),
        ]),
        throwsArgumentError,
      );
    });
  });
}
