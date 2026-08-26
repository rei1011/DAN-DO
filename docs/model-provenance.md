# モデルの出典・ライセンス管理

`lib/data/ml/ball_detector.dart` が使用するボール検出モデル、および `lib/data/ml/club_detector.dart` が使用するクラブ検出モデルの来歴を記録する。

## ボール検出モデル

| 項目 | 内容 |
|---|---|
| モデル | `yolo26n`をベースに、golf-ball-detection-r3lqj(Roboflow Universe)のデータセットで自前ファインチューニングしたカスタムモデル(`assets/models/best.mlpackage.zip`) |
| 検出クラス | `Golf-ball`(単一クラス。学習済みモデルのメタデータから確認) |
| 学習データ出典 | [golf-ball-detection-r3lqj](https://universe.roboflow.com/datario-c8sgs/golf-ball-detection-r3lqj)(Roboflow Universe、workspace: `datario-c8sgs`、project version 4) |
| データセットのライセンス | **CC BY 4.0**(表示義務あり。再学習・再配布は許諾範囲内だが、アプリ内クレジット表記が必要。App Store公開前に正式なクレジット文言をプロジェクトページで確認し、アプリ内(設定画面や利用規約等)に「golf ball detection Dataset by [author], licensed under CC BY 4.0, sourced from Roboflow Universe (https://universe.roboflow.com/datario-c8sgs/golf-ball-detection-r3lqj)」相当の表記を追加すること。正確な著者名はClaude側からプロジェクトページへ自動アクセスできない制約があるため未確認 — 要ユーザー確認) |
| 学習環境 | Google Colab(`yolo26n.pt`から100エポックでファインチューニング、`ultralytics`パッケージ標準の`model.train()`/`export()`使用) |
| `ultralytics_yolo`パッケージ自体のライセンス | AGPL-3.0 |
| 用途 | 個人開発・学習目的。将来App Store公開時は要再検討(`docs/implementation-plan-analysis-pipeline.md` 技術調査2.参照) |
| 確認日 | 2026-08-25(Phase 3.5: 自前ファインチューニングモデルへの差し替え) |

## クラブ検出モデル

| 項目 | 内容 |
|---|---|
| モデル | `yolo26n`をベースに、Golf Driver Tracker(Roboflow Universe)のデータセットで自前ファインチューニングしたカスタムモデル(`assets/models/best_club.mlpackage.zip`) |
| 検出クラス | データセットには`golf ball`・`golf club-handle`・`golf club-head`の3クラスが含まれるが、本アプリでは`golf club-head`・`golf club-handle`のみを使用(ボール検出は別モデル(`ball_detector.dart`)が担当) |
| 学習データ出典 | [Golf Driver Tracker](https://universe.roboflow.com/salo-levy-nlqrn/golf-driver-tracker)(Roboflow Universe、workspace: `salo-levy-nlqrn`、project version 2) |
| データセットのライセンス | **CC BY 4.0**(表示義務あり。再学習・再配布は許諾範囲内だが、アプリ内クレジット表記が必要。App Store公開前に正式なクレジット文言をプロジェクトページで確認し、アプリ内(設定画面や利用規約等)に「Golf Driver Tracker Dataset by [author], licensed under CC BY 4.0, sourced from Roboflow Universe (https://universe.roboflow.com/salo-levy-nlqrn/golf-driver-tracker)」相当の表記を追加すること。正確な著者名はClaude側からプロジェクトページへ自動アクセスできない制約があるため未確認 — 要ユーザー確認。ボール検出モデルと同じ未対応事項) |
| 学習環境 | Google Colab(`yolo26n.pt`から100エポックでファインチューニング、`ultralytics`パッケージ標準の`model.train()`/`export()`使用。手順は`docs/club-detector-training-guide.md`参照) |
| `ultralytics_yolo`パッケージ自体のライセンス | AGPL-3.0(ボール検出モデルと共通) |
| 用途 | 個人開発・学習目的。将来App Store公開時は要再検討 |
| 確認日 | 2026-08-26(Phase 2: クラブ検出モデルの学習・組み込み) |

現状の制約: このリポジトリには`android`プラットフォームフォルダが存在せず、iOS専用構成。学習成果物に含まれる`best.tflite`はユーザーの手元に保管し、Android対応時に配置方法を別途検討する(ボール検出モデルと同じ方針)。

## Phase 3.5: 自前ファインチューニングモデルへの差し替え(2026-08-25)

Phase 1のCOCO汎用モデル(`yolo26n`、`sports ball`クラス)は実機動画解析で検出精度不足が判明したため、golf-ball-detection-r3lqjのデータセットで`yolo26n`を自前ファインチューニングしたカスタムモデルに差し替えた。詳細な調査経緯は[roboflow-model-investigation-guide.md](roboflow-model-investigation-guide.md)を参照。

- 判断日: 2026-08-25
- 変更内容: `lib/data/ml/ball_detector.dart`のモデルロードを公式`yolo26n`自動ダウンロードからカスタムモデル(`assets/models/best.mlpackage.zip`、Flutter asset経由でiOSにロード)に変更。クラス名フィルタも`sports ball`→`Golf-ball`に変更
- 現状の制約: このリポジトリには`android`プラットフォームフォルダが存在せず、iOS専用構成。Android対応時は`best.tflite`の配置方法(Flutter asset or `android/app/src/main/assets/`)を別途検討する
- 未対応: `lib/core/tracking_constants.dart`の閾値は実機での新モデル検証結果を踏まえて調整する想定(今回は変更なし)

## Phase 3: Roboflow Universe公開モデルへの差し替え検討(見送り)

`docs/implementation-plan-analysis-pipeline.md` のPhase 3計画では、ゴルフボール特化モデル(Roboflow Universe公開データセット/モデル)への差し替えを検討する方針だった。計画上、この調査は「公開プロジェクトで学習済み重みが直接ダウンロードできるとは限らない」ことを前提に、**ユーザー自身のブラウザでのライセンス・重み入手性確認が必要**と明記されていた。

Phase 3着手時にユーザーへ確認したところ、**今回は差し替え調査自体を見送り、Phase 1と同じCOCO汎用モデル(`yolo26n`、`sports ball`クラス)のまま次のステップへ進む**という判断になった。

- 判断日: 2026-08-24
- 判断: Roboflow Universeモデルの調査・差し替えは行わない
- 理由: プロトタイプ段階では汎用モデルで妥当性検証を先に進める方が優先度が高いとユーザーが判断したため(自前学習は元々スコープ外)
- 影響: 検出精度(特にゴルフボール特有の小ささ・高速移動に対する検出率)の向上はPhase 4以降に先送りとなる。`BallKalmanTracker`のゲーティング・フェーズ判定はこの精度前提を踏まえたヒューリスティックな閾値(`lib/core/tracking_constants.dart`)で運用し、実機データで随時調整する
