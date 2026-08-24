/// フォトライブラリ選択動画には撮影時のカメラ画角メタデータが無いため、
/// 距離推定は固定の仮定画角を前提とした目安値ベースで行う。
///
/// 対象機種: iPhone 17(ベースモデル)・縦向き撮影を前提。
/// センサーは物理的に横向き固定のため、縦向き撮影で回転後のフレーム幅と
/// ペアリングすべきは狭い軸側の画角(約49.6°)。将来的には機種別FOVテーブルへ拡張する。
class AssumedCameraIntrinsics {
  const AssumedCameraIntrinsics._();

  static const double narrowAxisFovDegrees = 49.6;
}
