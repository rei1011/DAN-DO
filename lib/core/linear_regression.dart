/// 最小二乗法による単回帰の共通ユーティリティ。
class LinearRegression {
  const LinearRegression._();

  /// (時刻, 値)のサンプル列から回帰直線の傾きを算出する。
  static double slope(List<(double, double)> samples) {
    final n = samples.length;
    final sumT = samples.fold<double>(0, (sum, s) => sum + s.$1);
    final sumV = samples.fold<double>(0, (sum, s) => sum + s.$2);
    final meanT = sumT / n;
    final meanV = sumV / n;

    var numerator = 0.0;
    var denominator = 0.0;
    for (final (t, v) in samples) {
      numerator += (t - meanT) * (v - meanV);
      denominator += (t - meanT) * (t - meanT);
    }

    if (denominator == 0) return 0;
    return numerator / denominator;
  }
}
