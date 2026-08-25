import 'dart:math' as math;
import 'dart:ui';

import '../../core/tracking_constants.dart';
import '../../domain/models/raw_ball_detection.dart';
import '../../domain/models/tracked_ball_state.dart';

/// [BallKalmanTracker.step]がフレームをまたいで引き回す内部状態。
/// [predictedCenterPx]をROI決定(次フレームのクロップ中心)に使う。
class BallTrackerCursor {
  const BallTrackerCursor({
    required this.u,
    required this.v,
    required this.du,
    required this.dv,
    required this.diameterPx,
    required this.frameTimeMs,
    required this.hasLaunched,
  });

  final double u;
  final double v;
  final double du;
  final double dv;
  final double diameterPx;
  final int frameTimeMs;
  final bool hasLaunched;

  /// 現在の位置・速度から、[atFrameTimeMs]時点の予測位置を等速直線運動で外挿する。
  Offset predictedCenterPx(int atFrameTimeMs) {
    final dtSeconds = (atFrameTimeMs - frameTimeMs) / 1000.0;
    return Offset(u + du * dtSeconds, v + dv * dtSeconds);
  }
}

/// [BallKalmanTracker.step]が返す、1フレーム分の更新結果。
class BallTrackerStepResult {
  const BallTrackerStepResult({required this.cursor, required this.state});

  final BallTrackerCursor cursor;
  final TrackedBallState state;
}

/// 手書きの簡易カルマンフィルタ(定速度モデル、g-h/alpha-betaフィルタ)による
/// ボール位置の平滑化・誤検出のゲーティング・フェーズ判定を行う。
///
/// 統計的に厳密なMahalanobis距離等は用いず、単純な閾値判定のゲーティングで
/// 十分とする方針(`docs/implementation-plan-analysis-pipeline.md`参照)。
class BallKalmanTracker {
  const BallKalmanTracker({
    this.confidenceThreshold = TrackingConstants.confidenceThreshold,
    this.gatingRadiusPx = TrackingConstants.gatingRadiusPx,
    this.minDiameterRatio = TrackingConstants.minDiameterRatio,
    this.maxDiameterRatio = TrackingConstants.maxDiameterRatio,
    this.launchSpeedThresholdPxPerSecond =
        TrackingConstants.launchSpeedThresholdPxPerSecond,
  });

  final double confidenceThreshold;
  final double gatingRadiusPx;
  final double minDiameterRatio;
  final double maxDiameterRatio;
  final double launchSpeedThresholdPxPerSecond;

  /// 位置補正のゲイン(alpha)。予測と観測の残差をどれだけ位置に反映するか。
  static const double _positionGain = 0.6;

  /// 速度補正のゲイン(beta)。残差をどれだけ速度推定の更新に反映するか。
  static const double _velocityGain = 0.3;

  List<TrackedBallState> track(
    List<RawBallDetection> detections, {
    Offset? referencePositionPx,
  }) {
    final byFrameTimeMs = <int, List<RawBallDetection>>{};
    for (final detection in detections) {
      (byFrameTimeMs[detection.frameTimeMs] ??= []).add(detection);
    }
    final sortedFrameTimes = byFrameTimeMs.keys.toList()..sort();

    final states = <TrackedBallState>[];
    BallTrackerCursor? cursor;

    for (final frameTimeMs in sortedFrameTimes) {
      final candidates = byFrameTimeMs[frameTimeMs]!;

      if (cursor == null &&
          candidates.every((d) => d.confidence < confidenceThreshold)) {
        continue;
      }
      if (cursor != null && frameTimeMs - cursor.frameTimeMs <= 0) {
        continue;
      }

      final result = step(
        cursor: cursor,
        candidatesAtFrame: candidates,
        frameTimeMs: frameTimeMs,
        referencePositionPx: referencePositionPx,
      );
      cursor = result.cursor;
      states.add(result.state);
    }

    return states;
  }

  /// 1フレーム分の検出候補からトラッカー状態を1ステップ進める。
  ///
  /// [cursor]が`null`の場合は追跡開始前とみなし、[candidatesAtFrame]の中で
  /// 信頼度が[confidenceThreshold]以上の候補から追跡開始点を選ぶ。
  /// [referencePositionPx](ユーザーがタップしたボール位置)が指定されていれば、
  /// 背景に写り込んだ別のボール等を誤って追跡開始点に選ばないよう、
  /// その位置に最も近い候補を採用する。指定が無ければ最も信頼度が高い候補を採用する
  /// (後方互換のためのフォールバック)。信頼度条件を満たす候補が1件も無い状態で
  /// [cursor]が`null`のまま呼び出すことはできない(呼び出し側で候補が出るまで
  /// 呼び出しをスキップすること)。
  BallTrackerStepResult step({
    required BallTrackerCursor? cursor,
    required List<RawBallDetection> candidatesAtFrame,
    required int frameTimeMs,
    Offset? referencePositionPx,
  }) {
    final candidates = candidatesAtFrame
        .where((d) => d.confidence >= confidenceThreshold)
        .toList();

    if (cursor == null) {
      if (candidates.isEmpty) {
        throw ArgumentError(
          'cursorがnullの場合、candidatesAtFrameに信頼度条件を満たす候補が'
          '1件以上必要です',
        );
      }
      final best = referencePositionPx != null
          ? candidates.reduce(
              (a, b) =>
                  (a.centerPx - referencePositionPx).distanceSquared <=
                      (b.centerPx - referencePositionPx).distanceSquared
                  ? a
                  : b,
            )
          : candidates.reduce(
              (a, b) => a.confidence >= b.confidence ? a : b,
            );
      final newCursor = BallTrackerCursor(
        u: best.centerPx.dx,
        v: best.centerPx.dy,
        du: 0,
        dv: 0,
        diameterPx: best.diameterPx,
        frameTimeMs: frameTimeMs,
        hasLaunched: false,
      );
      final state = TrackedBallState(
        frameTimeMs: frameTimeMs,
        u: newCursor.u,
        v: newCursor.v,
        du: newCursor.du,
        dv: newCursor.dv,
        diameterPx: newCursor.diameterPx,
        phase: BallTrackingPhase.address,
      );
      return BallTrackerStepResult(cursor: newCursor, state: state);
    }

    final dtSeconds = (frameTimeMs - cursor.frameTimeMs) / 1000.0;
    final predicted = cursor.predictedCenterPx(frameTimeMs);
    final predictedU = predicted.dx;
    final predictedV = predicted.dy;

    RawBallDetection? matched;
    var matchedDistance = double.infinity;
    for (final candidate in candidates) {
      final diameterRatio = candidate.diameterPx / cursor.diameterPx;
      if (diameterRatio < minDiameterRatio || diameterRatio > maxDiameterRatio) {
        continue;
      }
      final dx = candidate.centerPx.dx - predictedU;
      final dy = candidate.centerPx.dy - predictedV;
      final distance = math.sqrt(dx * dx + dy * dy);
      if (distance <= gatingRadiusPx && distance < matchedDistance) {
        matched = candidate;
        matchedDistance = distance;
      }
    }

    if (matched == null) {
      final newCursor = BallTrackerCursor(
        u: predictedU,
        v: predictedV,
        du: cursor.du,
        dv: cursor.dv,
        diameterPx: cursor.diameterPx,
        frameTimeMs: frameTimeMs,
        hasLaunched: cursor.hasLaunched,
      );
      final state = TrackedBallState(
        frameTimeMs: frameTimeMs,
        u: newCursor.u,
        v: newCursor.v,
        du: newCursor.du,
        dv: newCursor.dv,
        diameterPx: newCursor.diameterPx,
        phase: BallTrackingPhase.lost,
      );
      return BallTrackerStepResult(cursor: newCursor, state: state);
    }

    final residualU = matched.centerPx.dx - predictedU;
    final residualV = matched.centerPx.dy - predictedV;

    final newU = predictedU + _positionGain * residualU;
    final newV = predictedV + _positionGain * residualV;
    final newDu = cursor.du + (_velocityGain / dtSeconds) * residualU;
    final newDv = cursor.dv + (_velocityGain / dtSeconds) * residualV;

    final speed = math.sqrt(newDu * newDu + newDv * newDv);
    final hasLaunched =
        cursor.hasLaunched || speed > launchSpeedThresholdPxPerSecond;

    final newCursor = BallTrackerCursor(
      u: newU,
      v: newV,
      du: newDu,
      dv: newDv,
      diameterPx: matched.diameterPx,
      frameTimeMs: frameTimeMs,
      hasLaunched: hasLaunched,
    );
    final state = TrackedBallState(
      frameTimeMs: frameTimeMs,
      u: newCursor.u,
      v: newCursor.v,
      du: newCursor.du,
      dv: newCursor.dv,
      diameterPx: newCursor.diameterPx,
      phase: hasLaunched
          ? BallTrackingPhase.launch
          : BallTrackingPhase.address,
    );
    return BallTrackerStepResult(cursor: newCursor, state: state);
  }
}
