import 'package:cross_file/cross_file.dart';
import 'package:dan_do/domain/models/shot_result.dart';
import 'package:dan_do/domain/services/shot_analysis_service.dart';

class FakeShotAnalysisService implements ShotAnalysisService {
  @override
  Future<ShotResult> analyze(XFile video) async {
    return const ShotResult(
      carryDistanceMeters: 150,
      launchAngleDegrees: 15,
      launchDirectionDegrees: 0,
      measuredTrajectory: [],
      simulatedTrajectory: [],
    );
  }
}
