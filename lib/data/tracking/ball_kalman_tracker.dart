import 'dart:math' as math;

import '../../core/tracking_constants.dart';
import '../../domain/models/raw_ball_detection.dart';
import '../../domain/models/tracked_ball_state.dart';

/// 手書きの簡易カルマンフィルタ(定速度モデル、g-h/alpha-betaフィルタ)による
/// ボール位置の平滑化・誤検出のゲーティング・フェーズ判定を行う。
///
/// 統計的に厳密なMahalanobis距離等は用いず、単純な閾値判定のゲーティングで
/// 十分とする方針(`docs/implementation-plan-analysis-pipeline.md`参照)。
class BallKalmanTracker {
  const BallKalmanTracker({
    this.confidenceThreshold = TrackingConstants.confidenceThreshold,
    this.gatingRadiusPx = TrackingConstants.gatingRadiusPx,
    this.launchSpeedThresholdPxPerSecond =
        TrackingConstants.launchSpeedThresholdPxPerSecond,
  });

  final double confidenceThreshold;
  final double gatingRadiusPx;
  final double launchSpeedThresholdPxPerSecond;

  /// 位置補正のゲイン(alpha)。予測と観測の残差をどれだけ位置に反映するか。
  static const double _positionGain = 0.6;

  /// 速度補正のゲイン(beta)。残差をどれだけ速度推定の更新に反映するか。
  static const double _velocityGain = 0.3;

  List<TrackedBallState> track(List<RawBallDetection> detections) {
    final byFrameTimeMs = <int, List<RawBallDetection>>{};
    for (final detection in detections) {
      (byFrameTimeMs[detection.frameTimeMs] ??= []).add(detection);
    }
    final sortedFrameTimes = byFrameTimeMs.keys.toList()..sort();

    final states = <TrackedBallState>[];
    _TrackState? current;
    var hasLaunched = false;

    for (final frameTimeMs in sortedFrameTimes) {
      final candidates = byFrameTimeMs[frameTimeMs]!
          .where((d) => d.confidence >= confidenceThreshold)
          .toList();

      if (current == null) {
        if (candidates.isEmpty) continue;
        final best = candidates.reduce(
          (a, b) => a.confidence >= b.confidence ? a : b,
        );
        current = _TrackState(
          u: best.centerPx.dx,
          v: best.centerPx.dy,
          du: 0,
          dv: 0,
          diameterPx: best.diameterPx,
          frameTimeMs: frameTimeMs,
        );
        states.add(
          TrackedBallState(
            frameTimeMs: frameTimeMs,
            u: current.u,
            v: current.v,
            du: current.du,
            dv: current.dv,
            diameterPx: current.diameterPx,
            phase: BallTrackingPhase.address,
          ),
        );
        continue;
      }

      final dtSeconds = (frameTimeMs - current.frameTimeMs) / 1000.0;
      if (dtSeconds <= 0) continue;

      final predictedU = current.u + current.du * dtSeconds;
      final predictedV = current.v + current.dv * dtSeconds;

      RawBallDetection? matched;
      var matchedDistance = double.infinity;
      for (final candidate in candidates) {
        final dx = candidate.centerPx.dx - predictedU;
        final dy = candidate.centerPx.dy - predictedV;
        final distance = math.sqrt(dx * dx + dy * dy);
        if (distance <= gatingRadiusPx && distance < matchedDistance) {
          matched = candidate;
          matchedDistance = distance;
        }
      }

      if (matched == null) {
        current = _TrackState(
          u: predictedU,
          v: predictedV,
          du: current.du,
          dv: current.dv,
          diameterPx: current.diameterPx,
          frameTimeMs: frameTimeMs,
        );
        states.add(
          TrackedBallState(
            frameTimeMs: frameTimeMs,
            u: current.u,
            v: current.v,
            du: current.du,
            dv: current.dv,
            diameterPx: current.diameterPx,
            phase: BallTrackingPhase.lost,
          ),
        );
        continue;
      }

      final residualU = matched.centerPx.dx - predictedU;
      final residualV = matched.centerPx.dy - predictedV;

      final newU = predictedU + _positionGain * residualU;
      final newV = predictedV + _positionGain * residualV;
      final newDu = current.du + (_velocityGain / dtSeconds) * residualU;
      final newDv = current.dv + (_velocityGain / dtSeconds) * residualV;

      final speed = math.sqrt(newDu * newDu + newDv * newDv);
      if (!hasLaunched && speed > launchSpeedThresholdPxPerSecond) {
        hasLaunched = true;
      }

      current = _TrackState(
        u: newU,
        v: newV,
        du: newDu,
        dv: newDv,
        diameterPx: matched.diameterPx,
        frameTimeMs: frameTimeMs,
      );
      states.add(
        TrackedBallState(
          frameTimeMs: frameTimeMs,
          u: current.u,
          v: current.v,
          du: current.du,
          dv: current.dv,
          diameterPx: current.diameterPx,
          phase: hasLaunched
              ? BallTrackingPhase.launch
              : BallTrackingPhase.address,
        ),
      );
    }

    return states;
  }
}

class _TrackState {
  const _TrackState({
    required this.u,
    required this.v,
    required this.du,
    required this.dv,
    required this.diameterPx,
    required this.frameTimeMs,
  });

  final double u;
  final double v;
  final double du;
  final double dv;
  final double diameterPx;
  final int frameTimeMs;
}
