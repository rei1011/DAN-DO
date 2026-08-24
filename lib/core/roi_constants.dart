/// ROI(探索範囲)限定・クロップ推論のヒューリスティックな閾値(目安値)。
///
/// 実機のスイング動画で検出成功率を確認しながら調整する想定。
class RoiConstants {
  const RoiConstants._();

  /// アドレス区間(タップ直後)の初期クロップサイズ(px、正方形の一辺)。
  static const double initialCropSizePx = 240;

  /// 追跡開始後、予測位置を中心にクロップするサイズ(px、正方形の一辺)。
  static const double trackingCropSizePx = 160;

  /// この回数だけ連続でROI内に検出が無かった場合、その回だけ全体フレーム
  /// 探索にフォールバックする。
  static const int maxLostFramesBeforeFullFrameFallback = 5;
}
