# flutter_hooks 問題集

`flutter_hooks: ^0.21.3+1` が提供する全hookを、実際にコードを書きながら習得するための問題集です。
回答例は [flutter-hooks-answers.md](./flutter-hooks-answers.md) を参照してください(問題番号が対応しています)。

## 進め方

- 各問題の「雛形コード」の `TODO` コメント部分を実装してください。
- 各問題は他の問題に依存しない、単体で動く `HookWidget` として作成されています。動作確認する場合は `lib/` 配下に一時的にファイルを作成し、`MaterialApp` / `CupertinoApp` の `home` に渡して実行するか、`flutter analyze` で構文チェックしてください。
- 難易度は ★1(易しい)〜★5(難しい) の5段階です。
- 迷ったら回答例を見る前に、公式ドキュメント( https://github.com/rrousselGit/flutter_hooks )のdocコメントも参考にしてください。

## 目次

1. Primitives(基本) — 問題01〜07
2. 非同期(dart:async) — 問題08〜11
3. Animation — 問題12〜14
4. Listenable — 問題15〜19
5. 状態管理・ライフサイクル・その他 — 問題20〜26
6. コントローラ系(生成・自動破棄) — 問題27〜42
7. アプリライフサイクル・プラットフォーム — 問題43〜46

---

## 1. Primitives(基本)

### 問題01: useState — カウンターを作る

**対象hook**: `useState`
**難易度**: ★☆☆☆☆

**学べること**
- `useState` で状態を保持する方法
- `ValueNotifier<T>` として返される値の読み書き(`.value`)
- 状態変更時に自動的にリビルドされる仕組み

**要件**
- `CounterView` を `HookWidget` として実装する
- ボタンを押すたびにカウントが1増える
- 現在のカウント数をテキストで表示する
- 初期値は0とする

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class CounterView extends HookWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useStateを使ってcount状態を作成する

    return Column(
      children: [
        const Text('Count: TODO'),
        ElevatedButton(
          onPressed: () {
            // TODO: countを1増やす
          },
          child: const Text('+1'),
        ),
      ],
    );
  }
}
```

---

### 問題02: useEffect — マウント時にログを出し、破棄時にクリーンアップする

**対象hook**: `useEffect`
**難易度**: ★★☆☆☆

**学べること**
- `useEffect` の第一引数(副作用本体)と戻り値(クリーンアップ関数)の役割
- 第二引数 `keys` によって再実行タイミングを制御する方法
- `StatefulWidget` の `initState` / `dispose` に相当する処理をhookで書く方法

**要件**
- `LoggerView` を `HookWidget` として実装する
- ウィジェットが最初にビルドされたとき(マウント時)に `debugPrint('mounted')` を1回だけ出力する(以降のリビルドでは再実行されない)
- ウィジェットが破棄されたときに `debugPrint('disposed')` を出力する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class LoggerView extends HookWidget {
  const LoggerView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useEffectを使い、マウント時に1回だけ'mounted'をログ出力し、
    // 破棄時に'disposed'をログ出力する(keysに空リストを渡す)

    return const Placeholder();
  }
}
```

---

### 問題03: useMemoized — 重い計算結果をキャッシュする

**対象hook**: `useMemoized`
**難易度**: ★★☆☆☆

**学べること**
- `useMemoized` で計算結果をリビルドを跨いでキャッシュする方法
- `keys` を変えない限り再計算されないことの確認
- 毎回リビルドで再計算されると何が問題になるか

**要件**
- `FibonacciView` を `HookWidget` として実装する
- 引数 `n`(int)を受け取り、フィボナッチ数列のn番目の値を計算して表示する
- 計算関数 `_slowFibonacci(int n)` (雛形に用意済み)は重い処理を模しているため、`n` が変わらない限り再計算されないように `useMemoized` の `keys` に `[n]` を指定する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

int _slowFibonacci(int n) {
  if (n <= 1) return n;
  return _slowFibonacci(n - 1) + _slowFibonacci(n - 2);
}

class FibonacciView extends HookWidget {
  const FibonacciView({super.key, required this.n});

  final int n;

  @override
  Widget build(BuildContext context) {
    // TODO: useMemoizedを使い、_slowFibonacci(n)の結果をnをkeyにキャッシュする

    return const Placeholder();
  }
}
```

---

### 問題04: useCallback — 子ウィジェットへ渡す関数インスタンスを安定させる

**対象hook**: `useCallback`
**難易度**: ★★☆☆☆

**学べること**
- `useCallback` が関数インスタンス自体をキャッシュすること(`useMemoized` の関数版であること)
- `keys` が変わらない限り同じ関数インスタンスが返されること
- `const` にできない子ウィジェットへコールバックを渡す際の再ビルド最適化

**要件**
- `SearchBox` を `HookWidget` として実装する
- `useState` でテキストを保持し、`onChanged` コールバックで更新する
- 更新用コールバックは `useCallback` でラップし、`keys` に空リスト `[]` を渡して同一インスタンスを維持する
- `TextField(onChanged: ...)` に渡す

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SearchBox extends HookWidget {
  const SearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    final query = useState('');

    // TODO: useCallbackを使い、queryを更新するonChanged関数をキャッシュする

    return Column(
      children: [
        Text('query: ${query.value}'),
        TextField(
          onChanged: null, // TODO: 上で作ったコールバックを渡す
        ),
      ],
    );
  }
}
```

---

### 問題05: useRef — リビルドを引き起こさない可変値を保持する

**対象hook**: `useRef`
**難易度**: ★★☆☆☆

**学べること**
- `useRef` が返す `ObjectRef<T>` は `.value` を書き換えてもリビルドを発生させないこと
- `useState` との違い(状態変更の通知有無)
- スクロール位置や過去のタップ時刻など「表示に影響しないが保持したい値」の扱い方

**要件**
- `TapCounterView` を `HookWidget` として実装する
- ボタンをタップした回数を `useRef<int>` に記録する(画面表示は更新されない)
- 別途 `useState` のカウンタも用意し、ボタンを押すたびに `ref.value` をインクリメントしつつ、5回タップされたタイミングでのみ `useState` のカウンタに `ref.value` を反映して画面を更新する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TapCounterView extends HookWidget {
  const TapCounterView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useRefでタップ回数(int, 初期値0)を保持する
    // TODO: useStateで画面表示用のカウンタ(int, 初期値0)を保持する

    return Column(
      children: [
        const Text('5回タップごとに更新されるカウンタ: TODO'),
        ElevatedButton(
          onPressed: () {
            // TODO: refをインクリメントし、5の倍数になったらuseStateへ反映する
          },
          child: const Text('タップ'),
        ),
      ],
    );
  }
}
```

---

### 問題06: useContext — カスタムhook内でBuildContextを取得する

**対象hook**: `useContext`
**難易度**: ★★★☆☆

**学べること**
- `useContext` は `build` メソッドの引数 `context` と同じものを、`HookWidget` の外(カスタムhook関数内)で取得するためのhookであること
- カスタムhook(`use` から始まる自作関数)を作る方法
- `Theme.of(context)` のような「contextが必要な処理」をカスタムhookに切り出す実践例

**要件**
- `useIsDarkMode()` というカスタムhook関数を作成する(`bool` を返す)
  - 内部で `useContext()` を使って `BuildContext` を取得する
  - `Theme.of(context).brightness == Brightness.dark` を返す
- `ThemeLabelView` を `HookWidget` として実装し、`useIsDarkMode()` の結果に応じて「ダークモード」「ライトモード」を表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

bool useIsDarkMode() {
  // TODO: useContextでBuildContextを取得し、Theme.of(context).brightnessを判定する
  throw UnimplementedError();
}

class ThemeLabelView extends HookWidget {
  const ThemeLabelView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useIsDarkMode()を呼び出し、結果に応じてテキストを出し分ける

    return const Placeholder();
  }
}
```

---

### 問題07: useValueChanged — propsの変化を検知して副作用を実行する

**対象hook**: `useValueChanged`
**難易度**: ★★★☆☆

**学べること**
- `useValueChanged` が「監視対象の値が前回と変わったとき」だけコールバックを実行すること
- コールバックの戻り値を新しい状態として使える(`R?` を返せる)こと
- `didUpdateWidget` に相当する処理をhookで書く方法

**要件**
- `ScoreChangeView` を `HookWidget` として実装する。引数 `score`(int)を受け取る
- `score` が変化するたびに、変化量(`newScore - oldScore`)を計算して保持し、画面に「直前の変化量」として表示する
- `useValueChanged<int, int>` を使い、`valueChanged` コールバックで `(oldScore, oldResult) => score - oldScore` のような計算を行う

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ScoreChangeView extends HookWidget {
  const ScoreChangeView({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    // TODO: useValueChangedでscoreの変化量(diff)を計算する
    // 初回ビルド時はdiffはnullになる

    return const Placeholder();
  }
}
```

---

## 2. 非同期(dart:async)

### 問題08: useFuture — Future の状態をUIに反映する

**対象hook**: `useFuture`
**難易度**: ★★☆☆☆

**学べること**
- `useFuture` が `AsyncSnapshot<T>` を返し、`connectionState` / `hasData` / `hasError` でUIを出し分けられること
- `Future` インスタンス自体は `useMemoized` などで安定させないと、リビルドのたびに新しいFutureが渡されてしまう問題

**要件**
- `UserNameView` を `HookWidget` として実装する
- 1秒待ってから文字列 `'Alice'` を返す非同期関数 `_fetchUserName()`(雛形に用意済み)を呼び出す
- `useMemoized` でFutureインスタンスを1回だけ生成し、`useFuture` で購読する
- ローディング中は `CircularProgressIndicator`、取得できたら名前を表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Future<String> _fetchUserName() async {
  await Future<void>.delayed(const Duration(seconds: 1));
  return 'Alice';
}

class UserNameView extends HookWidget {
  const UserNameView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useMemoizedで_fetchUserName()のFutureを1回だけ生成する
    // TODO: useFutureでそのFutureを購読する

    return const Placeholder();
    // snapshot.connectionState == ConnectionState.waiting でローディング表示
    // snapshot.hasData で snapshot.data を表示
  }
}
```

---

### 問題09: useStream — Streamの値をリアルタイムに表示する

**対象hook**: `useStream`
**難易度**: ★★☆☆☆

**学べること**
- `useStream` が `Stream` の最新値を `AsyncSnapshot<T>` として購読すること
- `Stream` インスタンスも `useMemoized` 等で安定させる必要があること
- `useFuture` との違い(1回きりの値 vs 継続的な値)

**要件**
- `TickerView` を `HookWidget` として実装する
- 1秒ごとにカウントアップする `Stream<int>` を `Stream.periodic` で作成する(`useMemoized` で1回だけ生成)
- `useStream` で購読し、現在の値を表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TickerView extends HookWidget {
  const TickerView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useMemoizedでStream.periodic(Duration(seconds: 1), (i) => i)を1回だけ生成する
    // TODO: useStreamでそのStreamを購読し、値を表示する

    return const Placeholder();
  }
}
```

---

### 問題10: useStreamController — 自動破棄されるStreamControllerを作る

**対象hook**: `useStreamController`
**難易度**: ★★★☆☆

**学べること**
- `useStreamController` がウィジェット破棄時に自動で `StreamController.close()` してくれること
- 手動で `StreamController` を管理する場合(`dispose`が必要)との違い
- 自前で作った `StreamController` を `useStream` と組み合わせて使う流れ

**要件**
- `ChatInputView` を `HookWidget` として実装する
- `useStreamController<String>()` でメッセージ用のコントローラを作る
- `TextField` の `onSubmitted` でコントローラに文字列を `add` する
- `useStream` でそのコントローラの `.stream` を購読し、直近に送信された文字列を画面に表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ChatInputView extends HookWidget {
  const ChatInputView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useStreamControllerでStreamController<String>を作成する(自動破棄される)
    // TODO: useStreamでcontroller.streamを購読する

    return Column(
      children: [
        const Text('last message: TODO'),
        TextField(
          onSubmitted: null, // TODO: controller.add(value) を呼ぶ
        ),
      ],
    );
  }
}
```

---

### 問題11: useOnStreamChange — 購読はするが値をUIに持たない

**対象hook**: `useOnStreamChange`
**難易度**: ★★★☆☆

**学べること**
- `useOnStreamChange` は `useStream` と違い `AsyncSnapshot` を返さず、`onData` / `onError` / `onDone` コールバックだけを登録すること
- 「値そのものはUIに出さないが、副作用(ログ送信・SnackBar表示など)だけ起こしたい」場面での使い分け
- 戻り値の `StreamSubscription<T>?` は通常使わなくてもよいこと

**要件**
- `ErrorToastView` を `HookWidget` として実装する
- 引数として `Stream<String> errorStream` を受け取る
- `useOnStreamChange` を使い、`errorStream` から値が流れてくるたびに `ScaffoldMessenger.of(context).showSnackBar(...)` でメッセージを表示する(画面自体には状態を持たせない)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ErrorToastView extends HookWidget {
  const ErrorToastView({super.key, required this.errorStream});

  final Stream<String> errorStream;

  @override
  Widget build(BuildContext context) {
    // TODO: useOnStreamChangeでerrorStreamを購読し、
    // onDataでSnackBarを表示する(SnackBar(content: Text(message)))

    return const SizedBox.shrink();
  }
}
```

---

## 3. Animation

### 問題12: useAnimationController — 自動破棄されるAnimationControllerでフェードイン

**対象hook**: `useAnimationController`
**難易度**: ★★★☆☆

**学べること**
- `useAnimationController` が内部で `vsync`(Ticker)を自動的に用意し、破棄も自動で行うこと
- `StatefulWidget` + `SingleTickerProviderStateMixin` で書いていた定型コードがhookで不要になること
- `AnimatedBuilder` と組み合わせたアニメーションの実装パターン

**要件**
- `FadeInView` を `HookWidget` として実装する
- `useAnimationController(duration: Duration(seconds: 1))` を作成し、ウィジェットが表示されたら自動的に `forward()` を実行する(`useEffect` と組み合わせる)
- `AnimatedBuilder` を使い、コントローラの値を `opacity` として `FlutterLogo` をフェードインさせる

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FadeInView extends HookWidget {
  const FadeInView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useAnimationControllerでdurationが1秒のcontrollerを作成する
    // TODO: useEffectでマウント時にcontroller.forward()を呼ぶ(keysは空リスト)

    return const Placeholder();
    // AnimatedBuilderのbuilderでOpacity(opacity: controller.value, child: FlutterLogo())を返す
  }
}
```

---

### 問題13: useAnimation — Animationの現在値だけを購読する

**対象hook**: `useAnimation`
**難易度**: ★★★☆☆

**学べること**
- `useAnimation` は `Animation<T>` を購読し、値が変わるたびに自動でリビルドしてくれること(`AnimatedBuilder` が不要になる)
- `useAnimationController` の `.drive(Tween)` と組み合わせる方法

**要件**
- 問題12と同じ `FadeInView` を、`AnimatedBuilder` を使わずに `useAnimation` だけで書き直した `FadeInViewV2` を実装する
- `useAnimationController` はそのまま使い、`useAnimation(controller)` で現在値を取得して直接 `Opacity(opacity: value, ...)` に渡す

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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

    // TODO: useAnimation(controller)で現在値を取得し、
    // AnimatedBuilderを使わずにOpacityへ直接渡す

    return const Placeholder();
  }
}
```

---

### 問題14: useSingleTickerProvider — 自前のAnimationControllerにvsyncを供給する

**対象hook**: `useSingleTickerProvider`
**難易度**: ★★★☆☆

**学べること**
- `useAnimationController` を使わず、あえて `AnimationController` を自分で `useMemoized` 等で生成するケースで、`vsync` に何を渡すべきか
- `useSingleTickerProvider` がその `vsync: TickerProvider` を用意してくれること
- `dispose` は自前で管理する必要がある(`useAnimationController` と違い自動破棄ではない)ことへの注意

**要件**
- `PulseView` を `HookWidget` として実装する
- `useSingleTickerProvider()` で `TickerProvider` を取得する
- `useMemoized` で `AnimationController(vsync: ticker, duration: Duration(milliseconds: 500))` を生成し、`useEffect` の中で `repeat(reverse: true)` を開始し、クリーンアップで `controller.dispose()` を呼ぶ
- `useAnimation` で値を購読し、`0.5〜1.5` の範囲にスケールする `Transform.scale` でロゴを拡大縮小させる

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PulseView extends HookWidget {
  const PulseView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useSingleTickerProviderでTickerProviderを取得する
    // TODO: useMemoizedでAnimationControllerを生成する(vsyncに上のtickerを渡す)
    // TODO: useEffectでrepeat(reverse: true)を開始し、クリーンアップでdispose()する
    // TODO: useAnimationで値を購読し、Transform.scaleに反映する(0.5 + controller.value を scaleに使うなど)

    return const Placeholder();
  }
}
```

---

## 4. Listenable

### 問題15: useListenable — 任意のListenableを購読してリビルドする

**対象hook**: `useListenable`
**難易度**: ★★☆☆☆

**学べること**
- `useListenable` が `Listenable`(`ChangeNotifier` 等)の変化を検知して自動リビルドすること
- 値そのものではなく「通知」だけを検知するため、値の取り出しは自分で行う必要があること

**要件**
- 雛形の `Counter extends ChangeNotifier` クラス(`value` プロパティと `increment()` メソッドを持つ)を使う
- `CounterListenableView` を `HookWidget` として実装する
- `useMemoized` で `Counter()` インスタンスを1回だけ生成する
- `useListenable(counter)` で購読し、`counter.value` をテキスト表示、ボタンで `counter.increment()` を呼ぶ

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
    // TODO: useMemoizedでCounter()を1回だけ生成する
    // TODO: useListenableで購読する

    return const Placeholder();
  }
}
```

---

### 問題16: useListenableSelector — 必要な部分だけを見てリビルドを絞り込む

**対象hook**: `useListenableSelector`
**難易度**: ★★★★☆

**学べること**
- `useListenable` は `Listenable` 全体の変化でリビルドされるが、`useListenableSelector` は `selector` の戻り値が変化したときだけリビルドされること
- 大きな状態オブジェクトの一部だけを見て不要な再描画を減らすテクニック

**要件**
- 雛形の `Profile extends ChangeNotifier`(`name` と `age` を持ち、それぞれ更新メソッドがある)を使う
- `AgeOnlyView` を `HookWidget` として実装する
- `useListenableSelector(profile, () => profile.age)` を使い、`age` が変化したときだけリビルドされるようにする(`name` の変更ではリビルドされないことがポイント)
- 画面には年齢のみを表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
    // TODO: useListenableSelectorでprofile.ageだけを購読する

    return const Placeholder();
  }
}
```

---

### 問題17: useValueListenable — ValueListenableの値を購読する

**対象hook**: `useValueListenable`
**難易度**: ★★☆☆☆

**学べること**
- `ValueListenable<T>`(`ValueNotifier` 等)を購読し、直接値 `T` を受け取れること
- `ValueListenableBuilder` をhookで置き換えられること

**要件**
- `VolumeView` を `HookWidget` として実装する
- 引数として `ValueNotifier<double> volume` を受け取る(外部から渡される想定)
- `useValueListenable(volume)` で現在値を購読し、`Slider` に反映する。`Slider.onChanged` では `volume.value = newValue` を設定する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class VolumeView extends HookWidget {
  const VolumeView({super.key, required this.volume});

  final ValueNotifier<double> volume;

  @override
  Widget build(BuildContext context) {
    // TODO: useValueListenable(volume)で現在値を取得する

    return const Placeholder();
    // Slider(value: currentValue, onChanged: (v) => volume.value = v)
  }
}
```

---

### 問題18: useValueNotifier — 自動破棄されるValueNotifierを作る

**対象hook**: `useValueNotifier`
**難易度**: ★★★☆☆

**学べること**
- `useValueNotifier` は `ValueNotifier` インスタンスを生成・自動破棄するだけで、それ自体は購読(リビルド)しないこと
- リビルドさせたい場合は `useValueListenable` と組み合わせる必要があること(`useState` との違いの理解)

**要件**
- `BrightnessSliderView` を `HookWidget` として実装する
- `useValueNotifier<double>(0.5)` で明るさ用の `ValueNotifier<double>` を作成する(自動破棄)
- 作成した `ValueNotifier` を `useValueListenable` で購読し、`Slider` の値として表示・更新する(問題17と似た構成だが、`ValueNotifier` 自体もhookで生成する点が異なる)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class BrightnessSliderView extends HookWidget {
  const BrightnessSliderView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useValueNotifier<double>(0.5)でValueNotifierを作成する(自動破棄される)
    // TODO: useValueListenableで現在値を購読する

    return const Placeholder();
  }
}
```

---

### 問題19: useOnListenableChange — 値を持たずリスナーだけ登録する

**対象hook**: `useOnListenableChange`
**難易度**: ★★★☆☆

**学べること**
- `useOnListenableChange` は `useListenable` と違いリビルドを発生させず、コールバックの登録・自動解除だけを行うこと
- 「Listenableの変化をトリガーに副作用(スクロール・フォーカス移動など)だけ起こしたい」場面での使い分け

**要件**
- `AutoScrollView` を `HookWidget` として実装する
- 引数として `TextEditingController controller`(問題27で使うものと同じ型)と `ScrollController scrollController` を受け取る
- `useOnListenableChange(controller, () { ... })` を使い、`controller` のテキストが変化するたびに `scrollController.jumpTo(scrollController.position.maxScrollExtent)` を呼ぶ(画面自体はリビルドしない)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
    // TODO: useOnListenableChangeでcontrollerを監視し、
    // 変化のたびにscrollControllerを末尾までスクロールする

    return const SizedBox.shrink();
  }
}
```

---

## 5. 状態管理・ライフサイクル・その他

### 問題20: useReducer — Redux風の状態管理をする

**対象hook**: `useReducer`
**難易度**: ★★★★☆

**学べること**
- `useReducer` が `useState` の代替として、複雑な状態遷移をまとめて管理できること
- `Reducer<StateT, ActionT>` 関数と `Store.dispatch` の使い方
- 状態(state)とアクション(action)を分離する設計の利点
- `useReducer` は `initialState` に加えて `initialAction` も必須で、初回ビルド時に `reducer(initialState, initialAction)` の実行結果が最初の `state` になるという挙動

**要件**
- 雛形の `CounterAction`(`increment` / `decrement` / 何もしない `none` の3種類、enumで定義)を使う
- `counterReducer(int state, CounterAction action)` 関数を実装する(incrementでstate+1、decrementでstate-1、noneはstateをそのまま返す)
- `ReducerCounterView` を `HookWidget` として実装し、`useReducer(counterReducer, initialState: 0, initialAction: CounterAction.none)` で状態を管理する(`initialAction` に `none` を渡すことで、初期表示が0のまま変わらないようにする)
- 2つのボタンで `store.dispatch(CounterAction.increment)` / `.decrement` を呼び、`store.state` を表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

enum CounterAction { increment, decrement, none }

int counterReducer(int state, CounterAction action) {
  // TODO: actionに応じてstateを+1/-1/そのままにする
  throw UnimplementedError();
}

class ReducerCounterView extends HookWidget {
  const ReducerCounterView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useReducerでcounterReducerを使い、initialState: 0で管理する

    return const Placeholder();
    // store.state を表示し、2つのボタンでstore.dispatch(...)する
  }
}
```

---

### 問題21: usePrevious — 直前のレンダリング時の値を取得する

**対象hook**: `usePrevious`
**難易度**: ★★☆☆☆

**学べること**
- `usePrevious` が「1回前のビルド時点での値」を返すこと(初回は `null`)
- 現在値と前回値を比較して「増えた/減った」のようなUIを作るパターン

**要件**
- `TemperatureView` を `HookWidget` として実装する。引数 `temperature`(double)を受け取る
- `usePrevious(temperature)` で前回値を取得する
- 前回値と比較し、上昇していれば `↑`、下降していれば `↓`、前回値がない(初回)、または同値なら何も表示しないアイコンを現在の気温と並べて表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TemperatureView extends HookWidget {
  const TemperatureView({super.key, required this.temperature});

  final double temperature;

  @override
  Widget build(BuildContext context) {
    // TODO: usePrevious(temperature)で前回値を取得する
    // TODO: 前回値と比較して上昇/下降のアイコンを出し分ける

    return const Placeholder();
  }
}
```

---

### 問題22: useIsMounted — 非同期処理後の安全なsetState代替

**対象hook**: `useIsMounted`
**難易度**: ★★★☆☆

**学べること**
- `useIsMounted()` が呼び出し可能な `IsMounted`(`bool Function()`)を返すこと
- 非同期処理の完了時に、ウィジェットが既に破棄されていないかを確認してから状態更新するパターン(`State.mounted` 相当)

**要件**
- `SafeAsyncButton` を `HookWidget` として実装する
- ボタンを押すと2秒待ってから `useState` の文字列を `'Done'` に更新する非同期処理を実行する
- `useIsMounted()` を使い、2秒待った後に「ウィジェットがまだマウントされているか」を確認してから状態更新を行う(アンマウント後に更新しようとするとエラーになることへの対策)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SafeAsyncButton extends HookWidget {
  const SafeAsyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    final status = useState('Idle');
    // TODO: useIsMounted()でIsMountedを取得する

    return Column(
      children: [
        Text(status.value),
        ElevatedButton(
          onPressed: () async {
            status.value = 'Loading';
            await Future<void>.delayed(const Duration(seconds: 2));
            // TODO: isMounted()がtrueの場合のみstatus.valueを'Done'にする
          },
          child: const Text('実行'),
        ),
      ],
    );
  }
}
```

---

### 問題23: useReassemble — ホットリロード時にだけ処理を行う

**対象hook**: `useReassemble`
**難易度**: ★★☆☆☆

**学べること**
- `useReassemble` はFlutterの「reassemble」(主にホットリロード時)に呼ばれるコールバックを登録すること
- 開発中のみ有効な用途(キャッシュクリアなど)であり、通常のビルドフローとは別のタイミングで動くこと

**要件**
- `CacheClearingView` を `HookWidget` として実装する
- `useReassemble` を使い、ホットリロードのたびに `debugPrint('reassembled: cache cleared')` を出力する(雛形コメントの通り、実行結果はホットリロードでしか確認できない点を理解する)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class CacheClearingView extends HookWidget {
  const CacheClearingView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useReassembleでホットリロード時に'reassembled: cache cleared'をログ出力する

    return const Placeholder();
  }
}
```

---

### 問題24: useAutomaticKeepAlive — リスト内アイテムの状態を保持する

**対象hook**: `useAutomaticKeepAlive`
**難易度**: ★★★★☆

**学べること**
- `ListView` 等の中でスクロールアウトしたアイテムは通常破棄されるが、`AutomaticKeepAliveClientMixin` 相当の仕組みで状態を保持できること
- `useAutomaticKeepAlive` を呼ぶだけで、`HookWidget` に対して同等のことができること

**要件**
- `KeepAliveTile` を `HookWidget` として実装する(`ListView` のアイテムとして使う想定)
- `useAutomaticKeepAlive()` を呼び出し、このタイルがスクロールでビューポート外に出ても状態(内部の `useState` によるON/OFFスイッチ)が破棄されないようにする
- スイッチのON/OFF状態を `useState<bool>` で保持し、`Switch` ウィジェットで表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class KeepAliveTile extends HookWidget {
  const KeepAliveTile({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    // TODO: useAutomaticKeepAlive()を呼び出す
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

---

### 問題25: useDebounced — 入力値のデバウンス処理をする

**対象hook**: `useDebounced`
**難易度**: ★★★☆☆

**学べること**
- `useDebounced(value, duration)` が「値が変化してから一定時間、変化がなければ」新しい値を返すこと
- 検索ボックスなど「入力のたびにAPIを叩きたくない」場面での典型的な使い方

**要件**
- `DebouncedSearchView` を `HookWidget` として実装する
- `useState<String>` で入力値(`rawQuery`)を保持し、`TextField.onChanged` で更新する
- `useDebounced(rawQuery.value, const Duration(milliseconds: 500))` でデバウンス後の値を取得する
- 画面には「入力中の値」と「500ms後に確定した検索クエリ」の両方を表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DebouncedSearchView extends HookWidget {
  const DebouncedSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    final rawQuery = useState('');
    // TODO: useDebouncedでrawQuery.valueを500msデバウンスした値を取得する

    return Column(
      children: [
        TextField(onChanged: (v) => rawQuery.value = v),
        Text('入力中: ${rawQuery.value}'),
        const Text('確定クエリ: TODO'),
      ],
    );
  }
}
```

---

### 問題26: useOverlayPortalController — オーバーレイの表示制御を行う

**対象hook**: `useOverlayPortalController`
**難易度**: ★★★★☆

**学べること**
- `useOverlayPortalController` が `OverlayPortalController` を生成・自動破棄すること
- `OverlayPortal` ウィジェットと組み合わせ、任意の位置にツールチップ/ドロップダウン等を重ねて表示する仕組み

**要件**
- `HintOverlayView` を `HookWidget` として実装する
- `useOverlayPortalController()` でコントローラを作成する
- ボタンを押すと `controller.toggle()` でオーバーレイの表示/非表示を切り替える
- `OverlayPortal(controller: controller, overlayChildBuilder: ...)` で、表示中は画面中央に小さな吹き出し(`Text('ヒント')` を `Card` で囲む程度でよい)を表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class HintOverlayView extends HookWidget {
  const HintOverlayView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useOverlayPortalController()でcontrollerを作成する

    return const Placeholder();
    // OverlayPortal(
    //   controller: controller,
    //   overlayChildBuilder: (context) => const Center(child: Card(child: Text('ヒント'))),
    //   child: ElevatedButton(onPressed: controller.toggle, child: const Text('トグル')),
    // )
  }
}
```

---

## 6. コントローラ系(生成・自動破棄)

このカテゴリの全hookは「対応するコントローラを生成し、ウィジェット破棄時に自動で `dispose()` する」という共通パターンを持っています。`StatefulWidget` で書く場合の定型コード(`initState` でコントローラ生成、`dispose` で破棄)を1行に圧縮できることを体感してください。

### 問題27: useTextEditingController — フォーム入力を管理する

**対象hook**: `useTextEditingController`
**難易度**: ★☆☆☆☆

**学べること**
- `useTextEditingController` で自動破棄される `TextEditingController` を生成する方法
- `initialText`(または `text:`)引数で初期値を設定できること

**要件**
- `NicknameFieldView` を `HookWidget` として実装する
- `useTextEditingController(text: '名無しさん')` で初期値付きのコントローラを生成する
- `TextField(controller: controller)` として表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class NicknameFieldView extends HookWidget {
  const NicknameFieldView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useTextEditingControllerで初期値'名無しさん'のコントローラを生成する

    return const Placeholder();
  }
}
```

---

### 問題28: useFocusNode — 入力欄のフォーカスを制御する

**対象hook**: `useFocusNode`
**難易度**: ★★☆☆☆

**学べること**
- `useFocusNode` で自動破棄される `FocusNode` を生成する方法
- `FocusNode.addListener` でフォーカス状態の変化を検知する方法(`useListenable` との組み合わせ)

**要件**
- `FocusAwareFieldView` を `HookWidget` として実装する
- `useFocusNode()` でフォーカスノードを生成する
- `useListenable(focusNode)` と組み合わせ、`focusNode.hasFocus` に応じて `TextField` の枠線の色を変える(フォーカス中は青、そうでなければグレー)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FocusAwareFieldView extends HookWidget {
  const FocusAwareFieldView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useFocusNode()でFocusNodeを生成する
    // TODO: useListenableでfocusNodeを購読し、hasFocusに応じて枠線色を変える

    return const Placeholder();
  }
}
```

---

### 問題29: useFocusScopeNode — フォーカスのスコープを管理する

**対象hook**: `useFocusScopeNode`
**難易度**: ★★★☆☆

**学べること**
- `useFocusScopeNode` が複数の `FocusNode` をまとめる `FocusScopeNode` を生成・自動破棄すること
- `FocusScope` ウィジェットと組み合わせ、`nextFocus()` でフォーカスを次の入力欄へ移す方法

**要件**
- `MultiFieldFormView` を `HookWidget` として実装する
- `useFocusScopeNode()` でスコープを作成し、`FocusScope(node: scopeNode, child: ...)` で2つの `TextField` を囲む
- 1つ目の `TextField` の `onSubmitted` で `scopeNode.nextFocus()` を呼び、2つ目にフォーカスを移す

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class MultiFieldFormView extends HookWidget {
  const MultiFieldFormView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useFocusScopeNode()でFocusScopeNodeを生成する

    return const Placeholder();
    // FocusScope(node: scopeNode, child: Column(children: [TextField(onSubmitted: (_) => scopeNode.nextFocus()), TextField()]))
  }
}
```

---

### 問題30: useScrollController — スクロール位置を監視する

**対象hook**: `useScrollController`
**難易度**: ★★☆☆☆

**学べること**
- `useScrollController` で自動破棄される `ScrollController` を生成する方法
- `useListenable` と組み合わせてスクロール位置に応じたUI変化(例: 「トップへ戻る」ボタンの表示)を作る方法

**要件**
- `ScrollToTopView` を `HookWidget` として実装する
- `useScrollController()` でコントローラを生成し、`ListView.builder` に渡す(100件程度のダミーアイテムでよい)
- `useListenable(scrollController)` と組み合わせ、`scrollController.offset > 200` のときだけ画面右下に「トップへ戻る」`FloatingActionButton` を表示する。押すと `scrollController.animateTo(0, ...)` でトップへ戻す

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ScrollToTopView extends HookWidget {
  const ScrollToTopView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useScrollController()でScrollControllerを生成する
    // TODO: useListenableで購読し、offset > 200 かどうかを判定する

    return const Placeholder();
  }
}
```

---

### 問題31: usePageController — PageViewのページ状態を管理する

**対象hook**: `usePageController`
**難易度**: ★★☆☆☆

**学べること**
- `usePageController` で自動破棄される `PageController` を生成する方法
- 現在のページindexを `useState` 等と組み合わせて表示する方法(`PageController` 自体はcurrentPageを同期的に持たないため、`onPageChanged` で拾う必要がある点に注意)

**要件**
- `OnboardingView` を `HookWidget` として実装する
- `usePageController()` でコントローラを生成し、3ページ分の `PageView`(色の違うContainerでよい)を作る
- 現在のページ番号を `useState<int>` で保持し、`PageView.onPageChanged` で更新、画面下部にドットインジケーター(現在ページを強調表示する3つの丸)を表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class OnboardingView extends HookWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: usePageController()でPageControllerを生成する
    final currentPage = useState(0);

    return const Placeholder();
    // PageView(controller: pageController, onPageChanged: (i) => currentPage.value = i, children: [...])
  }
}
```

---

### 問題32: useTabController — タブ切り替えを管理する

**対象hook**: `useTabController`
**難易度**: ★★★☆☆

**学べること**
- `useTabController` が `vsync` を自動で用意しつつ `TabController` を生成・自動破棄すること(`useAnimationController` と同様のvsync自動化パターン)
- `TabBar` と `TabBarView` に同じコントローラを渡して連動させる方法

**要件**
- `CategoryTabView` を `HookWidget` として実装する
- `useTabController(initialLength: 3)` でコントローラを生成する
- `TabBar(controller: controller, tabs: [...])` と `TabBarView(controller: controller, children: [...])` を `Column` 内に配置し、3つのカテゴリ(例: 'すべて' / 'お気に入り' / '最近')を切り替えられるようにする

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class CategoryTabView extends HookWidget {
  const CategoryTabView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useTabController(initialLength: 3)でTabControllerを生成する

    return const Placeholder();
  }
}
```

---

### 問題33: useCupertinoTabController — iOS風タブバーを管理する

**対象hook**: `useCupertinoTabController`
**難易度**: ★★☆☆☆

**学べること**
- `useCupertinoTabController` が `CupertinoTabController` を生成・自動破棄すること
- `CupertinoTabScaffold` と組み合わせ、Material版の `useTabController` との違い(vsync不要・indexプロパティで直接操作できる)を理解する

**要件**
- `IosStyleTabView` を `HookWidget` として実装する
- `useCupertinoTabController(initialIndex: 0)` でコントローラを生成する
- `CupertinoTabScaffold` の `controller` に渡し、`tabBar`(3項目)と `tabBuilder` で各タブのコンテンツ(シンプルな `Center(child: Text('タブN'))` でよい)を表示する

**雛形コード**
```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class IosStyleTabView extends HookWidget {
  const IosStyleTabView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useCupertinoTabController(initialIndex: 0)でコントローラを生成する

    return const Placeholder();
  }
}
```

---

### 問題34: useTransformationController — ピンチズームの変形状態を管理する

**対象hook**: `useTransformationController`
**難易度**: ★★★☆☆

**学べること**
- `useTransformationController` で自動破棄される `TransformationController` を生成する方法
- `InteractiveViewer` と組み合わせ、拡大率をコードから制御(リセットなど)する方法

**要件**
- `ZoomableImageView` を `HookWidget` として実装する
- `useTransformationController()` でコントローラを生成し、`InteractiveViewer(transformationController: controller, child: FlutterLogo(size: 200))` を表示する
- 「リセット」ボタンを押すと `controller.value = Matrix4.identity()` で拡大率を初期状態に戻す

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ZoomableImageView extends HookWidget {
  const ZoomableImageView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useTransformationController()でコントローラを生成する

    return const Placeholder();
  }
}
```

---

### 問題35: useFixedExtentScrollController — 固定高さのホイールピッカーを作る

**対象hook**: `useFixedExtentScrollController`
**難易度**: ★★★☆☆

**学べること**
- `useFixedExtentScrollController` で自動破棄される `FixedExtentScrollController` を生成する方法
- `ListWheelScrollView` と組み合わせた「時刻選択」のようなホイールUIの作り方

**要件**
- `HourPickerView` を `HookWidget` として実装する
- `useFixedExtentScrollController(initialItem: 0)` でコントローラを生成する
- `ListWheelScrollView(controller: controller, itemExtent: 40, children: [0〜23の時刻をTextで24個])` を表示する
- 選択中の時刻を `useState<int>` で保持し、`onSelectedItemChanged` で更新して画面上部に表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class HourPickerView extends HookWidget {
  const HourPickerView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useFixedExtentScrollController(initialItem: 0)でコントローラを生成する
    final selectedHour = useState(0);

    return const Placeholder();
  }
}
```

---

### 問題36: useSearchController — 検索バー(SearchAnchor)を制御する

**対象hook**: `useSearchController`
**難易度**: ★★★☆☆

**学べること**
- `useSearchController` で自動破棄される `SearchController` を生成する方法
- Material 3 の `SearchAnchor` ウィジェットと組み合わせた検索候補表示の基本

**要件**
- `FruitSearchView` を `HookWidget` として実装する
- `useSearchController()` でコントローラを生成する
- `SearchAnchor(searchController: controller, builder: ..., suggestionsBuilder: ...)` を使い、雛形の `_fruits` リストから `controller.text` を含むものだけを候補としてリスト表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const _fruits = ['りんご', 'みかん', 'ぶどう', 'バナナ', 'メロン'];

class FruitSearchView extends HookWidget {
  const FruitSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useSearchController()でSearchControllerを生成する

    return const Placeholder();
    // SearchAnchor(searchController: controller, builder: (context, controller) => IconButton(...),
    //   suggestionsBuilder: (context, controller) => _fruits.where((f) => f.contains(controller.text)).map((f) => ListTile(title: Text(f))))
  }
}
```

---

### 問題37: useDraggableScrollableController — ドラッグ可能なボトムシートを制御する

**対象hook**: `useDraggableScrollableController`
**難易度**: ★★★★☆

**学べること**
- `useDraggableScrollableController` で自動破棄される `DraggableScrollableController` を生成する方法
- `DraggableScrollableSheet` と組み合わせ、コードからシートの高さを操作する(`animateTo` など)方法

**要件**
- `ExpandableSheetView` を `HookWidget` として実装する
- `useDraggableScrollableController()` でコントローラを生成する
- `DraggableScrollableSheet(controller: controller, initialChildSize: 0.3, minChildSize: 0.1, maxChildSize: 0.9, builder: ...)` を表示する
- 画面上に「全開にする」ボタンを配置し、押すと `controller.animateTo(0.9, duration: ..., curve: ...)` でシートを最大まで広げる

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ExpandableSheetView extends HookWidget {
  const ExpandableSheetView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useDraggableScrollableController()でコントローラを生成する

    return const Placeholder();
  }
}
```

---

### 問題38: useCarouselController — カルーセル(横スクロール一覧)を制御する

**対象hook**: `useCarouselController`
**難易度**: ★★★☆☆

**学べること**
- `useCarouselController` で自動破棄される `CarouselController` を生成する方法
- `CarouselView` と組み合わせ、初期表示位置や自動破棄されるコントローラの使いどころを理解する

**要件**
- `PhotoCarouselView` を `HookWidget` として実装する
- `useCarouselController()` でコントローラを生成する
- `CarouselView(controller: controller, itemExtent: 200, children: [雛形の色付きContainerを5個])` を表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PhotoCarouselView extends HookWidget {
  const PhotoCarouselView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useCarouselController()でコントローラを生成する

    return const Placeholder();
    // CarouselView(controller: controller, itemExtent: 200, children: List.generate(5, (i) => Container(color: Colors.primaries[i])))
  }
}
```

---

### 問題39: useExpansibleController — 展開/折りたたみを外部から制御する

**対象hook**: `useExpansibleController`
**難易度**: ★★★☆☆

**学べること**
- `useExpansibleController` で自動破棄される `ExpansibleController` を生成する方法
- `ExpansionTile(controller: ...)` と組み合わせ、ボタン等の外部トリガーで展開状態を制御する方法

**要件**
- `FaqTileView` を `HookWidget` として実装する
- `useExpansibleController()` でコントローラを生成する
- `ExpansionTile(controller: controller, title: Text('質問'), children: [Text('回答')])` を表示する
- 別に配置した「開く」ボタンを押すと `controller.expand()` を呼び、タイルをタップしなくても展開できるようにする

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class FaqTileView extends HookWidget {
  const FaqTileView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useExpansibleController()でコントローラを生成する

    return const Placeholder();
  }
}
```

---

### 問題40: useSnapshotController — RepaintBoundaryのスナップショット化を制御する

**対象hook**: `useSnapshotController`
**難易度**: ★★★★☆

**学べること**
- `useSnapshotController` で自動破棄される `SnapshotController` を生成する方法
- `SnapshotWidget` と組み合わせ、複雑な描画をラスタ画像として一時的にキャッシュ(スナップショット化)し、アニメーション中の描画コストを下げるテクニック

**要件**
- `SnapshottedListView` を `HookWidget` として実装する
- `useSnapshotController(allowSnapshotting: false)` でコントローラを生成する
- 「アニメーション中はスナップショットを許可する」という想定で、スクロールや拡大操作の開始時に `controller.allowSnapshotting = true`、終了時に `false` を切り替えるボタンを2つ配置する(実際の重い描画対象は雛形の `FlutterLogo` で代用してよい)
- `SnapshotWidget(controller: controller, child: FlutterLogo(size: 150))` でラップする

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SnapshottedListView extends HookWidget {
  const SnapshottedListView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useSnapshotController(allowSnapshotting: false)でコントローラを生成する

    return const Placeholder();
  }
}
```

---

### 問題41: useTreeSliverController — 階層構造(ツリー)の開閉を管理する

**対象hook**: `useTreeSliverController`
**難易度**: ★★★★☆

**学べること**
- `useTreeSliverController` で自動破棄される `TreeSliverController` を生成する方法
- `TreeSliver` と組み合わせ、フォルダ階層のようなツリーUIのノード開閉をコードから制御する方法

**要件**
- `FileTreeView` を `HookWidget` として実装する
- `useTreeSliverController()` でコントローラを生成する
- 雛形の `_sampleTree`(`TreeSliverNode<String>` のリスト、フォルダ1つに子ノード2つを持つ程度でよい)を `TreeSliver(controller: controller, tree: _sampleTree, treeNodeBuilder: ...)` で表示する
- 「すべて展開」ボタンで各ルートノードに対し `controller.toggleNode(node)` を呼ぶ(`TreeSliverController.toggleNode` は開閉状態を反転させる)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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
    // TODO: useTreeSliverController()でコントローラを生成する

    return const Placeholder();
  }
}
```

---

### 問題42: useWidgetStatesController — WidgetState(hover/pressed等)を管理する

**対象hook**: `useWidgetStatesController`
**難易度**: ★★★☆☆

**学べること**
- `useWidgetStatesController` で自動破棄される `WidgetStatesController` を生成する方法
- `Set<WidgetState>` を使い、`hovered` / `pressed` / `disabled` 等の状態に応じてスタイルを出し分ける `WidgetStateProperty` の仕組み

**要件**
- `CustomHoverButtonView` を `HookWidget` として実装する
- `useWidgetStatesController()` でコントローラを生成する
- `MouseRegion` / `GestureDetector` で `hovered` / `pressed` 状態を `controller.update(WidgetState.hovered, true/false)` のように更新する
- `controller.value.contains(WidgetState.hovered)` かどうかで背景色を変える簡単なボタン風ウィジェットを作る

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class CustomHoverButtonView extends HookWidget {
  const CustomHoverButtonView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useWidgetStatesController()でコントローラを生成する

    return const Placeholder();
  }
}
```

---

## 7. アプリライフサイクル・プラットフォーム

### 問題43: useAppLifecycleState — アプリの状態(前面/背面)を購読する

**対象hook**: `useAppLifecycleState`
**難易度**: ★★☆☆☆

**学べること**
- `useAppLifecycleState()` が現在の `AppLifecycleState?`(resumed / inactive / paused / detached 等)を返し、変化のたびに自動リビルドすること
- アプリがバックグラウンドに回ったかどうかをUIに反映する典型例

**要件**
- `AppStateBadgeView` を `HookWidget` として実装する
- `useAppLifecycleState()` の結果を画面上部に常に表示する(例: `'現在の状態: AppLifecycleState.resumed'`)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AppStateBadgeView extends HookWidget {
  const AppStateBadgeView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useAppLifecycleState()で現在の状態を取得し表示する

    return const Placeholder();
  }
}
```

---

### 問題44: useOnAppLifecycleStateChange — 状態変化をトリガーに副作用を起こす

**対象hook**: `useOnAppLifecycleStateChange`
**難易度**: ★★★☆☆

**学べること**
- `useOnAppLifecycleStateChange` は `useAppLifecycleState` と違いリビルドを起こさず、変化前後の状態を受け取るコールバックだけを登録すること
- 「バックグラウンドに回ったタイミングで自動保存する」のような副作用の実装パターン

**要件**
- `AutoSaveView` を `HookWidget` として実装する
- `useOnAppLifecycleStateChange((previous, current) { ... })` を使い、`current == AppLifecycleState.paused` になった瞬間に `debugPrint('auto saved')` を出力する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AutoSaveView extends HookWidget {
  const AutoSaveView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useOnAppLifecycleStateChangeでpausedになった瞬間にログ出力する

    return const Placeholder();
  }
}
```

---

### 問題45: usePlatformBrightness — OSのダーク/ライトモードを購読する

**対象hook**: `usePlatformBrightness`
**難易度**: ★★☆☆☆

**学べること**
- `usePlatformBrightness()` が現在の `Brightness`(`Brightness.light` / `Brightness.dark`)を返し、OS設定変更時に自動リビルドされること
- アプリ独自のテーマ切り替えUIを作らずとも、OS設定に追従する実装ができること

**要件**
- `SystemThemeAwareView` を `HookWidget` として実装する
- `usePlatformBrightness()` の結果に応じて、背景色を白(`Brightness.light`)か黒(`Brightness.dark`)に切り替える `Container` を表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SystemThemeAwareView extends HookWidget {
  const SystemThemeAwareView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: usePlatformBrightness()を使い、背景色を出し分ける

    return const Placeholder();
  }
}
```

---

### 問題46: useOnPlatformBrightnessChange — 明るさ変化をトリガーに副作用を起こす

**対象hook**: `useOnPlatformBrightnessChange`
**難易度**: ★★★☆☆

**学べること**
- `useOnPlatformBrightnessChange` は `usePlatformBrightness` と違いリビルドを起こさず、変化前後の `Brightness` を受け取るコールバックだけを登録すること
- OSのテーマ変更をトリガーに、SnackBarなどでユーザーに通知する副作用の実装パターン

**要件**
- `ThemeChangeToastView` を `HookWidget` として実装する
- `useOnPlatformBrightnessChange((previous, current) { ... })` を使い、明るさが変化した瞬間に `ScaffoldMessenger.of(context).showSnackBar(...)` で「テーマが変わりました」と表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ThemeChangeToastView extends HookWidget {
  const ThemeChangeToastView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useOnPlatformBrightnessChangeで変化のたびにSnackBarを表示する

    return const SizedBox.shrink();
  }
}
```
