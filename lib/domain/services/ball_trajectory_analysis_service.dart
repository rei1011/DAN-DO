import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/assumed_camera_intrinsics.dart';
import '../../core/roi_constants.dart';
import '../../data/ml/ball_detector.dart';
import '../../data/ml/ball_detector_provider.dart';
import '../../data/ml/frame_cropper.dart';
import '../../data/tracking/ball_kalman_tracker.dart';
import '../../data/video/get_thumbnail_video_frame_source.dart';
import '../../data/video/video_duration_reader.dart';
import '../../data/video/video_frame_source.dart';
import '../../data/video/video_player_duration_reader.dart';
import '../models/raw_ball_detection.dart';
import '../models/shot_result.dart';
import '../models/tracked_ball_state.dart';
import '../models/trajectory_point.dart';
import 'ballistics_simulator.dart';
import 'distance_estimation.dart';
import 'launch_parameter_estimator.dart';
import 'roi_sequencer.dart';
import 'shot_analysis_service.dart';

part 'ball_trajectory_analysis_service.g.dart';

/// アドレス区間または飛球区間の観測が、弾道パラメータ推定に必要な数だけ
/// 得られなかった場合に投げられる。
class InsufficientTrajectoryDataException implements Exception {
  const InsufficientTrajectoryDataException(this.message);

  final String message;

  @override
  String toString() => 'InsufficientTrajectoryDataException: $message';
}

class BallTrajectoryAnalysisService implements ShotAnalysisService {
  BallTrajectoryAnalysisService({
    required this.ballDetector,
    required this.videoDurationReader,
    required this.frameSourceFactory,
    this.tracker = const BallKalmanTracker(),
  });

  static const frameInterval = Duration(milliseconds: 33);

  final BallDetector ballDetector;
  final VideoDurationReader videoDurationReader;
  final VideoFrameSource Function(XFile video) frameSourceFactory;
  final BallKalmanTracker tracker;

  @override
  Future<ShotResult> analyze(
    XFile video, {
    required Offset initialBallPositionPx,
  }) async {
    final duration = await videoDurationReader.read(video);
    final frameSource = frameSourceFactory(video);

    final detections = <RawBallDetection>[];
    double? frameWidthPx;
    Offset? searchCenterPx = initialBallPositionPx;
    var cropSizePx = RoiConstants.initialCropSizePx;
    BallTrackerCursor? roiCursor;
    var consecutiveLostFrames = 0;

    for (var t = Duration.zero; t < duration; t += frameInterval) {
      final frameBytes = await frameSource.frameAt(t);
      frameWidthPx ??= await _decodeFrameWidthPx(frameBytes);
      debugPrint('[diag] frameBytesLength=${frameBytes.lengthInBytes}');

      final decision = RoiSequencer.decideNextRoi(
        searchCenterPx: searchCenterPx,
        cropSizePx: cropSizePx,
        consecutiveLostFrames: consecutiveLostFrames,
      );

      List<RawBallDetection> frameDetections;
      if (decision.useFullFrame) {
        frameDetections = await ballDetector.detect(frameBytes, frameTime: t);
      } else {
        final cropped = await FrameCropper.crop(
          frameBytes,
          centerPx: decision.centerPx!,
          cropSizePx: decision.cropSizePx,
        );
        final rawDetections = await ballDetector.detect(
          cropped.bytes,
          frameTime: t,
        );
        frameDetections = rawDetections
            .map((d) => FrameCropper.translateDetection(d, cropped.offsetPx))
            .toList();
      }

      detections.addAll(frameDetections);

      debugPrint(
        '[diag] t=${t.inMilliseconds}ms '
        'mode=${decision.useFullFrame ? "full" : "crop c=${decision.centerPx} sz=${decision.cropSizePx}"} '
        'n=${frameDetections.length} '
        '${frameDetections.map((d) => "(conf=${d.confidence.toStringAsFixed(2)},pos=${d.centerPx},d=${d.diameterPx.toStringAsFixed(1)})").join(" ")}',
      );

      final hasConfidentCandidate = frameDetections.any(
        (d) => d.confidence >= tracker.confidenceThreshold,
      );
      if (roiCursor == null && !hasConfidentCandidate) {
        continue;
      }
      final stepResult = tracker.step(
        cursor: roiCursor,
        candidatesAtFrame: frameDetections,
        frameTimeMs: t.inMilliseconds,
        referencePositionPx: initialBallPositionPx,
      );
      consecutiveLostFrames =
          (frameDetections.isEmpty ||
              stepResult.state.phase == BallTrackingPhase.lost)
          ? consecutiveLostFrames + 1
          : 0;
      roiCursor = stepResult.cursor;
      searchCenterPx = Offset(roiCursor.u, roiCursor.v);
      cropSizePx = RoiConstants.trackingCropSizePx;

      debugPrint(
        '[diag]   -> phase=${stepResult.state.phase.name} '
        'cursor=(${roiCursor.u.toStringAsFixed(1)},${roiCursor.v.toStringAsFixed(1)}) '
        'vel=(${roiCursor.du.toStringAsFixed(1)},${roiCursor.dv.toStringAsFixed(1)}) '
        'lostStreak=$consecutiveLostFrames',
      );
    }

    debugPrint(
      'BallTrajectoryAnalysisService: sports ball detections=${detections.length}',
    );

    if (frameWidthPx == null) {
      throw const InsufficientTrajectoryDataException('動画からフレームを取得できませんでした');
    }

    return buildShotResult(
      detections: detections,
      frameWidthPx: frameWidthPx,
      initialBallPositionPx: initialBallPositionPx,
    );
  }

  static Future<double> _decodeFrameWidthPx(Uint8List frameBytes) async {
    final codec = await ui.instantiateImageCodec(frameBytes);
    final frame = await codec.getNextFrame();
    return frame.image.width.toDouble();
  }

  /// [BallKalmanTracker]・[DistanceEstimation]・[LaunchParameterEstimator]・
  /// [BallisticsSimulator]を結線し、検出列から[ShotResult]を構築する純粋関数。
  ///
  /// アドレス区間直近の観測から基準奥行き(Z0)を、飛球区間の観測から
  /// 打ち出しパラメータを算出し、着地までの弾道をシミュレーションする。
  static ShotResult buildShotResult({
    required List<RawBallDetection> detections,
    required double frameWidthPx,
    Offset? initialBallPositionPx,
    BallKalmanTracker tracker = const BallKalmanTracker(),
  }) {
    final trackedStates = tracker.track(
      detections,
      referencePositionPx: initialBallPositionPx,
    );

    final addressStates = trackedStates
        .where((s) => s.phase == BallTrackingPhase.address)
        .toList();
    final launchStates = trackedStates
        .where((s) => s.phase == BallTrackingPhase.launch)
        .toList();

    if (addressStates.isEmpty) {
      throw const InsufficientTrajectoryDataException('アドレス区間でボールを検出できませんでした');
    }
    if (launchStates.length < 2) {
      throw const InsufficientTrajectoryDataException(
        '飛球区間の観測が不足しています(ボールをロストした可能性があります)',
      );
    }

    final focalLengthPx = DistanceEstimation.focalLengthPx(
      frameWidthPx: frameWidthPx,
      fovDegrees: AssumedCameraIntrinsics.narrowAxisFovDegrees,
    );

    final referenceState = addressStates.last;
    final originPx = ui.Offset(referenceState.u, referenceState.v);
    final referenceDepthMeters = DistanceEstimation.estimateDepthMeters(
      diameterPx: referenceState.diameterPx,
      focalLengthPx: focalLengthPx,
    );

    final launchStartMs = launchStates.first.frameTimeMs;
    final measuredTrajectory = launchStates.map((state) {
      final world = DistanceEstimation.estimateWorldPosition(
        centerPx: ui.Offset(state.u, state.v),
        diameterPx: state.diameterPx,
        originPx: originPx,
        referenceDepthMeters: referenceDepthMeters,
        focalLengthPx: focalLengthPx,
      );
      return TrajectoryPoint(
        t: (state.frameTimeMs - launchStartMs) / 1000.0,
        x: world.x,
        y: world.y,
        z: world.z,
        isMeasured: true,
      );
    }).toList();

    final launchParams = LaunchParameterEstimator.estimate(measuredTrajectory);

    final simulatedTrajectory = BallisticsSimulator.simulate(
      v0: launchParams.v0,
      launchAngleDegrees: launchParams.launchAngleDegrees,
      launchDirectionDegrees: launchParams.launchDirectionDegrees,
    );

    final landing = simulatedTrajectory.last;
    final carryDistanceMeters = math.sqrt(
      landing.x * landing.x + landing.z * landing.z,
    );

    return ShotResult(
      carryDistanceMeters: carryDistanceMeters,
      launchAngleDegrees: launchParams.launchAngleDegrees,
      launchDirectionDegrees: launchParams.launchDirectionDegrees,
      measuredTrajectory: measuredTrajectory,
      simulatedTrajectory: simulatedTrajectory,
    );
  }
}

@riverpod
Future<ShotAnalysisService> shotAnalysisService(Ref ref) async {
  final detector = await ref.watch(ballDetectorProvider.future);
  final durationReader = ref.watch(videoDurationReaderProvider);

  return BallTrajectoryAnalysisService(
    ballDetector: detector,
    videoDurationReader: durationReader,
    frameSourceFactory: GetThumbnailVideoFrameSource.new,
  );
}
