# モデルの出典・ライセンス管理

`lib/data/ml/ball_detector.dart` が使用するボール検出モデルの来歴を記録する。

## 現在使用中のモデル

| 項目 | 内容 |
|---|---|
| モデル | `yolo26n`(Ultralyticsの公式COCO学習済みモデル、`ultralytics_yolo`パッケージ経由で初回自動ダウンロード) |
| 検出クラス | `sports ball`(COCOの汎用クラス。ゴルフボール専用ではない) |
| ライセンス | AGPL-3.0(`ultralytics_yolo`パッケージ自体のライセンスに準拠) |
| 用途 | 個人開発・学習目的。将来App Store公開時は要再検討(`docs/implementation-plan-analysis-pipeline.md` 技術調査2.参照) |
| 確認日 | 2026-08-24(Phase 1導入時) |

## Phase 3: Roboflow Universe公開モデルへの差し替え検討(見送り)

`docs/implementation-plan-analysis-pipeline.md` のPhase 3計画では、ゴルフボール特化モデル(Roboflow Universe公開データセット/モデル)への差し替えを検討する方針だった。計画上、この調査は「公開プロジェクトで学習済み重みが直接ダウンロードできるとは限らない」ことを前提に、**ユーザー自身のブラウザでのライセンス・重み入手性確認が必要**と明記されていた。

Phase 3着手時にユーザーへ確認したところ、**今回は差し替え調査自体を見送り、Phase 1と同じCOCO汎用モデル(`yolo26n`、`sports ball`クラス)のまま次のステップへ進む**という判断になった。

- 判断日: 2026-08-24
- 判断: Roboflow Universeモデルの調査・差し替えは行わない
- 理由: プロトタイプ段階では汎用モデルで妥当性検証を先に進める方が優先度が高いとユーザーが判断したため(自前学習は元々スコープ外)
- 影響: 検出精度(特にゴルフボール特有の小ささ・高速移動に対する検出率)の向上はPhase 4以降に先送りとなる。`BallKalmanTracker`のゲーティング・フェーズ判定はこの精度前提を踏まえたヒューリスティックな閾値(`lib/core/tracking_constants.dart`)で運用し、実機データで随時調整する
