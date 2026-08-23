# freezed 問題集

`freezed: ^3.2.6-dev.1` / `freezed_annotation: ^3.1.0` が提供する機能を、実際にコードを書きながら習得するための問題集です。
回答例は [freezed-answers.md](./freezed-answers.md) を参照してください(問題番号が対応しています)。

## 進め方

- 各問題の「雛形コード」の `TODO` コメント部分を実装してください。
- 各問題は他の問題に依存しない、単体で動く `Widget` として作成されています。動作確認する場合は `lib/` 配下に一時的にファイルを作成し、`MaterialApp` の `home` に渡して実行してください(`part` で参照している `.freezed.dart` / `.g.dart` は `dart run build_runner build` で生成されます)。
- Riverpod連携の問題(問題26〜28)は `ProviderScope` の中で実行してください。
- 各問題には「画面に何が表示されるか」を要件として明記しています。実行して目視(または`debugPrint`のログをターミナル/DevTools consoleで確認)し、要件どおりに動くか確認してください。
- 難易度は ★1(易しい)〜★5(難しい) の5段階です。
- 迷ったら回答例を見る前に、公式ドキュメント( https://pub.dev/packages/freezed )も参考にしてください。

## 目次

1. 基本のfreezedクラス — 問題01〜06
2. Union型・パターンマッチ — 問題07〜13
3. JSON変換 — 問題14〜18
4. コレクション・不変性 — 問題19〜21
5. 継承・ジェネリクス・高度な構文 — 問題22〜25
6. Riverpod連携 — 問題26〜28

---

## 1. 基本のfreezedクラス

### 問題01: 基本のfreezedクラスを作る

**対象**: `@freezed` の基本構文(`sealed class` + `factory`)
**難易度**: ★☆☆☆☆

**学べること**
- `@freezed sealed class X with _$X` の基本構文
- `factory` コンストラクタでイミュータブルなフィールドを定義する方法
- `part 'xxx.freezed.dart';` が生成コードを取り込む役割を持つこと

**要件**
- `User`(`name: String`, `age: int`)を freezed クラスとして定義する
- `UserFormView` を `HookWidget` として実装する
- 名前・年齢を入力する2つの `TextField` を配置する
- 「作成」ボタンを押すと入力値から `User` インスタンスを生成し、画面に「名前: ○○ / 年齢: ○○」の形式で表示する(未作成時は「未作成」と表示する)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_form_view.freezed.dart';

// TODO: Userをfreezedクラスとして定義する(name: String, age: int)

class UserFormView extends HookWidget {
  const UserFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final ageController = useTextEditingController();
    // TODO: User? を保持するuseStateを作成する(初期値null)

    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '名前'),
        ),
        TextField(
          controller: ageController,
          decoration: const InputDecoration(labelText: '年齢'),
          keyboardType: TextInputType.number,
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: 入力値からUserを作成し、useStateに保存する
          },
          child: const Text('作成'),
        ),
        const Text('未作成'), // TODO: user != null なら「名前: ○○ / 年齢: ○○」を表示する
      ],
    );
  }
}
```

---

### 問題02: copyWith — 一部フィールドだけを更新する

**対象**: `copyWith`
**難易度**: ★★☆☆☆

**学べること**
- freezedが自動生成する `copyWith` メソッドの使い方
- 「一部のフィールドだけ変更し、残りは維持した新しいインスタンス」を作る、イミュータブルな更新パターン

**要件**
- `Profile`(`name: String`, `age: int`)を freezed クラスとして定義する
- `ProfileAgeView` を `HookWidget` として実装する
- `useState<Profile>` の初期値として `Profile(name: 'ゲスト', age: 20)` を保持する
- 「年齢+1」ボタンを押すと `copyWith` で `age` だけを+1した新しいインスタンスに差し替える(`name` は変化しない)
- 画面には常に「名前: ○○ / 年齢: ○○」を表示し、ボタンを押すたびに年齢だけが増えることを確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_age_view.freezed.dart';

// TODO: Profileをfreezedクラスとして定義する(name: String, age: int)

class ProfileAgeView extends HookWidget {
  const ProfileAgeView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useState<Profile>(Profile(name: 'ゲスト', age: 20))を作成する

    return Column(
      children: [
        const Text('名前: TODO / 年齢: TODO'),
        ElevatedButton(
          onPressed: () {
            // TODO: copyWithでageだけ+1した新しいインスタンスに差し替える
          },
          child: const Text('年齢+1'),
        ),
      ],
    );
  }
}
```

---

### 問題03: `==` / `hashCode` — 値等価性を確認する

**対象**: 自動生成される `==` / `hashCode`
**難易度**: ★★☆☆☆

**学べること**
- freezedクラスは同じフィールド値を持てば `==` で等しいと判定される(値等価性)こと
- 通常のDartクラス(インスタンス等価性)との違い

**要件**
- `Point`(`x: int`, `y: int`)を freezed クラスとして定義する
- `PointEqualityView` を `HookWidget` として実装する
- 「比較」ボタンを押すと、その場で `Point(x: 1, y: 2)` を2つ別々に生成し、`==` で比較した結果(`true`/`false`)を `useState<bool?>` に保存して画面に表示する
- ボタンを押すと必ず「等しい」と表示されることを確認する(異なるインスタンスでも値が同じなら等しいと判定されるのがfreezedの特徴)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'point_equality_view.freezed.dart';

// TODO: Pointをfreezedクラスとして定義する(x: int, y: int)

class PointEqualityView extends HookWidget {
  const PointEqualityView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: bool? を保持するuseStateを作成する(初期値null)

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // TODO: Point(x: 1, y: 2)を2つ別々に生成し、==で比較した結果を保存する
          },
          child: const Text('比較'),
        ),
        const Text('未比較'), // TODO: 結果に応じて「等しい」/「等しくない」を表示する
      ],
    );
  }
}
```

---

### 問題04: `toString` — 自動生成される文字列表現を確認する

**対象**: 自動生成される `toString`
**難易度**: ★☆☆☆☆

**学べること**
- freezedクラスは `toString()` をオーバーライドし、クラス名とフィールド一覧を含む文字列を自動生成すること
- デバッグ時にオブジェクトの中身を確認しやすくなる利点

**要件**
- `Book`(`title: String`, `author: String`)を freezed クラスとして定義する
- `BookToStringView` を `HookWidget` として実装する
- `const Book(title: 'ノルウェイの森', author: '村上春樹')` のようなインスタンスを1つ作り、`Text(book.toString())` でそのまま画面に表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'book_to_string_view.freezed.dart';

// TODO: Bookをfreezedクラスとして定義する(title: String, author: String)

class BookToStringView extends HookWidget {
  const BookToStringView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Bookのインスタンスを1つ作成する

    return const Placeholder();
    // Text(book.toString())
  }
}
```

---

### 問題05: `@Default` — デフォルト値を設定する

**対象**: `@Default`
**難易度**: ★★☆☆☆

**学べること**
- `@Default(value)` で必須ではないフィールドに初期値を設定する方法
- 一部フィールドを省略してインスタンス化した際にデフォルト値が使われることの確認

**要件**
- `Coupon`(`code: String` は必須、`discountPercent: int` は `@Default(10)`)を freezed クラスとして定義する
- `CouponDefaultView` を `HookWidget` として実装する
- 「作成」ボタンを押すと `code` だけを渡して(`discountPercent` は省略して)`Coupon` を生成し、`useState<Coupon?>` に保存する
- 画面に「コード: ○○ / 割引: ○○%」と表示し、割引率がデフォルト値の10%になっていることを確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'coupon_default_view.freezed.dart';

// TODO: Couponをfreezedクラスとして定義する
// code: String は必須、discountPercent: int は @Default(10)

class CouponDefaultView extends HookWidget {
  const CouponDefaultView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Coupon? を保持するuseStateを作成する(初期値null)

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // TODO: codeだけを渡してCouponを作成する(discountPercentは省略する)
          },
          child: const Text('作成'),
        ),
        const Text('未作成'), // TODO: 「コード: ○○ / 割引: ○○%」を表示する
      ],
    );
  }
}
```

---

### 問題06: プライベートコンストラクタ + カスタムゲッター

**対象**: `X._()` + カスタムゲッター/メソッド
**難易度**: ★★★☆☆

**学べること**
- `abstract class X with _$X { const X._(); const factory X(...) = _X; }` の形でプライベートコンストラクタを追加すると、クラス本体に独自のゲッターやメソッドを書けるようになること
- freezedが生成する部分と自分で書く部分を共存させる方法

**要件**
- `Circle`(`radius: double`)を freezed クラスとして定義し、`area`(円の面積、`pi * radius * radius`)を計算するゲッターを追加する
- `CircleAreaView` を `HookWidget` として実装する
- 半径を入力する `TextField` を配置する
- 「計算」ボタンを押すと入力値から `Circle` を生成し、`circle.area` の値を画面に表示する

**雛形コード**
```dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'circle_area_view.freezed.dart';

// TODO: Circleをfreezedクラスとして定義する(radius: double)
// プライベートコンストラクタ(Circle._())を使い、areaゲッター(pi * radius * radius)を追加する

class CircleAreaView extends HookWidget {
  const CircleAreaView({super.key});

  @override
  Widget build(BuildContext context) {
    final radiusController = useTextEditingController();
    // TODO: Circle? を保持するuseStateを作成する(初期値null)

    return Column(
      children: [
        TextField(
          controller: radiusController,
          decoration: const InputDecoration(labelText: '半径'),
          keyboardType: TextInputType.number,
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: 入力値からCircleを作成する
          },
          child: const Text('計算'),
        ),
        const Text('面積: -'), // TODO: circle.areaを表示する
      ],
    );
  }
}
```

---

## 2. Union型・パターンマッチ

### 問題07: シンプルなUnion型を作る

**対象**: Union型(複数の `factory` コンストラクタ)
**難易度**: ★★★☆☆

**学べること**
- freezedのUnion型(sealed class + 複数の名前付き `factory`)の基本構文
- 「状態(state)」をクラスの種類として表現する考え方

**要件**
- `AuthState` を freezed のUnion型として定義する。`AuthState.loggedIn(String userName)` と `AuthState.loggedOut()` の2種類の状態を持つ
- `AuthToggleView` を `HookWidget` として実装する
- `useState<AuthState>` の初期値は `AuthState.loggedOut()` とする
- 「ログイン」ボタンで `AuthState.loggedIn('太郎')` に、「ログアウト」ボタンで `AuthState.loggedOut()` に切り替える
- 画面に現在の状態(ログイン中か未ログインか)を文字で表示する(判定方法は自由。パターンマッチの書き方は次の問題以降で学ぶ)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_toggle_view.freezed.dart';

// TODO: AuthStateをUnion型として定義する
// AuthState.loggedIn(String userName) と AuthState.loggedOut() の2種類

class AuthToggleView extends HookWidget {
  const AuthToggleView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: useState<AuthState>(AuthState.loggedOut())を作成する

    return Column(
      children: [
        const Text('状態: TODO'),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                // TODO: AuthState.loggedIn('太郎')に切り替える
              },
              child: const Text('ログイン'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: AuthState.loggedOut()に切り替える
              },
              child: const Text('ログアウト'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

### 問題08: `switch` 式でパターンマッチする

**対象**: Dartの `switch` 式によるパターンマッチ
**難易度**: ★★★☆☆

**学べること**
- Dart 3の `switch` 式でfreezedのUnion型を分岐する書き方
- 生成された各サブクラス(`AuthStateLoggedIn` 等)のフィールドをパターン内で取り出す方法(`:final userName` のような分解)

**要件**
- 問題07と同じ `AuthState` を使う
- `AuthIconView` を `HookWidget` として実装する
- ログイン/ログアウトを切り替えるボタンは問題07と同様に用意する
- `switch (state) { ... }` 式を使い、ログイン中は緑色のチェックアイコン+「ようこそ、○○さん」、未ログインならグレーのアイコン+「未ログイン」を画面に表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_icon_view.freezed.dart';

// TODO: AuthStateをUnion型として定義する(問題07と同じ)

class AuthIconView extends HookWidget {
  const AuthIconView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<AuthState>(AuthState.loggedOut());

    return Column(
      children: [
        // TODO: switch式でstate.valueを判定し、
        // ログイン中は緑チェックアイコン+「ようこそ、○○さん」、
        // 未ログインならグレーアイコン+「未ログイン」を表示する
        const Placeholder(),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => state.value = AuthState.loggedIn('太郎'),
              child: const Text('ログイン'),
            ),
            ElevatedButton(
              onPressed: () => state.value = AuthState.loggedOut(),
              child: const Text('ログアウト'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

### 問題09: `.when()` — 全パターンを網羅的に処理する

**対象**: `.when()`
**難易度**: ★★★☆☆

**学べること**
- freezedが自動生成する `.when()` メソッドで、全パターンをコールバック形式で網羅的に処理する方法
- `switch` 式との書き味の違い

**要件**
- 問題07と同じ `AuthState` を使う
- `AuthWhenView` を `HookWidget` として実装する
- 問題08と同じUI要件(ログイン中/未ログインでアイコンとメッセージを出し分ける)を、今度は `state.when(loggedIn: ..., loggedOut: ...)` で実装する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_when_view.freezed.dart';

// TODO: AuthStateをUnion型として定義する(問題07と同じ)

class AuthWhenView extends HookWidget {
  const AuthWhenView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<AuthState>(AuthState.loggedOut());

    return Column(
      children: [
        // TODO: state.value.when(loggedIn: (userName) => ..., loggedOut: () => ...)で
        // ログイン中/未ログインのWidgetを出し分ける
        const Placeholder(),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => state.value = AuthState.loggedIn('太郎'),
              child: const Text('ログイン'),
            ),
            ElevatedButton(
              onPressed: () => state.value = AuthState.loggedOut(),
              child: const Text('ログアウト'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

### 問題10: `.map()` — クラスインスタンスごとに処理する

**対象**: `.map()`
**難易度**: ★★★☆☆

**学べること**
- `.map()` は `.when()` と似ているが、フィールドを分解した値ではなく生成されたサブクラスのインスタンス自体をコールバックで受け取ること
- `.when()` との使い分け(サブクラス全体を扱いたいか、フィールド単位で扱いたいか)

**要件**
- 問題07と同じ `AuthState` を使う
- `AuthMapView` を `HookWidget` として実装する
- 問題09と同じUIを、今度は `state.map(loggedIn: (value) => ..., loggedOut: (value) => ...)` で実装する(`value.userName` のようにインスタンス経由でフィールドへアクセスする)

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_map_view.freezed.dart';

// TODO: AuthStateをUnion型として定義する(問題07と同じ)

class AuthMapView extends HookWidget {
  const AuthMapView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<AuthState>(AuthState.loggedOut());

    return Column(
      children: [
        // TODO: state.value.map(loggedIn: (value) => ..., loggedOut: (value) => ...)で
        // ログイン中/未ログインのWidgetを出し分ける
        const Placeholder(),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => state.value = AuthState.loggedIn('太郎'),
              child: const Text('ログイン'),
            ),
            ElevatedButton(
              onPressed: () => state.value = AuthState.loggedOut(),
              child: const Text('ログアウト'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

### 問題11: `.whenOrNull()` / `.maybeWhen()` — 一部のパターンだけ処理する

**対象**: `.whenOrNull()` / `.maybeWhen()`
**難易度**: ★★★★☆

**学べること**
- 全パターンを書かずに「特定のパターンの時だけ」処理したい場合の書き方
- `.whenOrNull()` はマッチしないと `null` を返し、`.maybeWhen()` は `orElse` で代替値を指定できるという違い

**要件**
- `BannerState` を freezed のUnion型として定義する。`BannerState.none()` / `BannerState.info(String message)` / `BannerState.warning(String message)` の3種類
- `WarningBannerView` を `HookWidget` として実装する
- 「なし」「情報」「警告」の3つのボタンで `useState<BannerState>` を切り替える
- `.maybeWhen()`(または `.whenOrNull()`)を使い、`warning` の場合だけ画面上部に赤いバナー(`message` を表示)を出し、それ以外の場合は何も表示しない

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'warning_banner_view.freezed.dart';

// TODO: BannerStateをUnion型として定義する
// BannerState.none() / BannerState.info(String message) / BannerState.warning(String message)

class WarningBannerView extends HookWidget {
  const WarningBannerView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<BannerState>(BannerState.none());

    return Column(
      children: [
        // TODO: state.value.maybeWhen(warning: (message) => ..., orElse: () => const SizedBox.shrink())で
        // warningの場合だけ赤いバナーを表示する
        const Placeholder(),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => state.value = BannerState.none(),
              child: const Text('なし'),
            ),
            ElevatedButton(
              onPressed: () => state.value = BannerState.info('お知らせがあります'),
              child: const Text('情報'),
            ),
            ElevatedButton(
              onPressed: () => state.value = BannerState.warning('接続が不安定です'),
              child: const Text('警告'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

### 問題12: `.mapOrNull()` / `.maybeMap()` — 一部のパターンだけ処理する(インスタンス版)

**対象**: `.mapOrNull()` / `.maybeMap()`
**難易度**: ★★★★☆

**学べること**
- 問題11の `.whenOrNull()` / `.maybeWhen()` の「インスタンスを受け取る版」であること
- `.map()` 系と `.when()` 系のペアの対応関係を整理する

**要件**
- 問題11と同じ `BannerState` を使う
- `WarningBannerMapView` を `HookWidget` として実装する
- 問題11と同じUI要件を、今度は `.maybeMap()`(または `.mapOrNull()`)で実装する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'warning_banner_map_view.freezed.dart';

// TODO: BannerStateをUnion型として定義する(問題11と同じ)

class WarningBannerMapView extends HookWidget {
  const WarningBannerMapView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<BannerState>(BannerState.none());

    return Column(
      children: [
        // TODO: state.value.maybeMap(warning: (value) => ..., orElse: () => const SizedBox.shrink())で
        // warningの場合だけ赤いバナーを表示する
        const Placeholder(),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => state.value = BannerState.none(),
              child: const Text('なし'),
            ),
            ElevatedButton(
              onPressed: () => state.value = BannerState.info('お知らせがあります'),
              child: const Text('情報'),
            ),
            ElevatedButton(
              onPressed: () => state.value = BannerState.warning('接続が不安定です'),
              child: const Text('警告'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

### 問題13: Union型に共通フィールドを持たせる

**対象**: Union型 + 共通フィールド(カスタムの生成コンストラクタ)
**難易度**: ★★★★☆

**学べること**
- Union型の全サブクラスに共通のフィールドを持たせたい場合、プライベートの生成コンストラクタ(`TaskState._({...}) : field = ...`)で初期化ロジックを共有する方法
- 各 `factory` から、その共通フィールド用の名前付き引数を受け渡す書き方

**要件**
- `TaskState` を freezed のUnion型として定義する。`TaskState.todo({DateTime? updatedAt})` / `TaskState.done({DateTime? updatedAt})` の2種類を持ち、両方に共通の `updatedAt`(省略時は生成時刻)フィールドを持たせる
- `TaskUpdatedAtView` を `HookWidget` として実装する
- 「未着手にする」「完了にする」の2つのボタンで状態を切り替える(切り替えるたびに新しい `updatedAt` が記録される)
- 画面に現在の状態(未着手/完了)と「最終更新: hh:mm:ss」を表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_updated_at_view.freezed.dart';

// TODO: TaskStateをUnion型として定義する
// TaskState.todo({DateTime? updatedAt}) / TaskState.done({DateTime? updatedAt})
// 共通フィールドupdatedAtを持たせ、省略時はDateTime.now()を使う

class TaskUpdatedAtView extends HookWidget {
  const TaskUpdatedAtView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<TaskState>(TaskState.todo());

    String formatTime(DateTime time) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
    }

    return Column(
      children: [
        // TODO: 状態(未着手/完了)を表示する
        const Text('状態: TODO'),
        Text('最終更新: ${formatTime(state.value.updatedAt)}'),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                // TODO: TaskState.todo()に切り替える
              },
              child: const Text('未着手にする'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: TaskState.done()に切り替える
              },
              child: const Text('完了にする'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## 3. JSON変換

### 問題14: `fromJson` / `toJson` — 相互変換する

**対象**: `fromJson` / `toJson`
**難易度**: ★★★☆☆

**学べること**
- `@freezed` と `json_serializable` を組み合わせ、`fromJson` / `toJson` を自動生成する方法
- `factory X.fromJson(Map<String, dynamic> json) => _$XFromJson(json);` という定型パターン

**要件**
- `Movie`(`title: String`, `year: int`)を freezed クラス + JSON変換対応として定義する
- `MovieJsonView` を `HookWidget` として実装する
- 雛形に用意されたJSON文字列(`_movieJson`)を「パース」ボタンでデコードし、`Movie.fromJson(...)` の結果を画面に表示する
- 「JSON化」ボタンでパース済みの `Movie` を `toJson()` し、`jsonEncode` した文字列を画面に表示する

**雛形コード**
```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'movie_json_view.freezed.dart';
part 'movie_json_view.g.dart';

const _movieJson = '{"title": "Interstellar", "year": 2014}';

// TODO: Movieをfreezedクラス+JSON変換対応として定義する(title: String, year: int)
// factory Movie.fromJson(...) => _$MovieFromJson(...) を追加する

class MovieJsonView extends HookWidget {
  const MovieJsonView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Movie? を保持するuseStateを作成する(初期値null)
    // TODO: String? を保持するuseState(JSON化した結果表示用)を作成する

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // TODO: _movieJsonをjsonDecodeし、Movie.fromJson(...)でパースして保存する
          },
          child: const Text('パース'),
        ),
        const Text('未パース'), // TODO: 「タイトル: ○○ / 公開年: ○○」を表示する
        ElevatedButton(
          onPressed: () {
            // TODO: パース済みのMovieをtoJson()し、jsonEncodeした文字列を保存する
          },
          child: const Text('JSON化'),
        ),
        const Text(''), // TODO: JSON化した文字列を表示する
      ],
    );
  }
}
```

---

### 問題15: `@JsonKey` — フィールド名をマッピングする

**対象**: `@JsonKey(name: ...)`
**難易度**: ★★★☆☆

**学べること**
- JSON側のキー名(例: snake_case)とDart側のフィールド名(camelCase)が異なる場合に `@JsonKey(name: '...')` でマッピングする方法

**要件**
- `WeatherInfo`(`cityName: String` ← JSON上は `city_name`、`temperatureCelsius: double` ← JSON上は `temp_c`)を freezed クラス + JSON変換対応として定義する
- `WeatherJsonView` を `HookWidget` として実装する
- 雛形のJSON文字列(`_weatherJson`)をボタンでパースし、「都市: ○○ / 気温: ○○℃」の形式で画面に表示する(Dart側のフィールド名でアクセスしつつ、JSON側のキー名は異なることを確認する)

**雛形コード**
```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_json_view.freezed.dart';
part 'weather_json_view.g.dart';

const _weatherJson = '{"city_name": "Tokyo", "temp_c": 28.5}';

// TODO: WeatherInfoをfreezedクラス+JSON変換対応として定義する
// cityName: String は @JsonKey(name: 'city_name')
// temperatureCelsius: double は @JsonKey(name: 'temp_c')

class WeatherJsonView extends HookWidget {
  const WeatherJsonView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: WeatherInfo? を保持するuseStateを作成する(初期値null)

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // TODO: _weatherJsonをjsonDecodeし、WeatherInfo.fromJson(...)でパースして保存する
          },
          child: const Text('パース'),
        ),
        const Text('未パース'), // TODO: 「都市: ○○ / 気温: ○○℃」を表示する
      ],
    );
  }
}
```

---

### 問題16: ネストしたfreezedクラスのJSON変換

**対象**: ネストしたfreezedクラス + JSON変換
**難易度**: ★★★★☆

**学べること**
- 親のfreezedクラスが子のfreezedクラスをフィールドとして持つ場合の `fromJson` の書き方
- `json_serializable` がネストしたオブジェクトも自動的に再帰変換してくれること

**要件**
- `Address`(`city: String`, `zip: String`)、`Customer`(`name: String`, `address: Address`)をそれぞれ freezed クラス + JSON変換対応として定義する
- `CustomerJsonView` を `HookWidget` として実装する
- 雛形のネストしたJSON文字列(`_customerJson`)をボタンでパースし、「顧客: ○○ / 住所: ○○ ○○」の形式で(子の `Address` の情報まで含めて)画面に表示する

**雛形コード**
```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_json_view.freezed.dart';
part 'customer_json_view.g.dart';

const _customerJson =
    '{"name": "Taro", "address": {"city": "Osaka", "zip": "530-0001"}}';

// TODO: Addressをfreezedクラス+JSON変換対応として定義する(city: String, zip: String)
// TODO: Customerをfreezedクラス+JSON変換対応として定義する(name: String, address: Address)

class CustomerJsonView extends HookWidget {
  const CustomerJsonView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Customer? を保持するuseStateを作成する(初期値null)

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // TODO: _customerJsonをjsonDecodeし、Customer.fromJson(...)でパースして保存する
          },
          child: const Text('パース'),
        ),
        const Text('未パース'), // TODO: 「顧客: ○○ / 住所: ○○ ○○」を表示する
      ],
    );
  }
}
```

---

### 問題17: Union型のJSON変換(discriminatorキー)

**対象**: Union型 + `fromJson`(discriminator)
**難易度**: ★★★★★

**学べること**
- Union型に `fromJson` を追加すると、JSON側のキー(既定では `runtimeType`、値は各 `factory` 名)を見てどのサブクラスにパースするか自動判定してくれること
- discriminatorキーの値が factory コンストラクタ名(小文字)と対応していること

**要件**
- `LoadState` を freezed のUnion型 + JSON変換対応として定義する。`LoadState.loading()` / `LoadState.success(String data)` / `LoadState.error(String message)` の3種類
- `LoadStateJsonView` を `HookWidget` として実装する
- 雛形に用意された3つのJSON文字列(loading/success/error それぞれの `runtimeType` を持つ)をボタンでパースし、`useState<LoadState>` に保存する
- パース結果に応じて、ローディング中はスピナー、成功時は緑文字で `data`、エラー時は赤文字で `message` を画面に表示する(パターンマッチの書き方は問題09/10で学んだものを使ってよい)

**雛形コード**
```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'load_state_json_view.freezed.dart';
part 'load_state_json_view.g.dart';

const _loadingJson = '{"runtimeType": "loading"}';
const _successJson = '{"runtimeType": "success", "data": "取得成功"}';
const _errorJson = '{"runtimeType": "error", "message": "通信に失敗しました"}';

// TODO: LoadStateをUnion型+JSON変換対応として定義する
// LoadState.loading() / LoadState.success(String data) / LoadState.error(String message)

class LoadStateJsonView extends HookWidget {
  const LoadStateJsonView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<LoadState>(LoadState.loading());

    return Column(
      children: [
        // TODO: state.valueをパターンマッチし、
        // loadingはスピナー、successは緑文字でdata、errorは赤文字でmessageを表示する
        const Placeholder(),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                // TODO: _loadingJsonをjsonDecodeし、LoadState.fromJson(...)でパースしてstateに保存する
              },
              child: const Text('loading'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: _successJsonをパースしてstateに保存する
              },
              child: const Text('success'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: _errorJsonをパースしてstateに保存する
              },
              child: const Text('error'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

### 問題18: `@JsonKey(defaultValue: ...)` と `@Default` の組み合わせ

**対象**: `@JsonKey(defaultValue: ...)` + `@Default`
**難易度**: ★★★★☆

**学べること**
- JSON側にキーが存在しない場合、`@JsonKey(defaultValue: ...)` を指定することでエラーにならず既定値が使われること
- Dartのコンストラクタレベルのデフォルト(`@Default`)とJSONパース時のデフォルト(`@JsonKey(defaultValue: ...)`)は別物であり、JSON変換をするなら両方指定する必要があること

**要件**
- `AppConfig`(`notificationsEnabled: bool`、`@Default(true)` かつ `@JsonKey(defaultValue: true)`)を freezed クラス + JSON変換対応として定義する
- `ConfigDefaultView` を `HookWidget` として実装する
- 雛形の、キーが空のJSON文字列(`_emptyConfigJson`、中身は `{}`)をボタンでパースし、`notificationsEnabled` がデフォルト値の `true` になっていることを画面に表示する

**雛形コード**
```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'config_default_view.freezed.dart';
part 'config_default_view.g.dart';

const _emptyConfigJson = '{}';

// TODO: AppConfigをfreezedクラス+JSON変換対応として定義する
// notificationsEnabled: bool は @Default(true) かつ @JsonKey(defaultValue: true)

class ConfigDefaultView extends HookWidget {
  const ConfigDefaultView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: AppConfig? を保持するuseStateを作成する(初期値null)

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // TODO: _emptyConfigJsonをjsonDecodeし、AppConfig.fromJson(...)でパースして保存する
          },
          child: const Text('パース'),
        ),
        const Text('未パース'), // TODO: 「通知: 有効」/「通知: 無効」を表示する
      ],
    );
  }
}
```

---

## 4. コレクション・不変性

### 問題19: `List` フィールドの不変性を確認する

**対象**: コレクションフィールドの不変性(既定)
**難易度**: ★★★☆☆

**学べること**
- freezedはコレクション型のフィールド(`List` / `Map` / `Set`)を既定で `unmodifiable`(変更不可)にすること
- 変更しようとすると `UnsupportedError` が発生すること

**要件**
- `Playlist`(`items: List<String>`)を freezed クラスとして定義する
- `ImmutableListView` を `HookWidget` として実装する
- `useState<Playlist>` の初期値を `Playlist(items: ['Song A'])` とする
- 「追加を試す」ボタンを押すと `playlist.items.add('Song B')` を `try`/`catch` し、例外が発生したことを示すメッセージ(例:「エラー: Unsupported operation」)を画面に表示する。リストの件数は変化しないことを確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'immutable_list_view.freezed.dart';

// TODO: Playlistをfreezedクラスとして定義する(items: List<String>)

class ImmutableListView extends HookWidget {
  const ImmutableListView({super.key});

  @override
  Widget build(BuildContext context) {
    final playlist = useState(Playlist(items: const ['Song A']));
    final errorMessage = useState<String?>(null);

    return Column(
      children: [
        Text('曲数: ${playlist.value.items.length}'),
        Text(errorMessage.value ?? ''),
        ElevatedButton(
          onPressed: () {
            // TODO: playlist.value.items.add('Song B')をtry/catchし、
            // 例外メッセージをerrorMessageに保存する
          },
          child: const Text('追加を試す'),
        ),
      ],
    );
  }
}
```

---

### 問題20: `makeCollectionsUnmodifiable: false` でオプションを指定する

**対象**: `@Freezed(makeCollectionsUnmodifiable: false)`
**難易度**: ★★★☆☆

**学べること**
- `@Freezed(...)` アノテーションでクラスごとのコード生成オプションを指定できること
- `makeCollectionsUnmodifiable: false` を指定すると、コレクションフィールドが変更可能になること(問題19との挙動の違い)

**要件**
- `MutablePlaylist`(`items: List<String>`)を `@Freezed(makeCollectionsUnmodifiable: false)` を付けて定義する
- `MutableListView` を `HookWidget` として実装する
- 問題19と同じ「追加を試す」ボタンの操作を行い、今度は例外が発生せず `items.add('Song B')` が成功し、画面上の曲数が1つ増えることを確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mutable_list_view.freezed.dart';

// TODO: @Freezed(makeCollectionsUnmodifiable: false)を付けてMutablePlaylistを定義する(items: List<String>)

class MutableListView extends HookWidget {
  const MutableListView({super.key});

  @override
  Widget build(BuildContext context) {
    // MutablePlaylist自体はuseRefで保持する(useStateにすると、==がリストの中身を比較するため、
    // リスト内容をその場でミューテートしただけでは新しい値だと判定されずリビルドされない)
    final playlistRef = useRef(MutablePlaylist(items: ['Song A']));
    // 曲数の表示・リビルドのトリガーは別のuseState<int>で持つ
    final itemCount = useState(playlistRef.value.items.length);

    return Column(
      children: [
        Text('曲数: ${itemCount.value}'),
        ElevatedButton(
          onPressed: () {
            // TODO: playlistRef.value.items.add('Song B')を実行し、
            // itemCount.valueを最新のitems.lengthに更新してリビルドを起こす
          },
          child: const Text('追加を試す'),
        ),
      ],
    );
  }
}
```

---

### 問題21: `Set` を使った複雑なフィールドを扱う

**対象**: `Set` フィールド
**難易度**: ★★★☆☆

**学べること**
- freezedクラスの `Set` フィールドを使い、重複を自動的に除去できること
- コレクションを持つfreezedクラスと `copyWith` を組み合わせた更新パターン

**要件**
- `TagBoard`(`tags: Set<String>`)を freezed クラスとして定義する
- `TagBoardView` を `HookWidget` として実装する
- タグ入力用の `TextField` と「追加」ボタンを配置する
- 追加ボタンを押すと、既存の `tags` に入力値を加えた新しい `Set` で `copyWith` し、`useState<TagBoard>` を更新する
- 画面には現在の `tags` を一覧表示する。同じタグを2回追加しても件数が増えない(重複しない)ことを確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_board_view.freezed.dart';

// TODO: TagBoardをfreezedクラスとして定義する(tags: Set<String>)

class TagBoardView extends HookWidget {
  const TagBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    final tagController = useTextEditingController();
    final board = useState(TagBoard(tags: const {}));

    return Column(
      children: [
        TextField(controller: tagController),
        ElevatedButton(
          onPressed: () {
            // TODO: board.value.tagsに入力値を加えた新しいSetでcopyWithし、boardを更新する
          },
          child: const Text('追加'),
        ),
        Text('タグ: ${board.value.tags.join(', ')}'),
      ],
    );
  }
}
```

---

## 5. 継承・ジェネリクス・高度な構文

### 問題22: ジェネリクスを使ったfreezedクラスを作る

**対象**: ジェネリクス(`Result<T>`)
**難易度**: ★★★★☆

**学べること**
- freezedのUnion型に型引数(ジェネリクス)を持たせる方法
- 成功/失敗を表現する「Resultラッパー」のような汎用的な型を作るパターン

**要件**
- `Result<T>` を freezed のUnion型として定義する。`Result.ok(T value)` / `Result.err(String message)` の2種類
- `ResultToggleView` を `HookWidget` として実装する
- 「成功にする」ボタンで `Result<int>.ok(42)` に、「失敗にする」ボタンで `Result<int>.err('計算に失敗しました')` に切り替える
- パターンマッチ(`switch` / `.when()` など任意)で、成功時は緑文字で「成功: 42」、失敗時は赤文字で「失敗: ○○」と画面に表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'result_toggle_view.freezed.dart';

// TODO: Result<T>をUnion型として定義する
// Result.ok(T value) / Result.err(String message)

class ResultToggleView extends HookWidget {
  const ResultToggleView({super.key});

  @override
  Widget build(BuildContext context) {
    final result = useState<Result<int>>(Result.ok(42));

    return Column(
      children: [
        // TODO: result.valueをパターンマッチし、
        // 成功時は緑文字で「成功: ○○」、失敗時は赤文字で「失敗: ○○」を表示する
        const Placeholder(),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => result.value = Result.ok(42),
              child: const Text('成功にする'),
            ),
            ElevatedButton(
              onPressed: () => result.value = Result.err('計算に失敗しました'),
              child: const Text('失敗にする'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

### 問題23: 非freezedクラスを `extends` する

**対象**: 非freezedクラスの継承
**難易度**: ★★★★☆

**学べること**
- freezedクラスが通常のDartクラス(非freezed)を `extends` できること
- `super.field` を使い、親クラスのコンストラクタへフィールドを受け渡す方法

**要件**
- 雛形の `Animal`(非freezedクラス、`name: String` を持つ)を使う
- `Dog`(`breed: String` を追加で持つ)を、`Animal` を継承した freezed クラスとして定義する
- `DogInfoView` を `HookWidget` として実装する
- `const Dog('ポチ', '柴犬')` のようなインスタンスを1つ作り、継承元の `name` と自身の `breed` を組み合わせて「名前: ポチ(柴犬)」と画面に表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dog_info_view.freezed.dart';

class Animal {
  const Animal(this.name);
  final String name;
}

// TODO: DogをAnimalを継承したfreezedクラスとして定義する(breed: Stringを追加)
// プライベートコンストラクタでsuper.nameを受け渡す

class DogInfoView extends HookWidget {
  const DogInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Dog('ポチ', '柴犬')のインスタンスを1つ作成する

    return const Placeholder();
    // Text('名前: ${dog.name}(${dog.breed})')
  }
}
```

---

### 問題24: 私有コンストラクタでバリデーション用のプロパティを追加する

**対象**: `X._()` + バリデーション用の計算プロパティ
**難易度**: ★★★★☆

**学べること**
- プライベートコンストラクタを使い、フィールドの値が妥当かどうかを判定する `isValid` のような計算プロパティを追加する方法
- freezedのコンストラクタ自体は例外を投げるバリデーションに向かないため、「作成はできるが、妥当性は別途プロパティで確認する」という設計パターン

**要件**
- `Percentage`(`value: int`)を freezed クラスとして定義し、`0 <= value <= 100` かどうかを返す `isValid` ゲッターを追加する
- `PercentageInputView` を `HookWidget` として実装する
- 数値入力用の `TextField` と「確認」ボタンを配置する
- ボタンを押すと入力値から `Percentage` を生成し、`isValid` が `true` なら緑文字で「有効な値です: ○○%」、`false` なら赤文字で「0〜100の範囲で入力してください」と画面に表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'percentage_input_view.freezed.dart';

// TODO: Percentageをfreezedクラスとして定義する(value: int)
// プライベートコンストラクタ(Percentage._())を使い、
// isValidゲッター(0 <= value && value <= 100)を追加する

class PercentageInputView extends HookWidget {
  const PercentageInputView({super.key});

  @override
  Widget build(BuildContext context) {
    final valueController = useTextEditingController();
    // TODO: Percentage? を保持するuseStateを作成する(初期値null)

    return Column(
      children: [
        TextField(
          controller: valueController,
          keyboardType: TextInputType.number,
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: 入力値からPercentageを作成する
          },
          child: const Text('確認'),
        ),
        const Text(''), // TODO: isValidに応じてメッセージを色分け表示する
      ],
    );
  }
}
```

---

### 問題25: `mixin` を適用する

**対象**: freezedクラスへの `mixin` 適用
**難易度**: ★★★★☆

**学べること**
- freezedクラスに独自の `mixin` を組み合わせられること(`with _$X, MyMixin`)
- `mixin` 側で宣言した抽象ゲッター/メソッドをfreezedクラス側で実装する方法

**要件**
- 雛形の `Loggable` mixin(`logLabel` という `String` 型の抽象ゲッターを持つ)を使う
- `Product`(`name: String`, `price: int`)を、`Loggable` を `with` した freezed クラスとして定義する。`logLabel` は `'name=$name, price=$price'` のような文字列を返す
- `ProductLogView` を `HookWidget` として実装する
- `const Product(name: 'Widget', price: 500)` のようなインスタンスを1つ作り、`product.logLabel` を画面に表示する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_log_view.freezed.dart';

mixin Loggable {
  String get logLabel;
}

// TODO: ProductをLoggableをwithしたfreezedクラスとして定義する(name: String, price: int)
// logLabelゲッターで 'name=$name, price=$price' のような文字列を返す

class ProductLogView extends HookWidget {
  const ProductLogView({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Productのインスタンスを1つ作成する

    return const Placeholder();
    // Text(product.logLabel)
  }
}
```

---

## 6. Riverpod連携

### 問題26: freezedクラスを `@riverpod` の `Future` プロバイダの戻り値型として使う

**対象**: freezed + `@riverpod`(`Future` プロバイダ)
**難易度**: ★★★★☆

**学べること**
- freezedクラスをRiverpodの非同期プロバイダの戻り値型として使う典型パターン
- `AsyncValue` を通じてローディング/成功/エラーの状態がUIに反映される仕組み

**要件**
- `Quote`(`text: String`, `author: String`)を freezed クラスとして定義する
- 1秒待ってから `Quote` を1件返す `@riverpod` の `Future` プロバイダ `quote` を定義する
- `QuoteView` を `HookConsumerWidget` として実装する
- `ref.watch(quoteProvider)` を購読し、ローディング中は `CircularProgressIndicator`、取得後は「"○○" — ○○」の形式で画面に表示する
- `ProviderScope` 内で実行して動作を確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quote_view.freezed.dart';
part 'quote_view.g.dart';

// TODO: Quoteをfreezedクラスとして定義する(text: String, author: String)

// TODO: @riverpodを付け、1秒待ってからQuoteを1件返すFuture<Quote> quote(Ref ref)を定義する

class QuoteView extends HookConsumerWidget {
  const QuoteView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: ref.watch(quoteProvider)でAsyncValue<Quote>を購読する

    return const Placeholder();
    // ローディング中はCircularProgressIndicator、取得後は「"text" — author」を表示する
  }
}
```

---

### 問題27: freezedのUnion型でUI状態を表現し `AsyncValue` と組み合わせる

**対象**: freezedのUnion型 + `AsyncValue`
**難易度**: ★★★★★

**学べること**
- `AsyncValue`(Riverpodが提供する非同期状態)を、freezedの独自Union型(`ScreenState`)へ変換してからUIを組み立てる設計
- 「Riverpodの非同期状態」と「画面の表示状態」を分離するメリット

**要件**
- `ScreenState` を freezed のUnion型として定義する。`ScreenState.loading()` / `ScreenState.data(String value)` / `ScreenState.error(String message)` の3種類
- 1秒待ってから文字列を1つ返す `@riverpod` の `Future` プロバイダ `message` を定義する
- `ScreenStateView` を `HookConsumerWidget` として実装する
- `ref.watch(messageProvider)`(`AsyncValue<String>`)を `.when()` で `ScreenState` に変換し、その `ScreenState` をさらにパターンマッチしてUIを組み立てる(ローディング中はスピナー、成功時は緑文字、エラー時は赤文字)
- `ProviderScope` 内で実行して動作を確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'screen_state_view.freezed.dart';
part 'screen_state_view.g.dart';

// TODO: ScreenStateをUnion型として定義する
// ScreenState.loading() / ScreenState.data(String value) / ScreenState.error(String message)

// TODO: @riverpodを付け、1秒待ってから文字列を1つ返すFuture<String> message(Ref ref)を定義する

class ScreenStateView extends HookConsumerWidget {
  const ScreenStateView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(messageProvider);

    // TODO: asyncValue.when(loading: ..., data: ..., error: ...)でScreenStateへ変換する

    // TODO: 変換したScreenStateをパターンマッチし、
    // loadingはスピナー、dataは緑文字、errorは赤文字で表示する
    return const Placeholder();
  }
}
```

---

### 問題28: freezedクラスをRiverpodの `Notifier` の `state` として使う

**対象**: freezed + `Notifier`
**難易度**: ★★★★☆

**学べること**
- freezedクラスをRiverpodの `Notifier` の `state` として使い、`copyWith` でイミュータブルに更新する典型パターン
- `useState` + `copyWith`(問題02)と、`Notifier` + `copyWith` の違い(状態をウィジェットの外で一元管理できる)

**要件**
- `CounterState`(`count: int`、`@Default(0)`)を freezed クラスとして定義する
- `@riverpod` の `Notifier` クラス `CounterNotifier` を定義する。`build()` は `const CounterState()` を返し、`increment()` メソッドで `state` を `copyWith(count: state.count + 1)` する
- `CounterNotifierView` を `HookConsumerWidget` として実装する
- `ref.watch(counterNotifierProvider)` で現在の `count` を画面に表示し、ボタンを押すと `ref.read(counterNotifierProvider.notifier).increment()` を呼び出して画面上の数値が増えることを確認する
- `ProviderScope` 内で実行して動作を確認する

**雛形コード**
```dart
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_notifier_view.freezed.dart';
part 'counter_notifier_view.g.dart';

// TODO: CounterStateをfreezedクラスとして定義する(count: int, @Default(0))

// TODO: @riverpodを付けたCounterNotifierクラスを定義する
// build()はconst CounterState()を返し、increment()でstateをcopyWithして更新する

class CounterNotifierView extends HookConsumerWidget {
  const CounterNotifierView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: ref.watch(counterNotifierProvider)でCounterStateを購読する

    return const Placeholder();
    // Text('${state.count}') と、
    // onPressed: () => ref.read(counterNotifierProvider.notifier).increment() のボタンを表示する
  }
}
```
