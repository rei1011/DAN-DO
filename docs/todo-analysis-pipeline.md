# 動画解析パイプライン 実装TODO

元計画: [implementation-plan-analysis-pipeline.md](implementation-plan-analysis-pipeline.md)

進捗管理用のチェックリスト。作業を中断・再開する際は、このファイルのチェック状況を見れば「どこまで終わっているか」がわかるようにする。

## 使い方

- タスクに着手したら `[ ]` → `[x]` にする
- 各Phase末尾の確認項目まで終わったら次のPhaseへ進む
- タスクの詳細(コード配置・設計判断の理由など)は元計画の該当セクションを参照
- 現在のステータス: **Phase 1 実装完了・実機確認待ち**(2026-08-24時点)

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

- [ ] `distance_estimation.dart` 実装(ピンホールモデル計算)
- [ ] `launch_parameter_estimator.dart` 実装(最小二乗フィッティングでV0・θ・φ算出)
- [ ] `ballistics_simulator.dart` 実装(抗力+マグヌス、RK4数値積分)
- [ ] `test/domain/` 配下に単体テスト作成(既知の初速・角度での着地時間・飛距離の妥当性確認)
- [ ] RK4刻み幅の数値安定性を確認するテストを作成
- [ ] Phase完了確認: `test/domain/` 配下の単体テストが通ることを確認
- [ ] Phase完了確認: `fvm dart analyze` でビルドエラー・lint警告がないことを確認

## Phase 3: 本実装モデル差し替え+トラッキング+UI仕上げ

- [ ] `BallKalmanTracker` 実装(ゲーティング・フェーズ判定)
- [ ] 合成データ(既知の観測列)による `BallKalmanTracker` の単体テスト作成(平滑化後の軌跡の妥当性・外れ値のゲーティング除去を確認)
- [ ] Roboflow Universe公開モデルのライセンス・重み入手性をユーザー自身のブラウザで確認
- [ ] (重みが直接入手できる場合)Roboflowモデルへ差し替え / (入手できない場合)Phase 1と同じCOCO汎用モデルのまま次へ進む
- [ ] `docs/model-provenance.md` を新設し、モデルのURL・ライセンス種別・確認日を記録
- [ ] `BallTrajectoryAnalysisService` でPhase 1〜3の各要素を結線
- [ ] `ResultScreen` に `CustomPainter` オーバーレイを追加(実測/シミュレーションの線種区別なし、一律描画)
- [ ] 数値表示(飛距離・打ち出し角度など)に精度注記(例:「目安値」)を追加
- [ ] (任意)`fl_chart` で俯瞰チャートを追加
- [ ] Phase完了確認: `BallKalmanTracker` の単体テストが通ることを確認
- [ ] Phase完了確認: 実際のゴルフスイング動画(最低3〜5本)で検出成功率・推定飛距離の妥当性を確認し、次フェーズ着手判断のための記録として残す
- [ ] Phase完了確認: `fvm dart analyze` でビルドエラー・lint警告がないことを確認

## Phase 4(将来、今回は着手しない)

- [ ] カメラ撮影(録画)機能の復活(`VideoSelectScreen` に録画導線を追加するだけで `ShotAnalysisService` 以降は無改修想定)
- [ ] 実機収録データでの追加ファインチューニング
- [ ] Android対応
- [ ] 露光時間制御(モーションブラー対策)
