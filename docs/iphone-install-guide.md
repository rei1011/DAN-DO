# DAN-DOアプリを自分のiPhoneへインストールする手順（Apple Developer Program未登録の場合）

> Apple Developer Program（年間有料）に登録していなくても、無料のApple ID（Personal Team）をXcodeに紐付けることで、開発中のアプリを自分のiPhoneにインストールして動作確認できます。本ドキュメントはその手順をまとめたものです。

## 0. 無料プロビジョニングの制約（先に理解しておくこと）

Apple Developer Programに登録した場合と比べて、以下の制約があります。

| 項目 | 無料のApple ID（Personal Team） | Apple Developer Program |
|---|---|---|
| 署名アプリの有効期限 | **7日間**（切れたら再ビルド・再インストールが必要） | 1年間 |
| 同時インストール可能なアプリ数 | 3個まで（Apple ID単位） | 実質無制限 |
| TestFlightでの配布 | 不可 | 可能 |
| App Storeへの公開 | 不可 | 可能 |

→ 開発中の動作確認用途としては無料のApple IDで十分ですが、**7日ごとに手順5を再実行してインストールし直す**必要がある点にご注意ください。

## 1. 前提条件

- Mac（Xcode 26.6以降がインストール済みであること。本プロジェクトでの動作確認済みバージョン: Xcode 26.6）
- iPhone本体
- **USBケーブル（初回のペアリングのみ必要）**
  - 本手順は基本的にワイヤレス（Wi-Fi経由）でのインストールを想定していますが、Xcodeの仕様上、ワイヤレスデバッグを有効化するには最初に一度だけUSBケーブルでの接続が必要です。
- 無料のApple ID（Personal Team）がXcodeに登録済みであること
  - 未登録の場合は Xcode → Settings（環境設定） → Accounts で「+」から自分のApple IDを追加してください。
- Flutter SDK（本プロジェクトは [FVM](https://fvm.app/) でバージョン管理されています。`.fvmrc` で `stable` チャンネルを指定。動作確認済みバージョン: Flutter 3.44.9）
  - コマンドは `flutter` の代わりに `fvm flutter` を使用してください（FVM未導入の場合はグローバルの `flutter` でも代用可）

## 2. Xcodeでの署名設定確認

1. `ios/Runner.xcworkspace` をXcodeで開く
   - **`Runner.xcodeproj` ではなく `Runner.xcworkspace` を開いてください**（CocoaPodsを使用しているため、workspaceを開かないと依存関係が正しく解決されません）
   ```bash
   open ios/Runner.xcworkspace
   ```
2. 左側のナビゲータで `Runner` プロジェクト → `Runner` ターゲットを選択し、上部タブから **Signing & Capabilities** を開く
3. **Team** の欄で、自分の無料Apple ID（Personal Team）が選択されていることを確認する
   - 現在のプロジェクト設定は `CODE_SIGN_STYLE = Automatic` になっているため、Teamを選択するだけでXcodeが自動的にプロビジョニングプロファイルを生成・管理します
4. 「Signing Certificate」や「Provisioning Profile」の欄にエラー（赤字）が出ていないか確認する
   - エラーが出る場合は一度Teamを「None」に戻してから選び直すと解消することがあります

> **補足（今後の対応事項）**: Bundle Identifierは現在 `com.example.danDo` という初期値のままです。無料のApple IDでは、同じApple ID内で他の `com.example.*` アプリと衝突する可能性があるため、将来的には一意な値（例: `com.yourname.danDo`）に変更することを推奨します。本手順書では設定変更は行わず、現状のままインストールする手順のみを記載しています。
>
> また、本アプリはカメラを使用する仕様ですが、`ios/Runner/Info.plist` に `NSCameraUsageDescription`（カメラ使用許可の説明文）がまだ設定されていません。この状態でカメラ機能を使おうとするとiOSがアプリを強制終了させる可能性があるため、開発を進める際は早めの対応をおすすめします。

## 3. USBケーブルでの初回ペアリング

1. iPhoneとMacをUSBケーブルで接続する
2. iPhone側に「このコンピュータを信頼しますか？」というダイアログが出たら「信頼」をタップし、iPhoneのパスコードを入力する
3. Xcodeのメニューから **Window → Devices and Simulators** を開く
4. 左側のデバイス一覧に自分のiPhoneが表示され、緑色のインジケータで接続されていることを確認する
   - ここで初めて接続した場合、Xcodeがデバイス用のシンボルを準備するのに数分かかることがあります

## 4. ワイヤレス（Wi-Fi経由）デバッグの有効化

1. 手順3と同じ **Devices and Simulators** 画面で、対象のiPhoneを選択する
2. 「**Connect via network**」（ネットワーク経由で接続）のチェックボックスをオンにする
3. Mac・iPhoneの両方が**同じWi-Fiネットワーク**に接続されていることを確認する
4. USBケーブルを抜く
5. Xcode上部のデバイス選択メニュー（スキーム名の隣）を開き、iPhone名の横に地球儀（ネットワーク）アイコンが表示されていれば、ワイヤレス接続が有効になっています
   - 表示されない場合は、iPhone・Mac双方を再起動するか、しばらく待ってから再度確認してください

## 5. ビルド＆実機インストール

### ビルドモードについて（重要）

iOS 14以降の仕様により、**debugモード**（デフォルト）でビルドしたアプリは、Flutterツール・IDE・Xcodeに接続された状態でしか起動できません。ホーム画面のアイコンをタップして単体で起動しようとすると、以下のようなメッセージが表示されて起動できません。

```
In iOS 14+, debug mode Flutter apps can only be launched from Flutter tooling,
IDEs with Flutter plugins or from Xcode.
```

Macを接続していない普段の状態でもホーム画面から起動できるようにするには、**releaseモード**（または profileモード）でビルドしてください。

| モード | 用途 | Mac接続なしでホーム画面から起動 |
|---|---|---|
| debug（デフォルト） | 開発中のホットリロードなどデバッグ用途 | 不可 |
| profile | パフォーマンス計測用 | 基本的に不可（Mac接続前提） |
| release | 実際の使用に近い最終ビルド | 可能 |

普段使い用にインストールする場合は、必ず`--release`オプションを付けてビルドしてください。

### Flutter CLIから実行する場合

```bash
fvm flutter devices
```

上記コマンドで自分のiPhoneが一覧に表示されることを確認したら、以下でビルド・インストール・起動まで一気に行えます。

```bash
# 開発中（ホットリロードなどを使う場合。Mac接続時のみ起動可能）
fvm flutter run -d <device-id>

# 普段使い用（Mac接続なしでホーム画面から起動できる）
fvm flutter run --release -d <device-id>
```

`<device-id>` は `flutter devices` の出力に表示されるIDに置き換えてください。

### Xcodeから実行する場合

1. Xcode上部のデバイス選択メニューで、ワイヤレス接続されたiPhoneを選択する
2. メニューバーの **Product → Scheme → Edit Scheme...** を開き、左側で「Run」を選択、「Build Configuration」を **Release** に変更する（普段使い用にする場合）
3. 左上の ▶（Run）ボタンを押す
4. ビルドが完了すると自動的にiPhoneへインストール・起動されます

> 手順7（7日ごとの再インストール）を行う際も、普段使いしているアプリを再インストールする場合は同様に`--release`を付けてビルドしてください。

## 6. iPhone側での初回起動時の設定（デベロッパーの信頼）

初回起動時、iPhone側に「信頼されていないデベロッパー」という警告が表示され、アプリが起動しないことがあります。その場合は以下の手順で信頼設定を行ってください。

1. iPhoneの **設定 → 一般 → VPNとデバイス管理**（または「デベロッパーApp」）を開く
2. 自分のApple IDに紐づくデベロッパープロファイルを選択する
3. 「"（Apple ID）"を信頼」をタップし、確認ダイアログで再度「信頼」を選ぶ
4. ホーム画面からDAN-DOアプリを起動し直す

アプリ起動後、カメラ機能を使用する際にはカメラアクセスの許可を求めるダイアログが表示されるので、許可してください（前述の通り、現状`NSCameraUsageDescription`が未設定のため、この確認ダイアログ自体が正しく表示されずクラッシュする可能性があります）。

## 7. 7日ごとの再インストールについて

無料のApple IDで署名したアプリは**7日間で有効期限が切れ**、アイコンをタップしても起動しなくなります。これは異常ではなく無料プロビジョニングの仕様です。

再度使用する場合は、手順5（ビルド＆実機インストール）を同じ手順で実行するだけで再度7日間使用できるようになります。Mac・iPhoneをWi-Fi経由で接続できる状態であれば、USBケーブルは不要です。

## 8. トラブルシューティング

| 症状 | 対処法 |
|---|---|
| Signing & Capabilitiesで赤いエラーが出る | Teamを一度「None」に戻し、再度自分のApple IDを選び直す |
| Devices and SimulatorsにiPhoneが表示されない | USBケーブルの抜き差し、iPhone側の「信頼」ダイアログの再確認、Macの再起動を試す |
| ワイヤレス接続がXcodeに出てこない | Mac・iPhoneが同一Wi-Fiに接続されているか確認。うまくいかない場合は一度USBケーブルを挿し直して手順4をやり直す |
| 「無料アカウントではこの機能を使用できません」と表示される | Push通知やiCloud連携など一部のCapabilityは無料アカウントでは使用不可。該当のCapabilityをRunnerターゲットから削除する必要がある |
| 「Maximum number of apps for free development profiles reached」と表示される | 無料アカウントの同時インストール上限（3個）に達している。iPhone側の設定 → 一般 → VPNとデバイス管理から不要な開発用アプリのプロファイルを削除する |
| アプリが7日を過ぎたら起動しなくなった | 仕様通りの動作。手順5を再実行して再インストールする |
| 「信頼されていないデベロッパー」の警告が消えない | 手順6の信頼設定を再確認。それでも解決しない場合は一度アプリを削除してから再インストールする |
