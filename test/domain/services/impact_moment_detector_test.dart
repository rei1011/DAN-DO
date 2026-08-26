import 'package:dan_do/domain/models/raw_club_detection.dart';
import 'package:dan_do/domain/services/impact_moment_detector.dart';
import 'package:flutter_test/flutter_test.dart';

RawClubDetection _det(int frameTimeMs, Offset centerPx) {
  return RawClubDetection(
    frameTimeMs: frameTimeMs,
    centerPx: centerPx,
    confidence: 0.9,
    part: ClubPart.head,
  );
}

void main() {
  group('ImpactMomentDetector.detect', () {
    const addressBallPositionPx = Offset(100, 100);

    test('バックスイングで離れてから最接近したフレームをインパクトと推定する', () {
      final detections = [
        _det(0, const Offset(100, 100)), // アドレス付近
        _det(33, const Offset(300, 50)), // バックスイングのピーク
        _det(66, const Offset(150, 90)), // ダウンスイング中
        _det(99, const Offset(102, 101)), // インパクト(最接近)
        _det(132, const Offset(250, 90)), // フォロースルーで再び離れる(ピークほどではない)
      ];

      final impactFrameTimeMs = ImpactMomentDetector.detect(
        headDetections: detections,
        addressBallPositionPx: addressBallPositionPx,
      );

      expect(impactFrameTimeMs, 99);
    });

    test('検出の順序が入れ替わっていても時刻でソートして判定する', () {
      final detections = [
        _det(132, const Offset(250, 90)),
        _det(0, const Offset(100, 100)),
        _det(99, const Offset(102, 101)),
        _det(33, const Offset(300, 50)),
        _det(66, const Offset(150, 90)),
      ];

      final impactFrameTimeMs = ImpactMomentDetector.detect(
        headDetections: detections,
        addressBallPositionPx: addressBallPositionPx,
      );

      expect(impactFrameTimeMs, 99);
    });

    test('検出が2点未満の場合はArgumentErrorを投げる', () {
      expect(
        () => ImpactMomentDetector.detect(
          headDetections: [_det(0, const Offset(100, 100))],
          addressBallPositionPx: addressBallPositionPx,
        ),
        throwsArgumentError,
      );
    });

    test('離れ続けるだけで復帰が観測できない場合はStateErrorを投げる', () {
      final detections = [
        _det(0, const Offset(100, 100)),
        _det(33, const Offset(200, 100)),
        _det(66, const Offset(300, 100)),
      ];

      expect(
        () => ImpactMomentDetector.detect(
          headDetections: detections,
          addressBallPositionPx: addressBallPositionPx,
        ),
        throwsStateError,
      );
    });
  });
}
