import 'package:freezed_annotation/freezed_annotation.dart';

import 'trajectory_point.dart';

part 'shot_result.freezed.dart';

@freezed
sealed class ShotResult with _$ShotResult {
  const factory ShotResult({
    required double carryDistanceMeters,
    required double launchAngleDegrees,
    required double launchDirectionDegrees,
    required List<TrajectoryPoint> measuredTrajectory,
    required List<TrajectoryPoint> simulatedTrajectory,
  }) = _ShotResult;
}
