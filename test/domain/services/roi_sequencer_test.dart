import 'package:dan_do/core/roi_constants.dart';
import 'package:dan_do/domain/services/roi_sequencer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoiSequencer.decideNextRoi', () {
    test('探索中心が未確定なら全体フレーム探索を返す', () {
      final decision = RoiSequencer.decideNextRoi(
        searchCenterPx: null,
        cropSizePx: RoiConstants.initialCropSizePx,
        consecutiveLostFrames: 0,
      );

      expect(decision.useFullFrame, isTrue);
      expect(decision.centerPx, isNull);
    });

    test('探索中心がありロスト回数が閾値未満ならクロップ探索を返す', () {
      final decision = RoiSequencer.decideNextRoi(
        searchCenterPx: const Offset(100, 200),
        cropSizePx: RoiConstants.trackingCropSizePx,
        consecutiveLostFrames: RoiConstants.maxLostFramesBeforeFullFrameFallback - 1,
      );

      expect(decision.useFullFrame, isFalse);
      expect(decision.centerPx, const Offset(100, 200));
      expect(decision.cropSizePx, RoiConstants.trackingCropSizePx);
    });

    test('ロスト回数が閾値以上になると全体フレーム探索にフォールバックする', () {
      final decision = RoiSequencer.decideNextRoi(
        searchCenterPx: const Offset(100, 200),
        cropSizePx: RoiConstants.trackingCropSizePx,
        consecutiveLostFrames: RoiConstants.maxLostFramesBeforeFullFrameFallback,
      );

      expect(decision.useFullFrame, isTrue);
    });
  });
}
