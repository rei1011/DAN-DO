# クラブ検出モデルの学習ガイド(ユーザー作業用)

## 背景

Phase 2([design-club-swing-analysis.md](design-club-swing-analysis.md)セクション11)では、Golf Driver Tracker(Roboflow Universe、`golf-driver-tracker/2`)のデータセットを使い、`yolo26n`をクラブヘッド・クラブハンドル検出用にファインチューニングする。

この作業のうち、以下は**Claude(Claude Code)では代行できず、ユーザー自身の作業が必要**(ブラウザでのRoboflow操作・Google ColabでのGPU学習のため)。

- Roboflowからのデータセットダウンロード
- Google Colabでのファインチューニング実行

これらが完了したら、成果物のZIPを共有してもらえれば、以降のアプリ組み込み(`lib/data/ml/club_detector.dart`実装、`assets/models/`配置、`pubspec.yaml`更新、`docs/model-provenance.md`更新)はClaude側で対応する。

golf-ball-detection-r3lqjでのボール検出モデル学習(`docs/roboflow-model-investigation-guide.md`参照)と同じ流れなので、手順に迷ったらそちらも参照可能。

## Step 1: Roboflowからデータセットをダウンロード

1. [Golf Driver Tracker](https://universe.roboflow.com/salo-levy-nlqrn/golf-driver-tracker)のプロジェクトページを開く(version 2を使用)
2. 「Dataset」タブ→「Download Dataset」
3. フォーマットは **「YOLO26」** を選択
4. 「Show download code」を選んで、以下のようなコードスニペットを取得する(APIキーが含まれるため、この場でメモ・保存しておく。リポジトリにはコミットしないこと)

   ```python
   from roboflow import Roboflow
   rf = Roboflow(api_key="YOUR_API_KEY")
   project = rf.workspace("salo-levy-nlqrn").project("golf-driver-tracker")
   version = project.version(2)
   dataset = version.download("yolo26")
   ```

5. ライセンス(CC BY 4.0)がプロジェクトページに明記されていることを再確認する(`docs/design-club-swing-analysis.md`セクション3で確認済みだが、正式なクレジット文言(著者名など)は未確認。App Store公開前に確認が必要 — これはgolf-ball-detection-r3lqjでも同様の未対応事項として残っている)
6. データセットの検出クラス名(`golf club-head`・`golf club-handle`という想定だが、実際の`data.yaml`の`names:`で正式名称を確認する。Step 2で使う)

## Step 2: Google Colabでファインチューニング

新規のColabノートブックを作成し、以下のセル構成で実行する(**ノートブック本体はリポジトリに含めない**方針。APIキーやデータセットZIPが混ざるのを避けるため)。

### セル1: パッケージインストール

```python
!pip install ultralytics roboflow
```

### セル2: データセットダウンロード

Step 1で取得したコードスニペットをそのまま貼り付ける。

### セル3: 学習

```python
from ultralytics import YOLO

model = YOLO("yolo26n.pt")
results = model.train(
    data=f"{dataset.location}/data.yaml",
    model="yolo26n.pt",
    epochs=100,
    imgsz=640,
    batch=16,
    patience=20,
    project="golf-club-finetune",
    name="yolo26n-golfclub",
)
print(results.save_dir)  # 実際の保存先を確認(下記の注意点参照)
```

**注意点(ボール検出モデル学習時にハマった点、`roboflow-model-investigation-guide.md`より)**: 使用するUltralyticsのバージョンによっては、`project="golf-club-finetune"`と指定してもデフォルトの`runs/detect/`配下にネストされることがある(実際の保存先が`golf-club-finetune/yolo26n-golfclub/weights/`ではなく`/content/runs/detect/golf-club-finetune/yolo26n-golfclub/weights/`だった前例あり)。学習セル直後に`print(results.save_dir)`で実際の保存先を確認すること。見つからない場合は`!find / -iname "best.pt"`で検索する。

### セル4: 検証

```python
best_model = YOLO(f"{results.save_dir}/weights/best.pt")
metrics = best_model.val()
```

学習後のクラス名一覧(`best_model.names`)も確認し、`club-head`・`club-handle`(または実際の名称)がどう出力されるかメモしておく。`lib/domain/models/raw_club_detection.dart`の`ClubPart` enumとのマッピングに使う。

### セル5: エクスポート(Android用・iOS用)

```python
best_model.export(format="tflite")     # Android用(将来対応時のため保管)
best_model.export(format="mlpackage")  # iOS用(今回のアプリ組み込みで使用)
```

### セル6: 成果物をZIPにまとめてダウンロード

```python
import shutil
from google.colab import files

weights_dir = f"{results.save_dir}/weights"
shutil.make_archive("club_detector_weights", "zip", weights_dir)
files.download("club_detector_weights.zip")
```

ZIPの中身は以下を想定(ボール検出モデルの前例と同じ構成):

- `best.pt`(PyTorch重み、保管用)
- `best.tflite`(Android用、将来対応時に使用)
- `best.mlpackage`(iOS用、今回のアプリ組み込みで使用)
- `last.pt`(最終エポックのチェックポイント、`best.pt`があれば不要)

## Step 3: Claudeに共有

ダウンロードした`club_detector_weights.zip`を共有してもらえれば、以下を実施する。

1. `best.mlpackage`をZIP化して`assets/models/best_club.mlpackage.zip`(仮称)として配置、`pubspec.yaml`の`flutter.assets`に追加
2. `lib/data/ml/club_detector.dart`を実装(`ball_detector.dart`と同様の構造。クラス名フィルタはセル4でメモした実際のクラス名を使用)
3. `docs/model-provenance.md`にクラブ検出モデルの出典・ライセンス(CC BY 4.0)を追記
4. 実機での`ClubDetector`単体動作確認は引き続きユーザー側での実機検証が必要(Phase完了確認項目)

あわせて、以下も共有してもらえると助かる。

- セル4でメモした実際のクラス名(`best_model.names`の出力)
- 検証(`metrics`)で気になる数値があれば(mAP等、参考情報)
