# riverpod_lint が `flutter analyze` で警告を出さない件の調査記録

`docs/riverpod-exercises.md` 問題13の雛形コード([lib/main.dart](../lib/main.dart))は、
`avoid_public_notifier_properties` ルールにわざと引っかかる悪い例になっているが、
`fvm flutter analyze` を実行してもエラー・警告が一切表示されない、という報告を受けて調査した記録。

## 結論

- 環境(Dart 3.12.2 / Flutter 3.44.9)では **`flutter analyze` はriverpod_lint(ネイティブアナライザプラグイン)の診断を拾わない**。
  `dart analyze`(`fvm dart analyze`)を使えば警告が表示される。
- さらに、調査対象のリポジトリでは [analysis_options.yaml](../analysis_options.yaml) の
  `plugins.riverpod_lint.version` が `^3.1.4` になっていたため、`dart analyze` を使っても
  **ハングして返ってこない**別の不具合を踏んでいた。バージョンを `3.1.4`(キャレットなしの完全固定)に
  変更することでこちらは解消した。

以上の2つの問題が重なっていたため、当初「`flutter analyze` を実行してもエラーが表示されない」という
現象になっていた。

## 調査の経緯

### 1. `flutter analyze` は一見正常終了する

```
$ fvm flutter analyze
Analyzing DAN-DO...
No issues found! (ran in 1.6s)
```

エラーもなく高速に完了するため、一見プラグインが正しく機能していないだけのように見えるが、
`-v` オプションを付けても `riverpod_lint` やプラグインのロードに関する情報は一切出力されない
(Flutter tool のネイティブプラグイン(camera・video_player等)のログしか出ない)。

### 2. `analysis_options.yaml` の設定自体は公式ドキュメント通り

Dart公式ドキュメント([pkg/analysis_server_plugin/doc/using_plugins.md](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/using_plugins.md))によると、
ネイティブアナライザプラグインは以下の書式で有効化する。

```yaml
plugins:
  my_plugin: ^1.0.0
```

`diagnostics:` で個別ルールを明示的に有効化する場合は、`path:` や `hosted:` と同様に
pubspecの依存関係マップ形式を使い、`version:` サブキーでバージョンを指定できる
(pubspecの `hosted:` + `version:` の組み合わせと同じ書式)。

```yaml
plugins:
  riverpod_lint:
    version: ^3.1.4
    diagnostics:
      avoid_public_notifier_properties: true
```

このリポジトリの設定はこの書式に沿っており、`avoid_public_notifier_properties` は
riverpod_lint本体に実在するルール(`riverpod_lint-3.1.4/lib/src/lints/avoid_public_notifier_properties.dart`)
であることもソースコードで確認済み。設定自体に誤りはなかった。

**重要**: ネイティブアナライザプラグインの `plugins:` セクションは、プロジェクト本体の
`pubspec.lock` とは**別に**、synthetic package を作って独自に `dart pub upgrade` を実行し
依存解決を行う。つまり `pubspec.yaml` の `dev_dependencies: riverpod_lint: ^3.1.4` を
`dart pub get` で解決した結果(`pubspec.lock` に記録される3.1.4)とは無関係に、
`plugins:` 側は毎回「`^3.1.4` を満たす最新版」を取得しようとする。

### 3. 問題A: バージョン固定なしだと `dart analyze` がハングする

`plugins.riverpod_lint.version: ^3.1.4` の場合、実際に解決されるのはリポジトリの
`pubspec.lock`(3.1.4)ではなく最新の **riverpod_lint 3.1.8** だった
(`~/.pub-cache/hosted/pub.dev/riverpod_lint-3.1.8` が存在することで確認)。

| riverpod_lint | analyzer 制約 |
|---|---|
| 3.1.4 | `^12.0.0` |
| 3.1.6〜3.1.8 | `^13.0.0` |

riverpod_lintの [CHANGELOG](https://raw.githubusercontent.com/rrousselGit/riverpod/master/packages/riverpod_lint/CHANGELOG.md) (Unreleased節)には以下の記載がある。

> Require Dart 3.13: the analysis server protocol needed by `analysis_server_plugin` 0.3.18
> (pulled in by the analyzer 13 upgrade) ships in Dart 3.13. On earlier SDKs the plugin
> previously hung `dart analyze`; now version solving fails with a clear error instead.

つまり analyzer `^13.0.0` を要求するバージョン(3.1.6以降)が解決されると、
Dart 3.13未満の環境(このリポジトリはDart 3.12.2)では **`dart analyze` がハングする**
既知の不具合がある(次回リリースで「明確なエラーで失敗する」ように修正予定だが、
現時点ではまだリリースされていない)。

実際に `fvm dart analyze` を実行したところ、120秒待っても `Analyzing DAN-DO...` から
先に進まずハングすることを確認した。

**対処**: `plugins.riverpod_lint.version` を `^3.1.4` ではなく `3.1.4`(キャレットなし)に
固定した。これにより synthetic package が analyzer `^12.0.0` を要求する3.1.4のみを
解決するようになり、ハングは解消した。

```yaml
plugins:
  riverpod_lint:
    version: 3.1.4
    diagnostics:
      avoid_public_notifier_properties: true
```

固定後、`fvm dart analyze` は正常終了し、狙い通り警告が表示された。

```
$ fvm dart analyze
Analyzing DAN-DO...

   info - lib/main.dart:28:3 - Notifiers should not have public properties/getters.
   Instead, all their public API should be exposed through the `state` property.
   - avoid_public_notifier_properties

1 issue found.
```

### 4. 問題B: `flutter analyze` は依然として警告を表示しない

問題Aを解消した(バージョン固定済みの)状態でも、`fvm flutter analyze` を実行すると
「No issues found!」のままだった。

`-v` オプション付きのログを確認すると、`flutter analyze` は内部で

```
dart language-server --dart-sdk ... --disable-server-feature-completion --disable-server-feature-search
```

を起動し、LSP(Language Server Protocol)のJSON-RPCで通信していることが分かった。
これは `dart analyze` が使う従来のバッチ解析パス(1回実行して結果をまとめて出力する経路)とは
別の実行経路であり、この環境(Dart 3.12.2 / Flutter 3.44.9)ではLSP経由の `flutter analyze` に
riverpod_lintの診断が反映されないことを、双方の実行結果を突き合わせて確認した
(`dart analyze` は警告あり、直後に実行した `flutter analyze` は警告なし、を再現性をもって確認)。

ネイティブアナライザプラグインの仕組み自体がDart 3.10で導入されたばかりの新しい機能であるため、
LSPモードとの統合がこのバージョンではまだ追いついていない可能性が高い。

## 今後この教材を進める上での注意

- **`flutter analyze` ではなく `fvm dart analyze` を使うこと。** 現時点の環境では
  `flutter analyze` はriverpod_lintの警告を表示しない。
- `analysis_options.yaml` の `plugins.riverpod_lint.version` は `^3.1.4` のような
  キャレット指定にすると、riverpod_lintの新しいバージョンが自動的に解決され、
  今回のような非互換(ハング)を意図せず踏む可能性がある。バージョンを固定しておくと安全。
- Dart SDKが3.13以降に上がれば問題Aの根本(analyzer 13系との非互換)は解消される見込み。
  問題B(`flutter analyze` のLSPモードがプラグイン診断を拾わない件)については
  別途Flutter/Dartのアップデートで改善されるか、改めて確認が必要。
