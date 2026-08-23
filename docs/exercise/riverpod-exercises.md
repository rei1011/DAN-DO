# Riverpod 問題集

`hooks_riverpod: ^3.3.2`(`riverpod_annotation: ^4.0.3` + `riverpod_generator: ^4.0.4` によるコード生成)を使った
状態管理を、実際にコードを書きながら習得するための問題集です。
回答例は [riverpod-answers.md](./riverpod-answers.md) を参照してください(問題番号が対応しています)。

## 進め方

- 各問題の「雛形コード」の `TODO` コメント部分を実装してください。
- 全問題で `@riverpod` アノテーション + `part 'xxx.g.dart';` によるコード生成を使います。Riverpod 2系の
  `StateNotifierProvider` や手書きの `FutureProvider`/`.family` 修飾子は扱いません。関数・`build()` メソッドの
  第一引数(クラス型の場合は暗黙のコンテキスト)は必ず統一された `Ref ref` 型です。
- 各問題は他の問題に依存しない、単体で動くprovider + `ConsumerWidget`(または `HookConsumerWidget`)として
  作成されています。動作確認する場合は `lib/` 配下に一時的にファイルを作成し、
  `dart run build_runner build --delete-conflicting-outputs` でコード生成した上で `MaterialApp` の `home` に
  渡して実行するか、`flutter analyze` で構文チェックしてください。
- 一部の問題(自動破棄・ライフサイクル系)は画面表示だけでは確認しづらいため、`debugPrint` の出力を
  ターミナルまたはDevToolsのコンソールで確認する形になります。
- 難易度は ★1(易しい)〜★5(難しい) の5段階です。
- 迷ったら回答例を見る前に、公式ドキュメント( https://riverpod.dev )も参考にしてください。
- 既に動いている実例として `lib/joke.dart`(`fetchRandomJoke` プロバイダ)と `lib/home.dart`(`HomeView`)が
  このプロジェクトにあります。基本パターンで迷ったら参照してください。
- 最後の問題33は、riverpod 3.3.2に実在するものの公式ドキュメントが「experimental(実験的機能)」と明記して
  おり、かつ検証の結果、現時点では一般公開APIとしてexportすらされていない Mutation API を扱います。
  パッケージ内部のパスを直接importする暫定的な書き方になる点、今後のバージョンで書き方が大きく変わる
  可能性がある点に留意してください。

## 目次

1. 基本(関数プロバイダ) — 問題01〜05
2. クラス型Provider(Notifier / AsyncNotifier / StreamNotifier) — 問題06〜13
3. Family(パラメータ付きProvider) — 問題14〜17
4. ref.watch / ref.read / ref.listen / ref.select の使い分け — 問題18〜21
5. AsyncValueの実践 — 問題22〜24
6. ライフサイクル・自動破棄 — 問題25〜28
7. Widgetとの統合 — 問題29〜32
8. 発展 — 問題33

---

## 1. 基本(関数プロバイダ)

### 問題01: Provider相当 — 同期的な導出値を提供する

**対象**: `@riverpod` 同期関数(`Provider`相当)
**難易度**: ★☆☆☆☆

**学べること**
- `@riverpod` 関数の戻り値が `Future` でも `Stream` でもない場合、同期的な `Provider` が生成されること
- 「状態を持たない、常に一定の値を返す設定値」をプロバイダとして表現する意義
- `ref.watch` で単純な値を読み取る基本

**要件**
- 消費税率(`double`、`0.1`固定)を返す `@riverpod double taxRate(Ref ref)` を実装する
- `PriceView` を `ConsumerWidget` として実装する。引数 `basePrice`(`int`、税抜価格)を受け取り、
  `taxRateProvider` を `ref.watch` して税込価格(`basePrice * (1 + taxRate)`)を計算し表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem01.g.dart';

// TODO: 消費税率0.1を返す同期プロバイダtaxRateを実装する

class PriceView extends ConsumerWidget {
  const PriceView({super.key, required this.basePrice});

  final int basePrice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: ref.watch(taxRateProvider)で税率を取得し、税込価格を計算して表示する

    return const Placeholder();
  }
}
```

---

### 問題02: FutureProvider相当 — 非同期の値を取得する(おさらい)

**対象**: `@riverpod` 非同期関数(`FutureProvider`相当)
**難易度**: ★☆☆☆☆

**学べること**
- `Future<T>` を返す `@riverpod` 関数が `AsyncValue<T>` として扱われる基本形の再確認
- `ref.watch` が `AsyncValue<T>` を返すこと
- 既に動いている `lib/joke.dart`(`fetchRandomJoke`)と全く同じパターンであることの認識

**要件**
- 1秒待ってから文字列 `'Hello, Riverpod!'` を返す `@riverpod Future<String> fetchGreeting(Ref ref)` を実装する
- `GreetingView` を `ConsumerWidget` として実装し、`fetchGreetingProvider` を購読して
  ローディング中は `CircularProgressIndicator`、取得できたらテキストを表示する
  (`lib/home.dart` の `switch` 式パターンを参考にしてよい)
- この問題は導入のため分量を最小限に留めています(次の問題以降で発展させます)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem02.g.dart';

// TODO: 1秒待って'Hello, Riverpod!'を返す非同期プロバイダfetchGreetingを実装する

class GreetingView extends ConsumerWidget {
  const GreetingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: fetchGreetingProviderを購読し、AsyncValueをswitch式等で分岐表示する

    return const Placeholder();
  }
}
```

---

### 問題03: StreamProvider相当 — 継続的に更新される値を購読する

**対象**: `@riverpod` Stream関数(`StreamProvider`相当)
**難易度**: ★★☆☆☆

**学べること**
- `Stream<T>` を返す `@riverpod` 関数も `Future` 版と同様に `AsyncValue<T>` として扱われること
- `Future` 版との違い(1回きりの値 vs 継続的に更新される値)
- Streamのライフサイクルはプロバイダの破棄と連動し、自動的に購読解除されること

**要件**
- `Stream.periodic(Duration(seconds: 1), (i) => i)` を返す `@riverpod Stream<int> tickerStream(Ref ref)` を実装する
- `TickerView` を `ConsumerWidget` として実装し、`tickerStreamProvider` を購読して現在値を表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem03.g.dart';

// TODO: Stream.periodic(Duration(seconds: 1), (i) => i)を返すtickerStreamを実装する

class TickerView extends ConsumerWidget {
  const TickerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: tickerStreamProviderを購読し、現在値を表示する

    return const Placeholder();
  }
}
```

---

### 問題04: Provider間の依存 — 複数のプロバイダを合成する

**対象**: プロバイダの合成(`ref.watch` の連鎖)
**難易度**: ★★★☆☆

**学べること**
- `ref.watch` で他のプロバイダを読み取り、その結果から新しい値を導出できること(宣言的な依存グラフ)
- 依存元の値が変わると、依存先が自動的に再計算されること
- コンストラクタ注入のような手動の値の受け渡しと比べたときの利点(依存関係の宣言だけで済む)

**要件**
- 単価(`int`、固定値 `100`)を返す `@riverpod int unitPrice(Ref ref)` を実装する
- 数量(`int`、固定値 `3`)を返す `@riverpod int quantity(Ref ref)` を実装する
- 上記2つを `ref.watch` で合成し、合計金額を返す `@riverpod int totalPrice(Ref ref)` を実装する
- `TotalPriceView` を `ConsumerWidget` として実装し、`totalPriceProvider` を購読して表示する。
  `unitPriceProvider` の値を変えると `totalPriceProvider` の値も連動して変わることをコード上で確認できるように、
  各プロバイダの値も併記して表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem04.g.dart';

// TODO: unitPrice(固定値100)を実装する
// TODO: quantity(固定値3)を実装する
// TODO: unitPriceとquantityをref.watchし、掛け算した結果を返すtotalPriceを実装する

class TotalPriceView extends ConsumerWidget {
  const TotalPriceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: totalPriceProvider(および参考としてunitPrice/quantity)を購読して表示する

    return const Placeholder();
  }
}
```

---

### 問題05: AsyncValue.guard — 関数プロバイダでの例外の扱いを理解する

**対象**: `AsyncValue.guard`
**難易度**: ★★☆☆☆

**学べること**
- `try/catch` で手動でエラーハンドリングする代わりに `AsyncValue.guard` を使うと簡潔に書けること
- `@riverpod Future` 関数は、内部で例外を投げれば自動的に呼び出し側で `AsyncValue.error` として観測されるため、
  実は関数プロバイダ自体の中では `guard` を明示的に使う必要が薄いことの理解
  (`guard` の本来の使いどころは後述のNotifierの状態更新時であり、その伏線としてここで違いを押さえる)
- 例外をそのまま投げてよい場面と、明示的に捕捉すべき場面の違い

**要件**
- 引数が負数なら `Exception('input must not be negative')` を投げ、そうでなければ100ミリ秒待って
  引数を2倍にして返す非同期関数 `_riskyFetch(int input)` を用意する
- `@riverpod Future<int> riskyValue(Ref ref, int input)` を実装する(引数付き=family化されるが、
  詳しい仕組みは問題14で扱うのでここでは深追いしなくてよい)。例外は`guard`を使わずそのまま投げる実装にする
- `RiskyValueView` を `ConsumerWidget` として実装し、正の値・負の値それぞれを渡すボタンを用意して
  `AsyncValue.error` になることを確認する
- 雛形コードのコメントとして、あえて `AsyncValue.guard` で書いた場合の等価な書き方も併記する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem05.g.dart';

Future<int> _riskyFetch(int input) async {
  await Future<void>.delayed(const Duration(milliseconds: 100));
  if (input < 0) {
    throw Exception('input must not be negative');
  }
  return input * 2;
}

// TODO: _riskyFetch(input)を呼び出すriskyValue(Ref ref, int input)を実装する
// (例外はそのまま投げてよい。コメントでAsyncValue.guardを使った等価な書き方も示すこと)

class RiskyValueView extends ConsumerWidget {
  const RiskyValueView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: riskyValueProvider(2)などを購読し、正常系・エラー系のボタンを用意する

    return const Placeholder();
  }
}
```

---

## 2. クラス型Provider(Notifier / AsyncNotifier / StreamNotifier)

### 問題06: Notifier基本 — カウンターをstateで管理する

**対象**: `Notifier`(`@riverpod class`)
**難易度**: ★★☆☆☆

**学べること**
- `@riverpod class Foo extends _$Foo` という宣言方法と、`build()` メソッドで初期状態を返す設計
- `state` プロパティへの代入がリビルドをトリガーすること(flutter_hooksの`useState`との類似点)
- 状態更新メソッドをNotifierクラス内に閉じ込める設計思想(`useState`のような単純な値のミュータブルな
  書き換えではなく、更新ロジックに名前を付けてカプセル化できる)

**要件**
- `@riverpod class Counter extends _$Counter` を実装する。`build()` は `int` の初期値 `0` を返し、
  `void increment()` メソッドで `state++` する
- `CounterView` を `ConsumerWidget` として実装し、`ref.watch(counterProvider)` で表示、ボタンの
  `onPressed` で `ref.read(counterProvider.notifier).increment()` を呼ぶ

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem06.g.dart';

// TODO: @riverpod classでCounterを実装する(build()はint 0を返し、incrementでstate++する)

class CounterView extends ConsumerWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: counterProviderを購読して表示し、ボタンでincrement()を呼ぶ

    return const Placeholder();
  }
}
```

---

### 問題07: Notifierのイミュータブルな状態更新 — 複数フィールドを持つ状態を安全に更新する

**対象**: `Notifier` + イミュータブルな状態更新
**難易度**: ★★★☆☆

**学べること**
- `state` を直接書き換えるのではなく、常に新しいインスタンスを `state = ...` として代入する必要があること
  (イミュータブル更新)
- `copyWith` パターンとの相性の良さ
- 一部フィールドだけ変えるつもりが、他のフィールドを巻き添えで消してしまう典型的なバグへの注意

**要件**
- `name`(`String`)と `age`(`int`)を持つ `Profile` クラス(`copyWith` 付き、雛形に用意済み)を使う
- `@riverpod class ProfileNotifier extends _$ProfileNotifier` を実装する。`build()` は
  `Profile(name: 'Alice', age: 20)` を初期値として返す
- `void updateName(String name)` / `void updateAge(int age)` の2つのメソッドを実装し、
  それぞれ他方のフィールドを保持したまま `state` を更新する(`state.copyWith(...)` を使う)
- `ProfileView` を `ConsumerWidget` として実装し、`name` と `age` それぞれを更新するUIを用意する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem07.g.dart';

class Profile {
  const Profile({required this.name, required this.age});

  final String name;
  final int age;

  Profile copyWith({String? name, int? age}) {
    return Profile(name: name ?? this.name, age: age ?? this.age);
  }
}

// TODO: @riverpod classでProfileNotifierを実装する
// build()の初期値はProfile(name: 'Alice', age: 20)
// updateName/updateAgeでは、copyWithを使い他方のフィールドを保持したままstateを更新する

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: profileNotifierProviderを購読して名前・年齢を表示し、
    // それぞれを変更するボタン/入力欄を用意する

    return const Placeholder();
  }
}
```

---

### 問題08: AsyncNotifier基本 — 非同期な初期値を持つNotifier

**対象**: `AsyncNotifier`
**難易度**: ★★★☆☆

**学べること**
- `build()` が `Future<T>` を返すと、自動的に `state` が `AsyncValue<T>` になる「AsyncNotifier」になること
- 初期ロード中は `ref.watch` 側で `AsyncValue.loading()` として観測されること
- 関数型の `FutureProvider`(問題02)との違い(状態更新メソッドを持てる点)

**要件**
- 100ミリ秒待ってから初期のTodoリスト `['牛乳を買う', '掃除する', '本を返す']` を返す
  `@riverpod class TodoList extends _$TodoList`(`build()` が `Future<List<String>>` を返す)を実装する
- `TodoListView` を `ConsumerWidget` として実装し、`ref.watch(todoListProvider)` の `AsyncValue<List<String>>` を
  `switch` 式で分岐表示する(ローディング中はインジケーター、エラー時はエラー文言、成功時は一覧表示)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem08.g.dart';

// TODO: @riverpod classでTodoListを実装する
// build()は100ミリ秒待って['牛乳を買う', '掃除する', '本を返す']を返すFuture<List<String>>

class TodoListView extends ConsumerWidget {
  const TodoListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: todoListProviderを購読し、AsyncValue<List<String>>をswitch式で分岐表示する

    return const Placeholder();
  }
}
```

---

### 問題09: AsyncNotifierの更新パターン — 更新中のローディング状態を表現する

**対象**: `AsyncNotifier` + `AsyncValue.guard`
**難易度**: ★★★★☆

**学べること**
- 更新処理の定石パターン: `state = const AsyncValue.loading();` → 実際の更新処理を `await` しつつ
  `state = await AsyncValue.guard(() async { ... });` で結果を反映する
- こう書くことで、更新中も `isLoading` を使ったローディング表現が自然に手に入ること
- もし `guard` を使わず生の `try/catch` で書いた場合に起こりがちな「エラー時に前の状態が消えてしまう/
  正しく戻し忘れる」バグへの理解

**要件**
- 問題08の `TodoList` に `Future<void> addTodo(String text)` メソッドを追加する
  - `text` が空文字列の場合は `Exception('text must not be empty')` を投げる
  - 追加処理は50ミリ秒待つ疑似的な非同期処理とし、成功時は既存のリストに `text` を追加した新しいリストを
    `state` に反映する
  - 処理中は `state` が `AsyncValue.loading()` になり、失敗時は `AsyncValue.error(...)` になるように、
    `AsyncValue.guard` を使って実装する
- `TodoListView`(問題08から発展)に入力欄と追加ボタンを追加し、追加中はローディング表示、
  空文字列で追加しようとするとエラー表示になることを確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem09.g.dart';

// TODO: @riverpod classでTodoListを実装する(build()は問題08と同じ)
// TODO: addTodo(String text)を実装する
// - 空文字列なら例外を投げる
// - state = const AsyncValue.loading() をまず設定する
// - state = await AsyncValue.guard(() async { ...50ミリ秒待って新しいリストを返す... }); で更新する

class TodoListView extends ConsumerWidget {
  const TodoListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: todoListProviderを購読して一覧表示し、
    // 入力欄+追加ボタンでaddTodo(text)を呼ぶ(TextEditingControllerは自由に用意してよい)

    return const Placeholder();
  }
}
```

---

### 問題10: Ref.mounted — 非同期処理後にNotifierがまだ有効か確認する

**対象**: `Ref.mounted`
**難易度**: ★★★☆☆

**学べること**
- `Notifier` のメソッド内で `await` を挟んだ後、そのプロバイダが既に破棄されている可能性があること
- `ref.mounted`(`BuildContext.mounted` のプロバイダ版)を使うことで、破棄後に `state` へ代入して
  エラーになる事態を安全に回避できること
- 非同期処理完了時点でプロバイダが有効かどうかを都度チェックするという設計上の心構え

**要件**
- `@riverpod class SlowCounter extends _$SlowCounter` を実装する。`build()` は `int` の初期値 `0` を返す
- `Future<void> incrementAfterDelay()` メソッドを実装する。2秒待った後、`ref.mounted` が `true` の場合のみ
  `state++` する(`false` の場合は何もしない)
- `SlowCounterView` を `ConsumerWidget` として実装し、ボタンで `incrementAfterDelay()` を呼び出す
- 検証用に、`SlowCounterView` を `Navigator.push` で表示できる構成にし、2秒待っている間に画面を閉じた
  (=プロバイダが破棄された)場合にエラーが起きないことを確認できるようにする

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem10.g.dart';

// TODO: @riverpod classでSlowCounterを実装する
// incrementAfterDelay()では2秒待った後、ref.mountedがtrueの場合のみstate++する

class SlowCounterView extends ConsumerWidget {
  const SlowCounterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: slowCounterProviderを購読して表示し、ボタンでincrementAfterDelay()を呼ぶ

    return const Placeholder();
  }
}
```

---

### 問題11: StreamNotifier — Streamを状態として管理する

**対象**: `StreamNotifier`
**難易度**: ★★★☆☆

**学べること**
- `build()` が `Stream<T>` を返すと `StreamNotifier` になり、状態が継続的に更新されること
- `Notifier`(単発の同期値)・`AsyncNotifier`(単発の非同期値)・`StreamNotifier`(継続的な非同期値)の
  3種類の使い分け
- `ref.invalidateSelf()` を使うと、Notifier自身の `build()` を再実行して(=内部で保持しているStreamを
  作り直して)状態をリセットできること

**要件**
- `@riverpod class ClockNotifier extends _$ClockNotifier` を実装する。`build()` は
  `Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now())` を返す
- `void restart()` メソッドを実装し、`ref.invalidateSelf()` を呼ぶことでStreamを作り直せるようにする
- `ClockView` を `ConsumerWidget` として実装し、`ref.watch(clockNotifierProvider)` の現在時刻を表示しつつ、
  「リセット」ボタンで `restart()` を呼べるようにする

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem11.g.dart';

// TODO: @riverpod classでClockNotifierを実装する
// build()はStream.periodic(Duration(seconds: 1), (_) => DateTime.now())を返す
// restart()ではref.invalidateSelf()を呼ぶ

class ClockView extends ConsumerWidget {
  const ClockView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: clockNotifierProviderを購読して現在時刻を表示し、
    // リセットボタンでrestart()を呼ぶ

    return const Placeholder();
  }
}
```

---

### 問題12: Notifier間の依存 — build内でref.watchして他プロバイダの変化に追従する

**対象**: `Notifier` + プロバイダ合成
**難易度**: ★★★☆☆

**学べること**
- `Notifier.build()` の内部でも `ref.watch` が使え、依存先のプロバイダが変わると `build()` が
  自動的に再実行される(=Notifierが作り直される)こと
- これにより、Notifierの状態を「他のプロバイダの値に追従して自動的に変わる派生状態」として設計できること
- Riverpod 3系では、依存が変化するたびにNotifierインスタンス自体が作り直され、直前の状態は
  引き継がれない(=`build()`の戻り値が新しい初期状態になる)という挙動の理解

**要件**
- `@riverpod class LocaleNotifier extends _$LocaleNotifier` を実装する。`build()` は `String` の初期値
  `'ja'` を返し、`void toggle()` メソッドで `'ja'` と `'en'` を切り替える
- `@riverpod class GreetingNotifier extends _$GreetingNotifier` を実装する。`build()` の中で
  `ref.watch(localeNotifierProvider)` を読み取り、`'ja'` なら `'こんにちは'`、`'en'` なら `'Hello'` を返す
- `GreetingView` を `ConsumerWidget` として実装し、`greetingNotifierProvider` の表示と、
  `localeNotifierProvider.notifier` の `toggle()` を呼ぶボタンを用意する。言語を切り替えると
  挨拶文が自動的に更新されることを確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem12.g.dart';

// TODO: @riverpod classでLocaleNotifierを実装する(build()の初期値'ja'、toggle()で'ja'/'en'切り替え)
// TODO: @riverpod classでGreetingNotifierを実装する
// build()内でref.watch(localeNotifierProvider)を読み、'ja'/'en'に応じた挨拶文を返す

class GreetingView extends ConsumerWidget {
  const GreetingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: greetingNotifierProviderを購読して表示し、
    // ボタンでlocaleNotifierProvider.notifier.toggle()を呼ぶ

    return const Placeholder();
  }
}
```

---

### 問題13: riverpod_lintを読む — avoid_public_notifier_propertiesに気づいて直す

**対象**: `riverpod_lint`(`avoid_public_notifier_properties` ルール)
**難易度**: ★★☆☆☆

**学べること**
- `Notifier`/`AsyncNotifier` は外部から見える状態を `state` に一本化すべきで、`state` 以外の公開
  ミュータブルなプロパティを持つべきではないこと(すべての状態変化は `state` の代入を通して観測されるべき、
  という設計思想)
- `riverpod_lint` の `avoid_public_notifier_properties` ルールがこれを静的に検出してくれること
- 悪い設計を良い設計に書き換える具体的な手順

**要件**
- 雛形として提示する「わざと `riverpod_lint` に警告される」悪い例
  (`@riverpod class BadCounter extends _$BadCounter` が `state` 以外に公開の可変フィールド
  `int extraCount` を持っている)を、`flutter analyze` を実行するか、IDEの警告表示で確認する
- `extraCount` が持っていた情報を `state` 側(必要なら `int` から「カウントと追加カウントを持つ
  レコードまたはクラス」に拡張する)に統合し、警告が解消される形に書き直す

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem13.g.dart';

// 以下は「悪い例」です。まずこのままの状態でflutter analyzeを実行し、
// riverpod_lintのavoid_public_notifier_propertiesルールが警告を出すことを確認してください。
// その後、TODOに従ってstate側に情報を統合する形に書き直してください。

@riverpod
class BadCounter extends _$BadCounter {
  // TODO: このextraCountをstateに統合し、公開の可変フィールドを持たない形に書き直す
  int extraCount = 0;

  @override
  int build() => 0;

  void increment() {
    state++;
    extraCount++;
  }
}

class BadCounterView extends ConsumerWidget {
  const BadCounterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(badCounterProvider);

    return Column(
      children: [
        Text('count: $count'),
        ElevatedButton(
          onPressed: () => ref.read(badCounterProvider.notifier).increment(),
          child: const Text('+1'),
        ),
      ],
    );
  }
}
```

---

## 3. Family(パラメータ付きProvider)

### 問題14: 関数プロバイダのfamily化 — 引数付きプロバイダを作る

**対象**: family(関数プロバイダ)
**難易度**: ★★☆☆☆

**学べること**
- Riverpod 2系の `.family` 修飾子を使わず、`@riverpod` 関数に引数を追加するだけで自動的にfamily化されること
- 呼び出し側は `ref.watch(fooProvider(引数))` のように引数を渡して使うこと
- 引数(の値)ごとに独立したキャッシュ(プロバイダインスタンス)が作られること

**要件**
- 100ミリ秒待ってから `'User#$userId'` という文字列を返す `@riverpod Future<String> userName(Ref ref, int userId)`
  を実装する
- `UserNameView` を `ConsumerWidget` として実装する。`useState` は使わず、`ConsumerWidget` 内で
  複数のボタン(userId: 1, 2, 3など)を用意し、押したidを表示するローカル変数の代わりに、まずは
  固定のuserId(例: `1`)を `ref.watch(userNameProvider(1))` して表示するだけでよい
  (idを動的に切り替えるUIはカテゴリ7の問題31で発展させます)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem14.g.dart';

// TODO: 100ミリ秒待って'User#$userId'を返すuserName(Ref ref, int userId)を実装する

class UserNameView extends ConsumerWidget {
  const UserNameView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: userNameProvider(1)を購読して表示する

    return const Placeholder();
  }
}
```

---

### 問題15: AsyncNotifierのfamily化 — buildにパラメータを持たせる

**対象**: family(`AsyncNotifier`)
**難易度**: ★★★☆☆

**学べること**
- `Notifier`/`AsyncNotifier` でも `build(引数)` のようにパラメータを取れば同様にfamily化されること
- クラス内の他のメソッドからも、フィールドと同じように `this.引数名` としてそのパラメータへ
  アクセスできること(Riverpodが自動的にフィールドとして保持してくれる)

**要件**
- `@riverpod class ItemDetail extends _$ItemDetail` を実装する
  - `Future<String> build(String itemId)` は100ミリ秒待って `'Item: $itemId'` を返す
  - `bool isFavorite = false`(privateにする必要はないが `state` とは別に内部フラグとして良い、
    または `state` を拡張してもよい。今回は簡単のためNotifier内のprivateなフィールドとして持ってよい)
  - `Future<void> toggleFavorite()` メソッドを実装し、`itemId`(`this.itemId`)を使って
    `debugPrint('toggle favorite: $itemId')` のようにログ出力する
- `ItemDetailView` を `ConsumerWidget` として実装する。引数 `itemId`(`String`)を受け取り、
  `ref.watch(itemDetailProvider(itemId))` の結果を表示し、お気に入りボタンで `toggleFavorite()` を呼ぶ

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem15.g.dart';

// TODO: @riverpod classでItemDetailを実装する
// build(String itemId)は100ミリ秒待って'Item: $itemId'を返す
// toggleFavorite()ではthis.itemIdを使ってdebugPrintする

class ItemDetailView extends ConsumerWidget {
  const ItemDetailView({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: itemDetailProvider(itemId)を購読して表示し、
    // お気に入りボタンでtoggleFavorite()を呼ぶ

    return const Placeholder();
  }
}
```

---

### 問題16: 複数引数のfamily — 2つの引数を持つプロバイダを作る

**対象**: family(複数引数)
**難易度**: ★★★☆☆

**学べること**
- 位置引数・名前付き引数を組み合わせて、複数パラメータのfamilyを定義できること
- 呼び出し側の書き方(`ref.watch(fooProvider(a, b: b))`)
- 引数の組み合わせごとに別インスタンスとして扱われること(`keyword`が同じでも`page`が違えば別キャッシュ)

**要件**
- `@riverpod Future<List<String>> searchItems(Ref ref, String keyword, {int page = 0})` を実装する。
  100ミリ秒待ってから `List.generate(5, (i) => '$keyword-result-${page * 5 + i}')` のような
  ダミーの検索結果を返す
- `SearchItemsView` を `ConsumerWidget` として実装する。`TextField` でキーワードを入力し
  (`useState` を使わず、`TextEditingController` を使ってもよい)、ページ番号を切り替えるボタンを用意し、
  `ref.watch(searchItemsProvider(keyword, page: page))` の結果一覧を表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem16.g.dart';

// TODO: searchItems(Ref ref, String keyword, {int page = 0})を実装する
// 100ミリ秒待って ['$keyword-result-${page*5}', ..., 5件] のようなダミー結果を返す

class SearchItemsView extends ConsumerWidget {
  const SearchItemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: キーワード入力欄・ページ切り替えボタンを用意し、
    // searchItemsProvider(keyword, page: page)を購読して一覧表示する

    return const Placeholder();
  }
}
```

---

### 問題17: family×autoDispose — パラメータごとにキャッシュが独立して破棄されることを確認する

**対象**: family + autoDispose
**難易度**: ★★★☆☆

**学べること**
- familyの各インスタンスも独立してautoDisposeの対象になること(=ある引数の画面を離れても、
  別の引数のキャッシュには影響しないこと)
- `ref.onDispose` をfamilyプロバイダに仕込んでログを見ることで、実際の破棄タイミングを観察する方法

**要件**
- 問題14の `userNameProvider` に `ref.onDispose(() => debugPrint('disposed: userId=$userId'))` を追加する
- `UserNameSwitcherView` を `ConsumerWidget` として実装する。`IndexedStack` または条件分岐で
  「userId: 1を表示する画面」「userId: 2を表示する画面」を切り替えられるボタンを用意し
  (どちらか一方だけがwatchされ、他方はwatchされなくなる構成にする)、切り替えるたびに
  ターミナル/DevToolsのコンソールに破棄ログが出ることを確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem17.g.dart';

// TODO: userName(Ref ref, int userId)を実装する(問題14と同じ内容)
// ref.onDispose(() => debugPrint('disposed: userId=$userId'))を追加すること

class UserNameSwitcherView extends ConsumerStatefulWidget {
  const UserNameSwitcherView({super.key});

  @override
  ConsumerState<UserNameSwitcherView> createState() => _UserNameSwitcherViewState();
}

class _UserNameSwitcherViewState extends ConsumerState<UserNameSwitcherView> {
  int selectedUserId = 1;

  @override
  Widget build(BuildContext context) {
    // TODO: selectedUserIdを切り替えるボタンと、
    // ref.watch(userNameProvider(selectedUserId))の表示を実装する

    return const Placeholder();
  }
}
```

---

## 4. ref.watch / ref.read / ref.listen / ref.select の使い分け

### 問題18: ref.watch vs ref.read — 使い分けの基本

**対象**: `ref.watch` / `ref.read`
**難易度**: ★★☆☆☆

**学べること**
- `build()` メソッド内(=リビルドされて構わない箇所)では `ref.watch` を、`onPressed` 等のコールバック内
  (=一度きり値を読みたい/操作したいだけの箇所)では `ref.read` を使うのが基本原則であること
- `build()` 内で `ref.read` を使ってしまうと、値が変化してもリビルドされず表示が更新されないバグになること

**要件**
- 問題06の `Counter`(`counterProvider`)を題材にする
- `CounterViewV2` を `ConsumerWidget` として実装し、`build()` 内では `ref.watch(counterProvider)` を
  使って表示し、ボタンの `onPressed` 内では `ref.read(counterProvider.notifier).increment()` を使う
- コメントとして、あえて `build()` 内で `ref.read(counterProvider)` を使ってしまった場合
  (増やしても表示が更新されない)の例も併記する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem18.g.dart';

// TODO: @riverpod classでCounterを実装する(問題06と同じ内容)

class CounterViewV2 extends ConsumerWidget {
  const CounterViewV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: build()内はref.watch、onPressed内はref.readを使って実装する
    // コメントで「build()内でref.readを使うとどうなるか」も説明すること

    return const Placeholder();
  }
}
```

---

### 問題19: ref.listen — build内で副作用(SnackBar)を起こす

**対象**: `ref.listen`
**難易度**: ★★★☆☆

**学べること**
- `ref.listen(provider, (previous, next) { ... })` は値をUIに反映するのではなく、変化をトリガーに
  副作用を起こすための仕組みであること(flutter_hooks版の `useOnListenableChange` 等に相当する立ち位置)
- `ConsumerWidget.build` 内で呼ぶ必要があり、コールバック内では呼べない制約があること

**要件**
- 問題09の `TodoList`(`todoListProvider`)を題材にする
- `TodoListWithToastView` を `ConsumerWidget` として実装し、`build()` 内で
  `ref.listen(todoListProvider, (previous, next) { ... })` を使い、`next` が `AsyncValue.hasError` に
  なった瞬間に `ScaffoldMessenger.of(context).showSnackBar(...)` でエラーメッセージを表示する
- 通常の一覧表示・追加UIは問題09の実装を流用してよい

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem19.g.dart';

// TODO: @riverpod classでTodoListを実装する(問題09と同じ内容)

class TodoListWithToastView extends ConsumerWidget {
  const TodoListWithToastView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: ref.listen(todoListProvider, (previous, next) { ... })で
    // next.hasErrorになった瞬間にSnackBarを表示する
    // その上で通常の一覧表示・追加UIを実装する(問題09を参考にしてよい)

    return const Placeholder();
  }
}
```

---

### 問題20: ref.listenでprevious/next — 遷移パターンで条件分岐する

**対象**: `ref.listen`(`previous`/`next`)
**難易度**: ★★★☆☆

**学べること**
- `previous`/`next` の両方を受け取れるため、「特定の状態から別の特定の状態に変わった瞬間」だけを
  検出できること(flutter_hooks版 `useOnAppLifecycleStateChange` と同型のパターン)
- `previous` が `null` になりうる(初回リッスン時)ケースへの配慮

**要件**
- 問題12の `LocaleNotifier`(`localeNotifierProvider`)を題材にする
- `LocaleToastView` を `ConsumerWidget` として実装し、`ref.listen(localeNotifierProvider, (previous, next) { ... })`
  で、`previous` が `'ja'` から `next` が `'en'` に変わった瞬間**だけ**(逆方向の`'en'`→`'ja'`は無視する)
  `'English mode'` とSnackBarで表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem20.g.dart';

// TODO: @riverpod classでLocaleNotifierを実装する(問題12と同じ内容)

class LocaleToastView extends ConsumerWidget {
  const LocaleToastView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: ref.listenでprevious == 'ja' && next == 'en' のときだけSnackBarを表示する
    // 言語表示と切り替えボタンも実装する

    return const Placeholder();
  }
}
```

---

### 問題21: ref.select — 部分監視でリビルドを絞り込む

**対象**: `ref.select`
**難易度**: ★★★★☆

**学べること**
- `ref.watch(fooProvider)` は状態全体の変化でリビルドされるが、
  `ref.watch(fooProvider.select((s) => s.age))` は `select` の戻り値が変わったときだけリビルドされること
  (flutter_hooks版の `useListenableSelector` と同じ動機)
- 大きな状態オブジェクトの一部だけをUIが必要とする場合の、無駄な再描画を防ぐ最適化手段

**要件**
- 問題07の `ProfileNotifier`(`profileNotifierProvider`)を題材にする
- `age` だけを `ref.watch(profileNotifierProvider.select((p) => p.age))` で購読して表示する
  `AgeOnlyView` を `ConsumerWidget` として実装する
- `AgeOnlyView` の `build()` 冒頭で `debugPrint('AgeOnlyView rebuilt')` を出力し、
  `name` だけを更新するボタンを押しても `AgeOnlyView` がリビルドされない(ログが出ない)ことを確認する
  UI(名前変更ボタン・年齢変更ボタンを両方持つ親Widget)も併せて実装する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem21.g.dart';

// TODO: @riverpod classでProfileNotifierを実装する(問題07と同じ内容)

class AgeOnlyView extends ConsumerWidget {
  const AgeOnlyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: profileNotifierProvider.select((p) => p.age)で年齢だけを購読する
    // debugPrint('AgeOnlyView rebuilt')も追加する

    return const Placeholder();
  }
}

class ProfileSelectDemoView extends ConsumerWidget {
  const ProfileSelectDemoView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: AgeOnlyViewを配置し、名前変更ボタン・年齢変更ボタンをそれぞれ用意する

    return const Placeholder();
  }
}
```

---

## 5. AsyncValueの実践

### 問題22: .when() — switch式パターンマッチとの書き分け

**対象**: `AsyncValue.when`
**難易度**: ★★☆☆☆

**学べること**
- `.when(data: ..., loading: ..., error: ...)` メソッドによる分岐の書き方
- `lib/home.dart` で採用されているDartの `switch` 式パターンマッチ(`AsyncValue(:final value?)` 等)との
  比較。両者は等価だが、`.when` は全ケースの記述が必須(`skipLoadingOnRefresh` 等のオプションもある)である点
- どちらのスタイルを選ぶかはプロジェクトの方針次第であり、このプロジェクトでは
  `lib/home.dart` が `switch` 式を採用していること

**要件**
- 問題02の `fetchGreetingProvider` を題材にする
- `GreetingViewV2` を `ConsumerWidget` として実装し、`.when()` を使った分岐の実装を書く
- コメントとして、`lib/home.dart` と同様の `switch` 式パターンマッチで書いた場合の等価な実装も併記する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem22.g.dart';

// TODO: fetchGreeting(Ref ref)を実装する(問題02と同じ内容)

class GreetingViewV2 extends ConsumerWidget {
  const GreetingViewV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: fetchGreetingProviderを.when()で分岐して表示する
    // コメントでswitch式パターンマッチ版も併記すること

    return const Placeholder();
  }
}
```

---

### 問題23: AsyncValueのプロパティ — isLoading/isRefreshing/hasError/requireValueを使い分ける

**対象**: `AsyncValue` のプロパティ群
**難易度**: ★★★☆☆

**学べること**
- `isLoading`(初回ロード中)と `isRefreshing`(既に値を持ちつつ再取得中)の違い
- `hasError`/`hasValue` で存在チェックしてから `requireValue`(値がなければ例外を投げる)や
  `valueOrNull` を使い分ける方法
- `lib/home.dart` の `randomJoke.isRefreshing` と同じ用途の理解の確認

**要件**
- 問題08/09の `todoListProvider` を題材にする
- `TodoListRefreshableView` を `ConsumerWidget` として実装し、`RefreshIndicator` で一覧を包む
- `onRefresh` では `ref.refresh(todoListProvider.future)` を呼び、再取得中は `isRefreshing` を使って
  画面上部に `LinearProgressIndicator` を重ねて表示する(`lib/home.dart` の構成を単純化して再現する)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem23.g.dart';

// TODO: @riverpod classでTodoListを実装する(問題08と同じ内容でよい)

class TodoListRefreshableView extends ConsumerWidget {
  const TodoListRefreshableView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: RefreshIndicator + ListView + Stack構成で、
    // isRefreshing中はLinearProgressIndicatorを重ねて表示する

    return const Placeholder();
  }
}
```

---

### 問題24: ref.refresh と ref.invalidate — 挙動の違いを体感する

**対象**: `ref.refresh` / `ref.invalidate`
**難易度**: ★★☆☆☆

**学べること**
- `ref.invalidate(provider)` は「次に必要になったときに再計算する」ように予約するのに対し、
  `ref.refresh(provider)`(または `.future`)は「即座に再計算をトリガーし、その結果を待つことができる」
  という違い
- `lib/home.dart` で `ref.invalidate(fetchRandomJokeProvider)` が使われている理由
  (再取得後の値をその場のコードで直接使う必要がないため)

**要件**
- 問題02の `fetchGreetingProvider` を題材にする
- `GreetingRefreshDemoView` を `ConsumerWidget` として実装し、2つのボタンを用意する
  - 「invalidateボタン」: `ref.invalidate(fetchGreetingProvider)` のみを呼ぶ(結果はUIの通常の
    購読(`ref.watch`)経由で反映される)
  - 「refreshボタン」: `await ref.refresh(fetchGreetingProvider.future)` した結果を、
    その場で `ScaffoldMessenger` の `SnackBar` に表示する
- コメントで両者の違いを説明する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem24.g.dart';

// TODO: fetchGreeting(Ref ref)を実装する(問題02と同じ内容)

class GreetingRefreshDemoView extends ConsumerWidget {
  const GreetingRefreshDemoView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: invalidateボタンとrefreshボタンをそれぞれ実装する
    // コメントで両者の違いを説明すること

    return const Placeholder();
  }
}
```

---

## 6. ライフサイクル・自動破棄

### 問題25: autoDispose — デフォルトの破棄タイミングを確認する

**対象**: autoDispose(デフォルト挙動)
**難易度**: ★★★☆☆

**学べること**
- Riverpod 3系ではすべてのプロバイダがデフォルトでautoDispose(リスナーが0になれば破棄される)であること
- `ref.onDispose` で破棄タイミングをログ出力して確認する方法
- 2系での `.autoDispose` 修飾子が不要になった経緯(3系では常に有効)

**要件**
- `@riverpod class DisposableCounter extends _$DisposableCounter` を実装する。`build()` は `int` の
  初期値 `0` を返し、`ref.onDispose(() => debugPrint('DisposableCounter disposed'))` を仕込む
- `increment()` メソッドも用意する
- そのプロバイダを使う `DisposableCounterView`(`ConsumerWidget`)を実装し、
  `Navigator.push`/`pop` で表示・非表示を切り替えられるアプリ構成(トップ画面にボタンを1つ置くだけでよい)
  にして、画面を閉じると(=ウォッチしているWidgetがなくなると)破棄ログが出ることを確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem25.g.dart';

// TODO: @riverpod classでDisposableCounterを実装する
// build()の初期値は0、ref.onDisposeで破棄ログを出力する

class DisposableCounterView extends ConsumerWidget {
  const DisposableCounterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: disposableCounterProviderを購読して表示する

    return const Placeholder();
  }
}

class DisposableCounterHomeView extends StatelessWidget {
  const DisposableCounterHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: DisposableCounterViewへNavigator.pushで遷移するボタンを配置する

    return const Placeholder();
  }
}
```

---

### 問題26: ref.keepAlive() — 条件付きでキャッシュを維持する

**対象**: `ref.keepAlive()`
**難易度**: ★★★☆☆

**学べること**
- `ref.keepAlive()` を呼ぶとautoDisposeが無効化され、リスナーが0になっても状態が保持されること
- 「成功した結果はキャッシュしたいが、失敗した結果はキャッシュしたくない」という、条件付きで
  キャッシュ有無を切り替える典型パターン(成功時のみ `keepAlive()` を呼ぶ)
- 戻り値の `KeepAliveLink` の `.close()` を呼べば、再びautoDispose化できること

**要件**
- `@riverpod Future<String> cachedFetch(Ref ref)` を実装する。100ミリ秒待った後、
  `DateTime.now().millisecond` が偶数なら成功として `'success'` を返しつつ `ref.keepAlive()` を呼ぶ、
  奇数なら `Exception('failed, try again')` を投げる(`keepAlive()` は呼ばない)
- `CachedFetchView` を `ConsumerWidget` として実装し、`Navigator.push`/`pop` で画面を出入りしても、
  前回成功していれば再取得が走らない(キャッシュされたまま)ことと、失敗していれば
  画面に戻るたびに再取得が走ることを確認できる構成にする

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem26.g.dart';

// TODO: cachedFetch(Ref ref)を実装する
// 100ミリ秒待ち、DateTime.now().millisecondが偶数なら成功('success'を返しref.keepAlive()を呼ぶ)、
// 奇数なら例外を投げる(keepAlive()は呼ばない)

class CachedFetchView extends ConsumerWidget {
  const CachedFetchView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: cachedFetchProviderを購読して結果を表示する

    return const Placeholder();
  }
}
```

---

### 問題27: ref.onCancel / ref.onResume — リスナー0件時の一時停止・再開を扱う

**対象**: `ref.onCancel` / `ref.onResume`
**難易度**: ★★★★☆

**学べること**
- プロバイダは破棄される前に、リスナーが0件になった時点でまず `onCancel` が呼ばれ、その後(autoDisposeの
  性質上)一定のタイミングで新しいリスナーが付けば `onResume` が呼ばれて破棄を免れる、という
  「破棄」とは異なる中間状態があること
- 「誰も見ていない間だけ内部処理(タイマー等)を止める」という省リソース設計への応用

**要件**
- `@riverpod class LiveTimer extends _$LiveTimer` を実装する。`build()` は `int`(経過秒数、初期値0)を返す
- 内部で1秒ごとに `state++` する `Timer.periodic` を保持し、`ref.onCancel` でそのタイマーを一時停止
  (`Timer.cancel()` 等)、`ref.onResume` で再開する(タイマーを作り直す)。加えて、`ref.onDispose` でも
  タイマーを確実に破棄する
- `LiveTimerView`(このプロバイダをwatchする画面)と、それを表示しない「他の画面」を
  `IndexedStack` またはタブで切り替えられる `LiveTimerDemoView` を実装し、
  画面を切り替えている間はタイマーが進まず、戻ると再開することを `debugPrint` のログで確認する

**雛形コード**
```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem27.g.dart';

// TODO: @riverpod classでLiveTimerを実装する
// build()の初期値は0
// 1秒ごとにstate++するTimer.periodicを内部で保持する
// ref.onCancelでタイマーを一時停止、ref.onResumeで再開、ref.onDisposeで確実に破棄する

class LiveTimerView extends ConsumerWidget {
  const LiveTimerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: liveTimerProviderを購読して経過秒数を表示する

    return const Placeholder();
  }
}

class LiveTimerDemoView extends StatefulWidget {
  const LiveTimerDemoView({super.key});

  @override
  State<LiveTimerDemoView> createState() => _LiveTimerDemoViewState();
}

class _LiveTimerDemoViewState extends State<LiveTimerDemoView> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // TODO: IndexedStack等でLiveTimerViewと「何も表示しない画面」を切り替えられるようにする

    return const Placeholder();
  }
}
```

---

### 問題28: ProviderObserver — provider変化をログに記録する

**対象**: `ProviderObserver`
**難易度**: ★★★☆☆

**学べること**
- `ProviderObserver` を継承し、`didUpdateProvider` 等をオーバーライドすることで、アプリ全体の
  プロバイダの変化を横断的にロギングできること(Reduxのミドルウェアに近い用途)
- `ProviderScope(observers: [...])` への登録方法
- デバッグ・分析目的での「すべてのプロバイダの変化を1箇所で観測する」設計パターン

**要件**
- `AppProviderLogger extends ProviderObserver` を実装する。`didUpdateProvider` をオーバーライドし、
  更新されたプロバイダの名前(`context.provider`)と更新前後の値を `debugPrint` で出力する
- 問題06の `counterProvider` を使う小さな画面を作り、`ProviderScope(observers: [AppProviderLogger()], child: ...)`
  で包んだ状態でカウンタを操作し、操作のたびにログが出力されることを確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem28.g.dart';

// TODO: @riverpod classでCounterを実装する(問題06と同じ内容)

class AppProviderLogger extends ProviderObserver {
  // TODO: didUpdateProviderをオーバーライドし、
  // debugPrint('${context.provider}: $previousValue -> $newValue')のようにログ出力する
}

class ObservedCounterApp extends StatelessWidget {
  const ObservedCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: ProviderScope(observers: [AppProviderLogger()], child: ...)で
    // counterProviderを使う画面を包む

    return const Placeholder();
  }
}
```

---

## 7. Widgetとの統合

### 問題29: ConsumerWidget と Consumer — 部分的なリビルドの絞り込み

**対象**: `ConsumerWidget` / `Consumer`
**難易度**: ★★☆☆☆

**学べること**
- `ConsumerWidget` は `build` メソッド全体が `ref.watch` の変化でリビルドされるのに対し、
  `Consumer`(ビルダー形式)はウィジェットツリーの一部だけを `ref.watch` の対象にできること
  (flutter_hooks版の `AnimatedBuilder` 的な発想)
- ツリー全体を `ConsumerWidget` にせず、変化する部分だけを `Consumer` で囲む設計判断

**要件**
- 問題06の `counterProvider` を題材にする
- `CounterScreen` を(`ConsumerWidget` ではなく)`StatelessWidget` として実装する。静的な見出し
  `Text('カウンターデモ')` と、カウンタの値・ボタンを持つ部分を持つ画面とし、
  カウンタ表示部分だけを `Consumer(builder: (context, ref, child) => ...)` で囲む
- 見出し部分に `debugPrint('CounterScreen build')` を、`Consumer` の `builder` 内に
  `debugPrint('Consumer builder called')` を仕込み、カウンタを操作したときに前者のログが
  (再構築されないため)出力されないことを確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem29.g.dart';

// TODO: @riverpod classでCounterを実装する(問題06と同じ内容)

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('CounterScreen build');

    // TODO: 静的な見出しTextと、Consumer(builder: ...)で囲んだカウンタ表示部分を実装する
    // Consumerのbuilder内でdebugPrint('Consumer builder called')も出力すること

    return const Placeholder();
  }
}
```

---

### 問題30: ConsumerStatefulWidget — StatefulWidgetとRiverpodを併用する

**対象**: `ConsumerStatefulWidget` / `ConsumerState`
**難易度**: ★★★☆☆

**学べること**
- 独自の `AnimationController` など、既存の `State` 管理と `Riverpod` を併用したい場合に
  `ConsumerStatefulWidget`/`ConsumerState<T>` を使うこと
- `ConsumerState` 内では `ref` がインスタンスプロパティとして使え、`initState` 内でも `ref.read` が
  使える(ただし `ref.watch` はまだ使えない)こと

**要件**
- `WelcomeView` を `ConsumerStatefulWidget` として実装する
- `initState()` の中で `ref.read(counterProvider.notifier)`(問題06の `Counter`)を使い、
  `debugPrint('WelcomeView initialized, current count: ${ref.read(counterProvider)}')` のように
  初期化ログを出す
- `build()` メソッド内では通常どおり `ref.watch(counterProvider)` を使ってカウンタを表示し、
  ボタンで `increment()` を呼べるようにする

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem30.g.dart';

// TODO: @riverpod classでCounterを実装する(問題06と同じ内容)

class WelcomeView extends ConsumerStatefulWidget {
  const WelcomeView({super.key});

  @override
  ConsumerState<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends ConsumerState<WelcomeView> {
  @override
  void initState() {
    super.initState();
    // TODO: ref.readを使って初期化ログを出力する
  }

  @override
  Widget build(BuildContext context) {
    // TODO: ref.watch(counterProvider)で表示し、ボタンでincrement()を呼ぶ

    return const Placeholder();
  }
}
```

---

### 問題31: HookConsumerWidget — flutter_hooksとRiverpodの併用

**対象**: `HookConsumerWidget`
**難易度**: ★★★☆☆

**学べること**
- `hooks_riverpod` が提供する `HookConsumerWidget` を使うと、`useState` 等のflutter_hooksのhookと
  `ref.watch`/`ref.read` を同じ `build` メソッド内で併用できること
- ローカルなUI状態(フォームの一時入力値など)は `useState`、共有・非同期状態はRiverpodのプロバイダ、
  という役割分担の考え方

**要件**
- 問題14の `userNameProvider(userId)` を題材にする
- `UserNameSwitchView` を `HookConsumerWidget` として実装する。`useState<int>(1)` でuserIdの
  現在値をローカル管理しつつ、`ref.watch(userNameProvider(useStateの値))` で名前を取得・表示する
- userIdを増減させるボタン(`-`/`+`)を用意する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem31.g.dart';

// TODO: userName(Ref ref, int userId)を実装する(問題14と同じ内容)

class UserNameSwitchView extends HookConsumerWidget {
  const UserNameSwitchView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: useState<int>(1)でuserIdをローカル管理し、
    // ref.watch(userNameProvider(userId))で名前を表示する
    // -/+ボタンでuserIdを増減させる

    return const Placeholder();
  }
}
```

---

### 問題32: ProviderScopeのoverrides — モック実装への差し替え

**対象**: `ProviderScope(overrides: ...)`
**難易度**: ★★★☆☆

**学べること**
- `provider.overrideWithValue(...)`/`provider.overrideWith(...)` で、実行時やテスト時にプロバイダの
  実装・初期値を差し替えられること
- `docs/implementation-plan.md` で言及されている「`ShotAnalysisService` をモック→本実装に差し替える」設計と
  同じ仕組みであること
- 本番コードを一切変更せずに、部分的に挙動を差し替えられる利点

**要件**
- `@riverpod String greetingSource(Ref ref) => 'production'` という簡単なプロバイダを実装する
- `GreetingSourceView` を `ConsumerWidget` として実装し、`ref.watch(greetingSourceProvider)` の値を表示する
- `GreetingSourceComparisonView` を `StatelessWidget` として実装し、通常の `ProviderScope`(値は
  `'production'`)配下の `GreetingSourceView` と、
  `ProviderScope(overrides: [greetingSourceProvider.overrideWithValue('test-override')], child: ...)`
  でラップした配下の `GreetingSourceView` を `Column` 等で並べて表示し、同じWidgetでも
  差し替えた側だけ表示が変わることを確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem32.g.dart';

// TODO: greetingSource(Ref ref)を実装する('production'を返す)

class GreetingSourceView extends ConsumerWidget {
  const GreetingSourceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: greetingSourceProviderを購読して表示する

    return const Placeholder();
  }
}

class GreetingSourceComparisonView extends StatelessWidget {
  const GreetingSourceComparisonView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 通常のGreetingSourceViewと、
    // ProviderScope(overrides: [...], child: GreetingSourceView())でラップした版を
    // 並べて表示する

    return const Placeholder();
  }
}
```

---

## 8. 発展

### 問題33: Mutation API — 更新操作の状態(Pending/Success/Error)を型で表現する(experimental)

**対象**: `Mutation<T>`
**難易度**: ★★★★☆

**注意**: Mutation APIは riverpod 3.3.2 のソースコードには実在しますが、公式ドキュメントが
「*Mutations are experimental, and the API may change in a breaking way without a major version bump.*」
(実験的機能であり、メジャーバージョンを上げずに破壊的変更が入る可能性がある)と明記している機能です。
さらに実際に検証したところ、`Mutation`/`MutationState`等のクラスは執筆時点(riverpod 3.3.2・3.4.2で確認)、
`package:riverpod/riverpod.dart` からも `package:hooks_riverpod/hooks_riverpod.dart` からも
**一切exportされておらず**、通常の方法ではimportできません。「実験的機能」というより「まだ一般公開されて
いない内部実装」という状態です。この問題では、`package:riverpod/src/framework.dart` という
パッケージ内部のパスを直接importすることで動作を確認します(`lib/src` 配下を直接importするのは
通常は避けるべき書き方で、`flutter analyze` でも info レベルの警告が出ます)。
正式に一般公開APIとしてexportされるまでは、本番コードでの利用は避けてください。
実装前に https://riverpod.dev/docs/concepts2/mutations で最新の状況を確認してください。

**学べること**
- 「更新操作(mutation)そのもの」を、通常の `AsyncValue`(データ取得の状態)とは別に、
  `Mutation<T>` という専用の型として表現できること
- `final addTodo = Mutation<Todo>();` のようにグローバル(またはNotifierのstatic final)な変数として定義し、
  `addTodo.run(ref, (tsx) async { ... })` の形で実行すること
- UI側では `ref.watch(addTodoのようなMutationインスタンス)` が返す状態を `switch` 文で
  `MutationIdle()` / `MutationPending()` / `MutationError()` / `MutationSuccess()` に分岐できること
  (`AsyncValue`の`loading`/`error`/`data`と似た構図だが、対象が「取得結果」ではなく「実行中の操作」である点が異なる)

**要件**
- 問題06の `Counter`(`counterProvider`)を題材にする
- トップレベル(またはファイル内)に `final incrementMutation = Mutation<int>();` を定義する
- `MutationCounterView` を `ConsumerWidget` として実装する。ボタン押下で
  `incrementMutation.run(ref, (tsx) async { ... 200ミリ秒待ってからCounterのincrement()を呼び、
  更新後の値を返す ... })` を実行する
- `ref.watch(incrementMutation)` の状態を `switch` 文で分岐し、`Pending` 中はボタンを無効化して
  ローディング表示、`Error` 時はエラー文言、`Success` 時は結果を表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// Mutation関連クラスは通常のpublic exportには含まれていないため、
// パッケージ内部のパスから直接importする(教材用の暫定対応)。
import 'package:riverpod/src/framework.dart'
    show Mutation, MutationIdle, MutationPending, MutationError, MutationSuccess;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem33.g.dart';

// TODO: @riverpod classでCounterを実装する(問題06と同じ内容)

// TODO: final incrementMutation = Mutation<int>(); を定義する

class MutationCounterView extends ConsumerWidget {
  const MutationCounterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: ref.watch(incrementMutation)の状態をswitch文で分岐して表示する
    // ボタン押下でincrementMutation.run(ref, (tsx) async { ... })を実行する

    return const Placeholder();
  }
}
```
