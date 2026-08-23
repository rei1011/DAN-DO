# DAN-DO 実装計画: 動画選択→ボール弾道解析・飛距離予測(撮影機能は後回し)

## Context

`docs/implementation-plan.md` は当初「アプリの土台+撮影機能まで」を先に実装するスコープだったが、ユーザーの判断で優先順位を入れ替える。動画撮影(カメラ録画)自体は技術的な難易度が低いため後回しにし、**「撮影済みの動画を使って弾道を表示し、飛距離を予測する」というアプリの本丸機能を先に実装する**。

`docs/technical-design.md` の事前調査で「ボール検出・距離推定・弾道物理モデルのフル実装」は大規模開発になると判明していたが、以下の判断により実装可能な範囲に収める:
- ボール軌跡取得は**ML自動検出**(手動タップではない)。ただし**モデルは公開済み学習済みモデルをそのまま使い、自前データでのファインチューニングは今回のスコープ外**とする
- フレーム抽出は**ネイティブSwift実装を自作せず、既存Flutterパッケージ**で済ませる
- 動画はカメラ録画ではなく**端末フォトライブラリから選択**する。この場合、撮影時のカメラ画角メタデータが取得できないため、距離推定は**固定の仮定画角**を使う目安値ベースの設計に変更する

この方針転換により、`ShotAnalysisService` 抽象インターフェースの背後に置くのは「モック」ではなく「本実装(ML自動検出+距離推定+物理モデル)」になる。将来、撮影機能を復活させる際は `VideoSelectScreen` に録画導線を足すだけで済むよう、レイヤー分離は維持する。

### 技術調査で判明した既存計画からの変更点(裏取り済み)

1. **フレーム抽出**: 元々の推奨(ネイティブSwift `AVAssetReader`+Pigeon自作)は行わず、`get_thumbnail_video`(pub.dev, MIT, iOS対応, Dart SDK制約`^3.4.0`, Pub Points140/Likes63/週間DL106k)を採用。老舗`video_thumbnail`(GitHub 907 stars)のフォークでDart3対応済み、Dart3対応版の中では最も実利用実績が大きい。`thumbnailData({video, imageFormat: JPEG, timeMs, quality})`で指定ミリ秒位置のJPEGバイト列を取得できるが、単発フレーム抽出APIのみのためループ呼び出しで連番フレームを取得する(懸念点: 最終更新が21ヶ月前で停滞気味だが、API自体は枯れた機能のみで破壊的変更の影響を受けにくいと判断)
2. **ML推論**: `ultralytics_yolo`(pub.dev, **AGPL-3.0ライセンス**)を採用。個人開発・学習目的のため気にせず進める方針で合意済み(将来App Store公開時は要再検討)
3. **モデル入手**: Phase 1は`ultralytics_yolo`公式の汎用COCO学習済みモデル(`yolo11n`、初回自動ダウンロード)の`sports ball`クラスで代用し配線確認する。ゴルフボール特化モデル(Roboflow Universe公開データセット/モデル)への差し替えはPhase 3で行うが、**公開プロジェクトで学習済み重みが直接ダウンロードできるとは限らない**(データセットのみ提供の場合がある)。この点はPhase 3着手時にユーザー自身のブラウザでの確認が必要だが、**重みが直接入手できない場合、自前学習(Ultralyticsでの学習)は今回のスコープ外とし、Phase 1と同じCOCO汎用`sports ball`クラスのまま妥協する**(精度向上はPhase 4以降に先送り)
4. **距離推定の前提変更**: 撮影時の `videoFieldOfView` ライブ取得が前提だった数式を、既存動画では使えないため、**固定の仮定画角**を使う目安値ベースに変更する。対象機種は**iPhone 17(ベースモデル)・縦向き撮影**を前提とする。Appleの公式スペック(メインカメラ26mm相当)からフルサイズ換算で逆算すると、横向き基準の水平画角は約69.4°になるが、**センサーは物理的に横向き固定のため、縦向き撮影で回転後のフレーム幅とペアリングすべきは狭い軸側の約49.6°**であり、69.4°をそのまま使うと距離推定が体系的にずれる(調査で判明・裏取り済み)。16:9クロップ等でさらに誤差が残るため、この49.6°はあくまで初期値とし、開発中は算出結果と実測値の比較を随時行って妥当性を確認する

## 画面構成

3画面の直線遷移を維持しつつ、1画面目の役割を変更する。

```
VideoSelectScreen  →  AnalyzingScreen  →  ResultScreen
(旧CaptureScreen)     (エラー分岐を強化)   (弾道オーバーレイ追加)
```

- **VideoSelectScreen** (`lib/features/video_select/video_select_screen.dart`): `image_picker`の`pickVideo(source: ImageSource.gallery)`で動画選択。選択直後に動画の長さを取得し、**1分を超える場合はバリデーションエラーとして再選択を促す**(長尺動画によるフレーム抽出の異常な遅延を防ぐ簡易ガード)。`camera`パッケージのプレビューは撤去(pubspec上は残置、将来の撮影機能復活用)
- **AnalyzingScreen** (`lib/features/analyzing/analyzing_screen.dart`): 本実装は失敗しうる(ボール未検出等)ため、`AsyncValue.error`分岐で「別の動画を選ぶ」ボタンを表示しVideoSelectScreenへ戻す
- **ResultScreen** (`lib/features/result/result_screen.dart`): `video_player`再生+数値表示に加え、弾道オーバーレイ(`CustomPainter`)を追加。実測区間とシミュレーション区間は線種(実線/破線等)で視覚的に区別せず一律描画とする(データモデル上の`isMeasured`は保持するが、UI描画では未使用)。飛距離・打ち出し角度などの数値表示には、仮定FOVによる目安値であることを示す精度注記(例:「目安値」)を添える。俯瞰チャート(`fl_chart`)は任意

前提: ユーザーが選ぶ動画はスイング全体を程よくトリミングした数秒のクリップとする(長尺動画からのスイング区間自動検出はスコープ外)。

## パイプライン設計

`docs/implementation-plan.md`のレイヤー方針(`features/` `domain/` `data/`)を踏襲する。

```
lib/
  core/
    ball_constants.dart              # ボール直径0.0427m、重力等
    ballistics_constants.dart        # 抗力係数・揚力係数のヒューリスティック
    assumed_camera_intrinsics.dart   # 仮定FOV定数(iPhone 17縦向き想定、約49.6°。将来: 機種別FOVテーブルへ拡張)

  features/
    video_select/video_select_screen.dart
    analyzing/
      analyzing_screen.dart
      analysis_controller.dart       # @riverpod class、ShotAnalysisServiceを呼ぶ薄いオーケストレーション
    result/
      result_screen.dart
      trajectory_painter.dart        # CustomPainter(Phase 3、実測/シミュレーションを線種で区別しない一律描画)
      trajectory_chart.dart          # fl_chartラッパー(Phase 3, 任意)

  domain/
    models/                          # freezed
      raw_ball_detection.dart        # frameTimeMs, centerPx(Offset), diameterPx, confidence
      tracked_ball_state.dart        # フィルタ後u,v,速度,フェーズ(address/launch/lost)
      trajectory_point.dart          # t,x,y,z,isMeasured(UI描画では未使用、検出成功率記録等の内部用途で保持)
      shot_result.dart               # carryDistanceMeters, launchAngleDegrees, launchDirectionDegrees, measuredTrajectory, simulatedTrajectory
    services/
      shot_analysis_service.dart              # abstract interface(差し替え可能性の要、変更なし)
      ball_trajectory_analysis_service.dart   # 本実装オーケストレータ
      distance_estimation.dart                # ピンホールモデル計算(純粋関数)
      launch_parameter_estimator.dart         # 最小二乗フィッティングでV0・θ・φ算出
      ballistics_simulator.dart               # 抗力+マグヌス、RK4数値積分(Flutter非依存の純粋関数)

  data/
    video/
      video_frame_source.dart              # interface: Future<Uint8List> frameAt(Duration t)
      get_thumbnail_video_frame_source.dart # get_thumbnail_videoを使った実装
    ml/
      ball_detector.dart                    # ultralytics_yoloのYOLOインスタンスの薄いラッパー
      ball_detector_provider.dart           # @Riverpod(keepAlive: true)、loadModel()を1回きりにする
    tracking/
      ball_kalman_tracker.dart              # 手書き簡易カルマンフィルタ+ゲーティング+フェーズ判定
```

### データフロー

```
XFile(動画パス)
  → VideoFrameSource.frameAt(各タイムスタンプ)          # fps間引きは後述
  → BallDetector.detect(frame bytes) → List<RawBallDetection>
  → BallKalmanTracker.process(...)
        → confidence閾値+予測位置からの距離閾値でゲーティング(誤検出除去)
        → 状態ベクトル[u,v,du,dv]の定速度モデルでカルマン平滑化
        → 速度急変検知で「静止(アドレス)区間」「インパクト直後区間」を判定
        → List<TrackedBallState>
  → DistanceEstimation: 仮定FOVから算出したf_px + アドレス区間の直径pxでZ0算出
                          → インパクト直後区間の各フレームでX,Y,Z算出
  → LaunchParameterEstimator: X(t),Y(t),Z(t)の線形回帰 → V0, launchAngle, launchDirection
  → BallisticsSimulator: RK4でインパクトから着地までの軌道を積分 → List<TrajectoryPoint>(isMeasured=false)
  → 実測区間+シミュレーション区間を結合 → ShotResult
```

- **fps間引き**: Phase 1は間引きなしで正確さ優先(数秒クリップなら90枚程度)。実機検証で90フレーム想定のクリップに対する抽出+推論の合計時間が**目安10秒を超える場合**、10〜15fps相当に間引く(インパクト直後の有効観測窓0.2〜0.5秒でも3〜7フレーム残る想定)
- **カルマンフィルタ**: 外部パッケージ品質が不透明なため手書き(80〜120行程度)。ゲーティングは単純な閾値判定で十分、Mahalanobis距離等の厳密な統計処理は今回は過剰

## 段階的な実装ステップ

### Phase 0: 下地整理
- `pubspec.yaml`に依存追加: `image_picker`, `get_thumbnail_video`, `ultralytics_yolo`, `fl_chart`(任意)
- `lib/main.dart`からriverpod学習用サンプル(`userNameProvider`, `UserNameSwitcherView`)を削除し、実アプリのエントリポイント(`ProviderScope`+`MaterialApp`+`VideoSelectScreen`起点のルーティング)に置き換え
- `test/score_change_view_test.dart`・`test/widget_test.dart`は現行`main.dart`と無関係で既に壊れているため削除
- `ios/Runner/Info.plist`に`NSPhotoLibraryUsageDescription`を追加(`image_picker`のギャラリーアクセスに必須)

### Phase 1: 配線確認(精度度外視)
- `image_picker`で動画選択→`get_thumbnail_video`でフレーム抽出→`ultralytics_yolo`公式`yolo11n`モデルの`sports ball`クラスで推論、が実機で一通り動くことを確認(最大のリスク検証ポイント)
- ダミーの距離推定(適当な定数)で仮の`ShotResult`を返し、3画面遷移・エラー分岐を実機で通す
- `FakeShotAnalysisService`を用意し、provider override経由の画面遷移widgetテストを1本作成

### Phase 2: 距離推定・弾道物理モデルの単体検証(純粋Dart、UI/ML非依存)
- `distance_estimation.dart`・`launch_parameter_estimator.dart`・`ballistics_simulator.dart`を実装
- `test/domain/`配下に単体テスト作成(既知の初速・角度での着地時間・飛距離の妥当性確認、RK4刻み幅の数値安定性確認)

### Phase 3: 本実装モデル差し替え+トラッキング+UI仕上げ
- `BallKalmanTracker`実装(ゲーティング・フェーズ判定)。合成データ(既知の観測列)を入力し、平滑化後の軌跡が期待通りか・明らかな外れ値がゲーティングで除去されるかを確認する単体テストを追加
- Roboflow Universe公開モデルへの差し替え(ユーザー自身のブラウザでのライセンス・重み入手性確認が前提。**重みが直接手に入らない場合は自前学習は行わず、Phase 1と同じCOCO汎用モデルのまま次フェーズへ進む**)
- `BallTrajectoryAnalysisService`でPhase1〜3の各要素を結線
- `ResultScreen`に`CustomPainter`オーバーレイ(実測/シミュレーションの線種区別なし)、数値表示への精度注記、任意で`fl_chart`俯瞰チャート追加

### Phase 4(将来、今回は着手しない)
- カメラ撮影(録画)機能の復活(`VideoSelectScreen`に録画導線を追加するだけで`ShotAnalysisService`以降は無改修想定)
- 実機収録データでの追加ファインチューニング、Android対応、露光時間制御(モーションブラー対策)

各Phase終了時に `fvm dart analyze`(`docs/riverpod-lint-investigation.md`記載の既知の制約により`flutter analyze`ではなくこちらを使う)でriverpod_lint警告が出ないことを確認する。

## 既存ファイルへの影響

- **`pubspec.yaml`**: `image_picker`, `get_thumbnail_video`, `ultralytics_yolo`, `fl_chart`(任意)を追加。既存の`camera`は削除せず放置。`freezed`/`json_serializable`/`riverpod_generator`は既存導入済みで今回初めて実際に使う
- **`lib/main.dart`**: riverpod学習用サンプルを全削除し実アプリのエントリポイントに置き換え。`main.g.dart`は`build_runner`で再生成
- **`test/`**: 陳腐化した2ファイルを削除、Phase 2/3で新規テストを追加
- **モデルのライセンス・出典管理**: `docs/model-provenance.md`を新設し、Roboflowデータセット/モデルのURL・ライセンス種別・確認日を記録(Phase 3着手時)

## 検証方法

- `fvm dart analyze`でビルドエラー・lint警告がないことを確認
- Phase 1完了時点で実機iPhoneで動画選択→解析→結果表示までの一連の流れが動くことを確認(Simulatorはカメラ非対応だが、ギャラリー動画選択+ML推論はSimulatorでもある程度検証可能。ただしCoreML/Neural Engineの実速度は実機必須)
- Phase 2で`test/domain/`配下の単体テストが通ることを確認(距離推定式・弾道シミュレーションの妥当性)
- Phase 3で`BallKalmanTracker`の単体テスト(合成データによるゲーティング・平滑化の妥当性確認)が通ることを確認
- 距離推定の精度(仮定FOV定数の妥当性)は特定のPhaseで区切って検証するのではなく、実機での算出結果と実測値の比較を開発中随時行い、必要に応じて`assumed_camera_intrinsics.dart`の定数を調整する
- 各Phaseの完了基準は定量的な合格閾値を設けず、プロトタイプ段階の記録目的の確認に留める。Phase 3完了時点では、実際のゴルフスイング動画(最低3〜5本)を使って検出成功率・推定飛距離の妥当性を確認し、次フェーズ着手判断のための記録として残す
