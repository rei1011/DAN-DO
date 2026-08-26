import 'dart:ui';

import '../models/raw_club_detection.dart';

/// クラブヘッド検出列とアドレス時ボール位置から、インパクトフレームを推定する(純粋関数)。
///
/// クラブヘッドはバックスイングでアドレス位置から離れ、ダウンスイングで再び
/// 最接近する。この最接近点をインパクトと推定する。ダウンスイング〜インパクト
/// 直前は検出が欠測しうるため、取得できた観測点だけで成立する実装とする。
class ImpactMomentDetector {
  const ImpactMomentDetector._();

  static int detect({
    required List<RawClubDetection> headDetections,
    required Offset addressBallPositionPx,
  }) {
    if (headDetections.length < 2) {
      throw ArgumentError.value(
        headDetections,
        'headDetections',
        'インパクトフレームの推定には2点以上のクラブヘッド検出が必要です',
      );
    }

    final sorted = [...headDetections]
      ..sort((a, b) => a.frameTimeMs.compareTo(b.frameTimeMs));

    var peakIndex = 0;
    var peakDistance = _distance(sorted[0].centerPx, addressBallPositionPx);
    for (var i = 1; i < sorted.length; i++) {
      final distance = _distance(sorted[i].centerPx, addressBallPositionPx);
      if (distance > peakDistance) {
        peakDistance = distance;
        peakIndex = i;
      }
    }

    if (peakIndex == sorted.length - 1) {
      throw StateError('バックスイングからの復帰を示すクラブヘッド検出がありません(インパクトの瞬間を特定できませんでした)');
    }

    var closestIndex = peakIndex + 1;
    var closestDistance = _distance(
      sorted[closestIndex].centerPx,
      addressBallPositionPx,
    );
    for (var i = peakIndex + 2; i < sorted.length; i++) {
      final distance = _distance(sorted[i].centerPx, addressBallPositionPx);
      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
      }
    }

    return sorted[closestIndex].frameTimeMs;
  }

  static double _distance(Offset a, Offset b) => (a - b).distance;
}
