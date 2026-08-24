import 'package:dan_do/domain/services/distance_estimation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DistanceEstimation.focalLengthPx', () {
    test('画角90度・フレーム幅1000pxなら焦点距離は500px', () {
      final result = DistanceEstimation.focalLengthPx(
        frameWidthPx: 1000,
        fovDegrees: 90,
      );

      expect(result, closeTo(500, 0.001));
    });
  });

  group('DistanceEstimation.estimateDepthMeters', () {
    test('既知のボール直径・画像上の直径・焦点距離から奥行きを算出する', () {
      final depth = DistanceEstimation.estimateDepthMeters(
        diameterPx: 50,
        focalLengthPx: 500,
        ballDiameterMeters: 0.05,
      );

      expect(depth, closeTo(0.5, 0.0001));
    });

    test('画像上の直径が半分になると奥行きは倍になる', () {
      final near = DistanceEstimation.estimateDepthMeters(
        diameterPx: 50,
        focalLengthPx: 500,
        ballDiameterMeters: 0.05,
      );
      final far = DistanceEstimation.estimateDepthMeters(
        diameterPx: 25,
        focalLengthPx: 500,
        ballDiameterMeters: 0.05,
      );

      expect(far, closeTo(near * 2, 0.0001));
    });
  });

  group('DistanceEstimation.estimateWorldPosition', () {
    test('基準点と同じ位置・同じ奥行きならXYZすべて0になる', () {
      final position = DistanceEstimation.estimateWorldPosition(
        centerPx: const Offset(500, 400),
        diameterPx: 50,
        originPx: const Offset(500, 400),
        referenceDepthMeters: 0.5,
        focalLengthPx: 500,
        ballDiameterMeters: 0.05,
      );

      expect(position.x, closeTo(0, 0.0001));
      expect(position.y, closeTo(0, 0.0001));
      expect(position.z, closeTo(0, 0.0001));
    });

    test('基準点よりU座標が大きい(右側)ならXは正になる', () {
      final position = DistanceEstimation.estimateWorldPosition(
        centerPx: const Offset(600, 400),
        diameterPx: 50,
        originPx: const Offset(500, 400),
        referenceDepthMeters: 0.5,
        focalLengthPx: 500,
        ballDiameterMeters: 0.05,
      );

      expect(position.x, closeTo(0.1, 0.0001));
      expect(position.y, closeTo(0, 0.0001));
    });

    test('基準点よりV座標が小さい(画像上部=高い位置)ならYは正になる', () {
      final position = DistanceEstimation.estimateWorldPosition(
        centerPx: const Offset(500, 350),
        diameterPx: 50,
        originPx: const Offset(500, 400),
        referenceDepthMeters: 0.5,
        focalLengthPx: 500,
        ballDiameterMeters: 0.05,
      );

      expect(position.y, closeTo(0.05, 0.0001));
    });

    test('画像上の直径が縮み奥行きが基準より深くなるとZは正になる', () {
      final position = DistanceEstimation.estimateWorldPosition(
        centerPx: const Offset(500, 400),
        diameterPx: 25,
        originPx: const Offset(500, 400),
        referenceDepthMeters: 0.5,
        focalLengthPx: 500,
        ballDiameterMeters: 0.05,
      );

      expect(position.z, closeTo(0.5, 0.0001));
    });
  });
}
