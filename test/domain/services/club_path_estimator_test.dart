import 'dart:math' as math;

import 'package:dan_do/domain/models/trajectory_point.dart';
import 'package:dan_do/domain/services/club_path_estimator.dart';
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
  group('ClubPathEstimator.estimate', () {
    test('クラブパス=0・角度既知の点列からattackAngleDegreesを復元する', () {
      const speed = 45.0;
      const attackAngleDegrees = -4.0;
      final theta = attackAngleDegrees * math.pi / 180;
      final vx = 0.0;
      final vy = speed * math.sin(theta);
      final vz = speed * math.cos(theta);

      final result = ClubPathEstimator.estimate(
        _syntheticPoints(vx: vx, vy: vy, vz: vz),
      );

      expect(result.attackAngleDegrees, closeTo(attackAngleDegrees, 0.01));
      expect(result.clubPathDegrees, closeTo(0, 0.01));
    });

    test('クラブパスが非0の点列からclubPathDegreesを復元する', () {
      const speed = 40.0;
      const attackAngleDegrees = -2.0;
      const clubPathDegrees = 3.5;
      final theta = attackAngleDegrees * math.pi / 180;
      final phi = clubPathDegrees * math.pi / 180;
      final vx = speed * math.cos(theta) * math.sin(phi);
      final vy = speed * math.sin(theta);
      final vz = speed * math.cos(theta) * math.cos(phi);

      final result = ClubPathEstimator.estimate(
        _syntheticPoints(vx: vx, vy: vy, vz: vz),
      );

      expect(result.attackAngleDegrees, closeTo(attackAngleDegrees, 0.01));
      expect(result.clubPathDegrees, closeTo(clubPathDegrees, 0.01));
    });

    test('観測点がちょうど2点でも算出できる(欠測を許容するロバスト性)', () {
      final result = ClubPathEstimator.estimate([
        const TrajectoryPoint(t: 0, x: 0, y: 0, z: 10, isMeasured: true),
        const TrajectoryPoint(t: 0.033, x: 1, y: 0, z: 11, isMeasured: true),
      ]);

      expect(result.clubPathDegrees, isNotNull);
      expect(result.attackAngleDegrees, isNotNull);
    });

    test('観測点が2点未満の場合はArgumentErrorを投げる', () {
      expect(
        () => ClubPathEstimator.estimate([
          const TrajectoryPoint(t: 0, x: 0, y: 0, z: 0, isMeasured: true),
        ]),
        throwsArgumentError,
      );
    });
  });
}
