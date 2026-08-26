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

  /// インパクト直後、限定範囲でボールを探索する際のクロップサイズ(px、正方形の一辺)。
  /// スロー撮影ではない前提で、想定される最大初速でも探索範囲に収まるよう
  /// 追跡用クロップより大きめにしている(目安値、要実機検証での調整。
  /// Phase6でPhase5実機検証結果を踏まえ500→800に拡大)。
  static const double postImpactBallSearchCropSizePx = 800;

  /// インパクトフレームから何フレーム分、限定範囲でボールを探索するか(目安値。
  /// Phase6でPhase5実機検証結果を踏まえ5→10に拡大)。
  static const int postImpactBallSearchFrameCount = 10;

  /// [postImpactBallSearchCropSizePx]での探索結果が2点未満だった場合のみ、
  /// 同じフレーム範囲を1回だけ再探索するフォールバック用クロップサイズ(px)。
  /// [FrameCropper.crop]は実フレームサイズにクランプするため、通常の動画では
  /// 実質フルフレーム探索になる(目安値、要実機検証での調整。Phase6新設)。
  static const double postImpactBallSearchFallbackCropSizePx = 2000;
}
