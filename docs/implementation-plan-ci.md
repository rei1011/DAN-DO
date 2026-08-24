# GitHub Actions CI 構築

## Context

DAN-DOはFlutter単一パッケージのiOSアプリだが、`.github/workflows/`は存在せず、CIが一切整備されていない。テスト・lint・ビルドが壊れたままmainにマージされるリスクを防ぎたい。今回、以下を確認済みの上でCIを新規構築する:

- Flutter SDK: `.fvmrc`で`stable`チャンネル追従（バージョン固定なし）
- lint: `flutter_lints` + `riverpod_lint`（`analysis_options.yaml`で有効化済み、追加ブートストラップ不要）
- test: `test/`配下にunit/widget testあり（integration_testはなし）
- build: `ios/`ディレクトリのみ存在（Android/Web等は未対応）、CocoaPods管理は`get_thumbnail_video`と`libwebp`のみで、`camera`/`video_player`/`ultralytics_yolo`等はFlutterのSwift Package Manager統合でローカルパス解決される
- `.g.dart`/`.freezed.dart`等の生成ファイルはgitにコミット済み（riverpod_generator/freezed/json_serializable）
- `pubspec.lock`はgit管理下（キャッシュキーに使える）

ユーザーが確定した追加要件:
- Flutterバージョンは`.fvmrc`にピン留めしたバージョンをローカル・CI双方で使う（詳細は末尾の追記参照。当初は`stable`チャンネル追従の予定だったが、PR #9のCI失敗を受けて方針変更）
- `dart format`チェックを追加
- 生成コード整合性チェック（build_runner実行結果とコミット済みファイルの差分検証）を追加
- カバレッジ計測は不要
- READMEにCIバッジを追加する
- lintは`flutter analyze`ではなく`dart analyze`を使う（ローカルで`fvm flutter analyze`が構文エラーを正しく検出しないケースが確認されているため。`dart analyze`も同じ`analysis_options.yaml`・lintルール一式を参照するため検出精度は同等以上で、エラー時の非ゼロ終了コードも同様）

## 実装方針

`.github/workflows/ci.yml` を新規作成し、2ジョブ構成にする。

**ジョブを1ファイルにまとめる理由**: `needs:`によるジョブ間依存は同一ワークフローファイル内でのみ機能する。lint/testが失敗した場合に高コストなmacOSビルドジョブの起動を止める（コスト対策）ために、両ジョブを同じファイルに置く。

### ジョブ1: `analyze_and_test`（`ubuntu-latest`）

安価なLinuxランナーで完結させる。ステップ順序:
1. `actions/checkout@v5`
2. `subosito/flutter-action@v2`（`flutter-version-file: .fvmrc`, `cache: true`）
3. `actions/cache@v5` — `~/.pub-cache`を`hashFiles('pubspec.lock')`でキャッシュ
4. `flutter pub get`
5. **生成コード整合性チェック**: `dart run build_runner build --delete-conflicting-outputs` 実行後、`git status --porcelain`が空でないなら`exit 1`（`git diff --exit-code`だけだと未追跡の新規生成ファイル漏れを検出できないため`git status --porcelain`を使う）
6. **フォーマットチェック**: `dart format --output=none --set-exit-if-changed .`
7. **lint**: `dart analyze`（`flutter analyze`ではなくこちらを使う。理由は上記「ユーザーが確定した追加要件」参照）
8. **test**: `flutter test`

### ジョブ2: `build_ios`（`macos-latest`, `needs: analyze_and_test`）

lint/testが通った場合のみ起動（macOSランナーはLinuxの約10倍のActions分数を消費するため）。ステップ順序:
1. `actions/checkout@v5`
2. `subosito/flutter-action@v2`（`flutter-version-file: .fvmrc`, `cache: true`）
3. `actions/cache@v5` — `~/.pub-cache`（ジョブ1と同じキー）
4. `actions/cache@v5` — `ios/Pods` と `~/Library/Caches/CocoaPods` を`hashFiles('ios/Podfile.lock')`でキャッシュ
5. `flutter pub get`
6. **build**: `flutter build ios --release --no-codesign`（内部で`pod install`とSPM解決を自動実行するため、明示的な`pod install`ステップは不要。署名なしのため証明書・Secrets設定は不要）

### 共通設定

- トリガー: `push: branches: [main]` / `pull_request: branches: [main]` / `workflow_dispatch`（手動実行用）
- `concurrency: group: ci-${{ github.workflow }}-${{ github.ref }}, cancel-in-progress: true` — 連続pushで古い実行を自動キャンセルし、特にmacOSジョブの二重実行を防ぐ
- `permissions: contents: read` — 最小権限
- `timeout-minutes`: ubuntu側15分、macOS側30分（`ultralytics_yolo`のネイティブSwiftコンパイルで初回ビルドが伸びる可能性を考慮）

### READMEへのCIバッジ追加

`README.md`は現状`# DAN-DO`の1行のみ。1行目の直後にCIバッジを追加する:

```markdown
[![CI](https://github.com/rei1011/DAN-DO/actions/workflows/ci.yml/badge.svg)](https://github.com/rei1011/DAN-DO/actions/workflows/ci.yml)
```

## 作成・変更するファイル

- `.github/workflows/ci.yml`（新規作成、上記2ジョブ構成のワークフロー全文）
- `README.md`（CIバッジを1行追加）
- `docs/implementation-plan-ci.md`（本ファイル。既存の`docs/implementation-plan-analysis-pipeline.md`等と同じ命名慣習でプロジェクトの設計ドキュメントとして保存）

## 留意事項（実装後もリスクとして残るが今回は許容）

- Flutterバージョンを`.fvmrc`にピン留めしたため、将来意図的にバージョンを上げる際は`.fvmrc`の更新と同時に`pubspec.lock`/`analysis_options.yaml`を再生成してコミットする必要がある。これを忘れると、再びPR #9と同じ理由（SDKバージョンと固定済みlockファイルの乖離）で「生成コード整合性チェック」が誤って失敗する（詳細は末尾の追記参照）
- `macos-latest`はGitHub側の方針で定期的にイメージが移行される。挙動変化を避けたい場合は将来的に`macos-15`等への明示ピン留めを検討可能

## 検証方法

1. `.github/workflows/ci.yml`をYAML構文として妥当か確認（`actionlint`があれば実行、なければ目視 + GitHub上での実行結果で確認）
2. ブランチを切ってpush、または直接mainにpushしてActionsタブでワークフローが起動することを確認
3. 各ステップ（生成コード整合性チェック→format→analyze→test→(build)）が期待通り成功することを確認
4. 意図的に以下を試してジョブが正しく失敗することを確認（余力があれば）:
   - `.g.dart`を手動編集してコミット → 生成コード整合性チェックで失敗することを確認
   - フォーマットを崩したコードをコミット → formatチェックで失敗することを確認
   - `analyze_and_test`をわざと失敗させ、`build_ios`ジョブが起動しない（skip扱いになる）ことを確認
5. README.mdのバッジがGitHub上で正しく表示されることを確認

## 追記 (2026-08-25): PR #9 CI失敗の原因と方針変更

実装完了後、PR #9で`analyze_and_test`の「生成コード整合性チェック」ステップが失敗した。調査の結果、生成コード（`.g.dart`/`.freezed.dart`）自体は最新であり、失敗の原因は無関係な2つの副作用だった:

- `flutter pub get`実行時にFlutter SDKが`analysis_options.yaml`へ`analyzer: exclude:`ブロックを自動追記する（1回限りの自動マイグレーション）
- コミット済み`pubspec.lock`が、実行時のFlutter/Dart SDKが同梱するパッケージバージョン（meta, test, vector_math等）より古く、`pub get`時に再解決されて更新される

ローカル(fvm)とCI(`stable-3.47.1-x64`)は同じFlutterバージョンだったが、`channel: stable`かつバージョン未固定の運用のため、「今実際に使われているSDKバージョン」と「`pubspec.lock`/`analysis_options.yaml`がコミットされた時点のSDKバージョン」が時間経過とともにズレていたことが根本原因。

これを受けて、Flutterバージョン運用を`stable`チャンネル追従からピン留めに変更した:
- `.fvmrc`を`{"flutter": "3.47.1"}`にピン留め
- `ci.yml`の`subosito/flutter-action@v2`は`channel: stable`ではなく`flutter-version-file: .fvmrc`を使用し、`.fvmrc`を唯一の情報源としてローカル・CIのバージョンを一致させる
- ピン留め後のバージョンで`pubspec.lock`/`analysis_options.yaml`を再生成してコミット

「生成コード整合性チェック」の`git status --porcelain`が生成ファイル以外の差分も拾ってしまう設計自体は変更していない（チェック対象を`*.g.dart`/`*.freezed.dart`に絞ることも検討したが、今回はバージョン固定のみで対応する方針をユーザーが選択）。将来Flutterバージョンを意図的に上げる際は、上記の留意事項の通り`pubspec.lock`等の再生成を忘れないこと。
