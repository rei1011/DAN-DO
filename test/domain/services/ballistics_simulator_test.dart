import 'dart:math' as math;

import 'package:dan_do/core/ball_constants.dart';
import 'package:dan_do/domain/services/ballistics_simulator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BallisticsSimulator.simulate', () {
    test('抗力・スピンなしの場合、放物運動の解析解と着地時刻・飛距離が一致する', () {
      const v0 = 30.0;
      const angleDegrees = 45.0;

      final trajectory = BallisticsSimulator.simulate(
        v0: v0,
        launchAngleDegrees: angleDegrees,
        launchDirectionDegrees: 0,
        backspinRpm: 0,
        sidespinRpm: 0,
        dragCoefficient: 0,
      );

      final theta = angleDegrees * math.pi / 180;
      final g = BallConstants.gravityMetersPerSecondSquared;
      final expectedTime = 2 * v0 * math.sin(theta) / g;
      final expectedRange = v0 * v0 * math.sin(2 * theta) / g;

      final landing = trajectory.last;
      expect(landing.t, closeTo(expectedTime, 0.01));
      expect(landing.z, closeTo(expectedRange, 0.05));
      expect(landing.x.abs(), lessThan(1e-6));
      expect(landing.y, closeTo(0, 1e-6));
    });

    test('抗力を加えると無抗力の場合より飛距離が短くなる', () {
      final noDrag = BallisticsSimulator.simulate(
        v0: 40,
        launchAngleDegrees: 12,
        launchDirectionDegrees: 0,
        dragCoefficient: 0,
      );
      final withDrag = BallisticsSimulator.simulate(
        v0: 40,
        launchAngleDegrees: 12,
        launchDirectionDegrees: 0,
        dragCoefficient: 0.25,
      );

      expect(withDrag.last.z, lessThan(noDrag.last.z));
    });

    test('バックスピンを加えるとスピンなしより飛距離が伸びる', () {
      final noSpin = BallisticsSimulator.simulate(
        v0: 40,
        launchAngleDegrees: 12,
        launchDirectionDegrees: 0,
        backspinRpm: 0,
      );
      final withBackspin = BallisticsSimulator.simulate(
        v0: 40,
        launchAngleDegrees: 12,
        launchDirectionDegrees: 0,
        backspinRpm: 2600,
      );

      expect(withBackspin.last.z, greaterThan(noSpin.last.z));
    });

    test('正のサイドスピンを加えると進行方向に対して右(X正)にドリフトする', () {
      final trajectory = BallisticsSimulator.simulate(
        v0: 40,
        launchAngleDegrees: 12,
        launchDirectionDegrees: 0,
        sidespinRpm: 300,
      );

      expect(trajectory.last.x, greaterThan(0));
    });

    test('サイドスピンなしならXはほぼ0のまま', () {
      final trajectory = BallisticsSimulator.simulate(
        v0: 40,
        launchAngleDegrees: 12,
        launchDirectionDegrees: 0,
        sidespinRpm: 0,
      );

      expect(trajectory.last.x.abs(), lessThan(1e-6));
    });

    test('刻み幅を細かくしても着地位置・時刻が大きく変わらない(数値安定性)', () {
      final coarse = BallisticsSimulator.simulate(
        v0: 45,
        launchAngleDegrees: 14,
        launchDirectionDegrees: 5,
        backspinRpm: 2600,
        sidespinRpm: 300,
        dt: 0.02,
      );
      final fine = BallisticsSimulator.simulate(
        v0: 45,
        launchAngleDegrees: 14,
        launchDirectionDegrees: 5,
        backspinRpm: 2600,
        sidespinRpm: 300,
        dt: 0.001,
      );

      expect(coarse.last.z, closeTo(fine.last.z, 0.5));
      expect(coarse.last.x, closeTo(fine.last.x, 0.5));
      expect(coarse.last.t, closeTo(fine.last.t, 0.05));
    });

    test('着地点ではYがちょうど0になる(着地補間の確認)', () {
      final trajectory = BallisticsSimulator.simulate(
        v0: 40,
        launchAngleDegrees: 12,
        launchDirectionDegrees: 0,
        dt: 0.05,
      );

      expect(trajectory.last.y, equals(0));
      expect(trajectory[trajectory.length - 2].y, greaterThan(0));
    });
  });
}
