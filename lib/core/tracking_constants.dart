/// [BallKalmanTracker]で使うゲーティング・フェーズ判定のヒューリスティックな閾値(目安値)。
///
/// 実機のスイング動画で誤検出除去率・フェーズ判定の妥当性を確認しながら調整する想定。
class TrackingConstants {
  const TrackingConstants._();

  /// この信頼度未満の検出候補はゲーティング前に除外する。
  static const double confidenceThreshold = 0.3;

  /// 予測位置からこのピクセル距離を超える候補は誤検出とみなして除外する。
  /// インパクト直後の急加速でも捕捉できるよう、やや大きめの値にしている。
  static const double gatingRadiusPx = 300;

  /// 直前の追跡対象の直径に対して、この比率の範囲外の候補は別物体(ノイズ等)
  /// とみなして除外する。飛球中の遠近によるサイズ変化(1フレームあたり
  /// 数%〜1割程度)は許容しつつ、無関係な小さなゴミ等への誤ロックオンを防ぐ。
  static const double minDiameterRatio = 0.4;
  static const double maxDiameterRatio = 2.5;

  /// この速度(px/秒)以下ならアドレス(静止)区間とみなす。
  static const double addressSpeedThresholdPxPerSecond = 200;

  /// この速度(px/秒)を初めて超えた時点でインパクト直後(launch)区間とみなす。
  static const double launchSpeedThresholdPxPerSecond = 800;
}
