import 'dart:ui';

import 'package:cross_file/cross_file.dart';

import '../../core/club_constants.dart';
import '../models/shot_result.dart';

abstract class ShotAnalysisService {
  Future<ShotResult> analyze(
    XFile video, {
    required Offset initialBallPositionPx,
    required ClubType clubType,
  });
}
