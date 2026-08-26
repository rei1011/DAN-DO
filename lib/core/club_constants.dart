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

  /// クラブ種別ごとの想定シャフト長(m、一般的な目安値)。
  ///
  /// クラブヘッド検出([RawClubDetection])にはボールの実直径のような
  /// サイズ情報が無いため、同一フレームで検出したクラブヘッド・ハンドル間の
  /// 画像上の距離(見かけのシャフト長)とこの実寸を比較することで、
  /// [DistanceEstimation]と同じピンホールカメラの原理でクラブヘッドの奥行きを推定する。
  static const Map<ClubType, double> shaftLengthMeters = {
    ClubType.driver: 1.145,
    ClubType.fairwayWood: 1.09,
    ClubType.utility: 1.02,
    ClubType.iron: 0.95,
    ClubType.wedge: 0.89,
  };

  /// クラブパス・アタック角の回帰に使う、インパクト直前の最大観測点数(目安値)。
  static const int maxPathRegressionFrames = 5;
}
