import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/shot_result.dart';
import '../../domain/services/ball_trajectory_analysis_service.dart';

part 'analysis_controller.g.dart';

@riverpod
class AnalysisController extends _$AnalysisController {
  @override
  Future<ShotResult> build(XFile video, Offset initialBallPositionPx) async {
    final service = await ref.watch(shotAnalysisServiceProvider.future);
    return service.analyze(
      video,
      initialBallPositionPx: initialBallPositionPx,
    );
  }
}
