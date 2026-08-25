# Roboflow Universe ゴルフボール検出モデル調査ガイド(ユーザー作業用)

## 背景

Phase 3では、ゴルフボール特化モデル(Roboflow Universe公開モデル)への差し替え調査を見送り、Phase 1と同じCOCO汎用モデル(`yolo26n`、`sports ball`クラス)のまま進めることで合意した(詳細: [model-provenance.md](model-provenance.md))。

しかしその後、実機での動画解析で検出精度不足が確認されたため、差し替えを再検討する。この調査は**Claude(Claude Code)では代行できず、ユーザー自身のブラウザでの確認が必要**な部分がある。理由: Roboflow Universeの公開プロジェクトは、学習済み重み(weights)を直接ダウンロードできるとは限らず(データセットのみ公開のケースが多い)、ライセンス条項も人間の目でページを開いて確認する必要があるため。

このドキュメントは、その調査を進めるための手順とチェックリストをまとめたもの。

## 事前調査で判明した重要な制約(2026-08-25、Claude Web調査)

本格的にブラウザ調査を始める前に、以下を認識しておくこと。

- **無料アカウントでは重みを直接ダウンロードできない**: Roboflow Universeは2025年2月のプラン変更以降、「Download Weights」パネル(`.pt`/`.tflite`/`.mlmodel`等のエクスポート)がBasic/Growth以上の**有料プラン限定**になっている。無料アカウントの場合、多くのプロジェクトで重み入手手段は「Hosted Inference API経由(クラウド呼び出し、オンデバイス推論不可)」または「データセットのみダウンロードして自分でファインチューニング」に限られる。プロジェクトページに「Deploy」タブがあっても、実際に重みファイルを落とせるかは要ログイン確認。
- **プロジェクト個別ページはClaude側から確認不可**: `universe.roboflow.com`の個別プロジェクトページは自動アクセスがブロックされている(WebFetchで403)。Step 2の確認は必ずユーザー自身のブラウザで行うこと。
- Step 2の表に「無料プランで重みダウンロード可能か」の観点を追加した(下記)。これがNoなら、有料プラン加入 or 自前ファインチューニングを要検討という判断になる。

### 目視での一次候補(タイトル検索のみ、詳細未確認)

Web検索のスニペットから見つかった候補。詳細(重み入手可否・ライセンス等)は未確認なので、Step 2の確認対象として優先的に見てほしい。

- [Golf Driver Tracker](https://universe.roboflow.com/salo-levy-nlqrn/golf-driver-tracker) — クラブヘッド+ボール軌道・スイング速度への言及があり、弾道表示・飛距離計算という今回の目的に近そう
- [Golf Ball Tracker](https://universe.roboflow.com/golf-balls/golf-ball-tracker-sksye) — 458枚、「pretrained model + API」の記載あり
- [golfBall (anna-gaming)](https://universe.roboflow.com/anna-gaming/golfball) — 31K枚と学習データ規模が大きい
- [Golf Ball Detection](https://universe.roboflow.com/golf-ball-detection/golf-ball-detection-hii2e) — 3307枚、2023年更新

GitHub上の野良モデル(例: `RyanShihabi/Golf-Ball-Broadcast-Model`)も探したが、LICENSEファイルが存在せず(無断利用不可)、現時点で採用候補にできるものは見つかっていない。GitHub側で見つける場合はLICENSEファイルの有無を必ず確認すること。

## 調査の進め方

### Step 1: 候補プロジェクトを検索する

`universe.roboflow.com` で "golf ball" 等のキーワードで検索し、ゴルフボール検出用のプロジェクトを探す。候補は最低3件程度リストアップする(上記の一次候補から始めてよい)。

### Step 2: 各候補について、以下の項目をページ上で確認する

候補ごとに、下の表を埋める形で記録する(このファイルに直接追記してもよいし、メモを別途取って後でまとめてもよい)。

| 確認項目 | 見る場所の目安 | 備考 |
|---|---|---|
| プロジェクト名・URL | - | - |
| 重みを直接ダウンロードできるか(無料プランで) | プロジェクトページの「Model」または「Deploy」タブ→「Download Weights」 | **無料アカウントでは有料プラン限定機能で非表示の場合が多い**。データセットのみ公開(重み非公開)の場合も含め、そのプロジェクトは候補から除外か要検討 |
| 重みの配布形式 | 同上 | 例: PyTorch(`.pt`)、TFLite(`.tflite`)、CoreML(`.mlmodel`)など。`ultralytics_yolo`パッケージが要求する形式に合っているか(要Claude側での技術確認、Step 4参照) |
| ライセンス種別 | プロジェクトページ下部、または「License」表記 | 例: CC BY 4.0 など。商用利用可否・表記義務の有無を確認 |
| 検出対象クラス名 | データセット/モデルの説明 | ゴルフボール単体を検出するクラスか、複数クラスの一部か |
| 学習データの内容 | データセットのサンプル画像 | 想定撮影条件(屋外/屋内、距離、動画からのフレームかなど)が今回のアプリの利用シーンに近いか |
| 精度指標(あれば) | モデルページの mAP 等 | 参考値。実際の精度は差し替え後の実機検証で確認する前提 |

### Step 3: 候補を絞り込む

上記が埋まったら、以下を満たす候補を残す:

- 重みが直接ダウンロード可能
- ライセンスが今回の用途(個人開発・将来的なApp Store公開の可能性)と両立する
- 配布形式が組み込み可能そうなもの(不明な場合は保留してよい。Step 4でClaude側が技術確認する)

### Step 4: 調査結果をClaudeに共有する

Step 2〜3で埋めた表(またはメモ)を共有してもらえれば、以下はClaude側で対応する:

- ライセンス表記の要否・組み込み方法の整理(`docs/model-provenance.md`への追記)
- 差し替え作業の実装(`lib/data/ml/ball_detector.dart`のクラス名フィルタ変更、`lib/core/tracking_constants.dart`の閾値再チューニングなど)

**カスタムモデルロード自体の技術確認は事前調査済み**(2026-08-25): `ultralytics_yolo`パッケージは`YOLO(modelPath: 'assets/models/xxx.tflite')`形式でローカルアセットのカスタムモデルに標準対応している。実装時の注意点:

- Android: `android/app/src/main/assets/`への配置が必要(TFLiteの制約上、`pubspec.yaml`の`assets:`指定だけでは不十分な既知の不具合[Issue #281](https://github.com/ultralytics/yolo-flutter-app/issues/281)がある。クロスプラットフォーム用の`assets/models/`とAndroid raw assets両方に配置する回避策が必要)
- iOS: `.mlpackage`形式でXcodeプロジェクトに追加
- モデルにUltralytics形式のメタデータが埋め込まれていればクラス名・taskを自動認識、なければ`YOLO(modelPath: ..., task: YOLOTask.detect)`のように明示指定する

## 候補プロジェクトの記録(調査結果をここに追記)

| プロジェクト名・URL | 重み入手可否(無料) | 形式 | ライセンス | 判定 |
|---|---|---|---|---|
| [Golf Driver Tracker](https://universe.roboflow.com/salo-levy-nlqrn/golf-driver-tracker)(`golf-driver-tracker/2`) | 手動DLは有料プランのみ | - | CC BY 4.0 | **不採用**: Hosted APIで実機検証したが`golf ball`クラスが一度も検出されず(`golf club-handle`/`golf club-head`のみ検出)。クラブ検出用に最適化されたモデルの模様 |
| [golfBall (anna-gaming)](https://universe.roboflow.com/anna-gaming/golfball) | 手動DLは有料プランのみ | - | 未確認 | 保留(Hosted API検証を試みたが、モデルID特定前に次候補へ切り替え) |
| golf-ball-detection-r3lqj(`golf-ball-detection-r3lqj/4`) | 手動DLは有料プランのみ | - | CC BY 4.0 | **ボール検出は実証済み**(下記参照)。Hosted APIとしては不採用、Datasetを使った自前ファインチューニングの候補として採用 |

## Hosted API実機検証の結果(2026-08-25、iOSシミュレータ実機検証)

Roboflow Hosted Inference API(`https://detect.roboflow.com/{project}/{version}?api_key=...`)経由でオンデバイス相当の動画解析ができるか、worktree上で使い捨て検証コードを作り実機検証した。

**検証方法**: `get_thumbnail_video`で動画から0.5秒間隔でフレームを抽出→base64化→Hosted APIへPOST→検出結果とレイテンシをログ表示。

**結果**:

| モデル | ボール検出 | レイテンシ(1フレームあたり) |
|---|---|---|
| Golf Driver Tracker (`golf-driver-tracker/2`) | ❌ 検出されず(クラブのみ) | 約1.2〜1.3秒 |
| golf-ball-detection-r3lqj (`golf-ball-detection-r3lqj/4`) | ✅ conf 0.73〜0.77で継続検出 | 0.5〜1.2秒程度(初回3秒超えることも) |

**結論**: golf-ball-detection-r3lqjはボール検出精度は良好だが、Hosted API方式は1フレームあたり0.5秒以上かかり、現状のオンデバイス実装(33ms間隔・30fps相当でフル解析)と同じ密度では動画解析に使えない。サンプリング間隔を粗くする代替案も検討したが、「オフライン不要」という前提を置けないこと、トラッキング精度(`BallKalmanTracker`)への影響が大きいことから **Hosted API方式は採用見送り** と判断した。

## 次のアクション: golf-ball-detection-r3lqjのデータセットで自前ファインチューニング(2026-08-25時点の方針)

Phase 3では「自前学習は元々スコープ外」と判断していたが(`docs/model-provenance.md`参照)、以下の理由から方針転換し、自前ファインチューニングを次のステップとする。

- Roboflow Universeは無料プランだと重みの直接ダウンロードができない(有料プラン$79〜99/月)
- Hosted APIはレイテンシの観点で動画解析用途に不向き
- golf-ball-detection-r3lqj(CC BY 4.0、ライセンス上再学習・再配布に問題なし)は、ゴルフボール検出そのものについては実機検証済みで精度が確認できている

**進捗(2026-08-25)**:

1. ✅ golf-ball-detection-r3lqjのDatasetタブから「Download dataset」→「YOLO26」形式→「Show download code」でダウンロード用コードスニペット取得済み(ユーザー側で保存済み)
2. ✅ 学習環境はGoogle Colabに決定。**ノートブック本体はリポジトリに含めず、Google Drive/Colab上でユーザーが管理する方針**(APIキーやデータセットZIPが混ざるリスクを避けるため)
3. ✅ ベースモデルは`yolo26n`(nano)に決定。Ultralytics YOLO26は`pip install ultralytics`の標準パッケージで学習・検証・エクスポート(train/val/export)がフルサポートされていることを確認済み([Ultralytics YOLO26 Docs](https://docs.ultralytics.com/models/yolo26))。
4. ✅ Colab上でファインチューニング完了。ノートブックの構成は以下の通り(チャット上でユーザーに提供したセル構成、実行済み):
   - データDL(Roboflowスニペット、`rf.workspace("datario-c8sgs").project("golf-ball-detection-r3lqj").version(4).download("yolo26")`)
   - `model.train(data=f"{dataset.location}/data.yaml", model="yolo26n.pt", epochs=100, imgsz=640, batch=16, patience=20, project="golf-ball-finetune", name="yolo26n-golfball")`
   - `model.val()`で検証
   - `.tflite`(Android向け)・`.mlpackage`(iOS向け)へのエクスポート
   - 成果物をZIPにまとめてダウンロード
   - **ハマりどころ**: 使用したUltralyticsのバージョンでは、`project="golf-ball-finetune"`と指定してもデフォルトの`runs/detect/`配下にネストされ、実際の保存先は`/content/runs/detect/golf-ball-finetune/yolo26n-golfball/weights/`だった(想定していた`golf-ball-finetune/yolo26n-golfball/weights/`ではなかった)。`!find / -iname "best.pt"`で実際のパスを特定して対処。次回同様の作業をする際は、学習セル直後に`print(results.save_dir)`で実際の保存先を確認するとよい。
   - ダウンロードしたZIPの中身: `best.pt`(PyTorch重み、保管用)、`best.tflite`(Android用)、`best.mlpackage`(iOS用)、`last.pt`(最終エポックのチェックポイント、`best.pt`があれば不要)。想定通りの構成で取得完了。
5. ✅ アプリへの組み込み実装(2026-08-25、iOS分のみ完了)
   - **事前調査時点の想定からアップデート**: `ultralytics_yolo` 0.6.13の公式ドキュメントを確認したところ、iOSでは`.mlpackage`をZIP化して`assets/models/`に置くFlutter asset方式(`assets/models/best.mlpackage.zip`)が使えると判明し、**Xcodeでの手動追加は不要だった**(当初想定を修正)
   - `assets/models/best.mlpackage.zip`を配置し、`pubspec.yaml`の`flutter.assets`に追加
   - `lib/data/ml/ball_detector.dart`: `YOLO(modelPath: 'assets/models/best.mlpackage.zip')`へ変更、クラス名フィルタを`sports ball`→`Golf-ball`(モデルのメタデータ`{0: 'Golf-ball'}`から確認)に変更
   - **Android未対応**: このリポジトリには現時点で`android`プラットフォームフォルダ自体が存在しない(iOS専用構成)。`best.tflite`は将来Android platform追加時のために手元に保管しておくこと。追加時は本ドキュメント冒頭の[Issue #281](https://github.com/ultralytics/yolo-flutter-app/issues/281)の回避策と、`ultralytics_yolo`公式ドキュメント(`doc/models.md`)の配置ルールを再確認する
   - 🔜 `lib/core/tracking_constants.dart`の閾値再チューニングは未着手。実機でのカスタムモデル検証結果を見てから調整する
   - 実機検証で発生した「解析中画面から遷移しない」問題の調査・修正内容は[investigation-custom-model-tracking-failure.md](investigation-custom-model-tracking-failure.md)にまとめた(トラッカーのバグ2件を修正。インパクト前後の遮蔽・高速移動という設計上の限界は未解決で対応方針を検討中)
6. ✅ `docs/model-provenance.md`への差し替え記録・ライセンス表記を追記済み。ただしCC BY 4.0の正式なクレジット文言(著者名など)は未確認(Claude側からプロジェクトページへ自動アクセスできないため) — **App Store公開前にユーザーがプロジェクトページで確認する必要あり**
