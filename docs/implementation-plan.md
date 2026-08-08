# ゴルフスイング解析アプリ「DAN-DO」— Flutterアプリ 初回実装(土台+撮影機能)

## Context

ゴルフのスイング動画を撮影し、飛距離と弾道を表示するFlutterアプリを新規に作る。リポジトリは現状README.mdのみの空プロジェクト。

ヒアリングの結果、最終的なアプリ像は以下の通り:
- iOSを優先(Androidは将来対応)
- カメラは後方固定(ダウンザライン)、30fps撮影
- ボール検出は既存MLパッケージ(YOLO系、CoreML)を活用し、動画からボールを画像追跡
- 飛距離はボール実寸(42.7mm)を基準にした単眼カメラでの距離推定+弾道物理モデルで算出
- 弾道は検出した実軌跡+物理モデルによる延長区間を組み合わせて表示
- 撮影履歴は不要、単発の「撮影→解析→結果表示」フロー

事前調査(Web調査)により、フル実装(ボール検出・距離推定・弾道物理モデルまで)はネイティブSwift連携(フレーム抽出・露出制御)とMLモデルの転移学習を要する大規模な開発になることが判明した。特に以下がボトルネック:
- 30fpsではインパクト直後のボールがモーションブラーで検出困難(露光時間の短縮にはネイティブAVFoundation連携が必要)
- 汎用MLモデルはゴルフボールを認識できず、Roboflow等の公開データセット+自前データでの転移学習がほぼ必須
- 単眼カメラでの距離推定はボール検出のピクセル誤差がそのまま距離誤差に直結する

**そのため、今回のスコープは「アプリの土台+撮影機能まで」とする。** ボール検出・距離推定・弾道物理計算は、差し替え可能なインターフェース(`ShotAnalysisService`)の背後にモック実装を置き、UI/画面遷移/撮影/動画保存までの一連の流れを先に動く形にする。ボール検出やML推論などの本実装は、この土台の上に後続セッションで段階的に追加する(モックをRiverpodのprovider override経由で本実装に差し替えるだけで済む設計にする)。

## 全体アーキテクチャ(将来を見据えた設計指針)

将来の本実装(ボール検出・距離推定・弾道シミュレーション)を見据え、以下のレイヤー構成を採用する。今回のスコープではこのうち土台部分のみを実装する。

```
lib/
  main.dart / app.dart
  core/                     # テーマ・定数
  features/
    capture/                # 撮影画面 + CameraController Riverpod provider ← 今回実装
    analyzing/              # 解析中画面 + オーケストレーション(Notifier) ← 今回実装(モック接続)
    result/                 # 結果画面(動画再生 + 数値表示) ← 今回実装(ダミー値表示)
  domain/
    models/
      shot_result.dart      # {carryDistance, launchAngle, launchDirection} ← 今回実装
    services/
      shot_analysis_service.dart       # 抽象インターフェース ← 今回実装
      mock_shot_analysis_service.dart  # ダミー実装(固定遅延+ダミー値) ← 今回実装
      # 将来: distance_estimation_service.dart, ballistics_simulation_service.dart 等をここに追加
  data/
    # 将来: ml/yolo_ball_detector.dart, platform/frame_extractor.dart(Pigeon)等を追加
```

- 状態管理: `flutter_riverpod`(+ `riverpod_annotation`/`riverpod_generator`)。非同期処理(撮影ファイル保存、将来の解析パイプライン)との相性、テスト容易性のため。
- `ShotAnalysisService`をRiverpodのproviderとして注入することで、将来「モック→実ML解析」への差し替えを他レイヤーに影響なく行える。

## 今回実装するスコープ(詳細)

### 1. プロジェクト作成
- `flutter create` でiOSをターゲットにした新規Flutterプロジェクトを作成(プロジェクト名: `dan_do`、表示名: `DAN-DO`)
- iOS最小バージョン・Podfile設定(camera要件に合わせる)

### 2. 依存パッケージ(pubspec.yaml)
| パッケージ | 用途 |
|---|---|
| `camera` | カメラプレビュー・30fps録画・ファイル保存 |
| `video_player` | 結果画面での録画動画の再生 |
| `path_provider` | 動画ファイルの保存先取得 |
| `permission_handler` | カメラ/マイク権限リクエスト |
| `flutter_riverpod` + `riverpod_annotation` | 状態管理(dev: `riverpod_generator`, `build_runner`) |

ML/CV系(`ultralytics_yolo`, `opencv_dart`, `pigeon`, `fl_chart`)、`freezed`は今回のスコープでは導入しない(モックのみのため過剰)。

### 3. 画面フロー(3画面の直線遷移、`Navigator`のpush/popで十分)

**CaptureScreen** (`lib/features/capture/`)
- `camera`パッケージでバックカメラのプレビュー表示
- 録画開始/停止ボタン、`CameraController`は30fps・妥当な解像度(例: 1080p)で初期化
- 権限リクエスト(カメラ・マイク)のハンドリング、拒否時のエラー表示
- 録画停止時、`XFile`を`path_provider`のアプリドキュメントディレクトリ配下に保存し、`AnalyzingScreen`へファイルパスを渡してpush

**AnalyzingScreen** (`lib/features/analyzing/`)
- 「解析中」のプログレスインジケーター表示
- Riverpodの`shotAnalysisServiceProvider`(現状は`MockShotAnalysisService`)を呼び出し、動画ファイルを渡して`ShotResult`を非同期取得
- 取得後、動画パス+`ShotResult`を持って`ResultScreen`へ自動遷移

**ResultScreen** (`lib/features/result/`)
- `video_player`で撮影した動画を再生
- `ShotResult`のダミー値(飛距離・打ち出し角・方向)を数値表示
- 弾道オーバーレイ描画(`CustomPainter`)は今回実装しない(将来のスコープ)。数値表示のみ

### 4. ドメイン層
- `lib/domain/models/shot_result.dart`: `ShotResult { double carryDistanceMeters; double launchAngleDegrees; double launchDirectionDegrees; }`
- `lib/domain/services/shot_analysis_service.dart`: 抽象クラス `abstract class ShotAnalysisService { Future<ShotResult> analyze(File videoFile); }`
- `lib/domain/services/mock_shot_analysis_service.dart`: 固定または簡易ランダムのダミー値を、擬似的な処理時間(例: 1.5秒delay)の後に返す実装。将来の本実装(フレーム抽出→ボール検出→距離推定→物理モデル)がこのインターフェースを実装してRiverpod provider側で差し替えられるようにする

### 5. iOS設定
- `Info.plist`にカメラ・マイクの使用目的説明(`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`)を追加
- 実機での動作を前提とした最小構成(Simulatorはカメラハードウェアにアクセスできないため)

## 検証方法

- `flutter analyze` / `flutter pub get`でビルドエラーがないことを確認
- 実機iPhoneを接続し `flutter run` で起動、以下を確認:
  - カメラプレビューが表示される
  - 録画開始→停止で動画ファイルが保存される
  - AnalyzingScreenで一定時間後に自動遷移する
  - ResultScreenで撮影した動画が再生され、ダミーの飛距離・角度・方向が表示される
- iOS Simulatorではカメラプレビューが動作しないため、画面遷移・UIレイアウトの確認のみSimulatorで行い、カメラ・録画の実動作確認は必ず実機で行う

## 将来のスコープ(参考、今回は着手しない)

- ネイティブSwift(AVAssetReader)によるフレーム抽出・露出時間の短縮制御
- `ultralytics_yolo`等を用いたゴルフボール検出(公開データセットからの転移学習含む)
- ボールピクセル径を用いた単眼距離推定ロジック(`distance_estimation_service.dart`)
- 空気抵抗・マグヌス効果を考慮した弾道物理シミュレーション(`ballistics_simulation_service.dart`)
- 動画への軌跡オーバーレイ描画(`CustomPainter`)・俯瞰弾道チャート(`fl_chart`)
