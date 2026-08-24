import 'package:flutter/material.dart' show Offset;

import '../../core/roi_constants.dart';

/// [RoiSequencer.decideNextRoi]が返す、次フレームで検出モデルに渡す範囲の決定。
class RoiDecision {
  const RoiDecision.crop({required Offset center, required this.cropSizePx})
    : centerPx = center,
      useFullFrame = false;

  const RoiDecision.fullFrame() : centerPx = null, cropSizePx = 0, useFullFrame = true;

  final Offset? centerPx;
  final double cropSizePx;
  final bool useFullFrame;
}

/// 現在の探索中心・ロスト連続回数から、次フレームで使うROI(クロップ範囲)を
/// 決める純粋関数。探索中心が未確定、またはロストが続いた場合は全体フレーム
/// 探索にフォールバックする。
class RoiSequencer {
  const RoiSequencer._();

  static RoiDecision decideNextRoi({
    required Offset? searchCenterPx,
    required double cropSizePx,
    required int consecutiveLostFrames,
  }) {
    if (searchCenterPx == null) {
      return const RoiDecision.fullFrame();
    }
    if (consecutiveLostFrames >= RoiConstants.maxLostFramesBeforeFullFrameFallback) {
      return const RoiDecision.fullFrame();
    }
    return RoiDecision.crop(center: searchCenterPx, cropSizePx: cropSizePx);
  }
}
