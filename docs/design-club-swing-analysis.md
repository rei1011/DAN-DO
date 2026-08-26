# 設計書: クラブ追跡ベースの弾道解析への方式転換

- 作成日: 2026-08-26
- ステータス: 実装中(Phase 1〜Phase 6完了。ただしモーションブラーによるボール検出の根本課題は未解決、対応方針〈OBB化検討等〉は次フェーズに持ち越し)
- 前提となる調査: [investigation-custom-model-tracking-failure.md](investigation-custom-model-tracking-failure.md)

## 1. 背景・目的

現行の`BallTrajectoryAnalysisService`は、インパクト後にボールを飛球中ずっと画像追跡し続けることで弾道パラメータ(初速・打ち出し角・打ち出し方向)を推定している。しかし[investigation-custom-model-tracking-failure.md](investigation-custom-model-tracking-failure.md)の調査で、以下が判明した。

- インパクト直前、クラブがボールに重なり視覚的に遮蔽するため、その瞬間にモデルの検出信頼度が低下する
- インパクト直後、ボールは秒速数十mで移動するため、33ms間隔・160pxクロップという検出方式では次のフレームで再検出できない
- フルフレーム探索は、小さなボールが640x640へのリサイズで検出困難になるため機能しない

これはコードのバグではなく、**「30fpsの単眼カメラでボールそのものを飛球中に追跡し続ける」というアプローチ自体の限界**である。

一方、市販の(専用機材やスロー撮影を使わない)弾道表示アプリは、後方からの通常速度撮影のみで弾道(左右の曲がりを含む)を表示できている。調査の結果、これらは**ボールを飛ばし続けて観測するのではなく、インパクト時のクラブの挙動から弾道を計算で導いている**と考えられる(Dプレーン理論)。本設計は、この方式へ転換するものである。

## 2. 採用する方式の物理的根拠

ゴルフのボールフライト理論(Dプレーン理論)における2つの経験則を利用する。

1. **打ち出し初期方向は、ほぼフェース角度そのものを反映する**(クラブパスの影響は初期方向にはごくわずか)
2. **曲がり幅は、フェース角度とクラブパスの差(フェース・トゥ・パス)に比例する**

この2つから、以下が導ける。

> フェース角度そのものを検出しなくても、「クラブパス(クラブヘッドの実測)」と「打ち出し初期方向(インパクト直後1〜2フレームのボール実測)」の**両方**が分かれば、フェース・トゥ・パス(＝曲がり幅の要因)を逆算できる。

これにより、以下の2つの技術的難所を両方回避できる。

- ❌ ボールを飛球中ずっと追い続ける(実測済みで不可能と判明)
- ❌ クラブヘッドの回転(フェース角度)を検出する(後述の理由で今回のデータセットでは不可能)

## 3. クラブ検出モデルとその制約

クラブ検出には、[roboflow-model-investigation-guide.md](roboflow-model-investigation-guide.md)で以前候補から外れた**Golf Driver Tracker**(Roboflow Universe、`golf-driver-tracker/2`)を自前ファインチューニングして使う。理由:

- 以前のHosted API実機検証で、`golf ball`クラスは検出できなかったが、`golf club-handle`・`golf club-head`クラスは安定して検出できていた実績がある
- ライセンス(CC BY 4.0)は確認済み

**制約(ユーザーによるブラウザ確認済み、2026-08-26)**: このデータセットのアノテーションは**軸に沿った矩形(通常のバウンディングボックス)のみ**で、回転情報(Oriented Bounding Box)を含まない。そのため、クラブヘッドの向き(真のフェース角度)はこのデータセットからは検出できない。本設計は、この制約を前提に、フェース角度を直接検出しない方式(セクション2)を採用している。

## 4. アーキテクチャ・データフロー

既存の`BallTrajectoryAnalysisService`と並存する形で、新しい`ClubSwingAnalysisService`(`ShotAnalysisService`の別実装)を追加する。

```mermaid
flowchart TD
    A["1. アドレス時のボール検出(既存)\n奥行き・スケール基準を確立"] --> B
    B["2. クラブヘッド追跡(新規)\n動画全体でフルフレーム検出"] --> C
    C["3. インパクトフレーム推定(新規)\nクラブヘッドがアドレス位置に最接近した瞬間"] --> D
    C --> E
    D["4. クラブパス・アタック角算出(新規)\nインパクト直前数フレームの回帰"] --> F
    E["5. インパクト直後のボール検出(新規・範囲限定)\n広めの探索範囲で数フレームのみ"] --> G
    G["6. 打ち出し方向・角度算出(既存流用)\nLaunchParameterEstimator"] --> F
    F["7. 曲がり量(サイドスピン)算出(新規)\nフェース・トゥ・パスから換算"] --> H
    G --> I
    I["8. 初速算出(新規)\nクラブヘッド速度 x スマッシュファクター"] --> H
    H["9. 弾道シミュレーション(既存流用)\nBallisticsSimulator"] --> J["ShotResult"]
```

1. **アドレス時のボール検出**(既存・変更なし): タップ位置周辺でボールを検出し、奥行き・スケール基準(`DistanceEstimation`)を確立
2. **クラブヘッド追跡**(新規): 動画全体でクラブヘッド・クラブハンドルを検出。クラブはボールより大きく高コントラストな被写体のため、まずフルフレーム検出を試す(ボールのような狭いROIクロップの要否は実機検証で判断)
3. **インパクトフレームの特定**(新規): クラブヘッドがバックスイングで離れた後、再びアドレス時のボール位置に最も近づいた瞬間をインパクトと推定
4. **クラブパス・アタック角の算出**(新規): インパクト直前の数フレーム(目安5フレーム程度)のクラブヘッド世界座標から線形回帰で算出
5. **インパクト直後のボール検出**(新規・範囲限定): インパクトフレームから数フレームのみ、広めの探索範囲(スロー撮影ではない前提で、想定される最大初速をカバーできるサイズ)でボールを検出
6. **打ち出し方向・角度の算出**(既存流用): 5.で得た1〜2点以上を`LaunchParameterEstimator.estimate()`にそのまま渡す
7. **曲がり量(サイドスピン)の算出**(新規): 6.の打ち出し方向と4.のクラブパスの差(フェース・トゥ・パス)から換算式でサイドスピン量を推定
8. **初速の算出**(新規): 4.のクラブヘッド速度 × クラブ種別ごとのスマッシュファクター
9. **弾道シミュレーション**(既存流用): 6.・7.・8.の結果を`BallisticsSimulator.simulate()`にそのまま渡す

## 5. 新規・変更コンポーネント

| ファイル | 種別 | 内容 |
|---|---|---|
| `lib/data/ml/club_detector.dart` | 新規 | `BallDetector`と同様の構造。`golf club-head`/`golf club-handle`クラスでフィルタしたカスタムYOLOモデルをラップ |
| `lib/domain/models/raw_club_detection.dart` | 新規 | `frameTimeMs`・`centerPx`・`confidence`・`part`(head/handleのenum) |
| `lib/domain/services/club_path_estimator.dart` | 新規(純粋関数) | クラブヘッドの世界座標列からクラブパス角度・アタック角度を線形回帰で算出 |
| `lib/domain/services/impact_moment_detector.dart` | 新規(純粋関数) | クラブヘッド位置列とアドレス時ボール位置から、インパクトフレームを推定 |
| `lib/domain/services/spin_estimator.dart` | 新規(純粋関数) | 打ち出し方向とクラブパスの差(フェース・トゥ・パス)からサイドスピン量(rpm)を換算 |
| `lib/domain/services/club_swing_analysis_service.dart` | 新規 | `ShotAnalysisService`の別実装。上記を結線するオーケストレーション層 |
| `lib/core/club_constants.dart` | 新規 | クラブ種別ごとのスマッシュファクター表・想定シャフト長表(Phase4追加)・クラブパス回帰の最大観測点数(Phase4追加) |
| `lib/core/roi_constants.dart` | 変更(Phase4追加) | インパクト直後のボール探索クロップサイズ・探索フレーム数を追加 |
| `lib/core/linear_regression.dart` | 新規 | `LaunchParameterEstimator._linearRegressionSlope`を共通ユーティリティとして切り出し、`club_path_estimator.dart`と共用 |
| `lib/core/ballistics_constants.dart` | 変更 | `sidespinRpmPerFaceToPathDegree`(目安値、要チューニング)を追加 |
| `lib/domain/services/shot_analysis_service.dart` | 変更 | `analyze()`に`required ClubType clubType`を追加 |
| `lib/features/club_selection/`(仮) | 新規 | クラブ種別選択画面 |
| `lib/domain/services/launch_parameter_estimator.dart` | 変更なし | インパクト直後1〜2点の推定にそのまま流用 |
| `lib/domain/services/ballistics_simulator.dart` | 変更なし | そのまま流用 |

## 6. 数式・定数

**曲がり量の換算**(`spin_estimator.dart`):

```
faceToPathDegrees = launchDirectionDegrees(ボール実測) - clubPathDegrees(クラブ実測)
sidespinRpm = faceToPathDegrees * BallisticsConstants.sidespinRpmPerFaceToPathDegree
```

`sidespinRpmPerFaceToPathDegree`は目安値としてコード上に明記し、実機データで補正する前提とする(既存の`assumedBackspinRpm`・`assumedSidespinRpm`と同じ「目安値」の扱い)。

**スマッシュファクター表**(`club_constants.dart`、一般的な目安値。要実機検証での補正):

| クラブ種別 | スマッシュファクター(目安) |
|---|---|
| ドライバー | 1.48 |
| フェアウェイウッド | 1.45 |
| ユーティリティ | 1.41 |
| アイアン(中番手目安) | 1.33 |
| ウェッジ | 1.25 |

**バックスピン量**: 今回のスコープでは真の測定手段が無いため、既存の`BallisticsConstants.assumedBackspinRpm`(固定仮定値)を変更せず流用する。バックスピン推定(≈飛距離・高さの精度向上)は本設計のスコープ外とする(セクション9参照)。

**クラブヘッドの奥行き推定・想定シャフト長表**(`club_constants.dart`、Phase4で判明した制約への対応。詳細はPhase4の完了メモ参照): `RawClubDetection`にはボールの実直径のようなサイズ情報が無いため、単独では奥行き(カメラからの距離)を推定できない。同一フレームで検出したクラブヘッド・ハンドル間の画像上の距離(見かけのシャフト長)と、以下の想定実シャフト長を比較し、ボールの実直径と同じピンホールカメラの原理で奥行きを推定する。

| クラブ種別 | 想定シャフト長(m、目安) |
|---|---|
| ドライバー | 1.145 |
| フェアウェイウッド | 1.09 |
| ユーティリティ | 1.02 |
| アイアン(中番手目安) | 0.95 |
| ウェッジ | 0.89 |

この方式はhead・handleが同一フレームで両方検出できた場合のみ算出可能なため、Phase2実機検証で確認された検出欠測(セクション10)の影響を強く受ける。クラブパス・アタック角の回帰には、インパクト以前でhead・handleが揃った点のうち直近`ClubConstants.maxPathRegressionFrames`(目安値5)点までを使う。

## 7. UI変更

`ball_position_picker_screen.dart`の前後に、クラブ種別選択ステップを追加する。ユーザーが解析前にクラブ種別(ドライバー/FW/UT/アイアン/ウェッジ等)を選択し、`ClubType`として`ClubSwingAnalysisService.analyze()`に渡す。

## 8. エラーハンドリング

既存の`InsufficientTrajectoryDataException`パターンを踏襲し、失敗箇所が分かるメッセージを追加する。

- 「クラブヘッドを検出できませんでした」(手順2で検出0件)
- 「インパクトの瞬間を特定できませんでした」(手順3で妥当な最接近点が見つからない)
- 「インパクト直後のボールを検出できませんでした」(手順5で1点も検出できない、または`LaunchParameterEstimator`が要求する2点に満たない)

## 9. スコープ外・今後の課題

- **バックスピン量の実測**: 今回は固定仮定値のまま。アタック角・(可能であれば)ロフト角からの推定は将来検討
- **芯を外した打点(ギア効果)の考慮**: 今回のフェース・トゥ・パスによる曲がり推定は、芯で捉えたショットを前提とした簡易モデル。ミスヒット時の追加サイドスピンは考慮しない
- **クラブ検出のROI最適化**: 手順2はまずフルフレーム検出で試す想定。実機検証で精度・速度が不十分な場合、ボールと同様のROIクロップ方式の導入を検討する(Phase 2実機検証で、ダウンスイング〜インパクト直前に検出欠測が確認されたため、Phase 4以降で優先度を再評価する。詳細はセクション10参照)

## 10. リスク・フォールバック方針

**最大のリスク**: セクション2の物理的根拠(打ち出し初期方向 ≈ フェース角度)は一般論としては妥当だが、実機の検出精度(クラブパスの測定誤差・インパクト直後のボール検出精度)次第では、曲がり幅の推定精度が実用に耐えない可能性がある。

**フォールバック方針**: 上記の方式で十分な精度が得られないと判明した場合、**回転情報(Oriented Bounding Box)を含むデータセットでのクラブヘッド検出モデルに切り替え、真のフェース角度を直接検出する方式への再設計が必要になる**。その場合、以下のいずれかの対応が必要:

- 回転情報を含む既存のRoboflow Universe公開データセットを新たに探す
- Golf Driver Trackerのデータセットの一部を自分でOBBアノテーションし直す(要ブラウザでのアノテーション作業)

いずれの場合も、`docs/roboflow-model-investigation-guide.md`と同様の調査手順(候補データセットの重み入手可否・ライセンス確認)を踏む必要がある。

**Phase 2実機検証で確認されたリスク(2026-08-26)**: `ClubDetector`単体をフルフレーム検出(100ms間隔サンプリング)で実機検証したところ、アドレス時(クラブ静止)はhead/handleともに高信頼度(0.83〜0.93)で安定検出できた一方、**スイング動作中、特にユーザーの申告で「ダウンスイング〜インパクト直前」に該当する区間で、最大900ms(9フレーム)連続してhead・handleとも検出0件になる欠測が確認された**(全56フレーム中、head検出30件・handle検出39件)。

原因はモーションブラーの可能性が高いと考えられる。クラブヘッド速度はインパクト直前に最大(ドライバーで秒速40〜50m程度)になり、これはセクション1でボール追跡が破綻した理由(高速移動による検出困難)と同種の物理的限界がクラブヘッドにも及んでいることを示唆する。ROIクロップ(セクション9)は探索範囲の絞り込みには有効だが、モーションブラー自体(シャッタースピード起因)は解消しない可能性がある点に注意。

**対応方針(2026-08-26、ユーザー確認済み)**: この場での設計変更は行わず、**現状のフルフレーム検出のままPhase 3に進む**。ただし以下を前提としてPhase 3以降を実装する。

- `club_path_estimator.dart`・`impact_moment_detector.dart`は、インパクト直前に理想的な5フレーム分のデータが揃わない(場合によっては大部分欠測する)ケースを前提に、**取得できたデータ点数だけで成立するロバストな実装**とする(必要最小点数を下回った場合のみ例外を投げる)
- 実際の精度への影響度は、Phase 4のオーケストレーション結線後、実データでの結果を見て判断する
- 精度が実用に耐えないと判明した場合は、ROIクロップ方式の導入(セクション9)、またはこのセクションのOBBベースのフォールバックを再検討する

**Phase 6実機検証で確認された、同種のリスクの再発(2026-08-26)**: Phase 2で確認された「クラブヘッドのモーションブラーによる検出欠測」と同じ物理的限界が、**手順5(インパクト直後のボール検出)にも及んでいる**ことが実機検証で確認された。

打ちっぱなし練習場で撮影した動画で検証したところ、以下が判明した。

- 探索範囲(クロップサイズ・フレーム数)を拡大しても、この動画では**インパクト直後の本物の飛球中のボールが一度も検出されなかった**(検出0件)
- 拡大した探索範囲では、代わりに画面手前に転がる無関係な静止ボール(打ちっぱなし練習場特有の環境要因)を誤検出し、これを打ち出し軌道として扱ってしまうバグが発生した(`_searchPostImpactBall`に、既存の`BallKalmanTracker`同様の直径比ゲーティングを追加して対応済み。詳細はPhase6の完了メモを参照)
- 直径比ゲーティング追加後は、この誤検出は正しく除外されるようになったが、その結果、本物のボールも検出できていないことが明らかになり、`インパクト直後のボールを検出できませんでした`という例外が発生する状態に戻った

**現時点の評価**: 「クラブパス(クラブ実測)」と「打ち出し初期方向(ボール実測)」の両方を測定するという本設計の前提(セクション2)のうち、**後者(打ち出し初期方向の実測)がモーションブラーにより成立しないケースがある**ことが実機で確認された。これは1つの動画(低いカメラ位置・近距離設置)での確認であり、どの程度の割合の動画で再現するかは未検証。今後の対応は以下のいずれかを想定している(2026-08-26時点で未決定、次フェーズ以降で判断)。

1. 他の動画(カメラ位置・距離が異なるもの)でも同様の問題が起きるか検証し、頻度に応じて対応要否を判断する
2. `postImpactBallSearchFrameCount`のさらなる拡大等、ROI側のチューニングを継続する(ただし今回の検証では本物のボールが探索範囲内で一度も検出されておらず、効果は限定的と予想される)
3. OBB(回転情報付き)モデルへの本格的な切り替えを検討する。この場合、「打ち出し方向・曲がり量」はフェース角度から直接計算できるためボール検出への依存を解消できるが、「打ち出し角度(縦方向)」は現状ボール実測に依存しており、OBB化だけでは解消しない(ロフト角+アタック角からの推定等、別の設計が必要)。新規データセット探し・アノテーション・再学習を要する大きな作業になる

## 11. 実装TODOリスト(Phase別)

Phaseごとに1つのPRとして完結させる想定。各Phase末尾の完了確認項目まで終わったら次のPhaseへ進む。

**方針確認済み(2026-08-26)**: `ClubSwingAnalysisService`は`BallTrajectoryAnalysisService`を完全に置き換える(UIの分岐は作らない)。既存の`BallTrajectoryAnalysisService`はテスト・参考実装として残すが、本番の解析フローからは外す。

### Phase 1: 基盤整備(共通ユーティリティ・定数・モデル定義)

- [x] `lib/core/linear_regression.dart`を新設し、`LaunchParameterEstimator._linearRegressionSlope`をここに切り出す(既存の`launch_parameter_estimator_test.dart`が通ることを確認)
- [x] `lib/core/club_constants.dart`を新設(`ClubType` enumとスマッシュファクター表)
- [x] `lib/core/ballistics_constants.dart`に`sidespinRpmPerFaceToPathDegree`を追加
- [x] `lib/domain/models/raw_club_detection.dart`を新設(`ClubPart` enum: head/handle)
- [x] `lib/domain/services/shot_analysis_service.dart`の`analyze()`に`required ClubType clubType`を追加(既存`BallTrajectoryAnalysisService`側も引数を受け取るだけに更新してビルドを通す)
- [x] Phase完了確認: `fvm flutter analyze`・`fvm flutter test`が通ることを確認

**完了(2026-08-26、[PR #12](https://github.com/rei1011/DAN-DO/pull/12))**: `analyze()`のシグネチャ変更に伴い、設計時点では想定していなかった呼び出し元(`AnalysisController`・`AnalyzingScreen`・`BallPositionPickerScreen`)とそのテストもビルドを通すため追従修正した。クラブ種別選択UIはまだ無いため、`BallPositionPickerScreen`は暫定的に`ClubType.driver`固定値を渡している(`TODO(Phase5)`コメント付き、Phase 5で実際の選択UIに置き換え予定)。アプリの実行時挙動(解析ロジック・画面遷移)はPhase 1では変化していない。

### Phase 2: クラブ検出モデルの学習・組み込み

- [x] Golf Driver Tracker(`golf-driver-tracker/2`)のDatasetをRoboflowからダウンロード(YOLO26形式、Show download code)
- [x] Colabで`yolo26n`をファインチューニング(club-head/club-handle。手順は`club-detector-training-guide.md`のノートブック構成を流用)
- [x] `.mlpackage`をZIP化して`assets/models/`に配置、`pubspec.yaml`更新
- [x] `lib/data/ml/club_detector.dart`を実装(`BallDetector`と同様の構造)
- [x] `docs/model-provenance.md`にクラブ検出モデルの出典・ライセンス(CC BY 4.0)を追記
- [x] Phase完了確認: 実機で`ClubDetector`単体がクラブヘッド・ハンドルを検出できることを確認

**完了(2026-08-26)**: Roboflowデータセットダウンロード・Colabでのファインチューニングはユーザー作業として完了(手順は新設の[club-detector-training-guide.md](club-detector-training-guide.md)にまとめた)。学習済みモデルの検出クラスは`golf ball`・`golf club-handle`・`golf club-head`の3クラスで、本アプリでは`golf club-head`・`golf club-handle`のみを`club_detector.dart`で使用(ボール検出は引き続き別モデル`ball_detector.dart`が担当)。モデルは`assets/models/best_club.mlpackage.zip`として配置。学習成果物のうち`best.pt`・`best.tflite`・`last.pt`はリポジトリには含めず(ボール検出モデルと同じ方針)、ユーザーの手元に保管。`fvm flutter analyze`・`fvm flutter test`(53件)は問題なし。

実機検証(iPhone 15 Proシミュレータ、使い捨てデバッグ画面`lib/features/club_detector_debug/`経由)で、head・handleともに検出できることを確認した。ただし**ダウンスイング〜インパクト直前で検出欠測が確認された**(詳細・対応方針はセクション10参照)。この欠測を許容してPhase 3に進む方針をユーザーと確認済み。デバッグ画面は`ClubSwingAnalysisService`(Phase 4)実装後に削除予定。

### Phase 3: クラブパス・インパクト検出・スピン推定ロジック(純粋関数)

**注意(2026-08-26、Phase 2実機検証結果を踏まえて追記)**: セクション10に記載の通り、実機ではダウンスイング〜インパクト直前のクラブヘッド検出に欠測が発生しうる。`club_path_estimator.dart`・`impact_moment_detector.dart`は、理想的な5フレーム分のデータが揃わないケース(取得できたデータ点数が少ない場合)でも成立するように実装し、必要最小点数を下回った場合のみ例外を投げる設計とする。

- [x] `lib/domain/services/club_path_estimator.dart`を実装+単体テスト(TDD)
- [x] `lib/domain/services/impact_moment_detector.dart`を実装+単体テスト(TDD)
- [x] `lib/domain/services/spin_estimator.dart`を実装+単体テスト(TDD)
- [x] Phase完了確認: `fvm flutter test`が通ることを確認

**完了(2026-08-26)**: 3つの純粋関数サービスをTDDで実装した。

- `ClubPathEstimator.estimate()`: `LaunchParameterEstimator`と同様に`LinearRegression.slope`を使い、クラブヘッド世界座標列(`TrajectoryPoint`)からクラブパス角度・アタック角度を算出。必要最小点数は2点(`LaunchParameterEstimator`と同じ閾値)で、それ未満は`ArgumentError`。
- `ImpactMomentDetector.detect()`: クラブヘッド検出列(`RawClubDetection`、時刻降順・昇順どちらでも可、内部でソート)とアドレス時ボール位置から、「アドレス位置から最も離れた点(バックスイングのピーク)」を求め、その後の観測点の中で最もアドレス位置に近い点をインパクトフレームとして返す。検出2点未満は`ArgumentError`、ピークが最後の観測点(復帰が一切観測できない)場合は`StateError`。
- `SpinEstimator.estimateSidespinRpm()`: `launchDirectionDegrees - clubPathDegrees`(フェース・トゥ・パス)に`BallisticsConstants.sidespinRpmPerFaceToPathDegree`を掛けるだけの単純な換算式。

新規テスト11件を追加(`club_path_estimator_test.dart`3件、`impact_moment_detector_test.dart`4件、`spin_estimator_test.dart`3件、うち2件は上記+2点ちょうどでも算出できることを確認するロバスト性テストを含む)。`fvm flutter test`は既存53件+新規11件の計64件が全てパス、`fvm flutter analyze`もPhase 3変更分に起因する指摘は0件(既存の`ball_detector.dart`の`unnecessary_import`指摘のみ残存、Phase 3範囲外)。

### Phase 4: ClubSwingAnalysisServiceの実装(オーケストレーション)

- [x] `lib/domain/services/club_swing_analysis_service.dart`を実装し、Phase 1〜3の要素を結線
- [x] `ball_trajectory_analysis_service_analyze_test.dart`を参考に、モックを使った結線テストを作成
- [x] Phase完了確認: `fvm flutter test`が通ることを確認

**完了(2026-08-26)**: `ClubSwingAnalysisService`(`ShotAnalysisService`実装)を新設し、Phase 1〜3の要素を結線した。

**実装前に発覚し、ユーザー確認済みの設計変更点**: セクション4・5では「クラブヘッド世界座標」を`ClubPathEstimator`に渡す想定だったが、`RawClubDetection`(Phase 1で確定済み)には中心座標のみでボールの実直径のようなサイズ情報が無いため、単独では奥行き(カメラからの距離)を推定できないことが判明した。特にダウンザライン撮影(セクション2の前提)では、クラブヘッド速度の大部分を占める「ターゲット方向への前進」成分がカメラ視線軸(奥行き)に沿うため、奥行きを推定できないと「クラブヘッド速度」(手順8で初速算出に必須)も「クラブパスのZ成分」も原理的に測定不能になる。

対応として、**同一フレームで検出したクラブヘッド・ハンドル間の画像上の距離(見かけのシャフト長)と、クラブ種別ごとの想定実シャフト長(`ClubConstants.shaftLengthMeters`、新設)を比較し、ボールの実直径と同じピンホールカメラの原理(`DistanceEstimation.estimateWorldPosition`)で奥行きを推定する**方式を採用した(ユーザー確認済み)。この方式は`DistanceEstimation`のコード変更を伴わず、既存の`ballDiameterMeters`引数にシャフト長を渡すだけで転用できる。ただし精度はボールの直径ほど安定しない可能性がある(head/handleが同一フレームで両方検出できた場合のみ算出可能なため、Phase 2実機検証で確認された欠測(セクション10)の影響を強く受ける)。

**具体的な実装内容**:

- `lib/core/club_constants.dart`に`shaftLengthMeters`(クラブ種別ごとの想定実シャフト長、目安値)と`maxPathRegressionFrames`(クラブパス回帰に使う最大観測点数、目安値5)を追加
- `lib/core/roi_constants.dart`に`postImpactBallSearchCropSizePx`(インパクト直後のボール探索クロップサイズ、目安値500px)と`postImpactBallSearchFrameCount`(探索フレーム数、目安値5)を追加
- `ClubSwingAnalysisService.analyze()`の処理順序: (1)タップ位置クロップでアドレス時のボールを検出し奥行き・スケール基準を確立 → (2)動画全体をフルフレームでクラブヘッド・ハンドル検出 → (3)`ImpactMomentDetector`でインパクトフレームを推定 → (4)インパクト以前でhead・handleが同一フレームで揃った点(最大`maxPathRegressionFrames`点)からhead-handle距離ベースで世界座標を算出し、`ClubPathEstimator`(クラブパス・アタック角)と`LaunchParameterEstimator`(`.v0`のみ、クラブヘッド速度として流用)に渡す → (5)インパクトフレームから`postImpactBallSearchFrameCount`フレームのみ広めのクロップでボールを検出 → (6)`LaunchParameterEstimator`(`.launchAngleDegrees`・`.launchDirectionDegrees`のみ、v0は使わない)で打ち出し方向・角度を算出 → (7)`SpinEstimator`でサイドスピン量を換算 → (8)クラブヘッド速度×`ClubConstants.smashFactor`で初速を算出(ボール自身の追跡からのv0は使わない、追跡窓が短すぎて速度推定の信頼性が低いため) → (9)`BallisticsSimulator`で弾道シミュレーション
- 失敗時は`ClubSwingAnalysisException`を投げる。セクション8記載の3メッセージに加え、「アドレス時のボールを検出できませんでした」「クラブパスを算出できませんでした」を追加(今回発覚したhead-handle依存の制約に伴う新しい失敗経路のため)
- `BallTrajectoryAnalysisService`と同様、`@riverpod`プロバイダ(`clubSwingAnalysisServiceProvider`)も同ファイルに追加。ただし`shotAnalysisServiceProvider`への切り替えはPhase 5のスコープのため今回は行っていない
- テスト: `test/domain/services/club_swing_analysis_service_analyze_test.dart`を新設(4件: 正常系1件、異常系3件〈クラブヘッド未検出・アドレス時ボール未検出・インパクト直後ボール検出不足〉)。既存64件と合わせて計68件が全てパス。`fvm flutter analyze`もPhase4変更分に起因する指摘は0件(既存の`ball_detector.dart`の`unnecessary_import`指摘のみ残存、Phase4範囲外)

### Phase 5: UI統合・既存フローの置き換え

- [x] クラブ種別選択画面を新設(`lib/features/club_selection/`)
- [x] 動画選択 → ボール位置指定 → クラブ種別選択 → 解析、の画面遷移に組み込む
- [x] `shotAnalysisServiceProvider`の実装を`ClubSwingAnalysisService`に切り替える(`BallTrajectoryAnalysisService`は削除せずテスト・参考実装として残す)
- [x] Phase完了確認: 実機で一連の画面遷移(動画選択→ボール位置指定→クラブ種別選択→解析→結果表示)が動くことを確認
- [x] Phase完了確認: `fvm flutter analyze`・`fvm flutter test`が通ることを確認

**実装状況(2026-08-26)**: 画面遷移の順序は、本セクション記載の2箇所の食い違い(TODOリストは「ボール位置指定→クラブ種別選択」、旧Phase完了確認は「クラブ種別選択→ボール位置指定」)についてユーザーに確認し、**「動画選択→ボール位置指定→クラブ種別選択→解析」の順序(前者)** を採用した。Phase 2で作成したデバッグ画面`lib/features/club_detector_debug/`は、ユーザー確認の上、今回は削除せず残している。

具体的な実装:

- `lib/features/club_selection/club_selection_screen.dart`(新規): `StatelessWidget`。`ClubType.values`をリスト表示し、タップした種別で`AnalyzingScreen`へ`push`する。表示ラベルはこの画面内にのみ持つ(`ClubConstants`側にはUI文言を持ち込まない)
- `lib/features/ball_position/ball_position_picker_screen.dart`(変更): `ConsumerStatefulWidget`から`HookConsumerWidget`(内部の`_FramePicker`は`HookWidget`)へ移行(`.claude/rules/flutter-widget-hooks.md`が移行対象として明記していたファイルのため、本Phaseでの変更を機に完了)。確定ボタン押下時の遷移先を`AnalyzingScreen`直接から`ClubSelectionScreen`に変更し、`TODO(Phase5)`コメントと`ClubType.driver`固定値を除去
- `lib/domain/services/ball_trajectory_analysis_service.dart`の`shotAnalysisServiceProvider`: 実装本体をPhase 4で追加済みの`clubSwingAnalysisServiceProvider`への委譲(`ref.watch(clubSwingAnalysisServiceProvider.future)`)に変更。`BallTrajectoryAnalysisService`クラス自体・`clubSwingAnalysisServiceProvider`はどちらも変更せず残置
- テスト: `test/features/club_selection/club_selection_screen_test.dart`を新設(2件: 5種類の選択肢表示、タップ時に正しい`ClubType`で`AnalyzingScreen`へ遷移)。既存の`test/widget/video_analysis_flow_test.dart`は、`confirmBallPositionButton`タップ後に`clubTypeOption_driver`をタップするヘルパー修正を行った。`fvm flutter analyze`・`fvm flutter test`(70件)は全てパス(既存の`ball_detector.dart`の`unnecessary_import`指摘のみ残存、Phase5範囲外)
- 実機(iPhone 15 Proシミュレータ)での一連の画面遷移確認は、自動化されたUIタップ操作がmacOSのアクセシビリティ権限不足で実行できなかったため、ユーザーが手動でシミュレータを操作して確認した

**実機検証で発見・修正したバグ(2026-08-26)**: ユーザーが実際のスイング動画で解析フローを試したところ、`ClubSwingAnalysisException: クラブヘッドを検出できませんでした`(手順2で検出0件)が発生した。調査の結果、これはPhase5の画面遷移ロジックの不具合ではなく、**`BallDetector`と`ClubDetector`が同じ`ultralytics_yolo`パッケージの既定チャンネル(`'default'`、`useMultiInstance`未指定時の共有スロット)を使っていたため、2つの別モデルが同時に使われる`ClubSwingAnalysisService`(Phase4で新設)において、後からロードされた方のモデルしか実質的に有効にならない**という実装バグだった。これまで「ボール検出のみ」「クラブ検出のみ」を別々に使う経路(`BallTrajectoryAnalysisService`、Phase2デバッグ画面)しか実機検証していなかったため発覚しなかった。`lib/data/ml/ball_detector.dart`・`lib/data/ml/club_detector.dart`の`YOLO`コンストラクタに`useMultiInstance: true`を追加して修正し、再検証で両モデルが正しく動作することを確認した(実機ログで確認: ClubDetector単体でhead 30件/handle 39件、修正後のClubSwingAnalysisService経由でもhead 352件/handle 472件を検出)。

**Phase6に持ち越す既知の課題(2026-08-26)**: 上記バグ修正後の実機再検証で、手順5(インパクト直後のボール検出)が`ClubSwingAnalysisException: インパクト直後のボールを検出できませんでした`で失敗する事象を確認した。実機ログとテスト動画のコマ送り確認により、この動画はカメラを低い位置・近距離に設置しておりアドレス時のボールが画面上わずか15〜20px程度と小さいことが判明した。インパクト直後のボールは低いカメラアングルの遠近効果も相まって画面内を素早く移動するため、現在の`RoiConstants.postImpactBallSearchCropSizePx`(500px)・`postImpactBallSearchFrameCount`(5)では捕捉しきれていない可能性が高い。セクション6に記載の通りこれらは「目安値、要実機検証での調整」であり、Phase6(実機検証・定数チューニング)で対応する想定(ユーザー確認済み)。

### Phase 6: 実機検証・定数チューニング

- [x] 実際のスイング動画で一連のフローがエラーなく完走することを確認
  - 既知の未解決課題(Phase5末尾の完了メモ参照): `RoiConstants.postImpactBallSearchCropSizePx`(500px)・`postImpactBallSearchFrameCount`(5)が、カメラを低い位置・近距離に設置した動画では不足し、インパクト直後のボール検出が0件になるケースを確認済み。クロップサイズ・フレーム数の拡大、またはインパクトフレーム推定精度の見直しから着手する
  - **完了条件の解釈(2026-08-26)**: 検証の結果、少なくとも1本の動画(低いカメラ位置・近距離設置)では、モーションブラーにより本物のボールがそもそも検出不能という、コード側では解決できない制約が判明した。そのため本Phaseでは「常にエラーなく完走する」ことまでは達成せず、**「誤った数値を返す不具合(直径の異なる無関係な物体を誤検出する問題)を修正し、検出できない場合は正直に例外を投げる」状態まで**を到達点とした。この動画で完走させるための追加対応(OBB化の検討等)は次フェーズ以降に持ち越し。詳細は下記完了メモ・セクション10参照
- [x] 弾道の見た目の妥当性(可能であれば実測値)と比較し、`sidespinRpmPerFaceToPathDegree`・スマッシュファクター表を補正 → 今回はスコープ外(ユーザー確認済み、実測値・参考データが無いため)
- [x] 本ドキュメントのセクション10(リスク・フォールバック方針)を、実機検証結果を踏まえて更新

**実装状況(2026-08-26)**: 上記1つ目の既知課題への対応として、以下を実装した(具体的な数値の調整材料〈失敗動画のコマ送り確認結果等〉が無かったため、いずれも保守的な目安値としてユーザー確認済み)。

- `RoiConstants.postImpactBallSearchCropSizePx`: 500px→800pxに拡大
- `RoiConstants.postImpactBallSearchFrameCount`: 5→10に拡大(探索窓を約165msから約330msへ)
- `RoiConstants.postImpactBallSearchFallbackCropSizePx`(新設、2000px): `postImpactBallSearchCropSizePx`での探索結果が2点未満だった場合のみ、同じフレーム範囲を1回だけ再探索するフォールバック用クロップサイズ。`FrameCropper.crop`が実フレームサイズにクランプするため、通常の動画では実質フルフレーム探索になる。既存のトラッキング側の`maxLostFramesBeforeFullFrameFallback`(まず狭い範囲、ロストしたら全体探索)と同じROI設計思想を踏襲した
- `ImpactMomentDetector`(インパクトフレーム特定ロジック)自体は変更していない。探索開始タイミングを前倒しする案も検討したが、ボール静止フレーム(インパクト前)を軌道回帰に誤って混入させるリスクがあるため見送った
- `test/domain/services/club_swing_analysis_service_analyze_test.dart`にフォールバック動作を検証するテストを追加(通常クロップでは検出不足・フォールバックの広いクロップで検出できた場合にShotResultが得られることを確認)。既存71件(新規1件含む)は全てパス、`fvm flutter analyze`もPhase6変更分に起因する指摘は0件(既存の`ball_detector.dart`の`unnecessary_import`指摘のみ残存、Phase6範囲外)

2つ目の項目(係数補正)は今回のスコープ外とした(ユーザー確認済み、実測値・参考データが無いため)。

**実機再検証で発見・修正したバグ(2026-08-26)**: 上記フォールバック実装後の実機再検証(打ちっぱなし練習場での撮影)で、`ClubSwingAnalysisException`は発生しなくなったものの、打ち出し方向が`-174.1度`(ほぼ真後ろ)という物理的にあり得ない値になり、結果画面の軌道グラフも表示されない事象が発生した。

調査の結果(診断ログ`[diag-club-swing]`を追加して実機再検証):

- 座標変換の数式自体(`DistanceEstimation`・`LaunchParameterEstimator`)には符号バグは無かった
- 原因は、Phase6で追加したフォールバック探索(実質フルフレーム)が、**画面手前に転がっている無関係なゴルフボール**(打ちっぱなし練習場のため画面内に多数のボールが存在)を誤検出したことだった。実機ログで、10フレーム全てがほぼ同一の位置・ほぼ同一の見かけの直径(diam≈152px、アドレス時のボールの数十pxと比べて明らかに大きい)を検出しており、実際には静止した物体を「打ち出し軌道」として扱っていたことが確認できた
- `ClubSwingAnalysisService`の`_searchPostImpactBall`には、既存の`BallKalmanTracker`が持つ「直径比によるゲーティング」(`TrackingConstants.minDiameterRatio`/`maxDiameterRatio`)が適用されておらず、信頼度さえ閾値を超えていればサイズを問わず候補として採用してしまう構造的な欠陥があった

**対応**: `_searchPostImpactBall`に、アドレス時のボール直径を基準とした直径比ゲート(`TrackingConstants.minDiameterRatio`〜`maxDiameterRatio`、既存のトラッキングロジックと同じ閾値を流用)を追加し、無関係なサイズの物体を除外するようにした。テストを2件追加(誤検出のみの場合は例外を投げる/正しいサイズの検出と誤検出が混在していても正しいサイズの検出のみを使って妥当な結果が得られる)。既存73件(累計)全てパス。

**この修正による重要なトレードオフ**: この修正により、上記の実機テスト動画では「誤った静止物体を弾く」結果、有効な検出が0件に戻り、`インパクト直後のボールを検出できませんでした`という例外に**戻る可能性が高い**(この動画で実際に飛んでいるボール自体をモデルが検出できていないという、Phase5から続く根本課題はこの修正だけでは解決しないため)。ただし、不正確な数値を黙って返すより、検出できなかったと正直に失敗する方が正しい挙動と判断した。

**実機再々検証で確認(2026-08-26)**: 同じ動画で実機再検証したところ、予想通り`postImpactSearch`は800px・2000pxのクロップどちらも`found=0`となり、`インパクト直後のボールを検出できませんでした`という例外が発生した。診断ログで、フォールバック探索(2000px)は依然として前述の無関係な静止ボール(`Golf-ball`, conf 0.27〜0.48)しか検出しておらず、直径比ゲートが正しくこれを除外していることを確認した。**誤った数値を返すバグは解消されたが、この動画で本物の飛球中のボールを検出できるようにする根本課題は未解決**という結論に至った。

**今後の方針の検討(2026-08-26)**: ここまでROI(探索範囲)側の調整を3回(定数拡大→フォールバック追加→直径ゲート追加)行ったが、いずれも「モーションブラーで本物のボールがそもそも検出されない」という核心には対処できないと判断し、一旦立ち止まってユーザーと今後の方針を相談した。検討した選択肢は以下の3つ。

1. 今回の修正(誤検出防止)でPhase6を一区切りとし、他の動画でも同様の問題が起きるか引き続き検証する
2. `postImpactBallSearchFrameCount`のさらなる拡大等、ROI側のチューニングを継続する(ただし今回の検証で本物のボールが探索範囲内で一度も検出されていないため、効果は限定的と予想される)
3. OBB(回転情報付き)モデルへの本格的な切り替えを検討する

3つ目の選択肢について、「OBB化すればボール検出は不要になるか」という質問があったため以下を整理・回答した。

- OBBでクラブヘッドの向き(真のフェース角度)を直接検出できれば、「打ち出し方向」「曲がり量(サイドスピン)」はフェース角度から直接計算でき、ボール検出への依存を解消できる(セクション2の経験則「打ち出し初期方向 ≈ フェース角度」による)
- 一方「打ち出し角度(縦方向)」は現状ボールの飛球直後の軌道(y方向の傾き)から算出しており、OBB化だけではこの依存は解消しない(ロフト角+アタック角からの推定に切り替える等、別の設計変更が必要)
- 初速はもともとクラブヘッド速度から算出しており、ボール検出とは無関係(変更なし)
- OBB化は新規データセット探し・アノテーション・再学習を要する大きな作業であり、Phase6の範囲を大きく超える

この方針検討の結論として、**今回のPhase6は「誤った数値を返す不具合の修正」までを到達点とし、OBB化を含むさらなる対応は次フェーズ以降の検討事項として持ち越す**こととした(セクション10に記載)。
