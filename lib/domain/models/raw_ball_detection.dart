import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'raw_ball_detection.freezed.dart';

@freezed
sealed class RawBallDetection with _$RawBallDetection {
  const factory RawBallDetection({
    required int frameTimeMs,
    required Offset centerPx,
    required double diameterPx,
    required double confidence,
  }) = _RawBallDetection;
}
