import 'package:dan_do/data/tracking/ball_kalman_tracker.dart';
import 'package:dan_do/domain/models/raw_ball_detection.dart';
import 'package:dan_do/domain/models/tracked_ball_state.dart';
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
  group('BallKalmanTracker.track', () {
    test('静止した観測が続く間はaddressフェーズのまま平滑化された位置を出力する', () {
      const tracker = BallKalmanTracker();
      final detections = [
        _detection(frameTimeMs: 0, u: 100, v: 100),
        _detection(frameTimeMs: 33, u: 103, v: 98),
        _detection(frameTimeMs: 66, u: 98, v: 102),
        _detection(frameTimeMs: 99, u: 101, v: 99),
      ];

      final states = tracker.track(detections);

      expect(states, hasLength(4));
      for (final state in states) {
        expect(state.phase, BallTrackingPhase.address);
        expect(state.u, closeTo(100, 5));
        expect(state.v, closeTo(100, 5));
      }
    });

    test('静止区間の後に急加速するとlaunchフェーズへ切り替わる', () {
      const tracker = BallKalmanTracker();
      final detections = [
        _detection(frameTimeMs: 0, u: 100, v: 100),
        _detection(frameTimeMs: 33, u: 101, v: 99),
        _detection(frameTimeMs: 66, u: 99, v: 101),
        // インパクト直後、1フレーム(33ms)で150px移動(=約4545px/秒)
        _detection(frameTimeMs: 99, u: 249, v: 101),
        _detection(frameTimeMs: 132, u: 399, v: 101),
      ];

      final states = tracker.track(detections);

      expect(states, hasLength(5));
      expect(states[0].phase, BallTrackingPhase.address);
      expect(states[1].phase, BallTrackingPhase.address);
      expect(states[2].phase, BallTrackingPhase.address);
      expect(states[3].phase, BallTrackingPhase.launch);
      expect(states[4].phase, BallTrackingPhase.launch);
    });

    test('予測位置から大きく外れた誤検出はゲーティングで除去され、追跡は乱れない', () {
      const tracker = BallKalmanTracker();
      final detections = [
        _detection(frameTimeMs: 0, u: 100, v: 100),
        _detection(frameTimeMs: 33, u: 100, v: 100),
        // 白帽子等の誤検出を想定した、遠く離れた候補
        _detection(frameTimeMs: 66, u: 900, v: 900),
        _detection(frameTimeMs: 99, u: 100, v: 100),
      ];

      final states = tracker.track(detections);

      expect(states, hasLength(4));
      expect(states[2].phase, BallTrackingPhase.lost);
      expect(states[2].u, isNot(closeTo(900, 100)));
      expect(states[3].phase, BallTrackingPhase.address);
      expect(states[3].u, closeTo(100, 5));
      expect(states[3].v, closeTo(100, 5));
    });

    test('信頼度が閾値未満の検出は候補から除外される', () {
      const tracker = BallKalmanTracker(confidenceThreshold: 0.5);
      final detections = [
        _detection(frameTimeMs: 0, u: 100, v: 100),
        _detection(frameTimeMs: 33, u: 100, v: 100),
        _detection(frameTimeMs: 66, u: 105, v: 100, confidence: 0.2),
        _detection(frameTimeMs: 99, u: 100, v: 100),
      ];

      final states = tracker.track(detections);

      expect(states[2].phase, BallTrackingPhase.lost);
    });
  });
}
