import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/ml/ball_detector.dart';
import '../../data/ml/ball_detector_provider.dart';
import '../../data/video/get_thumbnail_video_frame_source.dart';
import '../../data/video/video_duration_reader.dart';
import '../../data/video/video_frame_source.dart';
import '../../data/video/video_player_duration_reader.dart';
import '../models/raw_ball_detection.dart';
import '../models/shot_result.dart';
import 'shot_analysis_service.dart';

part 'ball_trajectory_analysis_service.g.dart';

class BallTrajectoryAnalysisService implements ShotAnalysisService {
  BallTrajectoryAnalysisService({
    required this.ballDetector,
    required this.videoDurationReader,
    required this.frameSourceFactory,
  });

  static const frameInterval = Duration(milliseconds: 33);

  final BallDetector ballDetector;
  final VideoDurationReader videoDurationReader;
  final VideoFrameSource Function(XFile video) frameSourceFactory;

  @override
  Future<ShotResult> analyze(XFile video) async {
    final duration = await videoDurationReader.read(video);
    final frameSource = frameSourceFactory(video);

    final detections = <RawBallDetection>[];
    for (var t = Duration.zero; t < duration; t += frameInterval) {
      final frameBytes = await frameSource.frameAt(t);
      detections.addAll(await ballDetector.detect(frameBytes, frameTime: t));
    }

    debugPrint(
      'BallTrajectoryAnalysisService: sports ball detections=${detections.length}',
    );

    // Phase1は配線確認が目的のため固定のダミー値を返す。距離推定・弾道シミュレーションの
    // 実計算はPhase2/3(distance_estimation.dart / ballistics_simulator.dart)で置き換える。
    return const ShotResult(
      carryDistanceMeters: 150,
      launchAngleDegrees: 15,
      launchDirectionDegrees: 0,
      measuredTrajectory: [],
      simulatedTrajectory: [],
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
