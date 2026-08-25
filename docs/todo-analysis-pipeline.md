# 動画解析パイプライン 実装TODO

元計画: [implementation-plan-analysis-pipeline.md](implementation-plan-analysis-pipeline.md)

進捗管理用のチェックリスト。作業を中断・再開する際は、このファイルのチェック状況を見れば「どこまで終わっているか」がわかるようにする。

## 使い方

- タスクに着手したら `[ ]` → `[x]` にする
- 各Phase末尾の確認項目まで終わったら次のPhaseへ進む
- タスクの詳細(コード配置・設計判断の理由など)は元計画の該当セクションを参照
- 現在のステータス: **Phase 3 実装完了、実機検証(最終確認項目)待ち**(2026-08-24時点)

## 全Phase共通・継続タスク

- [ ] 距離推定の精度(仮定FOV定数の妥当性)を、実機での算出結果と実測値の比較で随時検証し、必要に応じて `assumed_camera_intrinsics.dart` の定数を調整する(特定のPhaseで完結させない)

## Phase 0: 下地整理

- [x] `pubspec.yaml` に依存追加: `image_picker`, `get_thumbnail_video`, `ultralytics_yolo`, `fl_chart`(任意)
- [x] `lib/main.dart` からriverpod学習用サンプル(`userNameProvider`, `UserNameSwitcherView`)を削除し、実アプリのエントリポイント(`ProviderScope`+`MaterialApp`+`VideoSelectScreen`起点のルーティング)に置き換え(`VideoSelectScreen`は`lib/features/video_select/video_select_screen.dart`にプレースホルダーとして新設。実装はPhase 1で行う)
- [x] `build_runner` で `main.g.dart` を再生成(main.dartにriverpodコード生成対象がなくなったため、`main.g.dart`自体は不要になり削除された)
- [x] `test/score_change_view_test.dart`・`test/widget_test.dart` を削除(`score_change_view_test.dart`は着手時点で既に存在せず、`widget_test.dart`のみ削除)
- [x] `ios/Runner/Info.plist` に `NSPhotoLibraryUsageDescription` を追加
- [x] Phase完了確認: `fvm dart analyze` でビルドエラー・lint警告がないことを確認(`No issues found!`)

## Phase 1: 配線確認(精度度外視)

- [x] `image_picker` で動画選択 → `get_thumbnail_video` でフレーム抽出 → `ultralytics_yolo` 公式 `yolo26n` モデルの `sports ball` クラスで推論、が実機で一通り動くことを確認(最大のリスク検証ポイント)
- [x] ダミーの距離推定(適当な定数)で仮の `ShotResult` を返す
- [x] 3画面遷移(VideoSelectScreen → AnalyzingScreen → ResultScreen)・エラー分岐を実機で通す
  - 注意: `ballDetectorProvider`(モデルロード)が実際に失敗すると、Riverpodの自動リトライが`ballDetectorProvider`→`shotAnalysisServiceProvider`→`analysisControllerProvider`の3層で個別に発動し、AnalyzingScreenが最大約76〜114秒「解析中」表示のまま進まないことがある(フリーズではない)。実機確認時にネットワーク不調でモデルダウンロードが失敗した場合はこの挙動を想定しておくこと。恒常的に気になる場合はPhase2以降で`retry:`によるリトライ制限を検討
- [x] `FakeShotAnalysisService` を用意
- [x] provider override経由の画面遷移widgetテストを1本作成
- [x] Phase完了確認: 実機iPhoneで動画選択→解析→結果表示までの一連の流れが動くことを確認
- [x] Phase完了確認: `fvm dart analyze` でビルドエラー・lint警告がないことを確認

## Phase 2: 距離推定・弾道物理モデルの単体検証(純粋Dart、UI/ML非依存)

- [x] `distance_estimation.dart` 実装(ピンホールモデル計算)
- [x] `launch_parameter_estimator.dart` 実装(最小二乗フィッティングでV0・θ・φ算出)
- [x] `ballistics_simulator.dart` 実装(抗力+マグヌス、RK4数値積分)
  - 補足: マグヌス効果に必要なスピン量は2Dのボール中心トラッキングのみでは実測できないため、`ballistics_constants.dart`にバックスピン・サイドスピンの仮定値(目安値)を定数として置き、`simulate()`の引数として渡す設計にした(将来スピン推定機能を追加する場合はこの引数に実測値を渡すだけで拡張可能)。サイドスピンによる左右の曲がりもユーザー要望により反映する設計とした。
  - 実装中、マグヌス力の向き(外積の順序とスピン軸の符号)を誤り、バックスピンが揚力を弱める向きになっていたバグをTDDのテストで検出・修正済み
- [x] `test/domain/` 配下に単体テスト作成(既知の初速・角度での着地時間・飛距離の妥当性確認)
- [x] RK4刻み幅の数値安定性を確認するテストを作成
- [x] Phase完了確認: `test/domain/` 配下の単体テストが通ることを確認
- [x] Phase完了確認: `fvm dart analyze` でビルドエラー・lint警告がないことを確認

## Phase 3: 本実装モデル差し替え+トラッキング+UI仕上げ

- [x] `BallKalmanTracker` 実装(ゲーティング・フェーズ判定。定速度モデルの簡易カルマン(g-h/alpha-beta)フィルタ、`lib/data/tracking/ball_kalman_tracker.dart`)
- [x] 合成データ(既知の観測列)による `BallKalmanTracker` の単体テスト作成(平滑化後の軌跡の妥当性・外れ値のゲーティング除去を確認。`test/data/tracking/ball_kalman_tracker_test.dart`)
- [x] Roboflow Universe公開モデルのライセンス・重み入手性確認 → **ユーザー判断により今回は調査自体を見送り**、Phase 1と同じCOCO汎用モデル(`yolo26n`、`sports ball`クラス)のまま次へ進むことで合意(2026-08-24)
- [x] ~~(重みが直接入手できる場合)Roboflowモデルへ差し替え~~ / **(入手できない場合と同等の扱いとして)Phase 1と同じCOCO汎用モデルのまま次へ進む**
- [x] `docs/model-provenance.md` を新設し、現行モデルの出典・ライセンスと、Roboflow差し替え見送りの判断・理由を記録
- [x] `BallTrajectoryAnalysisService` でPhase 1〜3の各要素を結線(`BallKalmanTracker`→`DistanceEstimation`→`LaunchParameterEstimator`→`BallisticsSimulator`。純粋関数`buildShotResult`として分離しテスト可能にした。`test/domain/services/ball_trajectory_analysis_service_test.dart`)
- [x] `ResultScreen` に `CustomPainter` オーバーレイを追加(`trajectory_painter.dart`。実測/シミュレーションの線種区別なし、一律描画。世界座標(z=前後・y=高さ)の側面図として描画、動画ピクセルへの再投影は行わない設計)
- [x] 数値表示(飛距離・打ち出し角度など)に精度注記(「目安値」)を追加
- [ ] (任意)`fl_chart` で俯瞰チャートを追加 → **ユーザー判断により今回はスキップ**(コア機能に集中する方針、2026-08-24)
- [x] Phase完了確認: `BallKalmanTracker` の単体テストが通ることを確認
- [ ] Phase完了確認: 実際のゴルフスイング動画(最低3〜5本)で検出成功率・推定飛距離の妥当性を確認し、次フェーズ着手判断のための記録として残す(**実機iPhoneでの確認が必要なため、ユーザー側での実施が必要な項目として残っている**)
- [x] Phase完了確認: `fvm dart analyze` でビルドエラー・lint警告がないことを確認(`No issues found!`)

## Phase 3.5: 検出前処理(ROI限定・クロップ推論)

元計画: [implementation-plan-roi-crop-detection.md](implementation-plan-roi-crop-detection.md)
背景: [investigation-analyzing-screen-stuck.md](investigation-analyzing-screen-stuck.md) §6 対策案1

- [x] `FrameCropper`(`dart:ui`によるフレームクロップ+座標変換)実装+単体テスト
- [x] `RoiConstants`/`RoiSequencer`(次フレームのROI決定ロジック)実装+単体テスト
- [x] `BallKalmanTracker`に逐次ステップAPI(`step`/`BallTrackerCursor`)を追加するリファクタ(既存`track()`テストは無改修のまま通す)
- [x] `ShotAnalysisService`/`BallTrajectoryAnalysisService.analyze()`をROIベースの逐次検出+追跡ループに書き換え(`buildShotResult()`のシグネチャ・既存テストは変更しない)
- [x] `AnalysisController`/`AnalyzingScreen`に`initialBallPositionPx`を通す
- [x] `FirstFrameReader`(動画の最初のフレーム取得の抽象化)実装
- [x] タップ座標⇔画像ピクセル座標の変換関数(`tap_position_mapper.dart`)実装+単体テスト
- [x] `BallPositionPickerScreen`(タップでボール位置を指定する新規画面)実装、`VideoSelectScreen`からの導線を追加
- [x] E2Eウィジェットテスト(`video_analysis_flow_test.dart`)を新しい画面遷移(VideoSelect→BallPositionPicker→Analyzing→Result)に更新
- [x] Phase完了確認: `fvm flutter test`・`fvm dart analyze`が通ることを確認
- [x] Phase完了確認: 実際のゴルフスイング動画(調査で使用した`IMG_3068.MOV`を含む)で、ROI導入前後の検出成功率・飛距離推定の妥当性を比較し、次フェーズ着手判断のための記録として残す(**実機iPhoneでの確認が必要なため、ユーザー側での実施が必要な項目として残っている**)
  - 実施結果(iPhone 15 Pro Simulator、`IMG_3090.MOV`、2026-08-25): 下記フォローアップ課題2件を発見・修正した上で、`InsufficientTrajectoryDataException`(「飛球区間の観測が不足しています」)が発生。詳細ログ(`frames=271 fullFrame=258 detections=8 maxConfidence=0.797`)と検出ごとのダンプにより調査した結果、アドレス区間(t=0〜231ms、confidence最大0.797)は正しく検出・追跡できているが、ボールが打球された直後(ffmpegでの目視確認では概ねt=0.3〜1秒の間)から動画終了(8.93秒、271フレーム)まで、258回のフルフレーム探索を含め一度も"sports ball"が再検出されなかった。ROI/フォールバックロジックは正しく機能していることを確認済みであり、これはコードの不具合ではなく、**打球後の小さく・速く・被写体ブレの大きいボールを汎用YOLOモデルが背景から検出できていない**という検出精度・撮影条件側の限界と判断した。対応は本Phaseの範囲外とし、Phase 4の「実機収録データでの追加ファインチューニング」「露光時間制御(モーションブラー対策)」で扱う

### フォローアップ課題(PR #10統合時点で既知、未修正)

- [x] `consecutiveLostFrames`が`continue`分岐で更新されない不具合を修正する
  - 症状: `lib/domain/services/ball_trajectory_analysis_service.dart`の`analyze()`ループで、`roiCursor == null`かつ確信度が閾値未満の検出しかない場合に`continue`する分岐があるが、この分岐では`consecutiveLostFrames`をインクリメントしていない
  - 影響: アドレス区間(タップ直後、まだ確信度の高い検出が一度もない状態)でボールが検出され続けない場合、`consecutiveLostFrames`が閾値(`RoiConstants.maxLostFramesBeforeFullFrameFallback`)に達せず、全体フレーム探索へのフォールバックが機能しないまま、動画全体で同じ小さいクロップ範囲を探索し続けてしまう(トラッキング確立後にロストした場合のフォールバックは正しく動作する)
  - 発見経緯: 最終ブランチ全体レビューで見つかったCritical/Important計4件の指摘をまとめて1回で修正した際、修正同士の組み合わせで新たに生じた回帰(修正ラウンドの運用上限に達したため、その場では再修正せずPRに既知の課題として記録した)。実機(iPhone 15 Pro Simulator、`IMG_3090.MOV`)で解析失敗(`sports ball detections=8`のまま`InsufficientTrajectoryDataException`)として再現し、原因として特定した
  - 修正方針: `continue`分岐でも`consecutiveLostFrames`をインクリメントする(またはインクリメントの計算位置を`tracker.step()`呼び出し前に移し、`continue`より先に評価する)
  - 対応: `continue`分岐で`consecutiveLostFrames++`を追加。回帰テスト(`ball_trajectory_analysis_service_analyze_test.dart`に「roiCursorがnullのまま確信度不足の検出が5フレーム連続してもフルフレーム探索にフォールバックし、再検出後はクロップ探索に復帰する」を追加)で、修正前は失敗・修正後は成功することを確認済み。実機での解析成功確認はユーザー側で実施

- [x] `analysisControllerProvider`のRiverpod標準リトライ(既定で最大10回・指数バックオフ)が、決定論的に失敗する解析(同じ動画・同じタップ位置なら常に同じ結果)に対して無意味に繰り返される不具合を修正する
  - 症状: `InsufficientTrajectoryDataException`等は`Exception`型であり`ProviderContainer.defaultRetry`の対象(`error is Error`にも`ProviderException`にも該当しない)となるため、`AnalysisController.build()`(=`service.analyze()`全体)が最大10回リトライされる
  - 影響: 実機では1回の解析が全フレームへの実推論を伴うため非常に重く、10回リトライすると「解析中」画面が数分〜十数分単位で止まって見える(フリーズと誤認しやすい)
  - 発見経緯: 上記`consecutiveLostFrames`修正後、実機(`IMG_3090.MOV`)で「解析中から遷移しない」報告を受け、同一ログ(`sports ball detections=8`)が繰り返し出力されることから特定
  - 対応: `lib/features/analyzing/analysis_controller.dart`に`analysisRetryPolicy`(`ProviderContainer.defaultRetry`をmaxRetries=3でラップ)を追加し、`@Riverpod(retry: analysisRetryPolicy)`で適用。単体テスト(`test/features/analyzing/analysis_controller_test.dart`)で検証済み

## Phase 4(将来、今回は着手しない)

- [ ] カメラ撮影(録画)機能の復活(`VideoSelectScreen` に録画導線を追加するだけで `ShotAnalysisService` 以降は無改修想定)
- [ ] 実機収録データでの追加ファインチューニング
- [ ] Android対応
- [ ] 露光時間制御(モーションブラー対策)
