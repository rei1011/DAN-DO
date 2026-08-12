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
