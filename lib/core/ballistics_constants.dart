/// 弾道シミュレーション(抗力・マグヌス効果)で使うヒューリスティックな定数。
///
/// スピン量は2Dのボール中心トラッキングのみでは実測できないため、
/// バックスピン・サイドスピンともに一般的なドライバーショットを想定した固定の仮定値とする。
/// 将来スピン推定機能を追加する場合は、この定数値を推定結果で上書きする形で拡張する。
class BallisticsConstants {
  const BallisticsConstants._();

  static const double airDensityKgPerCubicMeter = 1.225;

  /// 抗力係数(目安値、ゴルフボールの一般的なレンジ0.2〜0.3の中央付近)。
  static const double dragCoefficient = 0.25;

  /// 仮定バックスピン量(rpm)。ドライバーショット想定の目安値。
  static const double assumedBackspinRpm = 2600;

  /// 仮定サイドスピン量(rpm)。正値はスライス方向(進行方向に対して右)を表す目安値。
  static const double assumedSidespinRpm = 300;
}
