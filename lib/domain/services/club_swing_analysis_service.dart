import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/assumed_camera_intrinsics.dart';
import '../../core/club_constants.dart';
import '../../core/roi_constants.dart';
import '../../core/tracking_constants.dart';
import '../../data/ml/ball_detector.dart';
import '../../data/ml/ball_detector_provider.dart';
import '../../data/ml/club_detector.dart';
import '../../data/ml/club_detector_provider.dart';
import '../../data/ml/frame_cropper.dart';
import '../../data/video/get_thumbnail_video_frame_source.dart';
import '../../data/video/video_duration_reader.dart';
import '../../data/video/video_frame_source.dart';
import '../../data/video/video_player_duration_reader.dart';
import '../models/raw_ball_detection.dart';
import '../models/raw_club_detection.dart';
import '../models/shot_result.dart';
import '../models/trajectory_point.dart';
import 'ballistics_simulator.dart';
import 'club_path_estimator.dart';
import 'distance_estimation.dart';
import 'impact_moment_detector.dart';
import 'launch_parameter_estimator.dart';
import 'shot_analysis_service.dart';
import 'spin_estimator.dart';

part 'club_swing_analysis_service.g.dart';

/// クラブヘッド検出の欠測・インパクト特定失敗など、[ClubSwingAnalysisService]
/// 固有の失敗箇所を表す例外。
class ClubSwingAnalysisException implements Exception {
  const ClubSwingAnalysisException(this.message);

  final String message;

  @override
  String toString() => 'ClubSwingAnalysisException: $message';
}

/// クラブヘッドの挙動(クラブパス・アタック角・クラブヘッド速度)からボールの
/// 弾道パラメータを逆算する[ShotAnalysisService]の実装(docs/design-club-swing-analysis.md)。
///
/// [RawClubDetection]にはボールの実直径のようなサイズ情報が無いため、クラブヘッドの
/// 奥行きは単独では推定できない。同一フレームで検出したクラブヘッド・ハンドル間の
/// 画像上の距離(見かけのシャフト長)と[ClubConstants.shaftLengthMeters]の実寸を
/// 比較し、ボールと同じピンホールカメラの原理([DistanceEstimation])で奥行きを推定する。
class ClubSwingAnalysisService implements ShotAnalysisService {
  ClubSwingAnalysisService({
    required this.ballDetector,
    required this.clubDetector,
    required this.videoDurationReader,
    required this.frameSourceFactory,
  });

  static const frameInterval = Duration(milliseconds: 33);

  final BallDetector ballDetector;
  final ClubDetector clubDetector;
  final VideoDurationReader videoDurationReader;
  final VideoFrameSource Function(XFile video) frameSourceFactory;

  @override
  Future<ShotResult> analyze(
    XFile video, {
    required Offset initialBallPositionPx,
    required ClubType clubType,
  }) async {
    final duration = await videoDurationReader.read(video);
    final frameSource = frameSourceFactory(video);

    // 1. アドレス時のボール検出: タップ位置周辺のクロップから奥行き・スケール基準を確立する。
    final addressFrameBytes = await frameSource.frameAt(Duration.zero);
    final addressCropped = await FrameCropper.crop(
      addressFrameBytes,
      centerPx: initialBallPositionPx,
      cropSizePx: RoiConstants.initialCropSizePx,
    );
    final addressCandidates = await ballDetector.detect(
      addressCropped.bytes,
      frameTime: Duration.zero,
    );
    final addressDetection = _bestConfidence(
      addressCandidates.where(
        (d) => d.confidence >= TrackingConstants.confidenceThreshold,
      ),
    );
    if (addressDetection == null) {
      throw const ClubSwingAnalysisException('アドレス時のボールを検出できませんでした');
    }
    final originPx = FrameCropper.translateDetection(
      addressDetection,
      addressCropped.offsetPx,
    ).centerPx;

    final frameWidthPx = await _decodeFrameWidthPx(addressFrameBytes);
    final focalLengthPx = DistanceEstimation.focalLengthPx(
      frameWidthPx: frameWidthPx,
      fovDegrees: AssumedCameraIntrinsics.narrowAxisFovDegrees,
    );
    final referenceDepthMeters = DistanceEstimation.estimateDepthMeters(
      diameterPx: addressDetection.diameterPx,
      focalLengthPx: focalLengthPx,
    );
    debugPrint(
      '[diag-club-swing] address originPx=$originPx '
      'diameterPx=${addressDetection.diameterPx.toStringAsFixed(1)} '
      'confidence=${addressDetection.confidence.toStringAsFixed(2)} '
      'referenceDepthMeters=${referenceDepthMeters.toStringAsFixed(2)} '
      'focalLengthPx=${focalLengthPx.toStringAsFixed(1)}',
    );

    // 2. クラブヘッド・ハンドル追跡: 動画全体をフルフレーム検出する。
    final clubDetections = <RawClubDetection>[];
    for (var t = Duration.zero; t < duration; t += frameInterval) {
      final frameBytes = await frameSource.frameAt(t);
      clubDetections.addAll(
        await clubDetector.detect(frameBytes, frameTime: t),
      );
    }

    final headDetections = clubDetections
        .where((d) => d.part == ClubPart.head)
        .toList();
    if (headDetections.isEmpty) {
      throw const ClubSwingAnalysisException('クラブヘッドを検出できませんでした');
    }

    // 3. インパクトフレームの推定。
    final int impactFrameTimeMs;
    try {
      impactFrameTimeMs = ImpactMomentDetector.detect(
        headDetections: headDetections,
        addressBallPositionPx: originPx,
      );
    } on ArgumentError {
      throw const ClubSwingAnalysisException('インパクトの瞬間を特定できませんでした');
    } on StateError {
      throw const ClubSwingAnalysisException('インパクトの瞬間を特定できませんでした');
    }
    debugPrint(
      '[diag-club-swing] headDetections=${headDetections.length} '
      'handleDetections=${clubDetections.where((d) => d.part == ClubPart.handle).length} '
      'impactFrameTimeMs=$impactFrameTimeMs',
    );

    // 4. クラブパス・アタック角・クラブヘッド速度の算出。
    final shaftLengthMeters = ClubConstants.shaftLengthMeters[clubType]!;
    final handleByFrameTimeMs = <int, RawClubDetection>{
      for (final d in clubDetections.where((d) => d.part == ClubPart.handle))
        d.frameTimeMs: d,
    };
    final pairedBeforeImpact =
        headDetections
            .where((d) => d.frameTimeMs <= impactFrameTimeMs)
            .where((d) => handleByFrameTimeMs.containsKey(d.frameTimeMs))
            .toList()
          ..sort((a, b) => a.frameTimeMs.compareTo(b.frameTimeMs));
    final windowStart = math.max(
      0,
      pairedBeforeImpact.length - ClubConstants.maxPathRegressionFrames,
    );
    final regressionSource = pairedBeforeImpact.sublist(windowStart);
    final clubPathStartMs = regressionSource.isEmpty
        ? 0
        : regressionSource.first.frameTimeMs;
    final clubHeadTrajectory = regressionSource.map((headDetection) {
      final handleDetection = handleByFrameTimeMs[headDetection.frameTimeMs]!;
      final shaftLengthPx =
          (headDetection.centerPx - handleDetection.centerPx).distance;
      final world = DistanceEstimation.estimateWorldPosition(
        centerPx: headDetection.centerPx,
        diameterPx: shaftLengthPx,
        originPx: originPx,
        referenceDepthMeters: referenceDepthMeters,
        focalLengthPx: focalLengthPx,
        ballDiameterMeters: shaftLengthMeters,
      );
      return TrajectoryPoint(
        t: (headDetection.frameTimeMs - clubPathStartMs) / 1000.0,
        x: world.x,
        y: world.y,
        z: world.z,
        isMeasured: true,
      );
    }).toList();

    final ({double clubPathDegrees, double attackAngleDegrees}) clubPath;
    final double clubHeadSpeedMetersPerSecond;
    try {
      clubPath = ClubPathEstimator.estimate(clubHeadTrajectory);
      clubHeadSpeedMetersPerSecond = LaunchParameterEstimator.estimate(
        clubHeadTrajectory,
      ).v0;
    } on ArgumentError {
      throw const ClubSwingAnalysisException('クラブパスを算出できませんでした');
    }
    debugPrint(
      '[diag-club-swing] regressionPoints=${clubHeadTrajectory.length} '
      'clubPathDegrees=${clubPath.clubPathDegrees.toStringAsFixed(1)} '
      'attackAngleDegrees=${clubPath.attackAngleDegrees.toStringAsFixed(1)} '
      'clubHeadSpeedMetersPerSecond=${clubHeadSpeedMetersPerSecond.toStringAsFixed(1)}',
    );

    // 5. インパクト直後のボール検出(範囲限定)。狭いクロップで検出不足の場合、
    // 低カメラアングル・近距離設置などでボールが探索範囲外に出るケースを
    // 想定し、1回だけ広いクロップ(実質フルフレーム)で再探索する。
    var launchDetections = await _searchPostImpactBall(
      frameSource: frameSource,
      impactFrameTimeMs: impactFrameTimeMs,
      duration: duration,
      originPx: originPx,
      cropSizePx: RoiConstants.postImpactBallSearchCropSizePx,
      referenceDiameterPx: addressDetection.diameterPx,
    );
    if (launchDetections.length < 2) {
      launchDetections = await _searchPostImpactBall(
        frameSource: frameSource,
        impactFrameTimeMs: impactFrameTimeMs,
        duration: duration,
        originPx: originPx,
        cropSizePx: RoiConstants.postImpactBallSearchFallbackCropSizePx,
        referenceDiameterPx: addressDetection.diameterPx,
      );
    }

    if (launchDetections.length < 2) {
      throw const ClubSwingAnalysisException('インパクト直後のボールを検出できませんでした');
    }

    final sortedLaunchDetections = [...launchDetections]
      ..sort((a, b) => a.frameTimeMs.compareTo(b.frameTimeMs));
    final launchStartMs = sortedLaunchDetections.first.frameTimeMs;
    final measuredTrajectory = sortedLaunchDetections.map((d) {
      final world = DistanceEstimation.estimateWorldPosition(
        centerPx: d.centerPx,
        diameterPx: d.diameterPx,
        originPx: originPx,
        referenceDepthMeters: referenceDepthMeters,
        focalLengthPx: focalLengthPx,
      );
      return TrajectoryPoint(
        t: (d.frameTimeMs - launchStartMs) / 1000.0,
        x: world.x,
        y: world.y,
        z: world.z,
        isMeasured: true,
      );
    }).toList();

    // 6. 打ち出し方向・角度算出(v0はクラブヘッド速度由来のため使わない)。
    final launchParams = LaunchParameterEstimator.estimate(measuredTrajectory);
    debugPrint(
      '[diag-club-swing] measuredTrajectory='
      '${measuredTrajectory.map((p) => "(t=${p.t.toStringAsFixed(3)},x=${p.x.toStringAsFixed(2)},y=${p.y.toStringAsFixed(2)},z=${p.z.toStringAsFixed(2)})").join(" ")} '
      'launchAngleDegrees=${launchParams.launchAngleDegrees.toStringAsFixed(1)} '
      'launchDirectionDegrees=${launchParams.launchDirectionDegrees.toStringAsFixed(1)}',
    );

    // 7. 曲がり量(サイドスピン)算出。
    final sidespinRpm = SpinEstimator.estimateSidespinRpm(
      launchDirectionDegrees: launchParams.launchDirectionDegrees,
      clubPathDegrees: clubPath.clubPathDegrees,
    );

    // 8. 初速算出。
    final smashFactor = ClubConstants.smashFactor[clubType]!;
    final v0 = clubHeadSpeedMetersPerSecond * smashFactor;

    // 9. 弾道シミュレーション。
    final simulatedTrajectory = BallisticsSimulator.simulate(
      v0: v0,
      launchAngleDegrees: launchParams.launchAngleDegrees,
      launchDirectionDegrees: launchParams.launchDirectionDegrees,
      sidespinRpm: sidespinRpm,
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

  /// インパクトフレームから[RoiConstants.postImpactBallSearchFrameCount]分、
  /// [cropSizePx]のクロップでボールを探索する。
  ///
  /// [referenceDiameterPx](アドレス時のボール直径)に対して
  /// [TrackingConstants.minDiameterRatio]〜[TrackingConstants.maxDiameterRatio]の
  /// 範囲外の検出候補は、無関係な物体(地面に転がる他のボール等)とみなして除外する。
  /// 実機検証で、探索範囲を広げた際に手前の無関係なボールを誤検出し、静止した
  /// 物体を打ち出し軌道として扱ってしまう事象が確認されたための対策(Phase6)。
  Future<List<RawBallDetection>> _searchPostImpactBall({
    required VideoFrameSource frameSource,
    required int impactFrameTimeMs,
    required Duration duration,
    required Offset originPx,
    required double cropSizePx,
    required double referenceDiameterPx,
  }) async {
    final minDiameterPx =
        TrackingConstants.minDiameterRatio * referenceDiameterPx;
    final maxDiameterPx =
        TrackingConstants.maxDiameterRatio * referenceDiameterPx;
    final detections = <RawBallDetection>[];
    for (var i = 0; i < RoiConstants.postImpactBallSearchFrameCount; i++) {
      final t = Duration(milliseconds: impactFrameTimeMs) + frameInterval * i;
      if (t >= duration) {
        break;
      }
      final frameBytes = await frameSource.frameAt(t);
      final cropped = await FrameCropper.crop(
        frameBytes,
        centerPx: originPx,
        cropSizePx: cropSizePx,
      );
      final rawDetections = await ballDetector.detect(
        cropped.bytes,
        frameTime: t,
      );
      detections.addAll(
        rawDetections
            .where((d) => d.confidence >= TrackingConstants.confidenceThreshold)
            .where(
              (d) =>
                  d.diameterPx >= minDiameterPx &&
                  d.diameterPx <= maxDiameterPx,
            )
            .map((d) => FrameCropper.translateDetection(d, cropped.offsetPx)),
      );
    }
    debugPrint(
      '[diag-club-swing] postImpactSearch cropSizePx=${cropSizePx.toStringAsFixed(0)} '
      'originPx=$originPx found=${detections.length} '
      '${detections.map((d) => "(t=${d.frameTimeMs}ms,center=${d.centerPx},diam=${d.diameterPx.toStringAsFixed(1)},conf=${d.confidence.toStringAsFixed(2)})").join(" ")}',
    );
    return detections;
  }

  static RawBallDetection? _bestConfidence(Iterable<RawBallDetection> ds) {
    RawBallDetection? best;
    for (final d in ds) {
      if (best == null || d.confidence > best.confidence) {
        best = d;
      }
    }
    return best;
  }

  static Future<double> _decodeFrameWidthPx(Uint8List frameBytes) async {
    final codec = await ui.instantiateImageCodec(frameBytes);
    final frame = await codec.getNextFrame();
    return frame.image.width.toDouble();
  }
}

@riverpod
Future<ShotAnalysisService> clubSwingAnalysisService(Ref ref) async {
  final ballDetectorInstance = await ref.watch(ballDetectorProvider.future);
  final clubDetectorInstance = await ref.watch(clubDetectorProvider.future);
  final durationReader = ref.watch(videoDurationReaderProvider);

  return ClubSwingAnalysisService(
    ballDetector: ballDetectorInstance,
    clubDetector: clubDetectorInstance,
    videoDurationReader: durationReader,
    frameSourceFactory: GetThumbnailVideoFrameSource.new,
  );
}
