/// 解析対象のクラブ種別。
enum ClubType {
  /// ドライバー。
  driver,

  /// フェアウェイウッド。
  fairwayWood,

  /// ユーティリティ。
  utility,

  /// アイアン(中番手目安)。
  iron,

  /// ウェッジ。
  wedge,
}

/// クラブ種別ごとのヒューリスティックな定数(目安値、要実機検証での補正)。
class ClubConstants {
  const ClubConstants._();

  /// クラブ種別ごとのスマッシュファクター(初速 = クラブヘッド速度 × スマッシュファクター)。
  static const Map<ClubType, double> smashFactor = {
    ClubType.driver: 1.48,
    ClubType.fairwayWood: 1.45,
    ClubType.utility: 1.41,
    ClubType.iron: 1.33,
    ClubType.wedge: 1.25,
  };
}
