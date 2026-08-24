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

- [ ] `FrameCropper`(`dart:ui`によるフレームクロップ+座標変換)実装+単体テスト
- [ ] `RoiConstants`/`RoiSequencer`(次フレームのROI決定ロジック)実装+単体テスト
- [ ] `BallKalmanTracker`に逐次ステップAPI(`step`/`BallTrackerCursor`)を追加するリファクタ(既存`track()`テストは無改修のまま通す)
- [ ] `ShotAnalysisService`/`BallTrajectoryAnalysisService.analyze()`をROIベースの逐次検出+追跡ループに書き換え(`buildShotResult()`のシグネチャ・既存テストは変更しない)
- [ ] `AnalysisController`/`AnalyzingScreen`に`initialBallPositionPx`を通す
- [ ] `FirstFrameReader`(動画の最初のフレーム取得の抽象化)実装
- [ ] タップ座標⇔画像ピクセル座標の変換関数(`tap_position_mapper.dart`)実装+単体テスト
- [ ] `BallPositionPickerScreen`(タップでボール位置を指定する新規画面)実装、`VideoSelectScreen`からの導線を追加
- [ ] E2Eウィジェットテスト(`video_analysis_flow_test.dart`)を新しい画面遷移(VideoSelect→BallPositionPicker→Analyzing→Result)に更新
- [ ] Phase完了確認: `fvm flutter test`・`fvm dart analyze`が通ることを確認
- [ ] Phase完了確認: 実際のゴルフスイング動画(調査で使用した`IMG_3068.MOV`を含む)で、ROI導入前後の検出成功率・飛距離推定の妥当性を比較し、次フェーズ着手判断のための記録として残す(**実機iPhoneでの確認が必要なため、ユーザー側での実施が必要な項目として残っている**)

## Phase 4(将来、今回は着手しない)

- [ ] カメラ撮影(録画)機能の復活(`VideoSelectScreen` に録画導線を追加するだけで `ShotAnalysisService` 以降は無改修想定)
- [ ] 実機収録データでの追加ファインチューニング
- [ ] Android対応
- [ ] 露光時間制御(モーションブラー対策)
