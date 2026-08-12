# flutter_hooks 問題集 回答例

[flutter-hooks-exercises.md](./flutter-hooks-exercises.md) の回答例集です。問題番号が対応しています。
まずは自分で実装してから確認することをおすすめします。

---

## 1. Primitives(基本)

### 問題01の回答例: useState — カウンターを作る

```dart
class CounterView extends HookWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useState(0);

    return Column(
      children: [
        Text('Count: ${count.value}'),
        ElevatedButton(
          onPressed: () => count.value++,
          child: const Text('+1'),
        ),
      ],
    );
  }
}
```

**解説**
- `useState(0)` は `ValueNotifier<int>` を返す。初期値は0。
- `.value` で読み書きでき、更新すると自動でリビルドされる。
- `StatefulWidget` の `setState` に相当する処理を、状態変数の宣言だけで実現できるのがポイント。

---

### 問題02の回答例: useEffect — マウント時にログを出し、破棄時にクリーンアップする

```dart
class LoggerView extends HookWidget {
  const LoggerView({super.key});

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      debugPrint('mounted');
      return () => debugPrint('disposed');
    }, []);

    return const Placeholder();
  }
}
```

**解説**
- `keys` に空リスト `[]` を渡すと、`effect` 本体はウィジェットのライフサイクル中で最初の1回しか実行されない(`initState` 相当)。
- `effect` の戻り値として関数を返すと、それがウィジェット破棄時(または `keys` が変わって再実行される直前)に呼ばれる(`dispose` 相当)。
- `keys` を省略すると `useMemoized` と同様デフォルトで `const []` 扱いになるため、明示しなくても同じ挙動になるが、意図を明確にするため明示するのが推奨。

---

### 問題03の回答例: useMemoized — 重い計算結果をキャッシュする

```dart
class FibonacciView extends HookWidget {
  const FibonacciView({super.key, required this.n});

  final int n;

  @override
  Widget build(BuildContext context) {
    final result = useMemoized(() => _slowFibonacci(n), [n]);

    return Text('fibonacci($n) = $result');
  }
}
```

**解説**
- `useMemoized` は初回呼び出し時に `valueBuilder` を実行して結果をキャッシュし、以降のリビルドでは `keys` が変わらない限り再計算しない。
- `keys` に `[n]` を渡しているため、`n` が変化したときだけ `_slowFibonacci` が再実行される。他のstate変更によるリビルドでは再計算されない。
- もし `useMemoized` を使わず毎回 `_slowFibonacci(n)` を直接呼んでいたら、無関係な状態変更でのリビルドのたびに再計算されてしまい、パフォーマンスが悪化する。

---

### 問題04の回答例: useCallback — 子ウィジェットへ渡す関数インスタンスを安定させる

```dart
class SearchBox extends HookWidget {
  const SearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    final query = useState('');

    final onChanged = useCallback<void Function(String)>((value) {
      query.value = value;
    }, []);

    return Column(
      children: [
        Text('query: ${query.value}'),
        TextField(onChanged: onChanged),
      ],
    );
  }
}
```

**解説**
- `useCallback(callback, keys)` は内部的に `useMemoized(() => callback, keys)` を呼んでいるだけで、「関数インスタンスをキャッシュする」という点では `useMemoized` と全く同じ仕組み。
- `keys` に `[]` を渡しているため、`onChanged` は常に同じ関数インスタンスを指す。`const` にできないウィジェットでも、コールバックの同一性を保つことで無駄な再構築を避けやすくなる。
- 注意点として、このコールバックは `query`(クロージャで捕捉した変数)そのものは変わらない(`useState` が返す `ValueNotifier` インスタンスは不変)ため、`keys: []` でも常に最新の `query` を参照できる。もし `query.value` 自体をクロージャの外から直接使う設計だった場合は `keys` の設計に注意が必要。

---

### 問題05の回答例: useRef — リビルドを引き起こさない可変値を保持する

```dart
class TapCounterView extends HookWidget {
  const TapCounterView({super.key});

  @override
  Widget build(BuildContext context) {
    final tapCountRef = useRef(0);
    final displayedCount = useState(0);

    return Column(
      children: [
        Text('5回タップごとに更新されるカウンタ: ${displayedCount.value}'),
        ElevatedButton(
          onPressed: () {
            tapCountRef.value++;
            if (tapCountRef.value % 5 == 0) {
              displayedCount.value = tapCountRef.value;
            }
          },
          child: const Text('タップ'),
        ),
      ],
    );
  }
}
```

**解説**
- `useRef(0)` が返す `ObjectRef<int>` の `.value` を書き換えても、それ自体はリビルドを起こさない。1〜4回目のタップでは `tapCountRef.value` だけが増え、画面は再描画されない。
- 5の倍数になったタイミングで `useState` の `.value` を更新することで、初めてリビルドが起きる。
- `useRef` は「毎レンダリングで値を保持したいが、その値の変化自体はUIに影響しない/直接反映したくない」場面(例: 直近のタップ時刻、デバウンス用のタイマー参照など)に向いている。

---

### 問題06の回答例: useContext — カスタムhook内でBuildContextを取得する

```dart
bool useIsDarkMode() {
  final context = useContext();
  return Theme.of(context).brightness == Brightness.dark;
}

class ThemeLabelView extends HookWidget {
  const ThemeLabelView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = useIsDarkMode();

    return Text(isDark ? 'ダークモード' : 'ライトモード');
  }
}
```

**解説**
- `HookWidget.build(BuildContext context)` の中では `context` 引数が既にあるため、`useContext()` をわざわざ呼ぶ必要はない。`useContext` が真価を発揮するのは、`ThemeLabelView.build` のように `context` を直接受け取れない「カスタムhook関数」の内部。
- カスタムhookは「`use` から始まる関数で、内部で他のhookを呼び出せる」という規約に従うだけの普通のDart関数。今回のように「`context` を使った処理」をロジックごと再利用可能な形に切り出せるのが利点。
- `useContext()` は必ずフックのビルドコンテキスト(`HookWidget` のビルド中)で呼ぶ必要があり、非同期コールバックの中などタイミングがずれた場所で呼ぶとエラーになる点に注意。

---

### 問題07の回答例: useValueChanged — propsの変化を検知して副作用を実行する

```dart
class ScoreChangeView extends HookWidget {
  const ScoreChangeView({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final diff = useValueChanged<int, int>(
      score,
      (oldScore, oldResult) => score - oldScore,
    );

    return Text(diff == null ? '変化なし' : '変化量: ${diff >= 0 ? '+' : ''}$diff');
  }
}
```

**解説**
- `useValueChanged<T, R>(value, valueChanged)` は、`value`(ここでは `score`)が前回のビルド時と異なる場合にだけ `valueChanged(oldValue, oldResult)` を呼び出し、その戻り値を返す。`value` が変わらなければ前回の戻り値がそのまま返る。
- 初回ビルド時はコールバックが呼ばれないため、戻り値は `null`(`R?`)になる。今回は `diff == null` を「変化なし」の初期表示として扱っている。
- `StatefulWidget` の `didUpdateWidget(oldWidget)` で `widget.score != oldWidget.score` を判定していた処理を、hookの中に閉じ込められる点が利点。

---

## 2. 非同期(dart:async)

### 問題08の回答例: useFuture — Future の状態をUIに反映する

```dart
class UserNameView extends HookWidget {
  const UserNameView({super.key});

  @override
  Widget build(BuildContext context) {
    final future = useMemoized(() => _fetchUserName());
    final snapshot = useFuture(future);

    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return Text('エラー: ${snapshot.error}');
    }
    return Text(snapshot.data ?? '');
  }
}
```

**解説**
- `useMemoized(() => _fetchUserName())`(`keys` 省略 = `const []`)により、`Future` インスタンスはウィジェットの生存期間中1回しか生成されない。これを省略して `useFuture(_fetchUserName())` のように直接書くと、リビルドのたびに新しい `Future` が生成されて `useFuture` に渡り、無限にローディング状態を繰り返すバグになる。
- `useFuture` が返す `AsyncSnapshot<T>` は `FutureBuilder` の `snapshot` と全く同じ型。`connectionState` / `hasData` / `hasError` / `data` / `error` の使い方も共通。

---

### 問題09の回答例: useStream — Streamの値をリアルタイムに表示する

```dart
class TickerView extends HookWidget {
  const TickerView({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = useMemoized(
      () => Stream<int>.periodic(const Duration(seconds: 1), (i) => i),
    );
    final snapshot = useStream(stream);

    return Text('count: ${snapshot.data ?? 0}');
  }
}
```

**解説**
- `useFuture` と同様、`Stream` インスタンスも `useMemoized` で1回だけ生成しないと、リビルドのたびに新しいStreamが作られ、値が流れ続けない/再購読が繰り返されるといった不具合につながる。
- `useStream` は継続的に発生するイベントを購読する用途、`useFuture` は1回きりの結果を購読する用途と使い分ける。
- `Stream.periodic` はデフォルトでは1つの購読者しか持てない(single-subscription)ため、複数箇所で同じStreamインスタンスを `useStream` すると2つ目でエラーになる点にも注意。

---

### 問題10の回答例: useStreamController — 自動破棄されるStreamControllerを作る

```dart
class ChatInputView extends HookWidget {
  const ChatInputView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useStreamController<String>();
    final snapshot = useStream(controller.stream);

    return Column(
      children: [
        Text('last message: ${snapshot.data ?? ''}'),
        TextField(
          onSubmitted: (value) => controller.add(value),
        ),
      ],
    );
  }
}
```

**解説**
- `useStreamController<String>()` は `StreamController<String>` を生成し、ウィジェット破棄時に自動で `close()` してくれる。手動管理であれば `initState` で `StreamController()`、`dispose` で `controller.close()` を書く必要があった。
- `controller.stream` を `useStream` に渡すことで、コントローラに `add` した値を即座にUIへ反映できる。`StreamController` はデフォルトでbroadcastではないため、`.stream` を複数箇所で購読したい場合は `useStreamController(sync: ...)` の代わりに `broadcast: true` 相当のオプションや `.stream.asBroadcastStream()` の検討が必要になる(今回は1箇所のみの購読なので問題ない)。

---

### 問題11の回答例: useOnStreamChange — 購読はするが値をUIに持たない

```dart
class ErrorToastView extends HookWidget {
  const ErrorToastView({super.key, required this.errorStream});

  final Stream<String> errorStream;

  @override
  Widget build(BuildContext context) {
    useOnStreamChange<String>(
      errorStream,
      onData: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
    );

    return const SizedBox.shrink();
  }
}
```

**解説**
- `useStream` は「値をUIの一部として表示したい」場面向けで `AsyncSnapshot` を返すが、`useOnStreamChange` は「値そのものはUIに持たず、イベント発生時に副作用だけ起こしたい」場面向けで戻り値を使わなくてよい設計になっている。
- 今回のように毎回SnackBarを出すだけの用途では、`useStream` の `AsyncSnapshot` を経由して `useEffect` で監視するよりも、`useOnStreamChange` を使う方が意図が明確でコード量も少ない。
- `onData` 以外にも `onError` / `onDone` を指定でき、エラー発生時やStream終了時の副作用もまとめて登録できる。

---

## 3. Animation

### 問題12の回答例: useAnimationController — 自動破棄されるAnimationControllerでフェードイン

```dart
class FadeInView extends HookWidget {
  const FadeInView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 1),
    );

    useEffect(() {
      controller.forward();
      return null;
    }, []);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Opacity(
        opacity: controller.value,
        child: const FlutterLogo(size: 100),
      ),
    );
  }
}
```

**解説**
- `useAnimationController` は内部で `useSingleTickerProvider` 相当のvsyncを自動生成し、コントローラ自身の `dispose()` もウィジェット破棄時に自動で行う。`StatefulWidget` + `SingleTickerProviderStateMixin` を書く必要がない。
- `useEffect(() { controller.forward(); return null; }, [])` により「マウント時に1回だけ再生開始」を実現している。`return null` はクリーンアップ不要であることを明示している(クリーンアップ関数を返さないなら省略時と同じ意味だが、意図を明確にするため明示している)。
- `AnimatedBuilder` はコントローラの値が変わるたびに `builder` だけを再実行し、ウィジェットツリー全体の無駄な再構築を避ける定石パターン。

---

### 問題13の回答例: useAnimation — Animationの現在値だけを購読する

```dart
class FadeInViewV2 extends HookWidget {
  const FadeInViewV2({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 1),
    );

    useEffect(() {
      controller.forward();
      return null;
    }, []);

    final value = useAnimation(controller);

    return Opacity(
      opacity: value,
      child: const FlutterLogo(size: 100),
    );
  }
}
```

**解説**
- `useAnimation(animation)` は内部で `animation` にリスナーを登録し、値が変わるたびに `HookWidget` 全体をリビルドする。`AnimatedBuilder` を使わずに済む分コードは短くなるが、「アニメーション中は `build` メソッド全体が毎フレーム呼ばれる」という点は理解しておく必要がある。
- ツリーの一部だけを再構築したい(パフォーマンスを細かく制御したい)場合は問題12のように `AnimatedBuilder` を使う方が適しており、シンプルさを優先するなら `useAnimation` が適している、というトレードオフがある。

---

### 問題14の回答例: useSingleTickerProvider — 自前のAnimationControllerにvsyncを供給する

```dart
class PulseView extends HookWidget {
  const PulseView({super.key});

  @override
  Widget build(BuildContext context) {
    final ticker = useSingleTickerProvider();
    final controller = useMemoized(
      () => AnimationController(
        vsync: ticker,
        duration: const Duration(milliseconds: 500),
      ),
    );

    useEffect(() {
      controller.repeat(reverse: true);
      return controller.dispose;
    }, []);

    final value = useAnimation(controller);

    return Transform.scale(
      scale: 0.5 + value,
      child: const FlutterLogo(size: 100),
    );
  }
}
```

**解説**
- `useAnimationController` はvsyncも自動破棄も両方面倒を見てくれる「全部入り」hookだが、内部で `AnimationController` をカスタマイズしたい特殊なケース(独自のサブクラスを使いたい等)では、`useSingleTickerProvider` で `vsync` だけを取得し、`AnimationController` 自体は自分で管理することもできる。
- その場合、自動破棄はされないため、`useEffect` のクリーンアップで明示的に `controller.dispose()` を呼ぶ必要がある(`return controller.dispose;` は `return () => controller.dispose();` と同じ意味)。
- 通常のユースケースでは問題12・13のように `useAnimationController` を使う方がシンプルで安全。このhookは「vsyncだけ欲しい」という限定的な場面で使う。

---

## 4. Listenable

### 問題15の回答例: useListenable — 任意のListenableを購読してリビルドする

```dart
class Counter extends ChangeNotifier {
  int value = 0;

  void increment() {
    value++;
    notifyListeners();
  }
}

class CounterListenableView extends HookWidget {
  const CounterListenableView({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = useMemoized(() => Counter());
    useListenable(counter);

    return Column(
      children: [
        Text('${counter.value}'),
        ElevatedButton(
          onPressed: counter.increment,
          child: const Text('+1'),
        ),
      ],
    );
  }
}
```

**解説**
- `useListenable(counter)` は `counter.addListener(...)` を内部で行い、`notifyListeners()` が呼ばれるたびに `HookWidget` をリビルドする(ウィジェット破棄時には自動で `removeListener` される)。
- `useListenable` 自体は `counter`(Listenableそのもの)を返すだけで、値の取り出しは呼び出し側(`counter.value`)で行う必要がある。これは `useValueListenable` のように値そのものを返すhookとの違い。
- `ChangeNotifier` を使った独自の状態クラスをリスト等に複数個持つ場合、それぞれの `dispose()` を手動で呼ぶ設計にはまだ注意が必要(今回は `useMemoized` で生成しただけで自動破棄はされないため、実務では `useListenable` と組み合わせて手動 `dispose` する設計、あるいはRiverpod等の状態管理ライブラリに任せる設計が一般的)。

---

### 問題16の回答例: useListenableSelector — 必要な部分だけを見てリビルドを絞り込む

```dart
class Profile extends ChangeNotifier {
  String name = 'Alice';
  int age = 20;

  void setName(String value) {
    name = value;
    notifyListeners();
  }

  void setAge(int value) {
    age = value;
    notifyListeners();
  }
}

class AgeOnlyView extends HookWidget {
  const AgeOnlyView({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final age = useListenableSelector(profile, () => profile.age);

    return Text('age: $age');
  }
}
```

**解説**
- `useListenable(profile)` を使った場合、`profile.setName(...)` を呼んでも `profile.setAge(...)` を呼んでも同様にリビルドが発生してしまう(Listenable全体の変化を見ているため)。
- `useListenableSelector(profile, () => profile.age)` は、`profile` が通知するたびに `selector` を実行し、その **戻り値が前回と変わったときだけ** リビルドする。`name` だけが変わったときは `selector` の戻り値(`age`)は変化しないため、`AgeOnlyView` は再描画されない。
- 大きな状態オブジェクトの一部だけをUIが必要とする場合に、無駄な再描画を防ぐための最適化手段。

---

### 問題17の回答例: useValueListenable — ValueListenableの値を購読する

```dart
class VolumeView extends HookWidget {
  const VolumeView({super.key, required this.volume});

  final ValueNotifier<double> volume;

  @override
  Widget build(BuildContext context) {
    final currentValue = useValueListenable(volume);

    return Slider(
      value: currentValue,
      onChanged: (v) => volume.value = v,
    );
  }
}
```

**解説**
- `useValueListenable(valueListenable)` は `ValueListenableBuilder` の中身をhook化したもので、`valueListenable.value` の変化を購読し、その値 `T` を直接返す。
- `useListenable` と異なり、戻り値がすでに「値そのもの」なので、呼び出し側で `.value` を再度参照する必要がない。
- `volume`(`ValueNotifier`)自体はこのウィジェットの外(親や状態管理レイヤー)で生成されている想定のため、このhookでは破棄の責任を持たない点にも注意(破棄は所有者側が行う)。

---

### 問題18の回答例: useValueNotifier — 自動破棄されるValueNotifierを作る

```dart
class BrightnessSliderView extends HookWidget {
  const BrightnessSliderView({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = useValueNotifier(0.5);
    final currentValue = useValueListenable(brightness);

    return Slider(
      value: currentValue,
      onChanged: (v) => brightness.value = v,
    );
  }
}
```

**解説**
- `useValueNotifier(0.5)` は `ValueNotifier<double>` を生成し、ウィジェット破棄時に自動で `dispose()` する。ただし、これ単体では値の変化を購読(リビルド)しない点が `useState` との重要な違い。
- リビルドさせたい場合は問題17と同様、`useValueListenable` と組み合わせる必要がある。「生成・破棄」と「購読」の責務が分かれているのが `useValueNotifier` の設計思想。
- 単純にリビルドもさせたいだけなら `useState` の方がシンプル。`useValueNotifier` は「`ValueNotifier` インスタンス自体を、購読せずに子ウィジェットへ渡したい」場面(例: 子ウィジェット側で `ValueListenableBuilder` を使う設計)で真価を発揮する。

---

### 問題19の回答例: useOnListenableChange — 値を持たずリスナーだけ登録する

```dart
class AutoScrollView extends HookWidget {
  const AutoScrollView({
    super.key,
    required this.controller,
    required this.scrollController,
  });

  final TextEditingController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    useOnListenableChange(controller, () {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });

    return const SizedBox.shrink();
  }
}
```

**解説**
- `useListenable` は購読対象の変化のたびに **このウィジェット自体をリビルド** するが、`useOnListenableChange` はリビルドせずコールバックだけを実行する。今回のように「テキスト変化をトリガーにスクロール位置を操作したいだけで、このウィジェット自体には表示すべき状態がない」場面に向いている。
- `scrollController.hasClients` のチェックを入れているのは、`ListView` 等がまだ描画(アタッチ)されていないタイミングで `jumpTo` を呼ぶと例外になるため。
- `useOnListenableChange` は登録したリスナーをウィジェット破棄時に自動で解除してくれるため、`initState` で `addListener`、`dispose` で `removeListener` していた定型コードが不要になる。

---

## 5. 状態管理・ライフサイクル・その他

### 問題20の回答例: useReducer — Redux風の状態管理をする

```dart
enum CounterAction { increment, decrement, none }

int counterReducer(int state, CounterAction action) {
  switch (action) {
    case CounterAction.increment:
      return state + 1;
    case CounterAction.decrement:
      return state - 1;
    case CounterAction.none:
      return state;
  }
}

class ReducerCounterView extends HookWidget {
  const ReducerCounterView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = useReducer(
      counterReducer,
      initialState: 0,
      initialAction: CounterAction.none,
    );

    return Column(
      children: [
        Text('${store.state}'),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => store.dispatch(CounterAction.increment),
              child: const Text('+'),
            ),
            ElevatedButton(
              onPressed: () => store.dispatch(CounterAction.decrement),
              child: const Text('-'),
            ),
          ],
        ),
      ],
    );
  }
}
```

**解説**
- `useReducer(reducer, initialState: ..., initialAction: ...)` は `Store<StateT, ActionT>` を返し、`store.state` で現在値を、`store.dispatch(action)` で状態遷移を行う。
- `useState` は「値を直接書き換える」設計だが、`useReducer` は「起こりうる状態遷移(アクション)を列挙し、`reducer` 関数に遷移ロジックを一元化する」設計。状態遷移の種類が増えたり、遷移ロジックが複雑になったりするほど、`useState` の乱立よりも見通しが良くなる。
- `reducer` 関数はhookの外の純粋関数として書けるため、ウィジェットに依存せず単体テストしやすいという利点もある。
- ハマりどころ: `initialState` だけでなく `initialAction` も必須引数。実装(`_ReducerHookState`)は初回ビルド時に `state = reducer(initialState, initialAction)` を実行してから `state` を確定させるため、`initialAction` に `increment` のような「値を変えるアクション」を渡すと、初期表示がいきなり1からになってしまう。今回のように「初期状態をそのまま使いたい」場合は、`none` のような何もしないアクションを用意しておく必要がある。

---

### 問題21の回答例: usePrevious — 直前のレンダリング時の値を取得する

```dart
class TemperatureView extends HookWidget {
  const TemperatureView({super.key, required this.temperature});

  final double temperature;

  @override
  Widget build(BuildContext context) {
    final previous = usePrevious(temperature);

    IconData? icon;
    if (previous != null && temperature != previous) {
      icon = temperature > previous ? Icons.arrow_upward : Icons.arrow_downward;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$temperature℃'),
        if (icon != null) Icon(icon),
      ],
    );
  }
}
```

**解説**
- `usePrevious(val)` は「今回のビルドの `val` を保持しておき、次回のビルド時にそれを返す」という単純な仕組み。初回ビルドでは保持された値がまだないため `null` を返す。
- `useValueChanged` と似ているが、`usePrevious` は「前回の値そのもの」を返すだけで比較や計算ロジックを持たない点がシンプル。今回のように呼び出し側で自由に比較ロジック(上昇/下降判定)を書きたい場合に向いている。
- 毎ビルドごとに値を保持する仕組みのため、`temperature` が変わらないリビルドでは `previous == temperature` となり、アイコンは表示されない(要件通り)。

---

### 問題22の回答例: useIsMounted — 非同期処理後の安全なsetState代替

```dart
class SafeAsyncButton extends HookWidget {
  const SafeAsyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    final status = useState('Idle');
    final isMounted = useIsMounted();

    return Column(
      children: [
        Text(status.value),
        ElevatedButton(
          onPressed: () async {
            status.value = 'Loading';
            await Future<void>.delayed(const Duration(seconds: 2));
            if (isMounted()) {
              status.value = 'Done';
            }
          },
          child: const Text('実行'),
        ),
      ],
    );
  }
}
```

**解説**
- `useIsMounted()` は `bool Function()`(呼び出し可能な `IsMounted`)を返す。`isMounted()` のように関数として呼び出すことで、その時点でウィジェットがまだツリーに存在するかを確認できる。
- 非同期処理(`await` の後)は完了時にウィジェットが既に破棄されている可能性があり、破棄後に `.value` を更新しようとすると例外や警告が発生する。`isMounted()` でガードすることでこれを防げる。
- `StatefulWidget` では `if (mounted) { setState(...) }` と書いていた処理と全く同じ役割を果たす。
- 補足: `useIsMounted` はFlutterの `BuildContext.mounted`(Flutter 3.7以降で追加された、より簡潔な確認方法)が使えるようになったため非推奨(deprecated)扱いになっている。`HookWidget.build` の `context` を非同期コールバック内でも保持できる場合は `context.mounted` を使う方が今後は推奨されるが、本hookの動作を理解する教材としてはこのまま使って問題ない。

---

### 問題23の回答例: useReassemble — ホットリロード時にだけ処理を行う

```dart
class CacheClearingView extends HookWidget {
  const CacheClearingView({super.key});

  @override
  Widget build(BuildContext context) {
    useReassemble(() {
      debugPrint('reassembled: cache cleared');
    });

    return const Placeholder();
  }
}
```

**解説**
- `useReassemble(callback)` はFlutterの `State.reassemble()`(主にホットリロード時に呼ばれる)に相当するタイミングでコールバックを実行する。
- 通常のリビルドや `useEffect` とは異なるタイミングで発火するため、「開発中だけ有効にしたいデバッグ処理」(キャッシュのクリア、ログの再初期化など)に限定して使うのが基本用途。
- 実行結果を確認するには、実際にアプリを起動した状態でホットリロード(IDEの再読み込みボタンや `r` キー)を行う必要がある。通常のホットリスタートやウィジェットの通常リビルドでは呼ばれない。

---

### 問題24の回答例: useAutomaticKeepAlive — リスト内アイテムの状態を保持する

```dart
class KeepAliveTile extends HookWidget {
  const KeepAliveTile({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    useAutomaticKeepAlive();
    final isOn = useState(false);

    return ListTile(
      title: Text(label),
      trailing: Switch(
        value: isOn.value,
        onChanged: (v) => isOn.value = v,
      ),
    );
  }
}
```

**解説**
- `ListView.builder` 等は既定でビューポート外に出たアイテムを破棄し、状態(`useState` 等)も失われる。`useAutomaticKeepAlive()` を呼ぶことで、そのウィジェットが `AutomaticKeepAliveClientMixin` を実装した場合と同様に「保持してほしい」と親の `Viewport` に伝えられる。
- `StatefulWidget` で同じことをする場合、`AutomaticKeepAliveClientMixin` を `with` し、`wantKeepAlive` を `true` にして `super.build(context)` を呼ぶ、といった定型コードが必要だったが、hookでは1行で済む。
- 多用するとメモリ上に保持されるウィジェットが増えるため、本当に状態保持が必要なアイテムにだけ使うのが望ましい。

---

### 問題25の回答例: useDebounced — 入力値のデバウンス処理をする

```dart
class DebouncedSearchView extends HookWidget {
  const DebouncedSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final rawQuery = useState('');
    final debouncedQuery = useDebounced(
      rawQuery.value,
      const Duration(milliseconds: 500),
    );

    return Column(
      children: [
        TextField(onChanged: (v) => rawQuery.value = v),
        Text('入力中: ${rawQuery.value}'),
        Text('確定クエリ: ${debouncedQuery ?? ''}'),
      ],
    );
  }
}
```

**解説**
- `useDebounced(value, timeout)` は「`value` が変化してから `timeout` 経過するまでの間に再び変化がなければ、そのときの値を返す」というhook。戻り値の型は `T?` で、`timeout` が一度も経過していない最初の期間は `null` になる。
- 検索ボックスの `onChanged` のたびにAPIを叩くのではなく、`debouncedQuery` の変化を `useEffect` の `keys` に指定して監視すれば、「入力が落ち着いたときだけAPIを呼ぶ」という典型的な実装ができる。
- `TextEditingController` + `Timer` を自前で管理していた実装が、値の宣言だけで済むようになる。

---

### 問題26の回答例: useOverlayPortalController — オーバーレイの表示制御を行う

```dart
class HintOverlayView extends HookWidget {
  const HintOverlayView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useOverlayPortalController();

    return OverlayPortal(
      controller: controller,
      overlayChildBuilder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('ヒント'),
          ),
        ),
      ),
      child: ElevatedButton(
        onPressed: controller.toggle,
        child: const Text('トグル'),
      ),
    );
  }
}
```

**解説**
- `useOverlayPortalController()` は `OverlayPortalController` を生成し、自動破棄する。手動なら `initState` で生成、`dispose` で破棄が必要だった。
- `OverlayPortal` は `Overlay`(通常は `MaterialApp`/`CupertinoApp` が用意する)にウィジェットを重ねて表示する仕組みで、`controller.show()` / `hide()` / `toggle()` で表示状態を操作する。ツールチップやカスタムドロップダウンの実装に使われる。
- 従来の `OverlayEntry` を手動で `Overlay.of(context).insert(...)` / `.remove()` していた実装より、宣言的に書けるのが利点。

---

## 6. コントローラ系(生成・自動破棄)

このカテゴリは共通して「`XxxController` を生成し、自動で `dispose()` する」というhookです。個別の解説では、それぞれのコントローラを **どのウィジェットと組み合わせて使うか** に焦点を当てています。

### 問題27の回答例: useTextEditingController — フォーム入力を管理する

```dart
class NicknameFieldView extends HookWidget {
  const NicknameFieldView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: '名無しさん');

    return TextField(controller: controller);
  }
}
```

**解説**
- `useTextEditingController(text: '名無しさん')` は初期テキスト付きの `TextEditingController` を生成し、ウィジェット破棄時に自動で `dispose()` する。
- 引数の `text` は初回生成時のみ反映される。以降のリビルドで `text` 引数を変えても、既存のコントローラの中身は書き換わらない(`keys` を変える必要がある)点に注意。

---

### 問題28の回答例: useFocusNode — 入力欄のフォーカスを制御する

```dart
class FocusAwareFieldView extends HookWidget {
  const FocusAwareFieldView({super.key});

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    useListenable(focusNode);

    return TextField(
      focusNode: focusNode,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: focusNode.hasFocus ? Colors.blue : Colors.grey,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
      ),
    );
  }
}
```

**解説**
- `FocusNode` は `Listenable` を実装しているため、`useListenable(focusNode)` と組み合わせることで「フォーカス状態が変わるたびにリビルドする」処理を簡単に書ける。
- `enabledBorder` はフォーカスが当たっていない状態の見た目、`focusedBorder` はFlutterが自動的にフォーカス時に切り替えてくれるスタイルだが、今回はあえて `enabledBorder` 側も `hasFocus` を見て動的に変えることで、hookの購読が効いていることを確認しやすくしている。

---

### 問題29の回答例: useFocusScopeNode — フォーカスのスコープを管理する

```dart
class MultiFieldFormView extends HookWidget {
  const MultiFieldFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final scopeNode = useFocusScopeNode();

    return FocusScope(
      node: scopeNode,
      child: Column(
        children: [
          TextField(onSubmitted: (_) => scopeNode.nextFocus()),
          const TextField(),
        ],
      ),
    );
  }
}
```

**解説**
- `FocusScopeNode` は複数の `FocusNode` をグルーピングし、`nextFocus()` / `previousFocus()` のような「スコープ内での移動」操作を提供する。
- 今回のサンプルでは各 `TextField` に個別の `FocusNode` を明示的に渡していないが、`FocusScope` の直下にある `TextField` は自動的にこのスコープに属するため、`scopeNode.nextFocus()` で次のフィールドへ移動できる。
- フォームの入力欄が増えるほど、「Doneキーで次の欄へ」といったUXを実現する際にこのhookが役立つ。

---

### 問題30の回答例: useScrollController — スクロール位置を監視する

```dart
class ScrollToTopView extends HookWidget {
  const ScrollToTopView({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    useListenable(scrollController);

    final showButton =
        scrollController.hasClients && scrollController.offset > 200;

    return Scaffold(
      body: ListView.builder(
        controller: scrollController,
        itemCount: 100,
        itemBuilder: (context, index) => ListTile(title: Text('item $index')),
      ),
      floatingActionButton: showButton
          ? FloatingActionButton(
              onPressed: () => scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
}
```

**解説**
- `useListenable(scrollController)` により、スクロール位置(`offset`)が変わるたびにリビルドされる。`ScrollController` も `Listenable` を実装しているため、この組み合わせは `useFocusNode` の例(問題28)と同じパターン。
- `scrollController.offset` は `ListView` にアタッチされる前に参照すると例外になるため、`hasClients` で「まだ何もスクロール可能なビューに接続されていない」状態を弾いている。
- `animateTo` はアニメーション付きでスクロール位置を移動する。即座に移動させたい場合は `jumpTo` を使う。

---

### 問題31の回答例: usePageController — PageViewのページ状態を管理する

```dart
class OnboardingView extends HookWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController();
    final currentPage = useState(0);

    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: pageController,
            onPageChanged: (i) => currentPage.value = i,
            children: [
              Container(color: Colors.red),
              Container(color: Colors.green),
              Container(color: Colors.blue),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            return Container(
              margin: const EdgeInsets.all(4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentPage.value == i ? Colors.black : Colors.grey,
              ),
            );
          }),
        ),
      ],
    );
  }
}
```

**解説**
- `PageController` 自体は「現在のページ番号」を同期的に取り出せるプロパティを持たない(アニメーション中は小数になりうるため)。そのため、現在ページを画面に反映したい場合は `onPageChanged` コールバックで別途 `useState` に保存する必要がある。
- `useListenable(pageController)` で購読する方法もあるが、`page`(現在の正確な位置、小数を含む)を使った補間表示など高度な用途向けであり、単純な「今どのページか」を知りたいだけなら `onPageChanged` を使う方がシンプル。

---

### 問題32の回答例: useTabController — タブ切り替えを管理する

```dart
class CategoryTabView extends HookWidget {
  const CategoryTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useTabController(initialLength: 3);

    return Column(
      children: [
        TabBar(
          controller: controller,
          tabs: const [
            Tab(text: 'すべて'),
            Tab(text: 'お気に入り'),
            Tab(text: '最近'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: const [
              Center(child: Text('すべて')),
              Center(child: Text('お気に入り')),
              Center(child: Text('最近')),
            ],
          ),
        ),
      ],
    );
  }
}
```

**解説**
- `useTabController(initialLength: 3)` は `useAnimationController` と同じく、vsync(Ticker)を自動で用意してくれるため、`TickerProviderStateMixin` が不要になる。
- 通常 `DefaultTabController` ウィジェットを使う方法もあるが、`DefaultTabController` は `InheritedWidget` 経由でコントローラを暗黙的に共有する設計であるのに対し、`useTabController` は明示的に `controller` を受け渡す設計。コントローラをコード側から操作したい(例: ボタン押下で特定タブへ切り替える)場合は `useTabController` の方が扱いやすい。

---

### 問題33の回答例: useCupertinoTabController — iOS風タブバーを管理する

```dart
class IosStyleTabView extends HookWidget {
  const IosStyleTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useCupertinoTabController(initialIndex: 0);

    return CupertinoTabScaffold(
      controller: controller,
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'ホーム'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.search), label: '検索'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: '設定'),
        ],
      ),
      tabBuilder: (context, index) => Center(child: Text('タブ$index')),
    );
  }
}
```

**解説**
- `CupertinoTabController` は `TabController` と違い `vsync` を必要としない(タブ切り替えにアニメーションのTickerを使わない設計のため)。そのぶん `useCupertinoTabController` はシンプルに `index` の初期値だけを受け取る。
- `controller.index` を直接書き換えることでコードから任意のタブへ切り替えられる。`useTabController` の `animateTo` のようなアニメーション制御はなく、即座に切り替わる。
- DAN-DOのようなiOS風UIを目指すアプリでは、`CupertinoTabScaffold` + このhookの組み合わせが自然な選択肢になる。

---

### 問題34の回答例: useTransformationController — ピンチズームの変形状態を管理する

```dart
class ZoomableImageView extends HookWidget {
  const ZoomableImageView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useTransformationController();

    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            transformationController: controller,
            child: const FlutterLogo(size: 200),
          ),
        ),
        ElevatedButton(
          onPressed: () => controller.value = Matrix4.identity(),
          child: const Text('リセット'),
        ),
      ],
    );
  }
}
```

**解説**
- `TransformationController` は `ValueNotifier<Matrix4>` のサブクラスで、`InteractiveViewer` の拡大縮小・パン(移動)状態を表す変換行列を保持する。
- `controller.value = Matrix4.identity()` を代入すると、拡大率・移動量ともに初期状態(変換なし)に戻る。ユーザー操作(ピンチ)による更新も、プログラムからの代入も同じ `.value` を通して行われる。

---

### 問題35の回答例: useFixedExtentScrollController — 固定高さのホイールピッカーを作る

```dart
class HourPickerView extends HookWidget {
  const HourPickerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useFixedExtentScrollController(initialItem: 0);
    final selectedHour = useState(0);

    return Column(
      children: [
        Text('${selectedHour.value}時'),
        SizedBox(
          height: 200,
          child: ListWheelScrollView(
            controller: controller,
            itemExtent: 40,
            onSelectedItemChanged: (i) => selectedHour.value = i,
            children: List.generate(24, (i) => Center(child: Text('$i時'))),
          ),
        ),
      ],
    );
  }
}
```

**解説**
- `FixedExtentScrollController` は `ScrollController` のサブクラスで、`ListWheelScrollView` のように「全アイテムが同じ高さ(extent)を持つ」スクロールビュー専用に、`selectedItem`(現在中央に来ているindex)へのアクセスや `jumpToItem` / `animateToItem` を提供する。
- `usePageController` の例(問題31)と同様、選択中のindexそのものは `onSelectedItemChanged` コールバックで拾って別途状態に持つ必要がある。

---

### 問題36の回答例: useSearchController — 検索バー(SearchAnchor)を制御する

```dart
const _fruits = ['りんご', 'みかん', 'ぶどう', 'バナナ', 'メロン'];

class FruitSearchView extends HookWidget {
  const FruitSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useSearchController();

    return SearchAnchor(
      searchController: controller,
      builder: (context, controller) => IconButton(
        icon: const Icon(Icons.search),
        onPressed: controller.openView,
      ),
      suggestionsBuilder: (context, controller) {
        return _fruits
            .where((f) => f.contains(controller.text))
            .map((f) => ListTile(title: Text(f)));
      },
    );
  }
}
```

**解説**
- `SearchController` は `TextEditingController` を継承しており、`.text` で現在の入力値を取得できる。加えて `openView()` / `closeView()` で検索ビューの開閉を制御する。
- `SearchAnchor` の `builder`(閉じているときの見た目)と `suggestionsBuilder`(開いているときの候補一覧)はどちらもコールバック引数として渡ってくる `controller` を使う設計になっており、`useSearchController` で生成したものと同一のインスタンスが渡ってくる。

---

### 問題37の回答例: useDraggableScrollableController — ドラッグ可能なボトムシートを制御する

```dart
class ExpandableSheetView extends HookWidget {
  const ExpandableSheetView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useDraggableScrollableController();

    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ElevatedButton(
            onPressed: () => controller.animateTo(
              0.9,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),
            child: const Text('全開にする'),
          ),
        ),
        DraggableScrollableSheet(
          controller: controller,
          initialChildSize: 0.3,
          minChildSize: 0.1,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            color: Colors.white,
            child: ListView(
              controller: scrollController,
              children: const [Padding(padding: EdgeInsets.all(16), child: Text('シートの中身'))],
            ),
          ),
        ),
      ],
    );
  }
}
```

**解説**
- `DraggableScrollableController` の `size`(0.0〜1.0、画面高さに対する割合)を `animateTo` で操作することで、ユーザーのドラッグ操作なしにシートの開閉度をコードから制御できる。
- `builder` に渡ってくる `scrollController` は `DraggableScrollableSheet` が内部で管理する別のコントローラで、シート内のスクロール(中身が長いとき)専用のもの。`useDraggableScrollableController` で作った `controller`(シート全体の高さ制御用)とは役割が異なる点に注意。

---

### 問題38の回答例: useCarouselController — カルーセル(横スクロール一覧)を制御する

```dart
class PhotoCarouselView extends HookWidget {
  const PhotoCarouselView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useCarouselController();

    return CarouselView(
      controller: controller,
      itemExtent: 200,
      children: List.generate(
        5,
        (i) => Container(color: Colors.primaries[i % Colors.primaries.length]),
      ),
    );
  }
}
```

**解説**
- `CarouselController` は `ScrollController` のサブクラスで、Material 3 の `CarouselView` 専用に使う。基本的な使い方は他のスクロール系コントローラと同様。
- このカテゴリの多くのhookに共通することだが、「コントローラを外部から操作する必要がなければ、コントローラを渡さなくても各ウィジェットは動作する(内部で自動生成される)」。hookで明示的に生成するのは、`animateTo` などプログラムからの操作が必要な場合に限られる。

---

### 問題39の回答例: useExpansibleController — 展開/折りたたみを外部から制御する

```dart
class FaqTileView extends HookWidget {
  const FaqTileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useExpansibleController();

    return Column(
      children: [
        ElevatedButton(
          onPressed: controller.expand,
          child: const Text('開く'),
        ),
        ExpansionTile(
          controller: controller,
          title: const Text('質問'),
          children: const [Padding(padding: EdgeInsets.all(16), child: Text('回答'))],
        ),
      ],
    );
  }
}
```

**解説**
- `ExpansibleController` には `expand()` / `collapse()` / `isExpanded` があり、`ExpansionTile` のタイル部分をタップしなくても、任意のトリガー(今回は別ボタン)から開閉できる。
- flutter_hooksには `useExpansibleController` と(互換性のための旧名である)`useExpansionTileController` の2つの名前が存在するが、内部実装は同じもの。新規実装では `useExpansibleController` を使うのが推奨。

---

### 問題40の回答例: useSnapshotController — RepaintBoundaryのスナップショット化を制御する

```dart
class SnapshottedListView extends HookWidget {
  const SnapshottedListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useSnapshotController(allowSnapshotting: false);

    return Column(
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: () => controller.allowSnapshotting = true,
              child: const Text('開始'),
            ),
            ElevatedButton(
              onPressed: () => controller.allowSnapshotting = false,
              child: const Text('終了'),
            ),
          ],
        ),
        SnapshotWidget(
          controller: controller,
          child: const FlutterLogo(size: 150),
        ),
      ],
    );
  }
}
```

**解説**
- `SnapshotWidget` は、`controller.allowSnapshotting` が `true` の間、子ウィジェットの描画結果をラスタ画像としてキャッシュし、以降は再描画の代わりにそのキャッシュ画像を使い回すことでフレームレートを稼ぐ仕組み。
- 典型的には「アニメーション開始時に `allowSnapshotting = true` にしてスナップショット化 → アニメーション終了後に `false` に戻して通常描画に戻す」という使い方をする。今回のサンプルではボタンで手動切り替えできるようにして挙動を確認しやすくしている。
- 複雑な描画(多数のウィジェット、影や透明度を含むレイヤーなど)をアニメーションさせる際のパフォーマンス最適化テクニックの一つ。

---

### 問題41の回答例: useTreeSliverController — 階層構造(ツリー)の開閉を管理する

```dart
final _sampleTree = <TreeSliverNode<String>>[
  TreeSliverNode<String>(
    'フォルダA',
    children: <TreeSliverNode<String>>[
      TreeSliverNode<String>('ファイル1'),
      TreeSliverNode<String>('ファイル2'),
    ],
  ),
];

class FileTreeView extends HookWidget {
  const FileTreeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useTreeSliverController();

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            for (final node in _sampleTree) {
              controller.toggleNode(node);
            }
          },
          child: const Text('すべて展開'),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              TreeSliver<String>(
                tree: _sampleTree,
                controller: controller,
                treeNodeBuilder: (context, node, animationStyle) {
                  return Text(node.content.toString());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

**解説**
- `TreeSliver` / `TreeSliverController` はFlutterの比較的新しいウィジェットで、SDKのバージョンによってAPIの細部(`treeNodeBuilder` の引数構成や `toggleNode` の引数)が変わる可能性がある。実装時はIDEの補完・公式APIドキュメントで最新のシグネチャを確認してください。
- 考え方自体は他のコントローラ系hookと同じで、「ツリーの開閉状態」をコントローラが保持し、`useTreeSliverController` がその生成・自動破棄を担う。
- ハマりどころ: `TreeSliver<String>` のように型引数を指定しても、`treeNodeBuilder` に渡ってくる `node` の型は `TreeSliverNode<Object?>`(型消去された汎用シグネチャ)になる。そのため `node.content` は `Object?` として扱われ、`Text` に渡すには `.toString()` などで明示的に変換する必要がある。
- フォルダ階層や組織図のようなツリー構造をアプリ内に持つ場合の選択肢の一つ。

---

### 問題42の回答例: useWidgetStatesController — WidgetState(hover/pressed等)を管理する

```dart
class CustomHoverButtonView extends HookWidget {
  const CustomHoverButtonView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useWidgetStatesController();
    useListenable(controller);

    return MouseRegion(
      onEnter: (_) => controller.update(WidgetState.hovered, true),
      onExit: (_) => controller.update(WidgetState.hovered, false),
      child: GestureDetector(
        onTapDown: (_) => controller.update(WidgetState.pressed, true),
        onTapUp: (_) => controller.update(WidgetState.pressed, false),
        onTapCancel: () => controller.update(WidgetState.pressed, false),
        child: Container(
          padding: const EdgeInsets.all(16),
          color: controller.value.contains(WidgetState.hovered)
              ? Colors.blue.shade200
              : Colors.grey.shade200,
          child: const Text('Hover me'),
        ),
      ),
    );
  }
}
```

**解説**
- `WidgetStatesController` は `Set<WidgetState>`(`hovered` / `pressed` / `focused` / `disabled` 等)を保持する `ValueNotifier` 相当のクラスで、`ElevatedButton` などMaterialコンポーネント内部でも使われている仕組み。
- `controller.update(state, isActive)` で状態の追加/削除を行い、`WidgetStateProperty.resolveWith` 等と組み合わせることで「状態に応じてスタイルを切り替える」処理を宣言的に書ける(今回は簡略化のため直接 `contains` で判定している)。
- `useListenable(controller)` を忘れると、`update` を呼んでも画面が再描画されないため、色が変わらないバグになる点に注意。

---

## 7. アプリライフサイクル・プラットフォーム

### 問題43の回答例: useAppLifecycleState — アプリの状態(前面/背面)を購読する

```dart
class AppStateBadgeView extends HookWidget {
  const AppStateBadgeView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useAppLifecycleState();

    return Text('現在の状態: $state');
  }
}
```

**解説**
- `useAppLifecycleState()` は `WidgetsBindingObserver.didChangeAppLifecycleState` を内部でラップしたhookで、アプリがフォアグラウンド/バックグラウンドへ切り替わるたびに自動でリビルドする。
- 初回ビルド時点ではまだ状態を取得できていない場合があるため、戻り値の型は `AppLifecycleState?`(nullable)になっている。

---

### 問題44の回答例: useOnAppLifecycleStateChange — 状態変化をトリガーに副作用を起こす

```dart
class AutoSaveView extends HookWidget {
  const AutoSaveView({super.key});

  @override
  Widget build(BuildContext context) {
    useOnAppLifecycleStateChange((previous, current) {
      if (current == AppLifecycleState.paused) {
        debugPrint('auto saved');
      }
    });

    return const Placeholder();
  }
}
```

**解説**
- `useAppLifecycleState` との違いは、問題11・19で見た「値購読型 vs コールバック登録型」の構図と同じ。リビルドを起こさず、変化の前後の状態(`previous` / `current`)を受け取れる。
- `previous` と `current` の両方を受け取れるため、「`resumed` から `paused` に変わった瞬間だけ保存する」のように遷移パターンで条件分岐したい場合に特に有用(単に `current` を見るだけの `useAppLifecycleState` では前の状態と組み合わせた判定がやや書きにくい)。

---

### 問題45の回答例: usePlatformBrightness — OSのダーク/ライトモードを購読する

```dart
class SystemThemeAwareView extends HookWidget {
  const SystemThemeAwareView({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = usePlatformBrightness();

    return Container(
      color: brightness == Brightness.dark ? Colors.black : Colors.white,
    );
  }
}
```

**解説**
- `usePlatformBrightness()` はOSレベルのダーク/ライトモード設定(`MediaQuery.platformBrightnessOf(context)` 相当)を購読し、ユーザーがOS設定を変更した瞬間に自動でリビルドする。
- `MediaQuery.of(context).platformBrightness` を直接使う方法もあるが、それだと `MediaQuery` の他のプロパティ(画面サイズ等)が変わった場合にも依存関係が発生してしまうことがある。`usePlatformBrightness` は明るさの変化だけに関心を絞れる。

---

### 問題46の回答例: useOnPlatformBrightnessChange — 明るさ変化をトリガーに副作用を起こす

```dart
class ThemeChangeToastView extends HookWidget {
  const ThemeChangeToastView({super.key});

  @override
  Widget build(BuildContext context) {
    useOnPlatformBrightnessChange((previous, current) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('テーマが変わりました')),
      );
    });

    return const SizedBox.shrink();
  }
}
```

**解説**
- 本問題集全体を通して繰り返し登場したパターンの最後の例。「値を購読してUIに反映する」hook(`useXxx`)と「変化をトリガーに副作用だけ起こす」hook(`useOnXxxChange`)がペアで用意されている場合が多い(`useAppLifecycleState`/`useOnAppLifecycleStateChange`、`useStream`/`useOnStreamChange`、`useListenable`/`useOnListenableChange` など)。
- どちらを使うべきか迷ったときは、「その値をウィジェットの表示に使うか(→値購読型)」「値自体は表示せず、変化をきっかけに何か処理をしたいだけか(→コールバック登録型)」で判断すると選びやすい。
