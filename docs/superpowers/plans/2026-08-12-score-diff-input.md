# scoreをテキスト入力で変更しdiffの変化を確認できるようにする Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `ScoreChangeView`にテキスト入力欄と更新ボタンを追加し、`score`を変更できるようにすることで、`useValueChanged`による`diff`の変化を画面上で確認できるようにする。

**Architecture:** `ScoreChangeView`を`score`を外部から受け取るコンストラクタ引数から、`useState<int>(1)`で内部管理するstateに変更する。`useTextEditingController`で入力値を保持し、更新ボタンタップ時に`int.tryParse`でパースして`score`のstateを更新する。`score`が変わると`useValueChanged`が発火し`diff`が再計算される。

**Tech Stack:** Flutter, flutter_hooks, flutter_test (widget test)

## Global Constraints

- 対象ファイルは`lib/main.dart`のみ変更する(仕様docの設計に厳密に従う)。
- 入力バリデーションのエラーメッセージ表示、スコア変更履歴の保存はスコープ外(仕様doc参照)。
- 既存の`CupertinoApp`/`CupertinoThemeData`設定は変更しない。

---

### Task 1: ScoreChangeViewにテキスト入力とscore state管理を追加する

**Files:**
- Modify: `lib/main.dart` (全体、`ScoreChangeView`クラスと`MyApp.build`の`home:`行)
- Test: `test/score_change_view_test.dart` (新規作成)

**Interfaces:**
- Consumes: なし(既存の`ScoreChangeView`, `MyApp`のみを変更)
- Produces: `ScoreChangeView`は引数なしのコンストラクタ`ScoreChangeView({super.key})`になる。内部に`CupertinoTextField`(1つ)と`CupertinoButton`(1つ、`child: Text('更新')`)を持つ。

- [ ] **Step 1: 失敗するテストを書く**

`test/score_change_view_test.dart`を作成する:

```dart
// ScoreChangeView でテキスト入力欄からscoreを更新すると、
// useValueChangedによるdiffの表示が変化することを確認するテスト。

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dan_do/main.dart';

void main() {
  testWidgets('テキスト入力でscoreを更新するとdiffの表示が変化する', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CupertinoApp(home: ScoreChangeView()));

    // 初回ビルド直後はdiffがまだ計算されていないため「差分なし」
    expect(find.text('差分なし'), findsOneWidget);

    // scoreを1から5に更新する
    await tester.enterText(find.byType(CupertinoTextField), '5');
    await tester.tap(find.widgetWithText(CupertinoButton, '更新'));
    await tester.pump();

    // diff = 5 - 1 = 4 が表示される
    expect(find.text('4'), findsOneWidget);
    expect(find.text('差分なし'), findsNothing);
  });
}
```

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `flutter test test/score_change_view_test.dart`
Expected: FAIL(`ScoreChangeView()`が引数`score`を要求してコンパイルエラーになる、または`CupertinoTextField`/`更新`ボタンが見つからず`findsOneWidget`が失敗する)

- [ ] **Step 3: lib/main.dartを実装する**

`lib/main.dart`を以下の内容に置き換える:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Rolodex',
      theme: CupertinoThemeData(
        barBackgroundColor: CupertinoDynamicColor.withBrightness(
          color: Color(0xFFF9F9F9),
          darkColor: Color(0xFF1D1D1D),
        ),
      ),
      home: Center(child: ScoreChangeView()),
    );
  }
}

class ScoreChangeView extends HookWidget {
  const ScoreChangeView({super.key});

  @override
  Widget build(BuildContext context) {
    final score = useState(1);
    final diff = useValueChanged(
      score.value,
      (oldScore, _) => score.value - oldScore,
    );
    final controller = useTextEditingController();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('score: ${score.value}'),
        CupertinoTextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        CupertinoButton(
          onPressed: () {
            final parsed = int.tryParse(controller.text);
            if (parsed != null) {
              score.value = parsed;
            }
          },
          child: const Text('更新'),
        ),
        Text('${diff ?? "差分なし"}'),
      ],
    );
  }
}
```

- [ ] **Step 4: テストを実行して成功を確認する**

Run: `flutter test test/score_change_view_test.dart`
Expected: PASS

- [ ] **Step 5: コミットする**

```bash
git add lib/main.dart test/score_change_view_test.dart
git commit -m "scoreをテキスト入力で変更できるようにしdiffの変化を確認できるようにする"
```
