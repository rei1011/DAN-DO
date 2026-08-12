# scoreをテキスト入力で変更しdiffの変化を確認できるようにする

## 目的

`useValueChanged`の学習用サンプルとして、`ScoreChangeView`の`diff`が画面上で実際に変化する様子を確認したい。現状は`score`が`1`固定で変化するきっかけがなく、`diff`は常に`差分なし`のままになる。

## 設計

- `ScoreChangeView`は`score`をコンストラクタ引数として受け取るのをやめ、`useState<int>(1)`で内部管理する状態に変更する。
- UIに以下を追加する:
  - 現在の`score`を表示する`Text`
  - 数値入力用の`CupertinoTextField`(`keyboardType: TextInputType.number`)。`useTextEditingController`で入力値を保持する。
  - 「更新」`CupertinoButton` — タップ時に入力文字列を`int.tryParse`し、成功した場合のみ`score`のstateを更新する。パース失敗時は何もしない。
  - 既存の`diff`表示用`Text`はそのまま維持する。
- `score`のstateが更新されると`useValueChanged`が発火し、`diff`が自動再計算されて画面に反映される。
- `MyApp`側の`ScoreChangeView(score: 1)`呼び出しは`ScoreChangeView()`(引数なし)に変更する。

## スコープ外

- 入力バリデーションのエラーメッセージ表示
- スコア変更履歴の保存
