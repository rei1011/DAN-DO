# freezed 問題集 回答例

[freezed-exercises.md](./freezed-exercises.md) の回答例集です。問題番号が対応しています。
まずは自分で実装してから確認することをおすすめします。

---

## 1. 基本のfreezedクラス

### 問題01の回答例: 基本のfreezedクラスを作る

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_form_view.freezed.dart';

@freezed
sealed class User with _$User {
  const factory User({required String name, required int age}) = _User;
}

class UserFormView extends HookWidget {
  const UserFormView({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final ageController = useTextEditingController();
    final user = useState<User?>(null);

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
            user.value = User(
              name: nameController.text,
              age: int.tryParse(ageController.text) ?? 0,
            );
          },
          child: const Text('作成'),
        ),
        Text(
          user.value == null
              ? '未作成'
              : '名前: ${user.value!.name} / 年齢: ${user.value!.age}',
        ),
      ],
    );
  }
}
```

**解説**
- `@freezed sealed class User with _$User { const factory User({...}) = _User; }` が基本形。`_$User` は `part 'user_form_view.freezed.dart';` で取り込まれる生成コード側のmixinで、これが `copyWith` / `==` / `hashCode` / `toString` を提供する。
- `const factory User({...}) = _User;` の `_User` は「実際にインスタンスを作る、freezedが自動生成する実装クラス」を指す。開発者は基本的に `_User` を直接使わず、`User(...)` という公開コンストラクタ経由で生成する。
- `.g.dart`(json_serializable)は今回使っていないため `part` は `.freezed.dart` のみでよい。JSON変換が必要になるのは問題14以降。

---

### 問題02の回答例: copyWith — 一部フィールドだけを更新する

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_age_view.freezed.dart';

@freezed
sealed class Profile with _$Profile {
  const factory Profile({required String name, required int age}) = _Profile;
}

class ProfileAgeView extends HookWidget {
  const ProfileAgeView({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = useState(const Profile(name: 'ゲスト', age: 20));

    return Column(
      children: [
        Text('名前: ${profile.value.name} / 年齢: ${profile.value.age}'),
        ElevatedButton(
          onPressed: () {
            profile.value = profile.value.copyWith(age: profile.value.age + 1);
          },
          child: const Text('年齢+1'),
        ),
      ],
    );
  }
}
```

**解説**
- `copyWith` は「変更したいフィールドだけを名前付き引数で渡し、残りは元のインスタンスの値をそのまま引き継いだ新しいインスタンス」を返す。元の `profile.value` 自体は変更されない(イミュータブル)。
- `age` だけを更新しているため `name` は常に `'ゲスト'` のまま。もし `Profile` を手書きしていたら、`copyWith` 相当のメソッドをフィールド数だけ引数を持つ形で自前実装する必要があり、フィールドが増えるたびに書き直しが発生する。freezedはこれを自動生成してくれる。
- `useState` の `.value` に新しいインスタンスを代入することで、`ValueNotifier` が変更を検知してリビルドが走る。

---

### 問題03の回答例: `==` / `hashCode` — 値等価性を確認する

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'point_equality_view.freezed.dart';

@freezed
sealed class Point with _$Point {
  const factory Point({required int x, required int y}) = _Point;
}

class PointEqualityView extends HookWidget {
  const PointEqualityView({super.key});

  @override
  Widget build(BuildContext context) {
    final isEqual = useState<bool?>(null);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            const a = Point(x: 1, y: 2);
            const b = Point(x: 1, y: 2);
            isEqual.value = a == b;
          },
          child: const Text('比較'),
        ),
        Text(
          isEqual.value == null
              ? '未比較'
              : (isEqual.value! ? '等しい' : '等しくない'),
        ),
      ],
    );
  }
}
```

**解説**
- 通常のDartクラス(`==` をオーバーライドしていないもの)は、フィールドの値が同じでも別インスタンスなら `==` は `false`(参照(インスタンス)等価性)になる。freezedクラスは自動生成された `==` / `hashCode` により、全フィールドの値が等しければ `==` が `true` になる(値等価性)。
- この性質のおかげで、`Set` に入れて重複を除去したり、`Map` のキーとして使ったり、Riverpodの `AsyncValue`/プロバイダの再構築要否判定(値が変わっていなければリビルドしない)などで扱いやすくなる。
- 今回は `const Point(x: 1, y: 2)` を2つ書いているが、Dartの `const` インスタンスは同一値なら実行時に自動的に同一インスタンスへ正規化される(canonicalization)。ただし freezedの値等価性は `const` でなくても(`Point(x: 1, y: 2)` のように毎回新規生成しても)成立する点を確認したい場合は `const` を外して試すとよい。

---

### 問題04の回答例: `toString` — 自動生成される文字列表現を確認する

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'book_to_string_view.freezed.dart';

@freezed
sealed class Book with _$Book {
  const factory Book({required String title, required String author}) = _Book;
}

class BookToStringView extends HookWidget {
  const BookToStringView({super.key});

  @override
  Widget build(BuildContext context) {
    const book = Book(title: 'ノルウェイの森', author: '村上春樹');

    return Text(book.toString());
  }
}
```

**解説**
- 生成される `toString()` は `Book(title: ノルウェイの森, author: 村上春樹)` のような「クラス名(フィールド名: 値, ...)」形式の文字列を返す。
- `print(book)` や `debugPrint(book.toString())` でログに出力すればターミナルやDevTools consoleでも同じ内容を確認できる(画面表示・ログ出力のどちらでも構成をそのまま確認できるのがポイント)。
- 手書きクラスでは `toString` を書き忘れると `Instance of 'Book'` としか表示されずデバッグしづらいが、freezedクラスは常に中身が見える文字列になる。

---

### 問題05の回答例: `@Default` — デフォルト値を設定する

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'coupon_default_view.freezed.dart';

@freezed
sealed class Coupon with _$Coupon {
  const factory Coupon({
    required String code,
    @Default(10) int discountPercent,
  }) = _Coupon;
}

class CouponDefaultView extends HookWidget {
  const CouponDefaultView({super.key});

  @override
  Widget build(BuildContext context) {
    final coupon = useState<Coupon?>(null);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            coupon.value = const Coupon(code: 'WELCOME');
          },
          child: const Text('作成'),
        ),
        Text(
          coupon.value == null
              ? '未作成'
              : 'コード: ${coupon.value!.code} / 割引: ${coupon.value!.discountPercent}%',
        ),
      ],
    );
  }
}
```

**解説**
- `@Default(10)` を付けたフィールドは `required` にできず、省略可能になる。省略した場合は自動的に `10` が使われる。
- `@Default` は「Dartのコンストラクタレベルのデフォルト値」であり、JSONパース時にキーが無い場合のデフォルトとは別物(問題18で扱う `@JsonKey(defaultValue: ...)` が必要)。両方を組み合わせないと、JSON変換時にはデフォルトが効かずエラーになる場合がある点に注意。
- `@Default` を使わない場合は `discountPercent` を `required` にするか `int?`(nullable)にする必要があり、呼び出し側で必ず値を意識しなければならない。

---

### 問題06の回答例: プライベートコンストラクタ + カスタムゲッター

```dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'circle_area_view.freezed.dart';

@freezed
abstract class Circle with _$Circle {
  const Circle._();

  const factory Circle({required double radius}) = _Circle;

  double get area => pi * radius * radius;
}

class CircleAreaView extends HookWidget {
  const CircleAreaView({super.key});

  @override
  Widget build(BuildContext context) {
    final radiusController = useTextEditingController();
    final circle = useState<Circle?>(null);

    return Column(
      children: [
        TextField(
          controller: radiusController,
          decoration: const InputDecoration(labelText: '半径'),
          keyboardType: TextInputType.number,
        ),
        ElevatedButton(
          onPressed: () {
            circle.value = Circle(
              radius: double.tryParse(radiusController.text) ?? 0,
            );
          },
          child: const Text('計算'),
        ),
        Text('面積: ${circle.value == null ? '-' : circle.value!.area}'),
      ],
    );
  }
}
```

**解説**
- `sealed class` ではなく `abstract class` を使い、`const Circle._();` というプライベートの生成コンストラクタを追加している。これにより `area` のような独自のゲッター/メソッドをクラス本体に自由に書けるようになる。
- `sealed class` のままプライベートコンストラクタを足すこともできるが、Union型を作る予定がなく単一の実装クラスしか持たないなら `abstract class` を使うのが一般的(`sealed` は「このクラスを継承できるのは同じライブラリ内の限られたサブクラスだけ」という制約を表明するためのキーワードで、Union型を作らないなら必須ではない)。
- `area` はフィールドではなく計算プロパティ(ゲッター)なので、`copyWith` の対象にはならず、生成される `==`/`hashCode`/`toString` にも影響しない(あくまで `radius` から都度計算される)。

---

## 2. Union型・パターンマッチ

### 問題07の回答例: シンプルなUnion型を作る

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_toggle_view.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.loggedIn(String userName) = AuthStateLoggedIn;
  const factory AuthState.loggedOut() = AuthStateLoggedOut;
}

class AuthToggleView extends HookWidget {
  const AuthToggleView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<AuthState>(const AuthState.loggedOut());

    return Column(
      children: [
        Text(
          state.value is AuthStateLoggedIn ? 'ログイン中' : '未ログイン',
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => state.value = const AuthState.loggedIn('太郎'),
              child: const Text('ログイン'),
            ),
            ElevatedButton(
              onPressed: () => state.value = const AuthState.loggedOut(),
              child: const Text('ログアウト'),
            ),
          ],
        ),
      ],
    );
  }
}
```

**解説**
- `sealed class AuthState with _$AuthState` に対して、名前付きの `factory` コンストラクタを複数(`loggedIn` / `loggedOut`)定義すると、それぞれが独立した実装クラス(`AuthStateLoggedIn` / `AuthStateLoggedOut`)として生成される。これがfreezedの「Union型」で、Redux/リストの `enum` 的な状態表現を型安全に行える。
- `= AuthStateLoggedIn;` のように、生成される実装クラス名を明示的に指定できる(main.dartの `Response.data(...) = ResponseData;` と同じ指定方法)。指定しない場合は `_$AuthState` を元にした既定の名前が使われる。
- ここでは判定に `is` 演算子を使っているが、これは「Union型そのものは作れたが、まだパターンマッチの書き方を学んでいない」段階の暫定的な書き方。問題08以降で `switch` / `.when()` / `.map()` というfreezed本来の使い方を学ぶ。

---

### 問題08の回答例: `switch` 式でパターンマッチする

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_icon_view.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.loggedIn(String userName) = AuthStateLoggedIn;
  const factory AuthState.loggedOut() = AuthStateLoggedOut;
}

class AuthIconView extends HookWidget {
  const AuthIconView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<AuthState>(const AuthState.loggedOut());

    return Column(
      children: [
        switch (state.value) {
          AuthStateLoggedIn(:final userName) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              Text('ようこそ、$userNameさん'),
            ],
          ),
          AuthStateLoggedOut() => const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle_outlined, color: Colors.grey),
              Text('未ログイン'),
            ],
          ),
        },
        Row(
          children: [
            ElevatedButton(
              onPressed: () => state.value = const AuthState.loggedIn('太郎'),
              child: const Text('ログイン'),
            ),
            ElevatedButton(
              onPressed: () => state.value = const AuthState.loggedOut(),
              child: const Text('ログアウト'),
            ),
          ],
        ),
      ],
    );
  }
}
```

**解説**
- `sealed class` はDart 3の「網羅性チェック」と組み合わさる。`switch (state.value) { ... }` で `AuthStateLoggedIn` と `AuthStateLoggedOut` の両方を書き漏らすと、コンパイルエラー(`default` が無いのに非網羅)になる。これにより「新しいサブクラスを追加したのに分岐の追加を忘れる」というバグを防げる。
- `AuthStateLoggedIn(:final userName)` はDart 3のオブジェクトパターンで、`AuthStateLoggedIn` 型にマッチしつつ、その `userName` フィールドを同名の変数として取り出している(分割代入のようなもの)。
- `.when()` / `.map()`(問題09/10)を使わずとも、freezedの `sealed class` はDart標準の `switch` 式だけでパターンマッチできる。generated codeに依存しない分、より「素のDartらしい」書き方と言える。

---

### 問題09の回答例: `.when()` — 全パターンを網羅的に処理する

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_when_view.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.loggedIn(String userName) = AuthStateLoggedIn;
  const factory AuthState.loggedOut() = AuthStateLoggedOut;
}

class AuthWhenView extends HookWidget {
  const AuthWhenView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<AuthState>(const AuthState.loggedOut());

    return Column(
      children: [
        state.value.when(
          loggedIn: (userName) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              Text('ようこそ、$userNameさん'),
            ],
          ),
          loggedOut: () => const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle_outlined, color: Colors.grey),
              Text('未ログイン'),
            ],
          ),
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => state.value = const AuthState.loggedIn('太郎'),
              child: const Text('ログイン'),
            ),
            ElevatedButton(
              onPressed: () => state.value = const AuthState.loggedOut(),
              child: const Text('ログアウト'),
            ),
          ],
        ),
      ],
    );
  }
}
```

**解説**
- `.when()` は各 `factory` コンストラクタ名に対応する名前付きコールバック(`loggedIn` / `loggedOut`)を **すべて** 必須で渡す必要がある。1つでも書き忘れるとコンパイルエラーになり、`switch` 式と同様の網羅性チェックが働く。
- `loggedIn: (userName) => ...` のように、コールバックの引数にはfactoryコンストラクタの引数(この場合 `String userName`)がそのまま渡ってくる。`switch` 式のオブジェクトパターンより、IDEの補完が効きやすく読みやすいと感じる人も多い。
- `switch` 式との使い分けは好みの部分も大きいが、`.when()` は「メソッドチェーンとして式の途中に埋め込みやすい」、`switch` は「Dart標準の構文なので他のパターン(型パターン・リストパターン等)と混在させやすい」という違いがある。

---

### 問題10の回答例: `.map()` — クラスインスタンスごとに処理する

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_map_view.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.loggedIn(String userName) = AuthStateLoggedIn;
  const factory AuthState.loggedOut() = AuthStateLoggedOut;
}

class AuthMapView extends HookWidget {
  const AuthMapView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<AuthState>(const AuthState.loggedOut());

    return Column(
      children: [
        state.value.map(
          loggedIn: (value) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              Text('ようこそ、${value.userName}さん'),
            ],
          ),
          loggedOut: (value) => const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle_outlined, color: Colors.grey),
              Text('未ログイン'),
            ],
          ),
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => state.value = const AuthState.loggedIn('太郎'),
              child: const Text('ログイン'),
            ),
            ElevatedButton(
              onPressed: () => state.value = const AuthState.loggedOut(),
              child: const Text('ログアウト'),
            ),
          ],
        ),
      ],
    );
  }
}
```

**解説**
- `.map()` は `.when()` と同じ網羅性チェックを持つが、コールバックが受け取るのはフィールドを分解した値ではなく、そのサブクラス自身のインスタンス(`AuthStateLoggedIn` のインスタンス)。そのため `value.userName` のようにインスタンス経由でフィールドへアクセスする。
- 「サブクラスのインスタンスそのもの(例えば `toString()` や他のメソッドも呼びたい)を扱いたいなら `.map()`」「フィールドの値だけ使えれば十分なら `.when()`」という使い分けの目安になる。
- `.when()` / `.map()` はどちらも内部的には `switch` 文(または同等のif-else連鎖)として生成されているだけで、実行時のパフォーマンス上の優劣は基本的にない。読みやすさで選んでよい。

---

### 問題11の回答例: `.whenOrNull()` / `.maybeWhen()` — 一部のパターンだけ処理する

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'warning_banner_view.freezed.dart';

@freezed
sealed class BannerState with _$BannerState {
  const factory BannerState.none() = BannerStateNone;
  const factory BannerState.info(String message) = BannerStateInfo;
  const factory BannerState.warning(String message) = BannerStateWarning;
}

class WarningBannerView extends HookWidget {
  const WarningBannerView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<BannerState>(const BannerState.none());

    return Column(
      children: [
        state.value.maybeWhen(
          warning: (message) => ColoredBox(
            color: Colors.red,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => state.value = const BannerState.none(),
              child: const Text('なし'),
            ),
            ElevatedButton(
              onPressed: () =>
                  state.value = const BannerState.info('お知らせがあります'),
              child: const Text('情報'),
            ),
            ElevatedButton(
              onPressed: () =>
                  state.value = const BannerState.warning('接続が不安定です'),
              child: const Text('警告'),
            ),
          ],
        ),
      ],
    );
  }
}
```

**解説**
- `.maybeWhen()` は `.when()` と違い、書いたパターン(ここでは `warning` のみ)以外は `orElse` の戻り値で代替される。全パターンを書く必要がないため、「一部の状態のときだけ特別扱いしたい」場面に向く。
- `.whenOrNull()` はさらにシンプルで、マッチしなかった場合は自動的に `null` を返す(`orElse` を書く必要がない代わりに、戻り値の型が常に `nullable` になる)。今回のように「マッチしなければ何も表示しない(`SizedBox.shrink()`)」なら `.maybeWhen(... , orElse: () => const SizedBox.shrink())` と `.whenOrNull(...) ?? const SizedBox.shrink()` はほぼ同じ結果になる。
- `none` / `info` の場合はどちらもバナー非表示という同じ結果になるため、`orElse` で1つにまとめられるのが `.maybeWhen()` の利点(`.when()` だとこの2つのケースを別々に同じ内容で書く必要がある)。

---

### 問題12の回答例: `.mapOrNull()` / `.maybeMap()` — 一部のパターンだけ処理する(インスタンス版)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'warning_banner_map_view.freezed.dart';

@freezed
sealed class BannerState with _$BannerState {
  const factory BannerState.none() = BannerStateNone;
  const factory BannerState.info(String message) = BannerStateInfo;
  const factory BannerState.warning(String message) = BannerStateWarning;
}

class WarningBannerMapView extends HookWidget {
  const WarningBannerMapView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<BannerState>(const BannerState.none());

    return Column(
      children: [
        state.value.maybeMap(
          warning: (value) => ColoredBox(
            color: Colors.red,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                value.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => state.value = const BannerState.none(),
              child: const Text('なし'),
            ),
            ElevatedButton(
              onPressed: () =>
                  state.value = const BannerState.info('お知らせがあります'),
              child: const Text('情報'),
            ),
            ElevatedButton(
              onPressed: () =>
                  state.value = const BannerState.warning('接続が不安定です'),
              child: const Text('警告'),
            ),
          ],
        ),
      ],
    );
  }
}
```

**解説**
- `.maybeMap()` は `.mapOrNull()` の「`orElse` あり版」で、`.when()`/`.maybeWhen()` と `.map()`/`.maybeMap()` の対応関係は次のように整理できる: 「全パターン必須か・一部だけでよいか」×「フィールド分解か・インスタンスか」の2軸の組み合わせが4つのメソッド(`when`/`maybeWhen`/`map`/`maybeMap`)、そして「一部だけでよい」系にはさらに `orElse` 無しで `null` を返す版(`whenOrNull`/`mapOrNull`)が存在する。
- 今回は `value.message` のように、マッチしたサブクラス(`BannerStateWarning`)のインスタンス経由でフィールドを取得している。
- 全6メソッド(`when`/`map`/`whenOrNull`/`mapOrNull`/`maybeWhen`/`maybeMap`)を一度に覚える必要はなく、まずは `switch` 式と `.when()`(全パターン必須)、`.maybeWhen()`(一部だけ)の3つを使えれば実務では十分なことが多い。

---

### 問題13の回答例: Union型に共通フィールドを持たせる

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_updated_at_view.freezed.dart';

@freezed
sealed class TaskState with _$TaskState {
  TaskState._({DateTime? updatedAt})
    : updatedAt = updatedAt ?? DateTime.now();

  factory TaskState.todo({DateTime? updatedAt}) = TaskStateTodo;
  factory TaskState.done({DateTime? updatedAt}) = TaskStateDone;

  @override
  final DateTime updatedAt;
}

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
        Text(state.value is TaskStateDone ? '状態: 完了' : '状態: 未着手'),
        Text('最終更新: ${formatTime(state.value.updatedAt)}'),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => state.value = TaskState.todo(),
              child: const Text('未着手にする'),
            ),
            ElevatedButton(
              onPressed: () => state.value = TaskState.done(),
              child: const Text('完了にする'),
            ),
          ],
        ),
      ],
    );
  }
}
```

**解説**
- `TaskState._({DateTime? updatedAt}) : updatedAt = updatedAt ?? DateTime.now();` は、Union型の **すべての** サブクラスが経由するプライベートの生成コンストラクタ。ここで `updatedAt` を計算・初期化しておくことで、`todo` / `done` のどちらの `factory` から作っても共通のロジックで `updatedAt` が設定される。
- 各 `factory`(`TaskState.todo` / `TaskState.done`)は `{DateTime? updatedAt}` という名前付き引数をそのままプライベートコンストラクタへ中継しているだけ。呼び出し側で `updatedAt` を省略すると「その時点の現在時刻」が自動的に使われる。
- `@override final DateTime updatedAt;` の `@override` は、この宣言が(プライベートコンストラクタの引数と同名の)フィールドを表すことを示すfreezedの慣習的な書き方。プライベートコンストラクタが `const` にできない(`DateTime.now()` は定数式ではない)ため、`factory` 側にも `const` を付けていない点に注意。

---

## 3. JSON変換

### 問題14の回答例: `fromJson` / `toJson` — 相互変換する

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'movie_json_view.freezed.dart';
part 'movie_json_view.g.dart';

const _movieJson = '{"title": "Interstellar", "year": 2014}';

@freezed
sealed class Movie with _$Movie {
  const factory Movie({required String title, required int year}) = _Movie;

  factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);
}

class MovieJsonView extends HookWidget {
  const MovieJsonView({super.key});

  @override
  Widget build(BuildContext context) {
    final movie = useState<Movie?>(null);
    final jsonText = useState<String?>(null);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            final decoded = jsonDecode(_movieJson) as Map<String, dynamic>;
            movie.value = Movie.fromJson(decoded);
          },
          child: const Text('パース'),
        ),
        Text(
          movie.value == null
              ? '未パース'
              : 'タイトル: ${movie.value!.title} / 公開年: ${movie.value!.year}',
        ),
        ElevatedButton(
          onPressed: () {
            if (movie.value != null) {
              jsonText.value = jsonEncode(movie.value!.toJson());
            }
          },
          child: const Text('JSON化'),
        ),
        Text(jsonText.value ?? ''),
      ],
    );
  }
}
```

**解説**
- `factory Movie.fromJson(Map<String, dynamic> json) => _$MovieFromJson(json);` の `_$MovieFromJson` は `json_serializable` が `part 'movie_json_view.g.dart';` 側に生成する変換関数。`@freezed` と組み合わせる場合、`.freezed.dart` と `.g.dart` の両方の `part` が必要になる。
- `toJson()` はfreezedクラス側に自動で生えるメソッドで、`_$MovieToJson` を内部で呼び出して `Map<String, dynamic>` を返す。それを `jsonEncode` すれば文字列化できる。
- `fromJson`/`toJson` はどちらも「対応するJSONのキー名がDart側のフィールド名と一致している」ことを前提にしている。一致しない場合の対処は問題15で扱う。

---

### 問題15の回答例: `@JsonKey` — フィールド名をマッピングする

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_json_view.freezed.dart';
part 'weather_json_view.g.dart';

const _weatherJson = '{"city_name": "Tokyo", "temp_c": 28.5}';

@freezed
sealed class WeatherInfo with _$WeatherInfo {
  const factory WeatherInfo({
    @JsonKey(name: 'city_name') required String cityName,
    @JsonKey(name: 'temp_c') required double temperatureCelsius,
  }) = _WeatherInfo;

  factory WeatherInfo.fromJson(Map<String, dynamic> json) =>
      _$WeatherInfoFromJson(json);
}

class WeatherJsonView extends HookWidget {
  const WeatherJsonView({super.key});

  @override
  Widget build(BuildContext context) {
    final weather = useState<WeatherInfo?>(null);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            final decoded = jsonDecode(_weatherJson) as Map<String, dynamic>;
            weather.value = WeatherInfo.fromJson(decoded);
          },
          child: const Text('パース'),
        ),
        Text(
          weather.value == null
              ? '未パース'
              : '都市: ${weather.value!.cityName} / 気温: ${weather.value!.temperatureCelsius}℃',
        ),
      ],
    );
  }
}
```

**解説**
- `@JsonKey(name: 'city_name')` を `cityName` フィールドに付けることで、「Dart側では `cityName`(camelCase)としてアクセスしつつ、JSON側では `city_name`(snake_case)として読み書きする」というマッピングができる。バックエンドAPIの命名規則(snake_case)とDartの命名規則(lowerCamelCase)が異なる場合の定番パターン。
- `@JsonKey` は `toJson()` する際にも同じマッピングが使われるため、`weather.value!.toJson()` を呼べば `{"city_name": ..., "temp_c": ...}` のようなMapが返る(一貫性がある)。
- `@JsonKey` には `name` 以外にも `defaultValue`(問題18)、`includeFromJson`/`includeToJson`(特定方向の変換から除外)などのオプションがある。

---

### 問題16の回答例: ネストしたfreezedクラスのJSON変換

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_json_view.freezed.dart';
part 'customer_json_view.g.dart';

const _customerJson =
    '{"name": "Taro", "address": {"city": "Osaka", "zip": "530-0001"}}';

@freezed
sealed class Address with _$Address {
  const factory Address({required String city, required String zip}) =
      _Address;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
}

@freezed
sealed class Customer with _$Customer {
  const factory Customer({required String name, required Address address}) =
      _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}

class CustomerJsonView extends HookWidget {
  const CustomerJsonView({super.key});

  @override
  Widget build(BuildContext context) {
    final customer = useState<Customer?>(null);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            final decoded = jsonDecode(_customerJson) as Map<String, dynamic>;
            customer.value = Customer.fromJson(decoded);
          },
          child: const Text('パース'),
        ),
        Text(
          customer.value == null
              ? '未パース'
              : '顧客: ${customer.value!.name} / 住所: ${customer.value!.address.city} ${customer.value!.address.zip}',
        ),
      ],
    );
  }
}
```

**解説**
- `Customer` の `address` フィールドの型を(生の `Map` ではなく)freezedクラスの `Address` にしておくと、`json_serializable` は自動的に `address` の値を `Address.fromJson(...)` に渡してネストした変換を行ってくれる。開発者が手動でネストを解いてパースする必要はない。
- `Address` 自身にも `fromJson`/`toJson` を用意しておく必要がある(ネストされる側のfreezedクラスも `part '....g.dart';` とセットのJSON対応クラスである必要がある)。
- `Customer.fromJson(...).toJson()` のように親を `toJson()` すると、`address` の部分も再帰的に `Address.toJson()` された結果(ネストした `Map`)になる。

---

### 問題17の回答例: Union型のJSON変換(discriminatorキー)

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

@freezed
sealed class LoadState with _$LoadState {
  const factory LoadState.loading() = LoadStateLoading;
  const factory LoadState.success(String data) = LoadStateSuccess;
  const factory LoadState.error(String message) = LoadStateError;

  factory LoadState.fromJson(Map<String, dynamic> json) =>
      _$LoadStateFromJson(json);
}

class LoadStateJsonView extends HookWidget {
  const LoadStateJsonView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useState<LoadState>(const LoadState.loading());

    LoadState parse(String source) {
      final decoded = jsonDecode(source) as Map<String, dynamic>;
      return LoadState.fromJson(decoded);
    }

    return Column(
      children: [
        switch (state.value) {
          LoadStateLoading() => const CircularProgressIndicator(),
          LoadStateSuccess(:final data) => Text(
            data,
            style: const TextStyle(color: Colors.green),
          ),
          LoadStateError(:final message) => Text(
            message,
            style: const TextStyle(color: Colors.red),
          ),
        },
        Row(
          children: [
            ElevatedButton(
              onPressed: () => state.value = parse(_loadingJson),
              child: const Text('loading'),
            ),
            ElevatedButton(
              onPressed: () => state.value = parse(_successJson),
              child: const Text('success'),
            ),
            ElevatedButton(
              onPressed: () => state.value = parse(_errorJson),
              child: const Text('error'),
            ),
          ],
        ),
      ],
    );
  }
}
```

**解説**
- Union型に `fromJson` を追加すると、`json_serializable` はJSON側に既定で `"runtimeType"` というキーを要求し、その値(`"loading"` / `"success"` / `"error"`、各 `factory` コンストラクタ名をそのまま使う)を見て、対応するサブクラスの `fromJson` に振り分ける(内部的には `switch (json['runtimeType']) { case 'loading': return LoadStateLoading.fromJson(json); ... }` のようなコードが生成される)。
- discriminatorキー名やその値をカスタマイズしたい場合は、クラス全体に `@JsonKey(name: '...')` を型注釈的に使う方法や、各factoryに `@FreezedUnionValue('...')` を付ける方法があるが、既定のままで多くの場合は困らない。
- `toJson()` を呼んだ場合も自動的に `"runtimeType"` キー付きのJSONが出力されるため、サーバー側もこの規約(`runtimeType` キー)に合わせる必要がある点は事前にすり合わせておくとよい。

---

### 問題18の回答例: `@JsonKey(defaultValue: ...)` と `@Default` の組み合わせ

```dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'config_default_view.freezed.dart';
part 'config_default_view.g.dart';

const _emptyConfigJson = '{}';

@freezed
sealed class AppConfig with _$AppConfig {
  const factory AppConfig({
    @Default(true) @JsonKey(defaultValue: true) bool notificationsEnabled,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
}

class ConfigDefaultView extends HookWidget {
  const ConfigDefaultView({super.key});

  @override
  Widget build(BuildContext context) {
    final config = useState<AppConfig?>(null);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            final decoded =
                jsonDecode(_emptyConfigJson) as Map<String, dynamic>;
            config.value = AppConfig.fromJson(decoded);
          },
          child: const Text('パース'),
        ),
        Text(
          config.value == null
              ? '未パース'
              : (config.value!.notificationsEnabled ? '通知: 有効' : '通知: 無効'),
        ),
      ],
    );
  }
}
```

**解説**
- `@Default(true)` だけでは「Dartのコンストラクタで省略したとき」のデフォルトしか効かない。`AppConfig.fromJson({})` のようにJSONのキーが欠けている場合には別途 `@JsonKey(defaultValue: true)` が必要で、これが無いと `json_serializable` はキー欠落時に `null` を渡そうとして型エラー(`bool` に `null` は渡せない)になる。
- つまり「Dartコード内で省略したとき」用の `@Default` と、「JSONにキーが無かったとき」用の `@JsonKey(defaultValue:)` は、目的も適用されるタイミングも異なる、別々の仕組みだと理解しておく必要がある。JSON変換もするフィールドに省略可能な値を持たせたいときは、基本的に両方をセットで付けるのが安全。
- 今回は空のJSON(`{}`)をパースしても例外にならず `notificationsEnabled: true` になることが確認できる。もし `@JsonKey(defaultValue: true)` を外すとどうなるか、実際に試してエラーメッセージを見てみるとより理解が深まる。

---

## 4. コレクション・不変性

### 問題19の回答例: `List` フィールドの不変性を確認する

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'immutable_list_view.freezed.dart';

@freezed
sealed class Playlist with _$Playlist {
  const factory Playlist({required List<String> items}) = _Playlist;
}

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
            try {
              playlist.value.items.add('Song B');
            } catch (e) {
              errorMessage.value = 'エラー: $e';
            }
          },
          child: const Text('追加を試す'),
        ),
      ],
    );
  }
}
```

**解説**
- freezedは既定で `List` / `Map` / `Set` フィールドを `unmodifiable`(変更不可)なコレクションとしてラップして保持する。そのため `playlist.value.items.add(...)` を呼ぶと `UnsupportedError: Cannot add to an unmodifiable list` のような例外が発生する。
- これは「一度作ったfreezedインスタンスのフィールドは、コレクション型であっても後から書き換えられない」という、freezed全体のイミュータビリティ思想を徹底するための挙動。フィールドを変更したい場合は、この問題で使わなかったが `copyWith(items: [...playlist.value.items, 'Song B'])` のように新しいリストを作って丸ごと差し替えるのが正しい方法。
- ボタンを何度押しても `曲数` は増えない(常に1のまま)ことを確認できれば、不変性が効いていると分かる。

---

### 問題20の回答例: `makeCollectionsUnmodifiable: false` でオプションを指定する

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mutable_list_view.freezed.dart';

@Freezed(makeCollectionsUnmodifiable: false)
sealed class MutablePlaylist with _$MutablePlaylist {
  const factory MutablePlaylist({required List<String> items}) =
      _MutablePlaylist;
}

class MutableListView extends HookWidget {
  const MutableListView({super.key});

  @override
  Widget build(BuildContext context) {
    final playlistRef = useRef(MutablePlaylist(items: ['Song A']));
    final itemCount = useState(playlistRef.value.items.length);

    return Column(
      children: [
        Text('曲数: ${itemCount.value}'),
        ElevatedButton(
          onPressed: () {
            playlistRef.value.items.add('Song B');
            itemCount.value = playlistRef.value.items.length;
          },
          child: const Text('追加を試す'),
        ),
      ],
    );
  }
}
```

**解説**
- `@freezed`(引数なし)は内部的に `@Freezed()` の既定値を使っており、`makeCollectionsUnmodifiable` は既定で `true`。`@Freezed(makeCollectionsUnmodifiable: false)` を明示することで、この既定を上書きしてコレクションフィールドを通常の(変更可能な)`List`/`Map`/`Set` のまま保持できる。
- 今回は `playlistRef.value.items.add('Song B')` が例外を投げずに成功し、リストの件数が実際に増える。問題19と見比べると `makeCollectionsUnmodifiable` の有無で挙動が変わることが確認できる。
- ここで `useState<MutablePlaylist>` ではなく `useRef` + 別の `useState<int>` を組み合わせている点に注意。`useState` の `ValueNotifier` は代入時に `oldValue == newValue` を比較して変化が無ければリビルドをスキップする。`items.add(...)` はリストの中身を直接書き換える(同じインスタンス・同じリスト参照のまま中身だけ変わる)操作なので、`playlist.value = playlist.value;` のように同じ参照を再代入してもfreezedの値等価性(リストの中身まで比較する)により「変化なし」と判定され、リビルドされない場合がある。そのため、ミュータブルな操作を行った本体は `useRef` に保持しつつ、画面表示・リビルドのトリガー用に別の状態(`itemCount`)を明示的に更新する、という組み合わせが安全。

---

### 問題21の回答例: `Set` を使った複雑なフィールドを扱う

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_board_view.freezed.dart';

@freezed
sealed class TagBoard with _$TagBoard {
  const factory TagBoard({required Set<String> tags}) = _TagBoard;
}

class TagBoardView extends HookWidget {
  const TagBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    final tagController = useTextEditingController();
    final board = useState(const TagBoard(tags: {}));

    return Column(
      children: [
        TextField(controller: tagController),
        ElevatedButton(
          onPressed: () {
            final newTag = tagController.text;
            if (newTag.isEmpty) return;
            board.value = board.value.copyWith(
              tags: {...board.value.tags, newTag},
            );
          },
          child: const Text('追加'),
        ),
        Text('タグ: ${board.value.tags.join(', ')}'),
      ],
    );
  }
}
```

**解説**
- `{...board.value.tags, newTag}` はSetのスプレッド構文で、「既存のタグをすべて含み、かつ `newTag` を追加した新しいSet」を作る。同じ文字列を複数回追加しても `Set` の性質上重複が自動的に除去される(件数が増えない)。
- 問題19/20とは異なり、ここでは既存のコレクションを直接ミューテートせず、`copyWith` で新しいコレクション(新しいSetインスタンス)ごと差し替えている。この書き方なら `useState` だけで完結し、`makeCollectionsUnmodifiable` の設定(既定の `true` のまま)でも問題なく動く。
- 「コレクションをその場で書き換えたい(問題19/20)」か「新しいコレクションを作って丸ごと差し替えたい(この問題)」かで、`makeCollectionsUnmodifiable` を気にする必要があるかどうかが変わる、という点を意識しておくとよい。

---

## 5. 継承・ジェネリクス・高度な構文

### 問題22の回答例: ジェネリクスを使ったfreezedクラスを作る

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'result_toggle_view.freezed.dart';

@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.ok(T value) = ResultOk<T>;
  const factory Result.err(String message) = ResultErr<T>;
}

class ResultToggleView extends HookWidget {
  const ResultToggleView({super.key});

  @override
  Widget build(BuildContext context) {
    final result = useState<Result<int>>(const Result.ok(42));

    return Column(
      children: [
        switch (result.value) {
          ResultOk(:final value) => Text(
            '成功: $value',
            style: const TextStyle(color: Colors.green),
          ),
          ResultErr(:final message) => Text(
            '失敗: $message',
            style: const TextStyle(color: Colors.red),
          ),
        },
        Row(
          children: [
            ElevatedButton(
              onPressed: () => result.value = const Result.ok(42),
              child: const Text('成功にする'),
            ),
            ElevatedButton(
              onPressed: () =>
                  result.value = const Result.err('計算に失敗しました'),
              child: const Text('失敗にする'),
            ),
          ],
        ),
      ],
    );
  }
}
```

**解説**
- `sealed class Result<T> with _$Result<T>` のように型引数 `<T>` をクラスと `with` 節の両方に付ける。生成される各サブクラス(`ResultOk<T>` / `ResultErr<T>`)も同じ型引数を持つ。
- `Result.ok(T value)` は成功時の値を保持し、`Result.err(String message)` はエラーメッセージだけを保持する(成功時の値の型 `T` を持たない)。このように「成功と失敗で持つ情報が異なる」状態を型安全に表現できるのがUnion型 + ジェネリクスの強み(`Result<int>` なら成功時は必ず `int` が手に入ることが型で保証される)。
- API通信の結果や、バリデーション結果などを表現する際によく使われる「Result型」「Either型」と呼ばれる設計パターンの、freezedによる実装例になっている。

---

### 問題23の回答例: 非freezedクラスを `extends` する

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dog_info_view.freezed.dart';

class Animal {
  const Animal(this.name);
  final String name;
}

@freezed
sealed class Dog extends Animal with _$Dog {
  const Dog._(super.name);
  const factory Dog(String name, String breed) = _Dog;
}

class DogInfoView extends HookWidget {
  const DogInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    const dog = Dog('ポチ', '柴犬');

    return Text('名前: ${dog.name}(${dog.breed})');
  }
}
```

**解説**
- `sealed class Dog extends Animal with _$Dog` のように、freezedクラスは非freezedの通常クラス(`Animal`)を `extends` できる。`with _$Dog` はfreezedの生成コードを取り込むための `mixin`、`extends Animal` は本来のDartの継承。
- `const Dog._(super.name);` は「`Dog` のプライベート生成コンストラクタが、受け取った `name` 引数を親クラス `Animal` のコンストラクタへそのまま渡す」ことを `super.name` という省略記法で表している。`const factory Dog(String name, String breed) = _Dog;` の `name` は継承元 `Animal` が持つフィールドを埋めるために使われ、`breed` は `Dog` 独自のフィールドになる。
- こうして生成された `Dog` インスタンスは `dog.name`(継承元由来)と `dog.breed`(`Dog` 独自)の両方にアクセスでき、`copyWith`/`==` などfreezedの通常機能もそのまま使える。

---

### 問題24の回答例: 私有コンストラクタでバリデーション用のプロパティを追加する

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'percentage_input_view.freezed.dart';

@freezed
abstract class Percentage with _$Percentage {
  const Percentage._();

  const factory Percentage(int value) = _Percentage;

  bool get isValid => value >= 0 && value <= 100;
}

class PercentageInputView extends HookWidget {
  const PercentageInputView({super.key});

  @override
  Widget build(BuildContext context) {
    final valueController = useTextEditingController();
    final percentage = useState<Percentage?>(null);

    return Column(
      children: [
        TextField(
          controller: valueController,
          keyboardType: TextInputType.number,
        ),
        ElevatedButton(
          onPressed: () {
            percentage.value = Percentage(
              int.tryParse(valueController.text) ?? -1,
            );
          },
          child: const Text('確認'),
        ),
        if (percentage.value != null)
          Text(
            percentage.value!.isValid
                ? '有効な値です: ${percentage.value!.value}%'
                : '0〜100の範囲で入力してください',
            style: TextStyle(
              color: percentage.value!.isValid ? Colors.green : Colors.red,
            ),
          ),
      ],
    );
  }
}
```

**解説**
- freezedの `const factory` コンストラクタは、内部で例外を投げるような検証ロジックを直接書けない(値を受け取ってそのままフィールドに格納するだけの、定型的なコードとして生成される)。そのため「不正な値なら例外を投げて生成自体を失敗させる」バリデーションはfreezed単体では素直には書きにくい。
- 代わりに、この回答例では「インスタンスの生成は常に成功させ、妥当かどうかは `isValid` という計算プロパティで別途判定する」設計にしている。問題06の `Circle.area` と同じ「プライベートコンストラクタ + 計算プロパティ」の仕組みを、バリデーション目的に応用した形。
- どうしても構築時に例外を投げたい場合は、freezedクラスとは別に「バリデーション付きのファクトリ関数(`Percentage? tryParse(String input) { ...; return isValid ? Percentage(v) : null; }` のような静的関数)」をクラスの外に用意し、呼び出し側ではそちらを経由させる設計にすることが多い。

---

### 問題25の回答例: `mixin` を適用する

```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_log_view.freezed.dart';

mixin Loggable {
  String get logLabel;
}

@freezed
abstract class Product with _$Product, Loggable {
  const Product._();

  const factory Product({required String name, required int price}) =
      _Product;

  @override
  String get logLabel => 'name=$name, price=$price';
}

class ProductLogView extends HookWidget {
  const ProductLogView({super.key});

  @override
  Widget build(BuildContext context) {
    const product = Product(name: 'Widget', price: 500);

    return Text(product.logLabel);
  }
}
```

**解説**
- `abstract class Product with _$Product, Loggable` のように、`with` 節にはfreezedの生成コード(`_$Product`)と自作の `mixin`(`Loggable`)をカンマ区切りで両方指定できる。
- `Loggable` は `logLabel` という抽象ゲッターだけを持つ `mixin`。`Product` クラス本体で `@override String get logLabel => ...;` のように実装を与えることで、「`Product` は `Loggable` である」という制約を満たす。
- `mixin` を使う利点は、複数の異なるfreezedクラス(例えば `Product` と `Order` など)に同じ `Loggable` を適用し、「ログ出力可能なもの一覧」のように `List<Loggable>` として横断的に扱えるようになること。今回は `sealed class` ではなく `abstract class` を使っている点にも注意(`mixin` を適用しつつプライベートコンストラクタも書く場合、`abstract class` の形が必要になる)。

---

## 6. Riverpod連携

### 問題26の回答例: freezedクラスを `@riverpod` の `Future` プロバイダの戻り値型として使う

```dart
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quote_view.freezed.dart';
part 'quote_view.g.dart';

@freezed
sealed class Quote with _$Quote {
  const factory Quote({required String text, required String author}) =
      _Quote;
}

@riverpod
Future<Quote> quote(Ref ref) async {
  await Future<void>.delayed(const Duration(seconds: 1));
  return const Quote(text: '努力は必ず報われる', author: '無名');
}

class QuoteView extends HookConsumerWidget {
  const QuoteView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncQuote = ref.watch(quoteProvider);

    return switch (asyncQuote) {
      AsyncValue(:final value?) => Text('"${value.text}" — ${value.author}'),
      AsyncValue(:final error?) => Text('エラー: $error'),
      _ => const CircularProgressIndicator(),
    };
  }
}
```

**解説**
- `@riverpod Future<Quote> quote(Ref ref) async { ... }` のように、`riverpod_generator` の関数プロバイダの戻り値型としてfreezedクラスをそのまま使える。`ref.watch(quoteProvider)` は `AsyncValue<Quote>` を返し、`loading`(未取得)/`data`(取得成功、`Quote` インスタンス)/`error`(取得失敗)の3状態を型安全に扱える。
- `AsyncValue(:final value?)` のようなパターンは、`AsyncValue` が内部にDart 3のパターンマッチ対応(オブジェクトパターン)を実装しているために使える書き方で、`value` が `non-null`(取得済み)の場合にマッチする。これはfreezed固有の機能ではなくRiverpod側の機能だが、freezedのUnion型と同じ「Dart 3の `switch` パターンでの分岐」という考え方を共有している。
- `HookConsumerWidget` は `flutter_hooks` の機能(`useState` など)と `hooks_riverpod` の機能(`ref.watch` など)を同時に使えるウィジェット基底クラス。今回は `useXxx` を使っていないが、`HookWidget` ではなく `ConsumerWidget` 系を使う必要がある(Riverpodの `ref` を受け取るため)。

---

### 問題27の回答例: freezedのUnion型でUI状態を表現し `AsyncValue` と組み合わせる

```dart
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'screen_state_view.freezed.dart';
part 'screen_state_view.g.dart';

@freezed
sealed class ScreenState with _$ScreenState {
  const factory ScreenState.loading() = ScreenStateLoading;
  const factory ScreenState.data(String value) = ScreenStateData;
  const factory ScreenState.error(String message) = ScreenStateError;
}

@riverpod
Future<String> message(Ref ref) async {
  await Future<void>.delayed(const Duration(seconds: 1));
  return 'データ取得完了';
}

class ScreenStateView extends HookConsumerWidget {
  const ScreenStateView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(messageProvider);

    final screenState = asyncValue.when(
      loading: () => const ScreenState.loading(),
      data: (value) => ScreenState.data(value),
      error: (error, _) => ScreenState.error(error.toString()),
    );

    return switch (screenState) {
      ScreenStateLoading() => const CircularProgressIndicator(),
      ScreenStateData(:final value) => Text(
        value,
        style: const TextStyle(color: Colors.green),
      ),
      ScreenStateError(:final message) => Text(
        message,
        style: const TextStyle(color: Colors.red),
      ),
    };
  }
}
```

**解説**
- `AsyncValue<String>.when(loading: ..., data: ..., error: ...)`(Riverpod標準の`.when()`)を使って、まず `AsyncValue` を自前の `ScreenState`(freezedのUnion型)へ変換している。そのあとで `ScreenState` を `switch` 式でパターンマッチしてUIを組み立てる、という2段階の変換になっている。
- なぜわざわざ変換するのか: `AsyncValue` はRiverpod専用の型であり、「非同期処理の状態」しか表現できない。一方 `ScreenState` は自分で自由に定義できるため、例えば「取得済みだが中身が空だった」「オフラインだから再試行できない」のような **Riverpodの非同期状態だけでは表現しきれない、アプリ固有のUI状態** を後から追加しやすくなる。小規模なうちは `AsyncValue` をそのまま使ってもよいが、UI状態が複雑になるプロジェクトでは、このように「アプリ用の状態型」を用意して変換する設計が採られることがある。
- `error: (error, _) => ...` の第2引数はスタックトレース(`StackTrace`)。今回は使わないため `_` で捨てている。

---

### 問題28の回答例: freezedクラスをRiverpodの `Notifier` の `state` として使う

```dart
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'counter_notifier_view.freezed.dart';
part 'counter_notifier_view.g.dart';

@freezed
sealed class CounterState with _$CounterState {
  const factory CounterState({@Default(0) int count}) = _CounterState;
}

@riverpod
class CounterNotifier extends _$CounterNotifier {
  @override
  CounterState build() => const CounterState();

  void increment() {
    state = state.copyWith(count: state.count + 1);
  }
}

class CounterNotifierView extends HookConsumerWidget {
  const CounterNotifierView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(counterNotifierProvider);

    return Column(
      children: [
        Text('${state.count}'),
        ElevatedButton(
          onPressed: () => ref.read(counterNotifierProvider.notifier).increment(),
          child: const Text('+1'),
        ),
      ],
    );
  }
}
```

**解説**
- `@riverpod class CounterNotifier extends _$CounterNotifier` は `riverpod_generator` によるクラスベースのプロバイダ(`Notifier`)。`build()` が初期状態を返し、それ以外のメソッド(`increment()`)が状態更新のためのAPIとしてクラスに生えている。
- `state = state.copyWith(count: state.count + 1);` は問題02で学んだ `copyWith` と全く同じ考え方。違いは、状態(`Profile`/`CounterState`)を **ウィジェットの `useState` ではなく、Riverpodの `Notifier` が一元管理している** 点。これにより、複数の画面(複数の `HookConsumerWidget`)から同じ `counterNotifierProvider` を `watch` すれば、どこか1箇所で `increment()` を呼ぶだけで全画面が連動して更新される。
- `ref.watch(counterNotifierProvider)` は現在の `state`(`CounterState`)を購読・取得し、`ref.read(counterNotifierProvider.notifier)` は状態を「読まずに」`Notifier` インスタンス自身(メソッド呼び出し用)を取得する。ボタンの `onPressed` のような「読み取りではなく操作したいだけの場面」では `ref.read(...notifier)` を使うのがRiverpodの定石。
