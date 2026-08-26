---
paths:
  - "lib/**/*.dart"
---

# Flutter Widget実装: StatefulWidgetを使わずflutter_hooksを使う

## 新規実装

ローカル状態を持つWidgetを新規実装する場合、`StatefulWidget` / `ConsumerStatefulWidget` は使用せず、以下を使用すること。

- Riverpodと併用しない場合: `HookWidget`
- Riverpodと併用する場合（本プロジェクトの主流）: `HookConsumerWidget`

ローカル状態・ライフサイクル管理は `flutter_hooks` が提供するフックを用いる。

- `useState` — ローカル状態
- `useEffect` — 副作用・購読・破棄処理（`dispose`相当）
- `useMemoized` — 値のメモ化
- `useTextEditingController` / `useFocusNode` / `useAnimationController` / `useScrollController` など — コントローラ類のライフサイクル管理

使用パッケージ（導入済み）: `flutter_hooks`, `hooks_riverpod`

## 既存コードの移行方針

以下の既存ファイルは `StatefulWidget` / `ConsumerStatefulWidget` を使用している。新規に書き換えて回るのではなく、これらのファイルに変更を加える機会があれば、その範囲で `HookWidget` / `HookConsumerWidget` への移行を行うこと。

- `lib/features/result/result_screen.dart`
- `lib/features/ball_position/ball_position_picker_screen.dart`

## 例外（StatefulWidgetの使用を許可するケース）

以下のように flutter_hooks では代替できない場合に限り `StatefulWidget` の使用を許可する。使用する際は、なぜhooksで実装できないかをコメントで明記すること。

- `RouteAware` や `WidgetsBindingObserver` など、インターフェースの実装（クラスとしての `State` そのもの）を要求される場合
- サードパーティのAPI/SDKが `State<T>` の具象インスタンスを直接要求する場合
