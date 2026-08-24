import 'package:dan_do/domain/models/raw_ball_detection.dart';
import 'package:dan_do/domain/services/ball_trajectory_analysis_service.dart';
import 'package:flutter_test/flutter_test.dart';

RawBallDetection _detection({
  required int frameTimeMs,
  required double u,
  required double v,
  double diameterPx = 20,
  double confidence = 0.9,
}) {
  return RawBallDetection(
    frameTimeMs: frameTimeMs,
    centerPx: Offset(u, v),
    diameterPx: diameterPx,
    confidence: confidence,
  );
}

void main() {
  group('BallTrajectoryAnalysisService.buildShotResult', () {
    test('アドレス区間+飛球区間の検出列からShotResultを構築する', () {
      final detections = [
        // アドレス区間(静止)
        _detection(frameTimeMs: 0, u: 500, v: 800),
        _detection(frameTimeMs: 33, u: 501, v: 799),
        _detection(frameTimeMs: 66, u: 499, v: 801),
        // インパクト直後(飛球区間、右上方向へ急加速)
        _detection(frameTimeMs: 99, u: 650, v: 700, diameterPx: 18),
        _detection(frameTimeMs: 132, u: 800, v: 600, diameterPx: 16),
        _detection(frameTimeMs: 165, u: 950, v: 500, diameterPx: 14),
        _detection(frameTimeMs: 198, u: 1100, v: 400, diameterPx: 12),
      ];

      final result = BallTrajectoryAnalysisService.buildShotResult(
        detections: detections,
        frameWidthPx: 1080,
      );

      expect(result.carryDistanceMeters, greaterThan(0));
      expect(result.launchAngleDegrees, greaterThan(0));
      expect(result.launchAngleDegrees, lessThan(90));
      expect(result.measuredTrajectory, hasLength(4));
      expect(result.measuredTrajectory.every((p) => p.isMeasured), isTrue);
      expect(result.simulatedTrajectory, isNotEmpty);
      expect(result.simulatedTrajectory.every((p) => !p.isMeasured), isTrue);
      expect(result.simulatedTrajectory.last.y, equals(0));
    });

    test('飛球区間の観測が不足している場合は例外を投げる', () {
      final detections = [
        _detection(frameTimeMs: 0, u: 500, v: 800),
        _detection(frameTimeMs: 33, u: 501, v: 799),
      ];

      expect(
        () => BallTrajectoryAnalysisService.buildShotResult(
          detections: detections,
          frameWidthPx: 1080,
        ),
        throwsA(isA<InsufficientTrajectoryDataException>()),
      );
    });
  });
}
