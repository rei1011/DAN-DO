import 'package:freezed_annotation/freezed_annotation.dart';

part 'trajectory_point.freezed.dart';

@freezed
sealed class TrajectoryPoint with _$TrajectoryPoint {
  const factory TrajectoryPoint({
    required double t,
    required double x,
    required double y,
    required double z,
    required bool isMeasured,
  }) = _TrajectoryPoint;
}
