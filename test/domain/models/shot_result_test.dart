import 'package:dan_do/domain/models/shot_result.dart';
import 'package:dan_do/domain/models/trajectory_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShotResult', () {
    test('同じフィールド値なら等価になる', () {
      const pointA = TrajectoryPoint(t: 0, x: 0, y: 0, z: 0, isMeasured: true);
      const resultA = ShotResult(
        carryDistanceMeters: 150,
        launchAngleDegrees: 15,
        launchDirectionDegrees: 0,
        measuredTrajectory: [pointA],
        simulatedTrajectory: [],
      );
      const resultB = ShotResult(
        carryDistanceMeters: 150,
        launchAngleDegrees: 15,
        launchDirectionDegrees: 0,
        measuredTrajectory: [pointA],
        simulatedTrajectory: [],
      );

      expect(resultA, resultB);
    });

    test('copyWithで指定フィールドだけ更新できる', () {
      const original = ShotResult(
        carryDistanceMeters: 150,
        launchAngleDegrees: 15,
        launchDirectionDegrees: 0,
        measuredTrajectory: [],
        simulatedTrajectory: [],
      );

      final updated = original.copyWith(carryDistanceMeters: 200);

      expect(updated.carryDistanceMeters, 200);
      expect(updated.launchAngleDegrees, original.launchAngleDegrees);
    });
  });
}
