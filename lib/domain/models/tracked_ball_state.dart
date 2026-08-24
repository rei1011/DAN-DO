import 'package:freezed_annotation/freezed_annotation.dart';

part 'tracked_ball_state.freezed.dart';

/// [BallKalmanTracker]によるフィルタ後のフェーズ判定。
enum BallTrackingPhase {
  /// スイング開始前の静止(アドレス)区間。
  address,

  /// インパクト直後の飛球区間。
  launch,

  /// ゲーティングで候補が除外された、または検出が無かったフレーム。
  lost,
}

@freezed
sealed class TrackedBallState with _$TrackedBallState {
  const factory TrackedBallState({
    required int frameTimeMs,
    required double u,
    required double v,
    required double du,
    required double dv,
    required double diameterPx,
    required BallTrackingPhase phase,
  }) = _TrackedBallState;
}
