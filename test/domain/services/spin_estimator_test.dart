import 'package:dan_do/core/ballistics_constants.dart';
import 'package:dan_do/domain/services/spin_estimator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpinEstimator.estimateSidespinRpm', () {
    test('フェースがパスより右を向く場合は正のサイドスピンになる', () {
      const launchDirectionDegrees = 5.0;
      const clubPathDegrees = 2.0;
      const faceToPathDegrees = launchDirectionDegrees - clubPathDegrees;

      final sidespinRpm = SpinEstimator.estimateSidespinRpm(
        launchDirectionDegrees: launchDirectionDegrees,
        clubPathDegrees: clubPathDegrees,
      );

      expect(
        sidespinRpm,
        closeTo(
          faceToPathDegrees *
              BallisticsConstants.sidespinRpmPerFaceToPathDegree,
          0.001,
        ),
      );
      expect(sidespinRpm, greaterThan(0));
    });

    test('フェースがパスより左を向く場合は負のサイドスピンになる', () {
      const launchDirectionDegrees = -2.0;
      const clubPathDegrees = 1.0;

      final sidespinRpm = SpinEstimator.estimateSidespinRpm(
        launchDirectionDegrees: launchDirectionDegrees,
        clubPathDegrees: clubPathDegrees,
      );

      expect(sidespinRpm, lessThan(0));
    });

    test('フェースとパスが一致する場合はサイドスピン0になる', () {
      final sidespinRpm = SpinEstimator.estimateSidespinRpm(
        launchDirectionDegrees: 4.0,
        clubPathDegrees: 4.0,
      );

      expect(sidespinRpm, closeTo(0, 0.001));
    });
  });
}
