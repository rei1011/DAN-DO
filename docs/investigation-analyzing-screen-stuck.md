# 調査報告: 解析中画面から遷移せず結果を確認できない

- 調査日: 2026-08-24
- 対象ブランチ: worktree-phase3-analysis-pipeline
- 検証環境:
  - iOS Simulator (iPhone 15 Pro, iOS 17.5)
  - 実機 (溝渕嶺のiPhone, `fvm flutter run -d 00008150-000115580278401C`)
- 使用動画: `/Users/mizobuchirei/Downloads/IMG_3068.MOV`
  (1920x1080, 5.56秒, 12MB。ゴルフ練習場でのスイングを後方から撮影)

## 1. 事象

上記動画で動画選択→解析を実行したところ、「解析中」画面から結果画面
(`ResultScreen`) へ遷移せず、結果を確認できなかった。**シミュレータ・
実機の両方で再現する。**

## 2. 調査方法

1. `xcrun simctl spawn booted log show` でシミュレータの実行ログを取得し、
   Flutter側 `debugPrint` とネイティブ側 (CoreML/Espresso) のログを
   突き合わせ、解析パイプラインのどこで処理が止まる・失敗するかを追跡。
2. `lib/domain/services/ball_trajectory_analysis_service.dart`・
   `lib/data/tracking/ball_kalman_tracker.dart`・
   `lib/data/ml/ball_detector.dart`・
   `lib/features/analyzing/analyzing_screen.dart` のソースを確認。
3. ユーザーに実機での再検証を依頼したところ、同じ現象が再現することを
   確認(`flutter run` の標準出力ログを参照)。
4. `qlmanage -t` で動画の代表フレームをサムネイル抽出し、被写体(ボール)
   の映り方を目視確認。

## 3. 調査の経緯(仮説の変遷)

### 3.1 仮説1: iOS Simulator の CoreML/MPSGraph 非互換(棄却)

シミュレータのログには以下のエラーが一貫して出力されていた。

```
E5RT encountered an STL exception.
msg = Espresso exception: "Invalid state": MpsGraph backend validation
on incompatible OS.
[Espresso::handle_ex_] exception=Espresso compiled without MPSGraph engine.
```

これは iOS Simulator が Apple Neural Engine を持たず、CoreML の一部
バックエンド (MPSGraph) がシミュレータ環境と非互換であるために発生する
既知の制限であり、シミュレータ実行時の推論結果(`sports ball
detections=1`)が異常に少ない一因と考えられた。

**→ この仮説はユーザーによる実機再検証で棄却された。** 実機
(`fvm flutter run -d 00008150-000115580278401C`) では、ホットリスタート
を挟んだ3回の試行すべてで一貫して `sports ball detections=2` となり、
シミュレータ同様に極端に少ない検出数のまま解析中画面から遷移しなかった。
複数回の試行で結果が安定して再現していることから、偶発的なタイミング
問題ではなく決定的な要因(検出モデルの精度不足)であることが裏付けられ
る。実機はCoreML/ANEが正常に動作する環境であるため、この現象はシミュ
レータ固有の問題ではない。

### 3.2 仮説2(確定): ゴルフボールが汎用YOLOモデルにとって検出困難な被写体

動画のサムネイルを確認したところ、決定的な手がかりが得られた。

- カメラは打席の後方やや高い位置から撮影しており、**ティー上のボールは
  フレーム内で点のように小さくしか映っていない**(直径にして数ピクセル
  程度と推定される)。
- 背景の芝生には、**既に打たれた大量の白いボールが散乱**しており、
  見た目上はティー上のボールと区別がつきにくい。

`docs/model-provenance.md` に記録されている通り、このアプリが使用する
検出モデルは `yolo26n`(COCOデータセットで学習された汎用モデル)の
`sports ball` クラスであり、**ゴルフボール専用に学習されたモデルでは
ない**。Phase 3計画時点でゴルフボール特化モデル(Roboflow Universe等)
への差し替えが検討されたが、「プロトタイプ段階では汎用モデルで妥当性
検証を先に進める」というユーザー判断により見送られており、その際
`model-provenance.md` には以下の影響が明記されていた。

> 検出精度(特にゴルフボール特有の小ささ・高速移動に対する検出率)の
> 向上はPhase 4以降に先送りとなる。

今回の「動画全体で検出数1〜2件」という結果は、まさにこの既知の課題が
現実の動画で顕在化したものと考えられる。COCOの `sports ball` クラスは
サッカーボール・バスケットボールなど画面内で比較的大きく映る球体を
主な学習対象としており、小さく・遠く・背景に類似物が大量にある
ゴルフボールの検出は汎用モデルの守備範囲外である可能性が高い。

## 4. 根本原因の特定(因果チェーン・確定版)

1. 検出モデルが COCO 学習済み汎用モデル (`yolo26n`, `sports ball`
   クラス) であり、フレーム内で極小・背景に類似物が多いゴルフボールの
   検出を苦手とする。これはシミュレータ・実機を問わず共通して発生する
   (仮説1のCoreML/MPSGraph問題はシミュレータ固有の別要因であり、
   検出数が少ないこと自体の主因ではなかった)。
2. その結果、動画中でボールを検出できたフレームが実質 1〜2 件のみと
   なる(`lib/domain/services/ball_trajectory_analysis_service.dart:
   64-66` の `debugPrint` で確認)。
3. `BallKalmanTracker.track()` (`lib/data/tracking/
   ball_kalman_tracker.dart:46-70`) は、トラッキング開始前の最初の観測を
   必ず `BallTrackingPhase.address` として登録する仕様のため、検出が
   1〜2件しかない場合、`launchStates` (飛球区間) は 2件未満にしか
   ならない。
4. `BallTrajectoryAnalysisService.buildShotResult()`
   (`ball_trajectory_analysis_service.dart:107-111`) は
   `launchStates.length < 2` の場合に `InsufficientTrajectoryData
   Exception('飛球区間の観測が不足しています(ボールをロストした可能性
   があります)')` を送出する設計になっており、このケースで確実に
   例外が発生する。
5. `AnalysisController` (`@riverpod` の `AsyncNotifier`) はこの例外を
   捕捉して `AsyncError` 状態になる(Riverpod generator の標準動作)。
6. `AnalyzingScreen` (`lib/features/analyzing/analyzing_screen.dart`) は
   `ref.listen` で **`data` の場合のみ** `Navigator.pushReplacement` に
   よって `ResultScreen` に遷移する実装になっている
   (`analyzing_screen.dart:20-28`)。エラー時は画面遷移をせず、**同じ
   `AnalyzingScreen` 内で** `CircularProgressIndicator` を
   エラーメッセージ+「別の動画を選ぶ」ボタンに差し替えるだけ
   (`analyzing_screen.dart:33-53`)。

**結論**: アプリはフリーズしているのではなく、ボール検出数不足による
「解析失敗」が発生し、エラーメッセージ表示に切り替わっていたと考えら
れる。ただしエラー表示への切替が `AppBar` タイトルも含め同一画面内で
完結し見た目の変化に乏しいこと、1回の解析に時間がかかること
(§5参照)から、「画面遷移していない/結果を確認できない」という体感に
つながった可能性が高い。真因は **検出モデルの精度不足**であり、UI側の
実装そのものは仕様通りに動作している。

## 5. 副次的な設計上の要因

- `BallTrajectoryAnalysisService.analyze()`
  (`ball_trajectory_analysis_service.dart:52-75`) は動画区間を 33ms 刻み
  で `for` ループし、**フレームごとに直列に** `await frameSource.frameAt(t)`
  → `await ballDetector.detect(...)` を実行している。
  `GetThumbnailVideoFrameSource` は `VideoThumbnail.thumbnailData` で
  毎回動画ファイルをシークしてサムネイルを再生成する実装のため、
  フレーム数が多い動画では時間がかかりやすい(シミュレータでの計測では
  5.56秒の動画に対し解析全体で55〜58秒程度)。
- CoreML モデル (`yolo26n.mlpackage.zip`) は初回起動時に GitHub Releases
  から自動ダウンロードされる実装 (`ultralytics_yolo` の
  `YOLOModelResolver._downloadToFile`)。この処理には**タイムアウトが
  設定されていない**ため、ネットワークが不安定な環境では無期限に
  待たされる可能性がある(今回はモデルロード自体は成功しており直接の
  原因ではないが、初回起動時の別シナリオとして留意)。

## 6. 対策案

優先度の高いものから記載。

1. **検出モデルの精度向上(根本対策)**
   `model-provenance.md` に記録済みの通り、ゴルフボール特化モデルへの
   差し替え、または以下のような軽量な改善を検討する。
   - 撮影ガイド(カメラをボールに近づける、俯瞰でなく水平に近い角度で
     撮る等)をアプリ内で案内し、汎用モデルでも検出しやすい条件に誘導
     する。
   - 検出前処理として、ティー付近など探索範囲を限定する・入力解像度を
     上げてボール周辺をクロップしてから推論する、などのヒューリス
     ティックを追加する。
   - Roboflow Universe等のゴルフボール特化モデルへの差し替えを
     改めて検討する(Phase 3では見送られたが、精度不足が実測で確認
     できたため再検討の材料になる)。
2. **エラー時のUI/UXの改善**(「結果を確認できない」という体感の解消)
   - エラー発生時に「解析中」から明確に別状態へ遷移したとわかる見た目
     (例: `AppBar` タイトルを「解析結果」から「解析失敗」に変える、
     アイコンや色を変える等)にする。
   - `InsufficientTrajectoryDataException` のメッセージに実際の検出数
     (address/launch それぞれの件数)を含め、ユーザー・開発者双方が
     原因を切り分けやすくする。
3. **解析時間の短縮**(体感的なフリーズ感の解消)
   - フレーム抽出をシークベースの直列ループから、動画を1回デコード
     しながら連続フレームを取得する方式に変更することを検討する。
   - 進捗表示(「N/M フレーム処理中」等)を解析中画面に追加する。
4. **モデルダウンロードのタイムアウト・リトライ**
   `loadModel()` 呼び出しに `Future.timeout()` を設け、タイムアウト時に
   明確なエラーメッセージを表示することを検討する。

## 7. 参考: シミュレータ固有の別問題(対応不要・記録のみ)

シミュレータでは CoreML の一部バックエンドが `Espresso compiled without
MPSGraph engine` という縮退状態で動作する既知の制限がある。実機では
発生しないため、今回の主問題への対応としては不要だが、今後シミュレータ
上での検出精度・推論速度を評価する際は実機の結果と乖離しうる点に注意
する。
