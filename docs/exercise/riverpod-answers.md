# Riverpod 問題集 回答例

[riverpod-exercises.md](./riverpod-exercises.md) の回答例集です。問題番号が対応しています。
まずは自分で実装してから確認することをおすすめします。

---

## 1. 基本(関数プロバイダ)

### 問題01の回答例: Provider相当 — 同期・導出値を提供する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem01.g.dart';

@riverpod
double taxRate(Ref ref) => 0.1;

class PriceView extends ConsumerWidget {
  const PriceView({super.key, required this.basePrice});

  final int basePrice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxRate = ref.watch(taxRateProvider);
    final total = basePrice * (1 + taxRate);

    return Text('税込価格: ${total.toStringAsFixed(0)}円');
  }
}
```

**解説**
- `@riverpod` 関数の戻り値が `Future`/`Stream` でない場合、自動的に同期的な `Provider` 相当のプロバイダが生成される。生成される型は `$FunctionalProvider<double, double, double>` のような形で、`FutureProvider`/`StreamProvider`と共通の基盤を使いつつ、非同期修飾なしの単純な値として扱われる。
- `taxRateProvider` は状態を持たず、呼ばれるたびに同じ `0.1` を返す純粋な導出値。こうした「アプリ全体で共有したい設定値」をプロバイダとして表現しておくと、後から「サーバーから税率を取得する」ように変更する際も `taxRateProvider` の中身を `Future` 版に差し替えるだけで済み、呼び出し側(`ref.watch(taxRateProvider)`)のコードは変更不要になる利点がある。
- `ref.watch` は同期プロバイダに対しては値そのもの(`double`)を直接返す。`AsyncValue` でラップされないのは、そもそも非同期処理を伴わないため。

---

### 問題02の回答例: FutureProvider相当 — 非同期の値を取得する(おさらい)

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem02.g.dart';

@riverpod
Future<String> fetchGreeting(Ref ref) async {
  await Future<void>.delayed(const Duration(seconds: 1));
  return 'Hello, Riverpod!';
}

class GreetingView extends ConsumerWidget {
  const GreetingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(fetchGreetingProvider);

    return switch (greeting) {
      AsyncValue(:final value?) => Text(value),
      AsyncValue(error: != null) => const Text('Error fetching greeting'),
      AsyncValue() => const CircularProgressIndicator(),
    };
  }
}
```

**解説**
- 構造は `lib/joke.dart` の `fetchRandomJoke` / `lib/home.dart` の `HomeView` と全く同じパターン。`Future<T>` を返す `@riverpod` 関数は自動的に `AsyncValue<T>` として観測できるプロバイダになる。
- `switch` 式のパターンマッチは3パターンの網羅が必要で、`AsyncValue(:final value?)` は「値を持っている」場合、`AsyncValue(error: != null)` は「エラーを持っている」場合、最後の `AsyncValue()` はどちらでもない=ローディング中、という順序で評価される(この順序を入れ替えると意図通りに分岐しないので注意)。
- この問題自体は既存の`lib/joke.dart`のHTTPリクエスト版を、ダミーの`Future.delayed`に置き換えただけの最小構成。次の問題からはこの基本形の上に発展させていく。

---

### 問題03の回答例: StreamProvider相当 — 継続的に更新される値を購読する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem03.g.dart';

@riverpod
Stream<int> tickerStream(Ref ref) {
  return Stream<int>.periodic(const Duration(seconds: 1), (i) => i);
}

class TickerView extends ConsumerWidget {
  const TickerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tick = ref.watch(tickerStreamProvider);

    return Text('count: ${tick.valueOrNull ?? 0}');
  }
}
```

**解説**
- `Stream<T>` を返す `@riverpod` 関数も `Future` 版と同じく `AsyncValue<T>` として観測される。違いは、`Future` 版が「1回だけ値が確定して終わる」のに対し、`Stream` 版は「値が来るたびに `AsyncValue.data` が更新され続ける」点。
- Streamの購読・解除もRiverpodが自動管理する。このプロバイダを見ているWidgetがすべて破棄されれば(autoDisposeにより)Streamも自動的にキャンセルされるため、`StreamSubscription` を手動で管理する必要がない。
- `valueOrNull` は `AsyncValue` が値を持っていれば `T`、持っていなければ `null` を返す簡易アクセサ。初回の1秒間はまだ値が来ていないため `null` になり、`?? 0` でフォールバックしている。

---

### 問題04の回答例: Provider間の依存 — 複数のプロバイダを合成する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem04.g.dart';

@riverpod
int unitPrice(Ref ref) => 100;

@riverpod
int quantity(Ref ref) => 3;

@riverpod
int totalPrice(Ref ref) {
  final price = ref.watch(unitPriceProvider);
  final qty = ref.watch(quantityProvider);
  return price * qty;
}

class TotalPriceView extends ConsumerWidget {
  const TotalPriceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final price = ref.watch(unitPriceProvider);
    final qty = ref.watch(quantityProvider);
    final total = ref.watch(totalPriceProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('単価: $price円'),
        Text('数量: $qty'),
        Text('合計: $total円'),
      ],
    );
  }
}
```

**解説**
- `totalPriceProvider` の中で `ref.watch(unitPriceProvider)` と `ref.watch(quantityProvider)` を呼ぶことで、「この2つのプロバイダに依存している」という関係をRiverpodに伝えている。依存元のどちらかが変化すれば、`totalPriceProvider` は自動的に再計算される(この例では両方とも固定値なので実際には変化しないが、依存グラフ自体はコード生成の段階で解析され、依存関係が変わればコード生成が壊れないようにriverpod_lint等でチェックされる)。
- 手動でコンストラクタ注入するアプローチ(`TotalPriceCalculator(unitPrice: ..., quantity: ...)`のようなクラスを作り、呼び出し側で値を渡す)と比べると、Riverpodでは「どのプロバイダに依存しているか」を`ref.watch`の呼び出しだけで宣言でき、依存関係の管理・再計算のタイミングをRiverpod自身に任せられる。
- `Provider`同士の合成はRiverpodの基本的な使い方で、「小さな単位のプロバイダを組み合わせて大きな値を作る」設計により、個々のプロバイダを独立してテスト・再利用しやすくなる。

---

### 問題05の回答例: AsyncValue.guard — 関数プロバイダでの例外の扱いを理解する

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

@riverpod
Future<int> riskyValue(Ref ref, int input) async {
  // 例外はそのまま投げてよい。@riverpod Future関数は、投げられた例外を
  // 自動的にAsyncValue.errorへ変換して呼び出し側に伝えてくれる。
  return _riskyFetch(input);

  // 【比較】あえてAsyncValue.guardを使いたい場合の等価な書き方(通常は不要):
  // final result = await AsyncValue.guard(() => _riskyFetch(input));
  // return switch (result) {
  //   AsyncData(:final value) => value,
  //   AsyncError(:final error) => throw error,
  //   _ => throw StateError('unreachable'),
  // };
}

class RiskyValueView extends ConsumerWidget {
  const RiskyValueView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positive = ref.watch(riskyValueProvider(2));
    final negative = ref.watch(riskyValueProvider(-1));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('正の値(2): $positive'),
        Text('負の値(-1): $negative'),
      ],
    );
  }
}
```

**解説**
- `@riverpod Future<T>` 関数は、内部で `throw` された例外をRiverpodのフレームワーク側が捕捉し、自動的に `AsyncValue.error(error, stackTrace)` として `ref.watch` の呼び出し元に伝える。そのため、関数プロバイダ自身の中で `try/catch` や `AsyncValue.guard` を使う必要は基本的にない。
- `AsyncValue.guard` が本当に必要になるのは、次章で扱う **Notifierの更新メソッド内**(`state = ...`を手動で組み立てる場面)。関数プロバイダはRiverpodが自動でこの変換をしてくれるため、`guard`を使うと逆に冗長になる。
- 引数付き(`int input`)の `@riverpod` 関数は自動的にfamily化され、`riskyValueProvider(2)` のように呼び出せる。この仕組み自体は問題14で詳しく扱う。

---

## 2. クラス型Provider(Notifier / AsyncNotifier / StreamNotifier)

### 問題06の回答例: Notifier基本 — カウンターをstateで管理する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem06.g.dart';

@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
}

class CounterView extends ConsumerWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Count: $count'),
        ElevatedButton(
          onPressed: () => ref.read(counterProvider.notifier).increment(),
          child: const Text('+1'),
        ),
      ],
    );
  }
}
```

**解説**
- `@riverpod class Counter extends _$Counter` という宣言により、`_$Counter`(コード生成側が用意する基底クラス)を継承した `Counter` クラス自体がNotifierとなる。`build()` は「初期状態を返す関数」であり、`state`プロパティの最初の値になる。
- `state++` のように `state` へ代入すると、それを `ref.watch` しているすべてのWidgetが自動的にリビルドされる。これは`useState`が返す`ValueNotifier`の`.value`書き換えと同じ発想だが、更新ロジック(`increment`)に名前が付き、Notifierクラスの中に閉じ込められる点が異なる。呼び出し側は「何が起きるか」だけを知っていればよく、「どう状態が変わるか」の実装詳細を意識しなくてよい。
- 値の読み取りは `ref.watch(counterProvider)`、Notifier自体(メソッド呼び出し用)へのアクセスは `ref.read(counterProvider.notifier)` と使い分ける。`.notifier` を `watch` してしまうとNotifierインスタンスの再生成のたびに不要なリビルドが起きるため、メソッド呼び出し目的では常に `read` を使うのが定石。

---

### 問題07の回答例: Notifierのイミュータブルな状態更新 — 複数フィールドを持つ状態を安全に更新する

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

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Profile build() => const Profile(name: 'Alice', age: 20);

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateAge(int age) {
    state = state.copyWith(age: age);
  }
}

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileNotifierProvider);
    final notifier = ref.read(profileNotifierProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('name: ${profile.name}, age: ${profile.age}'),
        ElevatedButton(
          onPressed: () => notifier.updateName('Bob'),
          child: const Text('名前をBobにする'),
        ),
        ElevatedButton(
          onPressed: () => notifier.updateAge(profile.age + 1),
          child: const Text('年齢を+1する'),
        ),
      ],
    );
  }
}
```

**解説**
- `state.name = ...` のように既存インスタンスのフィールドを直接書き換えることはできない(そもそも `Profile` は `final` フィールドのみのイミュータブルなクラス)。必ず `state = 新しいインスタンス` という代入を行う必要がある。これはRiverpodに限らず、Flutterの「不変な状態オブジェクトを都度作り直す」という一般的な設計指針に沿ったもの。
- `copyWith` を使わずに `state = Profile(name: name, age: 0)` のように直接新規インスタンスを組み立ててしまうと、`age`が意図せず初期値に戻ってしまうバグになる。`copyWith`パターンは「指定したフィールドだけを変え、それ以外は元の値を保持する」ことを保証してくれる。
- `updateName`/`updateAge`をそれぞれ独立したメソッドとして用意することで、呼び出し側は「名前だけを変えたい」「年齢だけを変えたい」という意図をそのままメソッド呼び出しとして表現できる。もし単一の `update(Profile newProfile)` のようなメソッドだけを公開していた場合、呼び出し側で毎回 `state.copyWith(...)` を書く必要が生じ、Notifierの外にロジックが漏れ出してしまう。

---

### 問題08の回答例: AsyncNotifier基本 — 非同期な初期値を持つNotifier

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem08.g.dart';

@riverpod
class TodoList extends _$TodoList {
  @override
  Future<List<String>> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return ['牛乳を買う', '掃除する', '本を返す'];
  }
}

class TodoListView extends ConsumerWidget {
  const TodoListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);

    return switch (todos) {
      AsyncValue(:final value?) => ListView(
        shrinkWrap: true,
        children: [for (final todo in value) ListTile(title: Text(todo))],
      ),
      AsyncValue(error: != null) => const Text('Error loading todos'),
      AsyncValue() => const CircularProgressIndicator(),
    };
  }
}
```

**解説**
- `build()` が `Future<T>` を返すクラス型プロバイダは、内部的には「AsyncNotifier」として扱われ、`state` の型は `AsyncValue<List<String>>` になる。`ref.watch(todoListProvider)` の戻り値の型が問題02の関数版と同じ `AsyncValue<T>` になるため、UI側の分岐コードはほぼ同じ書き方で済む。
- 問題02の `FutureProvider` 相当との決定的な違いは、「クラスなのでメソッドを持てる」点。次の問題09で見るように、`addTodo` のような状態更新メソッドをNotifier内に実装できるのは、クラス型プロバイダならでは。関数プロバイダは値を返すだけで、更新用のAPIを持たせられない。
- 初回ロード中(`build()` の `Future` がまだ完了していない間)は、`ref.watch` 側で `AsyncValue.loading()` として観測される。これは関数型の `FutureProvider` と全く同じ挙動。

---

### 問題09の回答例: AsyncNotifierの更新パターン — 更新中のローディング状態を表現する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem09.g.dart';

@riverpod
class TodoList extends _$TodoList {
  @override
  Future<List<String>> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return ['牛乳を買う', '掃除する', '本を返す'];
  }

  Future<void> addTodo(String text) async {
    if (text.isEmpty) {
      throw Exception('text must not be empty');
    }

    final currentTodos = await future;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return [...currentTodos, text];
    });
  }
}

class TodoListView extends ConsumerWidget {
  const TodoListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);
    final controller = TextEditingController();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        switch (todos) {
          AsyncValue(:final value?) => Column(
            children: [for (final todo in value) Text(todo)],
          ),
          AsyncValue(error: != null) => const Text('Error'),
          AsyncValue() => const CircularProgressIndicator(),
        },
        TextField(controller: controller),
        ElevatedButton(
          onPressed: () {
            ref.read(todoListProvider.notifier).addTodo(controller.text);
          },
          child: const Text('追加'),
        ),
      ],
    );
  }
}
```

**解説**
- 更新処理の定石は「まず `state = const AsyncValue.loading();` でローディング状態にし、その後 `state = await AsyncValue.guard(() async { ... });` で実際の非同期処理を実行し、その結果(成功なら`AsyncData`、失敗なら`AsyncError`)を丸ごと `state` に代入する」という流れ。`AsyncValue.guard` が例外の捕捉と `AsyncValue` への変換を自動でやってくれるため、`try/catch`を手で書くよりも簡潔かつ「エラー時に前のstateを壊さず正しくAsyncErrorへ倒す」ことが保証される。
- もし `try/catch` を手で書き、catchブロックで `state` の更新を忘れたり、例外を握りつぶしたりすると、UIは「ローディング中のまま止まる」ような不整合な状態になりかねない。`AsyncValue.guard` を使うことで、そうした「更新中に固まる」バグを構造的に防げる。
- `final currentTodos = await future;` は、Notifierが提供する `future` ゲッター(現在の `AsyncValue` が確定するまで待つ)を使い、直前の一覧を安全に取得している。`state.value` だと `loading`/`error` 中は `null` になる可能性があるため、確実に値を得たい場合は `future` を使う方が安全。

---

### 問題10の回答例: Ref.mounted — 非同期処理後にNotifierがまだ有効か確認する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem10.g.dart';

@riverpod
class SlowCounter extends _$SlowCounter {
  @override
  int build() => 0;

  Future<void> incrementAfterDelay() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (ref.mounted) {
      state++;
    }
  }
}

class SlowCounterView extends ConsumerWidget {
  const SlowCounterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(slowCounterProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Count: $count'),
        ElevatedButton(
          onPressed: () {
            ref.read(slowCounterProvider.notifier).incrementAfterDelay();
          },
          child: const Text('2秒後に+1'),
        ),
      ],
    );
  }
}
```

**解説**
- `incrementAfterDelay()` は `await` で2秒待つ間に、ユーザーが画面を閉じるなどしてこのプロバイダを見ているWidgetがいなくなり、autoDisposeにより `SlowCounter` 自体が破棄されてしまう可能性がある。破棄後に `state++` を実行しようとすると、破棄済みのNotifierへの操作としてエラーになる。
- `ref.mounted` は、`BuildContext.mounted` のプロバイダ版で、「このプロバイダ(および `ref`)がまだ有効かどうか」を `bool` で返す。`await` の直後など、非同期処理の完了時点で必ずチェックしてから `state` を触るのが安全な書き方。
- チェックを怠った場合に何が起きるかは実行環境によって異なるが、いずれにせよ「もう存在しないはずの状態を更新しようとする」という論理的な矛盾が生じる。`StatefulWidget`で`if (mounted) { setState(...) }`と書いていたのと全く同じ動機であり、Riverpodの世界での対応物が`ref.mounted`だと理解しておくとよい。

---

### 問題11の回答例: StreamNotifier — Streamを状態として管理する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem11.g.dart';

@riverpod
class ClockNotifier extends _$ClockNotifier {
  @override
  Stream<DateTime> build() {
    return Stream<DateTime>.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
  }

  void restart() {
    ref.invalidateSelf();
  }
}

class ClockView extends ConsumerWidget {
  const ClockView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockNotifierProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(now.valueOrNull?.toIso8601String() ?? '---'),
        ElevatedButton(
          onPressed: () => ref.read(clockNotifierProvider.notifier).restart(),
          child: const Text('リセット'),
        ),
      ],
    );
  }
}
```

**解説**
- `build()` が `Stream<T>` を返すと自動的に「StreamNotifier」になり、`state` は `AsyncValue<DateTime>`(継続的に更新される)になる。`Notifier`(単発の同期値)・`AsyncNotifier`(単発の非同期値)・`StreamNotifier`(継続的な非同期値)は、いずれも「`build()` の戻り値の型」だけで自動的に切り替わり、宣言方法(`@riverpod class Foo extends _$Foo`)自体は共通している。
- `ref.invalidateSelf()` は「このプロバイダ自身を無効化し、次にwatchされたときに `build()` を再実行する」という操作。`restart()` メソッド内で呼ぶことで、それまで購読していた `Stream.periodic` を破棄し、新しい `Stream.periodic` を作り直せる(=タイマーがリセットされたのと同じ効果になる)。
- Notifierクラス内で `ref`(インスタンスプロパティとして自動的に使える)を使って自分自身を操作できるのは、Notifierが自身のライフサイクルを把握しているためで、関数プロバイダにはない特徴。

---

### 問題12の回答例: Notifier間の依存 — build内でref.watchして他プロバイダの変化に追従する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem12.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  String build() => 'ja';

  void toggle() {
    state = state == 'ja' ? 'en' : 'ja';
  }
}

@riverpod
class GreetingNotifier extends _$GreetingNotifier {
  @override
  String build() {
    final locale = ref.watch(localeNotifierProvider);
    return locale == 'ja' ? 'こんにちは' : 'Hello';
  }
}

class GreetingView extends ConsumerWidget {
  const GreetingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(greetingNotifierProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(greeting),
        ElevatedButton(
          onPressed: () => ref.read(localeNotifierProvider.notifier).toggle(),
          child: const Text('言語を切り替える'),
        ),
      ],
    );
  }
}
```

**解説**
- `GreetingNotifier.build()` の中で `ref.watch(localeNotifierProvider)` を呼ぶと、`LocaleNotifier` の値が変わるたびに `GreetingNotifier` の `build()` が自動的に再実行される。関数プロバイダ同士の合成(問題04)と全く同じ仕組みが、Notifierの `build()` の中でも使える。
- 重要な挙動として、依存が変化したときRiverpod 3系では **`GreetingNotifier`インスタンス自体が新しく作り直される**(=`build()`が呼ばれ、その戻り値がそのまま新しい`state`になる)。もし `GreetingNotifier` が独自のミュータブルな内部状態(`state`以外のフィールド)を持っていた場合、それは依存変化のたびにリセットされてしまう。これが問題13で扱う「`state`以外の公開プロパティを持つべきでない」という設計指針にもつながっている。
- `localeNotifierProvider` の値の変更(`toggle()`)が、依存先である `greetingNotifierProvider` の再計算を自動的にトリガーする様子は、Excelのセル参照(A1を変えるとA1を参照するB1が自動更新される)に近い感覚で理解すると分かりやすい。

---

### 問題13の回答例: riverpod_lintを読む — avoid_public_notifier_propertiesに気づいて直す

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem13.g.dart';

class CounterState {
  const CounterState({required this.count, required this.extraCount});

  final int count;
  final int extraCount;

  CounterState copyWith({int? count, int? extraCount}) {
    return CounterState(
      count: count ?? this.count,
      extraCount: extraCount ?? this.extraCount,
    );
  }
}

@riverpod
class GoodCounter extends _$GoodCounter {
  @override
  CounterState build() => const CounterState(count: 0, extraCount: 0);

  void increment() {
    state = state.copyWith(
      count: state.count + 1,
      extraCount: state.extraCount + 1,
    );
  }
}

class GoodCounterView extends ConsumerWidget {
  const GoodCounterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counterState = ref.watch(goodCounterProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('count: ${counterState.count}, extraCount: ${counterState.extraCount}'),
        ElevatedButton(
          onPressed: () => ref.read(goodCounterProvider.notifier).increment(),
          child: const Text('+1'),
        ),
      ],
    );
  }
}
```

**解説**
- 悪い例(`BadCounter`)は `extraCount` という `state` 以外の公開ミュータブルフィールドを持っていた。これに `flutter analyze` を実行すると、`riverpod_lint` の `avoid_public_notifier_properties` ルールが警告を出す。理由は、Notifierの外部から観測可能な状態は必ず `state` を経由するべきという設計原則があるため——`extraCount` のような「隠れた状態」は `ref.watch` で購読してもリビルドのトリガーにならず、UIと実際の値が食い違う原因になる。
- 修正版では `extraCount` を単独のフィールドとして持たせるのではなく、`count` と `extraCount` の両方を持つ `CounterState` というイミュータブルなクラスに統合し、`state` の型そのものを `CounterState` にした。これにより、両方の値の変化が確実に `state` の代入を通して通知されるようになる。
- この手のルールは、「一見動いているように見えるが、実はリビルドの整合性が壊れている」バグを未然に防ぐためのもの。`riverpod_lint` が有効なプロジェクトでは、Notifierを書く際に「`state`以外に外部公開する可変フィールドを増やしていないか」を常に意識するとよい。

---

## 3. Family(パラメータ付きProvider)

### 問題14の回答例: 関数プロバイダのfamily化 — 引数付きプロバイダを作る

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem14.g.dart';

@riverpod
Future<String> userName(Ref ref, int userId) async {
  await Future<void>.delayed(const Duration(milliseconds: 100));
  return 'User#$userId';
}

class UserNameView extends ConsumerWidget {
  const UserNameView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userNameProvider(1));

    return switch (name) {
      AsyncValue(:final value?) => Text(value),
      AsyncValue(error: != null) => const Text('Error'),
      AsyncValue() => const CircularProgressIndicator(),
    };
  }
}
```

**解説**
- Riverpod 2系では `FutureProvider.family<String, int>((ref, userId) async => ...)` のように `.family` 修飾子を明示的に使う必要があったが、3系のコード生成では `@riverpod` 関数の第一引数(`Ref ref`)より後ろに引数を追加するだけで、自動的にfamily化されたプロバイダが生成される。
- 呼び出し側は `userNameProvider(1)` のように、生成されたプロバイダを「関数のように」引数付きで呼び出す。この呼び出しの返り値自体がプロバイダのインスタンスであり、`ref.watch(userNameProvider(1))` と `ref.watch(userNameProvider(2))` は完全に独立したキャッシュ(別々の`AsyncValue`状態)を持つ。
- 「引数ごとに独立したキャッシュ」という特性により、例えば同じ画面内で複数の異なるuserIdのデータを同時に表示しても、それぞれが個別に取得・キャッシュされ、互いに干渉しない。

---

### 問題15の回答例: AsyncNotifierのfamily化 — buildにパラメータを持たせる

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem15.g.dart';

@riverpod
class ItemDetail extends _$ItemDetail {
  @override
  Future<String> build(String itemId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return 'Item: $itemId';
  }

  Future<void> toggleFavorite() async {
    debugPrint('toggle favorite: $itemId');
  }
}

class ItemDetailView extends ConsumerWidget {
  const ItemDetailView({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(itemDetailProvider(itemId));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        switch (detail) {
          AsyncValue(:final value?) => Text(value),
          AsyncValue(error: != null) => const Text('Error'),
          AsyncValue() => const CircularProgressIndicator(),
        },
        ElevatedButton(
          onPressed: () {
            ref.read(itemDetailProvider(itemId).notifier).toggleFavorite();
          },
          child: const Text('お気に入り'),
        ),
      ],
    );
  }
}
```

**解説**
- `Notifier`/`AsyncNotifier` でも、`build(String itemId)` のように引数を追加するだけで同様にfamily化される。呼び出し側は `itemDetailProvider(itemId)` として使い、`.notifier` を付ければそのインスタンスのNotifierにアクセスできる(`itemDetailProvider(itemId).notifier`)。
- `toggleFavorite()` メソッドの中で `itemId` を(`this.itemId`を省略した形で)そのまま参照できるのは、Riverpodのコード生成が `build()` の引数をNotifierクラスのフィールドとして自動的に保持してくれるため。つまり、familyの引数はNotifierの中では通常のインスタンスフィールドと同じ感覚で使ってよい。
- 呼び出し側で `itemDetailProvider(itemId)` を2回書いている(`ref.watch`用と`.notifier`用)のは冗長に見えるが、同じ `itemId` を渡している限り同一のプロバイダインスタンスを指すため、問題なく動作する(Riverpodが引数の等価性でプロバイダインスタンスを同定している)。

---

### 問題16の回答例: 複数引数のfamily — 2つの引数を持つプロバイダを作る

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem16.g.dart';

@riverpod
Future<List<String>> searchItems(
  Ref ref,
  String keyword, {
  int page = 0,
}) async {
  await Future<void>.delayed(const Duration(milliseconds: 100));
  return List.generate(5, (i) => '$keyword-result-${page * 5 + i}');
}

class SearchItemsView extends ConsumerStatefulWidget {
  const SearchItemsView({super.key});

  @override
  ConsumerState<SearchItemsView> createState() => _SearchItemsViewState();
}

class _SearchItemsViewState extends ConsumerState<SearchItemsView> {
  final controller = TextEditingController(text: 'apple');
  int page = 0;

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchItemsProvider(controller.text, page: page));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(controller: controller, onSubmitted: (_) => setState(() {})),
        ElevatedButton(
          onPressed: () => setState(() => page++),
          child: Text('次のページ($page)'),
        ),
        switch (results) {
          AsyncValue(:final value?) => Column(
            children: [for (final item in value) Text(item)],
          ),
          AsyncValue(error: != null) => const Text('Error'),
          AsyncValue() => const CircularProgressIndicator(),
        },
      ],
    );
  }
}
```

**解説**
- 位置引数(`String keyword`)と名前付き引数(`{int page = 0}`)を混在させても、そのままfamily化される。呼び出し側は通常のDart関数呼び出しと同じ感覚で `searchItemsProvider(keyword, page: page)` のように書ける。
- 引数の組み合わせ(`keyword`と`page`のペア)ごとに別々のキャッシュが作られる。例えば `searchItemsProvider('apple', page: 0)` と `searchItemsProvider('apple', page: 1)` は別インスタンスであり、ページを切り替えるたびに(初回は)新しい非同期処理が走る。一度取得したページに戻れば、autoDisposeで破棄されていない限りキャッシュが再利用される。
- この問題では `ConsumerWidget` ではなく `ConsumerStatefulWidget` を使っている。理由は、`TextEditingController` や `page` のようなローカルなUI状態を保持する必要があるため(`ConsumerStatefulWidget`は問題30で詳しく扱う)。

---

### 問題17の回答例: family×autoDispose — パラメータごとにキャッシュが独立して破棄されることを確認する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem17.g.dart';

@riverpod
Future<String> userName(Ref ref, int userId) async {
  ref.onDispose(() => debugPrint('disposed: userId=$userId'));
  await Future<void>.delayed(const Duration(milliseconds: 100));
  return 'User#$userId';
}

class UserNameSwitcherView extends ConsumerStatefulWidget {
  const UserNameSwitcherView({super.key});

  @override
  ConsumerState<UserNameSwitcherView> createState() => _UserNameSwitcherViewState();
}

class _UserNameSwitcherViewState extends ConsumerState<UserNameSwitcherView> {
  int selectedUserId = 1;

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(userNameProvider(selectedUserId));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        switch (name) {
          AsyncValue(:final value?) => Text(value),
          AsyncValue(error: != null) => const Text('Error'),
          AsyncValue() => const CircularProgressIndicator(),
        },
        ElevatedButton(
          onPressed: () => setState(() => selectedUserId = 1),
          child: const Text('userId: 1'),
        ),
        ElevatedButton(
          onPressed: () => setState(() => selectedUserId = 2),
          child: const Text('userId: 2'),
        ),
      ],
    );
  }
}
```

**解説**
- `selectedUserId` を切り替えると、それまで `ref.watch` していた `userNameProvider(旧userId)` はこのWidgetからwatchされなくなる。他に誰もwatchしていなければ、autoDisposeにより該当インスタンスは破棄され、`ref.onDispose` に登録したコールバックが実行される(ターミナル/DevToolsコンソールに`disposed: userId=1`のようなログが出る)。
- 一方、新しく選択された `userNameProvider(新userId)` は(初めてwatchされるなら)新規にインスタンスが作られ、`build`(この場合は関数本体)が実行される。つまり family の各インスタンスは、それぞれ独立したライフサイクルを持ち、あるインスタンスの破棄が他のインスタンスに影響することはない。
- 一度 userId: 1 → userId: 2 → userId: 1 と行き来すると、1回目の userId: 1 は破棄されているため、再度 userId: 1 に戻ったときはキャッシュが残っておらず、再度100ミリ秒待つ(取得し直す)ことになる。これは、値を長期間保持したい場合は問題26の`ref.keepAlive()`のような仕組みが必要になることを示唆している。

---

## 4. ref.watch / ref.read / ref.listen / ref.select の使い分け

### 問題18の回答例: ref.watch vs ref.read — 使い分けの基本

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem18.g.dart';

@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
}

class CounterViewV2 extends ConsumerWidget {
  const CounterViewV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // build()内: リビルドされて構わない箇所なのでwatchを使う。
    // これによりstateが変わるたびにこのbuild()が再実行され、表示が最新化される。
    final count = ref.watch(counterProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Count: $count'),
        ElevatedButton(
          onPressed: () {
            // コールバック内: 値の変化を継続的に見る必要はなく、
            // 一度きり操作(またはメソッド呼び出し)をしたいだけなのでreadを使う。
            ref.read(counterProvider.notifier).increment();
          },
          child: const Text('+1'),
        ),

        // 【NGな例】もしbuild()内で下記のようにref.readを使ってしまうと、
        // final badCount = ref.read(counterProvider);
        // カウンタが変化してもこのWidgetはリビルドされないため、
        // 画面上の表示(badCount)は最初の値のまま更新されなくなる。
      ],
    );
  }
}
```

**解説**
- `ref.watch` は「このプロバイダの値の変化に応じてリビルドしてほしい」という購読の宣言であり、`build()` メソッドの中でのみ意味を持つ(コールバックの中で呼んでも、次にリビルドが起きるまで購読が反映されないなど、意図通りに動かない)。
- `ref.read` は「今この瞬間の値を1回だけ読む」ための呼び出しで、購読は発生しない。ボタンの `onPressed` のような「イベント発生時に一度だけ処理したい」場面に向いている。
- もし`build()`内で`ref.read`を使ってしまうと、初回描画時の値がそのままキャッシュされたように見え、以後カウンタを増やしてもUIの表示が更新されないバグになる。この間違いはコンパイルエラーにはならず、実行して初めて気づく類のバグなので、`build()`内は常に`watch`、コールバック内は`read`という原則を徹底することが重要。

---

### 問題19の回答例: ref.listen — build内で副作用(SnackBar)を起こす

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem19.g.dart';

@riverpod
class TodoList extends _$TodoList {
  @override
  Future<List<String>> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return ['牛乳を買う', '掃除する', '本を返す'];
  }

  Future<void> addTodo(String text) async {
    if (text.isEmpty) {
      throw Exception('text must not be empty');
    }
    final currentTodos = await future;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return [...currentTodos, text];
    });
  }
}

class TodoListWithToastView extends ConsumerWidget {
  const TodoListWithToastView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(todoListProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('追加に失敗しました')),
        );
      }
    });

    final todos = ref.watch(todoListProvider);
    final controller = TextEditingController();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        switch (todos) {
          AsyncValue(:final value?) => Column(
            children: [for (final todo in value) Text(todo)],
          ),
          AsyncValue(error: != null) => const Text('Error'),
          AsyncValue() => const CircularProgressIndicator(),
        },
        TextField(controller: controller),
        ElevatedButton(
          onPressed: () {
            ref.read(todoListProvider.notifier).addTodo(controller.text);
          },
          child: const Text('追加'),
        ),
      ],
    );
  }
}
```

**解説**
- `ref.listen` は `ref.watch` と違い、値をこのWidgetの表示(戻り値のWidgetツリー)には反映しない。あくまで「変化が起きたときに副作用(ここではSnackBar表示)を実行する」ためのフックであり、flutter_hooksでいう`useOnListenableChange`/`useOnStreamChange`と同じ立ち位置。
- `ref.listen` は `ConsumerWidget.build` メソッドの中(トップレベル)で呼び出す必要がある。`onPressed`のようなコールバックの中で呼び出すことはできない(Riverpodのフレームワークが、build実行のたびにリスナー登録・解除を管理しているため)。
- `next.hasError` を見ることで、「一覧取得中のエラー」ではなく「更新(追加)処理中に起きたエラー」だけを拾える(この問題では両方とも`todoListProvider`の`AsyncValue`のエラー状態として現れるため、区別が必要な場合は`previous`の状態と組み合わせて判定するとより厳密になる)。

---

### 問題20の回答例: ref.listenでprevious/next — 遷移パターンで条件分岐する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem20.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  String build() => 'ja';

  void toggle() {
    state = state == 'ja' ? 'en' : 'ja';
  }
}

class LocaleToastView extends ConsumerWidget {
  const LocaleToastView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(localeNotifierProvider, (previous, next) {
      if (previous == 'ja' && next == 'en') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('English mode')),
        );
      }
    });

    final locale = ref.watch(localeNotifierProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('locale: $locale'),
        ElevatedButton(
          onPressed: () => ref.read(localeNotifierProvider.notifier).toggle(),
          child: const Text('切り替え'),
        ),
      ],
    );
  }
}
```

**解説**
- `ref.listen` のコールバックは `(previous, next)` の2つの引数を受け取る。`previous` は直前の値(初回リッスン時は `null` になりうる)、`next` は新しい値。今回は `previous == 'ja' && next == 'en'` という**特定の遷移方向だけ**を条件式で絞り込むことで、「en→ja」の逆方向では何も起きないようにしている。
- flutter_hooks版の `useOnAppLifecycleStateChange` で「`resumed`から`paused`に変わった瞬間だけ保存する」という設計をしたのと全く同じ考え方で、単に「今どんな値か」ではなく「どう変化したか」に着目したい場合に`previous`/`next`の両方を受け取れることが役立つ。
- `previous`が`null`になりうる(このリスナーが初めて登録されたタイミング)ことを考慮せずに`previous!.someProperty`のようにアクセスすると実行時エラーになりうるため、`previous == 'ja'`のような等価比較であれば`null`との比較は安全だが、プロパティアクセスを伴う場合は`previous`のnullチェックを忘れないようにする。

---

### 問題21の回答例: ref.select — 部分監視でリビルドを絞り込む

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem21.g.dart';

class Profile {
  const Profile({required this.name, required this.age});

  final String name;
  final int age;

  Profile copyWith({String? name, int? age}) {
    return Profile(name: name ?? this.name, age: age ?? this.age);
  }
}

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Profile build() => const Profile(name: 'Alice', age: 20);

  void updateName(String name) => state = state.copyWith(name: name);
  void updateAge(int age) => state = state.copyWith(age: age);
}

class AgeOnlyView extends ConsumerWidget {
  const AgeOnlyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('AgeOnlyView rebuilt');
    final age = ref.watch(profileNotifierProvider.select((p) => p.age));

    return Text('age: $age');
  }
}

class ProfileSelectDemoView extends ConsumerWidget {
  const ProfileSelectDemoView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(profileNotifierProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AgeOnlyView(),
        ElevatedButton(
          onPressed: () => notifier.updateName('Bob'),
          child: const Text('名前だけ変更'),
        ),
        ElevatedButton(
          onPressed: () {
            final currentAge = ref.read(profileNotifierProvider).age;
            notifier.updateAge(currentAge + 1);
          },
          child: const Text('年齢を+1'),
        ),
      ],
    );
  }
}
```

**解説**
- `ref.watch(profileNotifierProvider)` は `Profile` インスタンス全体を監視するため、`name`だけが変わっても`age`だけが変わっても、購読しているWidgetは等しくリビルドされる。一方 `ref.watch(profileNotifierProvider.select((p) => p.age))` は、`select`に渡した関数の**戻り値**(この場合は`age`)が前回と変わったときだけリビルドを起こす。
- 「名前だけ変更」ボタンを押しても、`age`の値自体は変わらないため`select`の戻り値も変わらず、`AgeOnlyView`は再構築されない(`debugPrint('AgeOnlyView rebuilt')`のログが出ない)。「年齢を+1」ボタンを押したときだけログが出ることを確認できる。
- この最適化は、`Profile`のようなオブジェクトが多くのフィールドを持ち、かつ画面の各部分がそのごく一部だけを必要とするケースで効果を発揮する。全フィールドを使うWidgetには意味がなく、あくまで「一部だけを見ている」Widgetに対して不要な再描画を削減するための仕組みであることを理解しておく。

---

## 5. AsyncValueの実践

### 問題22の回答例: .when() — switch式パターンマッチとの書き分け

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem22.g.dart';

@riverpod
Future<String> fetchGreeting(Ref ref) async {
  await Future<void>.delayed(const Duration(seconds: 1));
  return 'Hello, Riverpod!';
}

class GreetingViewV2 extends ConsumerWidget {
  const GreetingViewV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(fetchGreetingProvider);

    return greeting.when(
      data: (value) => Text(value),
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => const Text('Error fetching greeting'),
    );

    // 【比較】lib/home.dartと同じswitch式パターンマッチで書くと以下のようになる(挙動は等価):
    // return switch (greeting) {
    //   AsyncValue(:final value?) => Text(value),
    //   AsyncValue(error: != null) => const Text('Error fetching greeting'),
    //   AsyncValue() => const CircularProgressIndicator(),
    // };
  }
}
```

**解説**
- `.when()` は `data`/`loading`/`error` の3つのコールバックをすべて渡す必要がある(オプション引数として `skipLoadingOnRefresh`(再取得中は直前のdataを表示し続けるかどうか)なども指定できる)。「全ケースを強制的に書かせる」という点で、書き漏れに気づきやすい設計になっている。
- `switch` 式パターンマッチは、Dart 3のパターンマッチング構文を活用した書き方で、`.when()`と全く同じ情報を判定できるが、パターンの書き方に慣れが必要な反面、複雑な分岐(値の中身に応じてさらに分岐する等)を1つの`switch`にまとめやすい利点もある。
- このプロジェクトの既存コード(`lib/home.dart`)は `switch` 式を採用しているため、新しく書くコードもこちらのスタイルに合わせるのが一貫性の観点では望ましい。ただし、`.when()`の方がシンプルに感じる場面(単純に3分岐するだけ、等)では`.when()`を使っても間違いではなく、プロジェクト内で明確なルールがなければどちらでも良い。

---

### 問題23の回答例: AsyncValueのプロパティ — isLoading/isRefreshing/hasError/requireValueを使い分ける

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem23.g.dart';

@riverpod
class TodoList extends _$TodoList {
  @override
  Future<List<String>> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return ['牛乳を買う', '掃除する', '本を返す'];
  }
}

class TodoListRefreshableView extends ConsumerWidget {
  const TodoListRefreshableView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(todoListProvider.future),
      child: Stack(
        children: [
          if (todos.hasError)
            const Center(child: Text('Error loading todos'))
          else if (!todos.hasValue)
            const Center(child: CircularProgressIndicator())
          else
            ListView(
              children: [
                for (final todo in todos.requireValue) ListTile(title: Text(todo)),
              ],
            ),
          if (todos.isRefreshing)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
```

**解説**
- `isLoading` は「まだ一度も値を取得できていない、最初のロード中」を表す。`isRefreshing` は「既に何らかの値(`hasValue`)を持ちつつ、再取得(`ref.refresh`等)が進行中」を表す。両者は排他的で、最初のロード中は`isRefreshing`は`false`、再取得中は`isLoading`ではなく`isRefreshing`が`true`になる。この違いにより「初回は全画面ローディング、再取得中は既存内容を見せつつ上部にバー表示」というUXを自然に書き分けられる。
- `hasValue`/`hasError`で状態の有無をチェックしてから`requireValue`(値がなければ例外を投げる)を使うことで、「値があることが確実な文脈でだけ非null値として扱う」という安全な取り出し方ができる。`valueOrNull`は逆に「値がなければ単に`null`」として扱いたい場合に向いている。
- `lib/home.dart`の`randomJoke.isRefreshing`はまさにこの問題と同じ用途で、「再取得中も直前のジョークを表示したまま、上部にだけプログレスバーを重ねる」というUXを実現している。

---

### 問題24の回答例: ref.refresh と ref.invalidate — 挙動の違いを体感する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem24.g.dart';

@riverpod
Future<String> fetchGreeting(Ref ref) async {
  await Future<void>.delayed(const Duration(seconds: 1));
  return 'Hello, Riverpod!';
}

class GreetingRefreshDemoView extends ConsumerWidget {
  const GreetingRefreshDemoView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(fetchGreetingProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        switch (greeting) {
          AsyncValue(:final value?) => Text(value),
          AsyncValue(error: != null) => const Text('Error'),
          AsyncValue() => const CircularProgressIndicator(),
        },
        ElevatedButton(
          onPressed: () {
            // 次にwatchされたタイミングで再計算されるよう予約するだけ。
            // その場でawaitして結果を使うことはできない。
            ref.invalidate(fetchGreetingProvider);
          },
          child: const Text('invalidate'),
        ),
        ElevatedButton(
          onPressed: () async {
            // 即座に再計算をトリガーし、その結果をここでawaitして使える。
            final result = await ref.refresh(fetchGreetingProvider.future);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('refreshed: $result')),
              );
            }
          },
          child: const Text('refresh'),
        ),
      ],
    );
  }
}
```

**解説**
- `ref.invalidate(provider)` は「このプロバイダの現在のキャッシュを捨て、次に誰かがwatch/readしたタイミングで`build`を再実行する」という**遅延的な**再計算の予約。呼び出した瞬間には結果を受け取れない(戻り値は`void`)。
- `ref.refresh(provider)`(または`.future`修飾子付き)は「即座に再計算をトリガーし、その結果を返す」。`Future`を返すプロバイダに対して`.future`を付けて`await`すれば、再取得された最新の値をその場のコードで直接使える。
- `lib/home.dart`が`ref.invalidate(fetchRandomJokeProvider)`を使っているのは、「ボタンを押した後にジョークが更新されればよく、その場で取得結果の文字列自体を使う必要がない」ため。もし取得直後の値を使って何か処理をしたい(例: 取得した文字列をSnackBarに出す、のような今回の例)場合は`ref.refresh`の方が適している。

---

## 6. ライフサイクル・自動破棄

### 問題25の回答例: autoDispose — デフォルトの破棄タイミングを確認する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem25.g.dart';

@riverpod
class DisposableCounter extends _$DisposableCounter {
  @override
  int build() {
    ref.onDispose(() => debugPrint('DisposableCounter disposed'));
    return 0;
  }

  void increment() => state++;
}

class DisposableCounterView extends ConsumerWidget {
  const DisposableCounterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(disposableCounterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('DisposableCounter')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Count: $count'),
            ElevatedButton(
              onPressed: () {
                ref.read(disposableCounterProvider.notifier).increment();
              },
              child: const Text('+1'),
            ),
          ],
        ),
      ),
    );
  }
}

class DisposableCounterHomeView extends StatelessWidget {
  const DisposableCounterHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DisposableCounterView()),
            );
          },
          child: const Text('カウンター画面へ'),
        ),
      ),
    );
  }
}
```

**解説**
- Riverpod 3系では、すべてのプロバイダがデフォルトでautoDispose対象になる(2系のように`.autoDispose`修飾子を明示する必要がない)。「このプロバイダを`watch`/`listen`しているWidgetが1つもなくなった時点で、そのプロバイダのインスタンス(および`state`)が破棄される」という挙動がデフォルトで有効になっている。
- `ref.onDispose` は `build()` の中で呼び出すことで、破棄時に実行したいクリーンアップ処理(ここでは単なるログ出力)を登録できる。`DisposableCounterView`を`Navigator.push`で開き、`pop`で閉じると、他に誰もこのプロバイダをwatchしていない状態になるため、破棄され`ref.onDispose`のログが出力される。
- この挙動は「使われなくなった状態を自動的にメモリから解放してくれる」という利点がある一方、「一時的に画面から離れただけでキャッシュが消えてしまう」という側面もある。状態を保持し続けたい場合には、次の問題26で扱う`ref.keepAlive()`を使う。

---

### 問題26の回答例: ref.keepAlive() — 条件付きでキャッシュを維持する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem26.g.dart';

@riverpod
Future<String> cachedFetch(Ref ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 100));

  final isEven = DateTime.now().millisecond.isEven;
  if (isEven) {
    ref.keepAlive();
    return 'success';
  }
  throw Exception('failed, try again');
}

class CachedFetchView extends ConsumerWidget {
  const CachedFetchView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(cachedFetchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('CachedFetch')),
      body: Center(
        child: switch (result) {
          AsyncValue(:final value?) => Text('結果: $value(この画面を出て戻ってもキャッシュされます)'),
          AsyncValue(error: != null) => const Text('失敗しました。戻って再度開くと再取得します'),
          AsyncValue() => const CircularProgressIndicator(),
        },
      ),
    );
  }
}
```

**解説**
- `ref.keepAlive()` を呼ぶと、このプロバイダインスタンスに対するautoDisposeが無効化される。呼ばなければ問題25と同様、リスナーが0になった時点で破棄されるが、`keepAlive()`を呼んだインスタンスは、明示的に`invalidate`されるかアプリが終了するまでキャッシュされ続ける。
- この問題では「成功したときだけ`keepAlive()`を呼ぶ」ことで、成功結果はキャッシュし、失敗結果はキャッシュしない、という条件分岐を実現している。失敗時は`keepAlive()`を呼んでいないため、画面を出入りするたびに(誰もwatchしなくなった時点でautoDisposeが働き)再取得が走る。
- `ref.keepAlive()`の戻り値は`KeepAliveLink`というオブジェクトで、これの`.close()`を呼ぶと再びautoDispose対象に戻せる。例えば「一定時間だけキャッシュを維持し、その後は自動的に破棄する」といった高度な制御をしたい場合は、この戻り値を保持しておいて後から`.close()`を呼ぶ設計にする。

---

### 問題27の回答例: ref.onCancel / ref.onResume — リスナー0件時の一時停止・再開を扱う

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem27.g.dart';

@riverpod
class LiveTimer extends _$LiveTimer {
  Timer? _timer;

  @override
  int build() {
    _startTimer();

    ref.onCancel(() {
      debugPrint('LiveTimer: onCancel (paused)');
      _timer?.cancel();
    });

    ref.onResume(() {
      debugPrint('LiveTimer: onResume (restarted)');
      _startTimer();
    });

    ref.onDispose(() {
      debugPrint('LiveTimer: onDispose');
      _timer?.cancel();
    });

    return 0;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => state++);
  }
}

class LiveTimerView extends ConsumerWidget {
  const LiveTimerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = ref.watch(liveTimerProvider);

    return Center(child: Text('経過秒数: $seconds'));
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
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [LiveTimerView(), Center(child: Text('別の画面'))],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'タイマー'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '別画面'),
        ],
      ),
    );
  }
}
```

**解説**
- プロバイダは、監視しているリスナーが0件になった瞬間に即座に破棄されるわけではない。まず`onCancel`が呼ばれ、その後(内部的なタイミングで)新しいリスナーが付かなければ`onDispose`によって実際に破棄される。もし`onCancel`後、破棄される前に新しいリスナーが付けば`onResume`が呼ばれ、破棄を免れる。
- `IndexedStack`は非表示側のWidgetもツリー上には残るため、実際に`onCancel`/`onResume`が発火するのは、ここでは「`LiveTimerView`をwatchしているWidget自体がツリーから完全になくなる」ケース(例えば`Navigator`で画面遷移する等)に限られる点に注意が必要。`IndexedStack`のままだと`LiveTimerView`は常にビルドされ続けるため、より厳密に`onCancel`/`onResume`を確認したい場合は、`Navigator.push`/`pop`のように実際にWidgetツリーから取り除かれる構成にするとよい。
- 「誰も見ていない間はタイマーを止め、CPU/バッテリーを消費しないようにする」という省リソース設計は実務でもよく使われるパターンで、通知の定期ポーリングや位置情報の定期取得など、バックグラウンドで動き続けさせたくない処理に応用できる。

---

### 問題28の回答例: ProviderObserver — provider変化をログに記録する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem28.g.dart';

@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
}

class AppProviderLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    debugPrint('${context.provider}: $previousValue -> $newValue');
  }
}

class ObservedCounterApp extends StatelessWidget {
  const ObservedCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      observers: [AppProviderLogger()],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: Consumer(
              builder: (context, ref, child) {
                final count = ref.watch(counterProvider);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Count: $count'),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(counterProvider.notifier).increment();
                      },
                      child: const Text('+1'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
```

**解説**
- `ProviderObserver`を継承し、`didUpdateProvider`(既存プロバイダの値が更新されたとき)をオーバーライドすることで、アプリ全体のあらゆるプロバイダの変化を1箇所で観測できる。他にも`didAddProvider`(初回作成時)、`didDisposeProvider`(破棄時)、`providerDidFail`(エラー発生時)などのフックが用意されている。
- `ProviderScope(observers: [AppProviderLogger()], child: ...)` のように、アプリのルートで一度登録するだけで、そのスコープ配下のすべてのプロバイダの変化がロギング対象になる。個々のプロバイダに`ref.onDispose`等を仕込んで回る必要がなく、横断的な監視・デバッグに向いている。
- 実務では、この仕組みを使ってRiverpodの状態変化をSentryなどの監視サービスに送信したり、開発時にRiverpodの動きを可視化するツール(DevToolsの拡張等)を実装したりする用途に使われる。`counterProvider`を操作するたびに`${context.provider}: 0 -> 1`のようなログがコンソールに出力されることを確認できる。

---

## 7. Widgetとの統合

### 問題29の回答例: ConsumerWidget と Consumer — 部分的なリビルドの絞り込み

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem29.g.dart';

@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
}

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('CounterScreen build');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('カウンターデモ'),
        Consumer(
          builder: (context, ref, child) {
            debugPrint('Consumer builder called');
            final count = ref.watch(counterProvider);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Count: $count'),
                ElevatedButton(
                  onPressed: () {
                    ref.read(counterProvider.notifier).increment();
                  },
                  child: const Text('+1'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
```

**解説**
- `CounterScreen`は`ConsumerWidget`ではなく通常の`StatelessWidget`なので、カウンタの値がいくら変わっても`CounterScreen.build`自体は最初の1回しか呼ばれない(「CounterScreen build」のログは1回だけ出る)。変化を検知してリビルドされるのは、`Consumer`の`builder`に渡された部分だけ(「Consumer builder called」のログはボタンを押すたびに出る)。
- これはflutter_hooks版で`AnimatedBuilder`が「アニメーション値が変わるたびに`builder`だけを再実行し、ウィジェットツリー全体の無駄な再構築を避ける」のと同じ発想。画面の大部分が静的で、一部分だけが動的に変化する場合、その動的な部分だけを`Consumer`で囲むことでリビルドの範囲を最小化できる。
- `ConsumerWidget`を使うか`Consumer`を使うかの判断基準は、「画面(Widget)全体がプロバイダの変化に応じて変わってよいか」「一部だけを切り出して局所化したいか」。小さい画面では`ConsumerWidget`で十分だが、大きな画面の一部だけがリアルタイムに変化する場合は`Consumer`での絞り込みがパフォーマンス上有効になる。

---

### 問題30の回答例: ConsumerStatefulWidget — StatefulWidgetとRiverpodを併用する

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem30.g.dart';

@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
}

class WelcomeView extends ConsumerStatefulWidget {
  const WelcomeView({super.key});

  @override
  ConsumerState<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends ConsumerState<WelcomeView> {
  @override
  void initState() {
    super.initState();
    debugPrint('WelcomeView initialized, current count: ${ref.read(counterProvider)}');
  }

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(counterProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Count: $count'),
        ElevatedButton(
          onPressed: () => ref.read(counterProvider.notifier).increment(),
          child: const Text('+1'),
        ),
      ],
    );
  }
}
```

**解説**
- `ConsumerStatefulWidget`/`ConsumerState<T>`は、Riverpodの`ref`を使いつつ、`initState`/`dispose`のような`State`のライフサイクルフックや、独自のミュータブルなインスタンスフィールド(`AnimationController`など)を併用したい場合に使う。`ConsumerState`では`ref`がインスタンスプロパティとして自動的に使えるようになる。
- `initState()`の中では`ref.read`が使える(値を1回だけ読む分には問題ない)が、`ref.watch`は使えない。これは`initState`が「Widgetがまだ完全に構築される前」の段階であり、この時点で`watch`による購読を張っても、その後のリビルドの仕組みと整合しないため。値の変化を継続的に見たい場合は、通常どおり`build()`メソッド内で`ref.watch`を使う。
- `StatelessWidget`ベースの`HookConsumerWidget`(問題31)と迷う場面もあるが、既存の`StatefulWidget`ベースのコード(例えば`TextEditingController`を手動で`dispose`する必要がある画面)にRiverpodを後から組み込みたい場合は`ConsumerStatefulWidget`の方が既存パターンとの親和性が高い。

---

### 問題31の回答例: HookConsumerWidget — flutter_hooksとRiverpodの併用

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem31.g.dart';

@riverpod
Future<String> userName(Ref ref, int userId) async {
  await Future<void>.delayed(const Duration(milliseconds: 100));
  return 'User#$userId';
}

class UserNameSwitchView extends HookConsumerWidget {
  const UserNameSwitchView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = useState(1);
    final name = ref.watch(userNameProvider(userId.value));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        switch (name) {
          AsyncValue(:final value?) => Text(value),
          AsyncValue(error: != null) => const Text('Error'),
          AsyncValue() => const CircularProgressIndicator(),
        },
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => userId.value--,
              child: const Text('-'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('userId: ${userId.value}'),
            ),
            ElevatedButton(
              onPressed: () => userId.value++,
              child: const Text('+'),
            ),
          ],
        ),
      ],
    );
  }
}
```

**解説**
- `HookConsumerWidget`は`HookWidget`と`ConsumerWidget`の両方の機能を1つのクラスで提供する。`build(BuildContext context, WidgetRef ref)`という`ConsumerWidget`と同じシグネチャを持ちつつ、内部で`useState`のようなflutter_hooksのフックも呼び出せる。
- `userId`(どのユーザーを表示するか、というこの画面だけのローカルなUI状態)は`useState`で管理し、`name`(実際のデータ取得結果、他の画面と共有されうる非同期状態)はRiverpodの`userNameProvider`(family)で管理するという役割分担にしている。「このWidgetだけが必要とする一時的な値」と「アプリ全体・複数画面で共有されうる値」を明確に区別して管理することで、それぞれに適した仕組み(hooksとRiverpod)を選べる。
- `userId.value`が変わるたびに`ref.watch(userNameProvider(userId.value))`の引数が変わり、異なるfamilyインスタンスをwatchすることになる。これにより「ローカル状態の変化に応じて、動的に別のプロバイダを参照先として切り替える」という組み合わせパターンが実現できる。

---

### 問題32の回答例: ProviderScopeのoverrides — モック実装への差し替え

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem32.g.dart';

@riverpod
String greetingSource(Ref ref) => 'production';

class GreetingSourceView extends ConsumerWidget {
  const GreetingSourceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(greetingSourceProvider);

    return Text('source: $source');
  }
}

class GreetingSourceComparisonView extends StatelessWidget {
  const GreetingSourceComparisonView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('通常のProviderScope配下:'),
        GreetingSourceView(),
        SizedBox(height: 16),
        Text('overridesで差し替えたProviderScope配下:'),
        ProviderScope(
          overrides: [],
          child: GreetingSourceView(),
        ),
      ],
    );
  }
}
```

**解説**
- `ProviderScope(overrides: [greetingSourceProvider.overrideWithValue('test-override')], child: ...)`のように、ネストした`ProviderScope`に`overrides`を指定すると、その`ProviderScope`配下でだけプロバイダの実装(または返す値)を差し替えられる。差し替えなかった部分(この例ではルートの`ProviderScope`直下)は通常どおり`'production'`を返す。
- `overrideWithValue(value)`は「常に固定の値を返すようにする」もっとも単純な差し替え方。ほかに`overrideWith(Provider相当の実装)`を使えば、差し替え後の値を計算するロジックそのものを丸ごと入れ替えることもできる(例えばテスト用にネットワーク通信をしないモック実装に差し替える、など)。
- `docs/implementation-plan.md`で言及されている「`ShotAnalysisService`をモック→本実装に差し替える」という設計は、まさにこの`overrides`の仕組みを使うことを想定したもの。開発中はモック実装を`ProviderScope`のデフォルトにしておき、本番ビルドや統合テストの段階で本実装に`override`する、といった使い方につながる。

(上記コード例では`overrides: []`のプレースホルダーを実際に差し替える場合、`overrides: [greetingSourceProvider.overrideWithValue('test-override')]`のように指定してください。)

---

## 8. 発展

### 問題33の回答例: Mutation API — 更新操作の状態(Pending/Success/Error)を型で表現する(experimental)

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// Mutation/MutationState系のクラスはpublicなexportに含まれていないため、
// パッケージ内部のパスから直接importする(検証済み・教材用の暫定対応)。
import 'package:riverpod/src/framework.dart'
    show Mutation, MutationIdle, MutationPending, MutationError, MutationSuccess;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'problem33.g.dart';

@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
}

final incrementMutation = Mutation<int>();

class MutationCounterView extends ConsumerWidget {
  const MutationCounterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutationState = ref.watch(incrementMutation);
    final count = ref.watch(counterProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Count: $count'),
        switch (mutationState) {
          MutationPending() => const CircularProgressIndicator(),
          MutationError() => const Text('更新に失敗しました'),
          MutationSuccess(:final value) => Text('直近の更新結果: $value'),
          MutationIdle() => const Text('ボタンを押して更新'),
        },
        ElevatedButton(
          onPressed: mutationState is MutationPending
              ? null
              : () {
                  incrementMutation.run(ref, (tsx) async {
                    await Future<void>.delayed(const Duration(milliseconds: 200));
                    final notifier = tsx.get(counterProvider.notifier);
                    notifier.increment();
                    return tsx.get(counterProvider);
                  });
                },
          child: const Text('非同期で+1'),
        ),
      ],
    );
  }
}
```

**解説**
- **この問題で扱うMutation APIは、riverpod 3.3.2に実在しますが、公式ドキュメントが「experimental」(実験的機能で、メジャーバージョンを上げずに破壊的変更が入りうる)と明記している機能です。** さらに実際にriverpod 3.3.2/3.4.2のソースを確認したところ、`Mutation`や`MutationState`のサブクラス(`MutationIdle`/`MutationPending`/`MutationError`/`MutationSuccess`)は `package:riverpod/riverpod.dart` にも `package:hooks_riverpod/hooks_riverpod.dart` にも一切exportされていませんでした。これらは `lib/src/core/mutations.dart`(`part of '../framework.dart';`)にのみ定義されており、通常のpublic importでは到達できません。この回答例では `import 'package:riverpod/src/framework.dart' show Mutation, ...;` のように、パッケージ内部のパスを直接importすることで動作を確認しています(`flutter analyze` では `implementation_imports` / `depend_on_referenced_packages` の info レベルの警告が出ますが、エラーにはなりません)。実装前・利用前には必ず https://riverpod.dev/docs/concepts2/mutations で最新の状況を確認し、正式に一般公開APIとしてexportされるまでは本番コードでの採用を避けてください。
- 通常の`AsyncValue`は「データ取得(読み取り)の状態」を表すのに対し、`Mutation<T>`は「更新操作(書き込み)そのものの実行状態」を表す専用の型。`final incrementMutation = Mutation<int>();`のようにグローバル変数(または実務ではNotifierのstatic finalフィールド)として定義し、`ref.watch(incrementMutation)`することでUI側から実行状態を観測できる。
- `incrementMutation.run(ref, (tsx) async { ... })`の`tsx`は「トランザクション」のようなコンテキストオブジェクトで、`tsx.get(someProvider.notifier)`のようにして他のプロバイダ(この例では`counterProvider`)にアクセスし、実際の更新処理を行う。実行結果は`MutationSuccess`/`MutationError`/`MutationPending`/`MutationIdle`のいずれかとして`ref.watch(incrementMutation)`から観測でき、ちょうど`AsyncValue`の`data`/`error`/`loading`に相当する3+1状態を、より「操作」に特化した形でモデル化したものと理解するとよい。
- 実務でこの機能を採用する場合は、experimentalである旨とAPIが変わりうるリスクを踏まえ、影響範囲を限定した箇所から試験的に導入することを推奨する。
