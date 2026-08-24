# ボール検出前処理(ROI限定・クロップ推論)実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ゴルフボール検出前に「探索範囲の限定(ROI)」と「ROI周辺のクロップ推論」を導入し、フレーム全体推論では検出できない極小ボールの検出率を上げる。

**Architecture:** アドレス区間(スイング前静止)の初期ボール位置はユーザーが動画の最初のフレームをタップして指定する。飛球区間は`BallKalmanTracker`の予測位置を使って次フレームのROIを都度更新しながら検出→追跡を1フレームずつ逐次実行する。ROIで一定回数連続未検出になったら全体フレーム探索に一時フォールバックする。クロップ処理は新規パッケージを追加せず`dart:ui`のみで実装する。

**Tech Stack:** Flutter/Dart, Riverpod(riverpod_generator), freezed, `dart:ui`(Canvas経由のクロップ), 既存の`ultralytics_yolo`/`get_thumbnail_video`

**Spec:** [docs/investigation-analyzing-screen-stuck.md](investigation-analyzing-screen-stuck.md) §6「対策案」1番目(検出前処理: 探索範囲の限定・クロップ推論)。初期ROIの決め方(ユーザーがタップして指定)は本計画作成時の会話で確定した設計判断。

## Global Constraints

- 新規pubパッケージ依存を追加しない。クロップ処理は`dart:ui`(`Canvas`/`PictureRecorder`)のみで実装する
- `BallKalmanTracker.track()`の公開シグネチャと既存の振る舞いを変えない。既存テスト`test/data/tracking/ball_kalman_tracker_test.dart`を無改修のまま通す
- `BallTrajectoryAnalysisService.buildShotResult()`のシグネチャと既存テスト`test/domain/services/ball_trajectory_analysis_service_test.dart`を変えない
- `distance_estimation.dart`・`ballistics_simulator.dart`・`launch_parameter_estimator.dart`(Phase2実装)には触れない
- 対象範囲は投資調査ドキュメントの対策案1のみ。モデル差し替え(Roboflow等)・撮影ガイド・エラー時UI改善(対策案2)・解析時間短縮(対策案3)・モデルDLタイムアウト(対策案4)は本計画のスコープ外
- 初期ROI(アドレス区間)は動画選択直後にユーザーが最初のフレーム上でタップして指定する(固定領域の自動推定はしない)

---

## File Structure

新規作成:
- `lib/core/roi_constants.dart` — ROI関連の閾値定数
- `lib/domain/services/roi_sequencer.dart` — 次フレームのROI(クロップ or 全体探索)を決める純粋関数
- `lib/data/ml/frame_cropper.dart` — `dart:ui`でフレームをクロップし、検出結果の座標を元フレーム座標系に戻す
- `lib/data/video/first_frame_reader.dart` — 動画の最初のフレームを取得する抽象+実装+Riverpodプロバイダ
- `lib/features/ball_position/tap_position_mapper.dart` — 画面上のタップ座標⇔画像ピクセル座標の変換(純粋関数)
- `lib/features/ball_position/ball_position_picker_screen.dart` — 初期ボール位置をタップ指定する新規画面

既存ファイルの変更:
- `lib/data/tracking/ball_kalman_tracker.dart` — `step()`/`BallTrackerCursor`/`BallTrackerStepResult`を追加し、`track()`を内部でstep()を使うようリファクタ
- `lib/domain/services/shot_analysis_service.dart` — `analyze()`に`initialBallPositionPx`引数を追加
- `lib/domain/services/ball_trajectory_analysis_service.dart` — `analyze()`をROIベースの逐次クロップ+検出+追跡ループに書き換え
- `lib/features/analyzing/analysis_controller.dart` — `build()`に`initialBallPositionPx`引数を追加
- `lib/features/analyzing/analyzing_screen.dart` — `initialBallPositionPx`を受け取りプロバイダに渡す
- `lib/features/video_select/video_select_screen.dart` — 遷移先を`BallPositionPickerScreen`に変更
- `test/fakes/fake_shot_analysis_service.dart` — シグネチャ変更に追随
- `test/widget/video_analysis_flow_test.dart` — タップ操作を挟むフローに更新

画面遷移(変更後):
```
VideoSelectScreen → BallPositionPickerScreen(新規) → AnalyzingScreen → ResultScreen
```

---

## Task 1: FrameCropper(dart:uiによるフレームクロップ+座標変換)

**Files:**
- Create: `lib/data/ml/frame_cropper.dart`
- Test: `test/data/ml/frame_cropper_test.dart`

**Interfaces:**
- Produces: `class CroppedFrame { Uint8List bytes; Offset offsetPx; }` / `class FrameCropper { static Future<CroppedFrame> crop(Uint8List frameBytes, {required Offset centerPx, required double cropSizePx}); static RawBallDetection translateDetection(RawBallDetection detection, Offset offsetPx); }`
- Consumes: `RawBallDetection`(`lib/domain/models/raw_ball_detection.dart`、既存の`copyWith`を利用)

- [ ] **Step 1: 失敗するテストを書く**

```dart
// test/data/ml/frame_cropper_test.dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dan_do/data/ml/frame_cropper.dart';
import 'package:dan_do/domain/models/raw_ball_detection.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> _makeTestFramePng({int width = 100, int height = 80}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF000000),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FrameCropper.crop', () {
    test('中心座標周辺を指定サイズで切り出し、切り出し原点を返す', () async {
      final frameBytes = await _makeTestFramePng();

      final cropped = await FrameCropper.crop(
        frameBytes,
        centerPx: const ui.Offset(45, 35),
        cropSizePx: 20,
      );

      expect(cropped.offsetPx, const ui.Offset(35, 25));

      final codec = await ui.instantiateImageCodec(cropped.bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 20);
      expect(frame.image.height, 20);
    });

    test('中心座標がフレーム端に寄っている場合、範囲内に収まるようクランプする', () async {
      final frameBytes = await _makeTestFramePng(width: 100, height: 80);

      final cropped = await FrameCropper.crop(
        frameBytes,
        centerPx: const ui.Offset(5, 5),
        cropSizePx: 20,
      );

      expect(cropped.offsetPx.dx, greaterThanOrEqualTo(0));
      expect(cropped.offsetPx.dy, greaterThanOrEqualTo(0));
    });
  });

  group('FrameCropper.translateDetection', () {
    test('クロップ内座標にオフセットを加算し元フレーム座標系に戻す', () {
      const detection = RawBallDetection(
        frameTimeMs: 100,
        centerPx: ui.Offset(10, 8),
        diameterPx: 6,
        confidence: 0.8,
      );

      final translated = FrameCropper.translateDetection(
        detection,
        const ui.Offset(35, 25),
      );

      expect(translated.centerPx, const ui.Offset(45, 33));
      expect(translated.frameTimeMs, 100);
      expect(translated.diameterPx, 6);
      expect(translated.confidence, 0.8);
    });
  });
}
```

- [ ] **Step 2: テストを実行し失敗を確認する**

Run: `fvm flutter test test/data/ml/frame_cropper_test.dart`
Expected: FAIL(`frame_cropper.dart`が存在しない)

- [ ] **Step 3: 実装する**

```dart
// lib/data/ml/frame_cropper.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../domain/models/raw_ball_detection.dart';

/// [FrameCropper.crop]の結果。[bytes]はクロップ後のPNGバイト列、[offsetPx]は
/// 元フレーム座標系におけるクロップ範囲の左上原点。
class CroppedFrame {
  const CroppedFrame({required this.bytes, required this.offsetPx});

  final Uint8List bytes;
  final ui.Offset offsetPx;
}

/// 元フレームから指定中心・サイズの矩形を切り出す。切り出しにより検出モデルに
/// 渡す画像内でのボールの相対的な大きさ(実効解像度)が上がり、極小の被写体を
/// 検出しやすくなる。
class FrameCropper {
  const FrameCropper._();

  static Future<CroppedFrame> crop(
    Uint8List frameBytes, {
    required ui.Offset centerPx,
    required double cropSizePx,
  }) async {
    final codec = await ui.instantiateImageCodec(frameBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final frameWidth = image.width.toDouble();
    final frameHeight = image.height.toDouble();

    final width = math.min(cropSizePx, frameWidth);
    final height = math.min(cropSizePx, frameHeight);
    final left = (centerPx.dx - width / 2).clamp(0.0, frameWidth - width);
    final top = (centerPx.dy - height / 2).clamp(0.0, frameHeight - height);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(left, top, width, height),
      ui.Rect.fromLTWH(0, 0, width, height),
      ui.Paint(),
    );
    final picture = recorder.endRecording();
    final croppedImage = await picture.toImage(width.round(), height.round());
    final byteData = await croppedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return CroppedFrame(
      bytes: byteData!.buffer.asUint8List(),
      offsetPx: ui.Offset(left, top),
    );
  }

  /// クロップ画像内座標系の[detection]を、元フレーム座標系に変換する。
  static RawBallDetection translateDetection(
    RawBallDetection detection,
    ui.Offset offsetPx,
  ) {
    return detection.copyWith(centerPx: detection.centerPx + offsetPx);
  }
}
```

- [ ] **Step 4: テストを実行し成功を確認する**

Run: `fvm flutter test test/data/ml/frame_cropper_test.dart`
Expected: PASS

- [ ] **Step 5: コミット**

```bash
git add lib/data/ml/frame_cropper.dart test/data/ml/frame_cropper_test.dart
git commit -m "feat: フレームクロップ+座標変換のFrameCropperを追加"
```

---

## Task 2: RoiConstants + RoiSequencer(次フレームのROI決定ロジック)

**Files:**
- Create: `lib/core/roi_constants.dart`
- Create: `lib/domain/services/roi_sequencer.dart`
- Test: `test/domain/services/roi_sequencer_test.dart`

**Interfaces:**
- Consumes: なし(純粋ロジック)
- Produces: `class RoiConstants { static const double initialCropSizePx; static const double trackingCropSizePx; static const int maxLostFramesBeforeFullFrameFallback; }` / `class RoiDecision { Offset? centerPx; double cropSizePx; bool useFullFrame; }` / `class RoiSequencer { static RoiDecision decideNextRoi({required Offset? searchCenterPx, required double cropSizePx, required int consecutiveLostFrames}); }`

- [ ] **Step 1: 定数ファイルを作成する**

```dart
// lib/core/roi_constants.dart
/// ROI(探索範囲)限定・クロップ推論のヒューリスティックな閾値(目安値)。
///
/// 実機のスイング動画で検出成功率を確認しながら調整する想定。
class RoiConstants {
  const RoiConstants._();

  /// アドレス区間(タップ直後)の初期クロップサイズ(px、正方形の一辺)。
  static const double initialCropSizePx = 240;

  /// 追跡開始後、予測位置を中心にクロップするサイズ(px、正方形の一辺)。
  static const double trackingCropSizePx = 160;

  /// この回数だけ連続でROI内に検出が無かった場合、その回だけ全体フレーム
  /// 探索にフォールバックする。
  static const int maxLostFramesBeforeFullFrameFallback = 5;
}
```

- [ ] **Step 2: 失敗するテストを書く**

```dart
// test/domain/services/roi_sequencer_test.dart
import 'package:dan_do/core/roi_constants.dart';
import 'package:dan_do/domain/services/roi_sequencer.dart';
import 'package:flutter/material.dart' show Offset;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoiSequencer.decideNextRoi', () {
    test('探索中心が未確定なら全体フレーム探索を返す', () {
      final decision = RoiSequencer.decideNextRoi(
        searchCenterPx: null,
        cropSizePx: RoiConstants.initialCropSizePx,
        consecutiveLostFrames: 0,
      );

      expect(decision.useFullFrame, isTrue);
      expect(decision.centerPx, isNull);
    });

    test('探索中心がありロスト回数が閾値未満ならクロップ探索を返す', () {
      final decision = RoiSequencer.decideNextRoi(
        searchCenterPx: const Offset(100, 200),
        cropSizePx: RoiConstants.trackingCropSizePx,
        consecutiveLostFrames: RoiConstants.maxLostFramesBeforeFullFrameFallback - 1,
      );

      expect(decision.useFullFrame, isFalse);
      expect(decision.centerPx, const Offset(100, 200));
      expect(decision.cropSizePx, RoiConstants.trackingCropSizePx);
    });

    test('ロスト回数が閾値以上になると全体フレーム探索にフォールバックする', () {
      final decision = RoiSequencer.decideNextRoi(
        searchCenterPx: const Offset(100, 200),
        cropSizePx: RoiConstants.trackingCropSizePx,
        consecutiveLostFrames: RoiConstants.maxLostFramesBeforeFullFrameFallback,
      );

      expect(decision.useFullFrame, isTrue);
    });
  });
}
```

- [ ] **Step 3: テストを実行し失敗を確認する**

Run: `fvm flutter test test/domain/services/roi_sequencer_test.dart`
Expected: FAIL(`roi_sequencer.dart`が存在しない)

- [ ] **Step 4: 実装する**

```dart
// lib/domain/services/roi_sequencer.dart
import 'package:flutter/material.dart' show Offset;

import '../../core/roi_constants.dart';

/// [RoiSequencer.decideNextRoi]が返す、次フレームで検出モデルに渡す範囲の決定。
class RoiDecision {
  const RoiDecision.crop({required Offset center, required this.cropSizePx})
    : centerPx = center,
      useFullFrame = false;

  const RoiDecision.fullFrame() : centerPx = null, cropSizePx = 0, useFullFrame = true;

  final Offset? centerPx;
  final double cropSizePx;
  final bool useFullFrame;
}

/// 現在の探索中心・ロスト連続回数から、次フレームで使うROI(クロップ範囲)を
/// 決める純粋関数。探索中心が未確定、またはロストが続いた場合は全体フレーム
/// 探索にフォールバックする。
class RoiSequencer {
  const RoiSequencer._();

  static RoiDecision decideNextRoi({
    required Offset? searchCenterPx,
    required double cropSizePx,
    required int consecutiveLostFrames,
  }) {
    if (searchCenterPx == null) {
      return const RoiDecision.fullFrame();
    }
    if (consecutiveLostFrames >= RoiConstants.maxLostFramesBeforeFullFrameFallback) {
      return const RoiDecision.fullFrame();
    }
    return RoiDecision.crop(center: searchCenterPx, cropSizePx: cropSizePx);
  }
}
```

- [ ] **Step 5: テストを実行し成功を確認する**

Run: `fvm flutter test test/domain/services/roi_sequencer_test.dart`
Expected: PASS

- [ ] **Step 6: コミット**

```bash
git add lib/core/roi_constants.dart lib/domain/services/roi_sequencer.dart test/domain/services/roi_sequencer_test.dart
git commit -m "feat: ROI決定ロジックRoiSequencerを追加"
```

---

## Task 3: BallKalmanTracker に逐次ステップAPI(step)を追加

既存の`track()`は「全検出をまとめて渡す」バッチ処理のみだが、ROIベースの逐次処理では「1フレーム進めて次の予測位置を得る」操作が必要になる。`track()`のロジックを`step()`に切り出し、`track()`は内部でループしながら`step()`を呼ぶ形にリファクタする。**既存テストは無改修のまま通ること**を確認する。

**Files:**
- Modify: `lib/data/tracking/ball_kalman_tracker.dart`
- Test: `test/data/tracking/ball_kalman_tracker_test.dart`(既存テストは変更しない。`step()`用のテストを追記する)

**Interfaces:**
- Consumes: `RawBallDetection`, `TrackedBallState`, `BallTrackingPhase`(既存)
- Produces: `class BallTrackerCursor { double u,v,du,dv,diameterPx; int frameTimeMs; bool hasLaunched; Offset predictedCenterPx(int atFrameTimeMs); }` / `class BallTrackerStepResult { BallTrackerCursor cursor; TrackedBallState state; }` / `BallKalmanTracker.step({required BallTrackerCursor? cursor, required List<RawBallDetection> candidatesAtFrame, required int frameTimeMs}) -> BallTrackerStepResult`

- [ ] **Step 1: 既存テストが通ることを確認する(リファクタ前のベースライン)**

Run: `fvm flutter test test/data/tracking/ball_kalman_tracker_test.dart`
Expected: PASS(4テストとも成功。この後のリファクタで壊さないことの基準にする)

- [ ] **Step 2: `step()`用の失敗するテストを追記する**

`test/data/tracking/ball_kalman_tracker_test.dart`の末尾、`main()`内の既存`group`の後に追記する。

```dart
  group('BallKalmanTracker.step', () {
    test('cursorがnullのとき、最も信頼度が高い候補で追跡を開始しaddressフェーズを返す', () {
      const tracker = BallKalmanTracker();
      final candidates = [
        _detection(frameTimeMs: 0, u: 100, v: 100, confidence: 0.5),
        _detection(frameTimeMs: 0, u: 200, v: 200, confidence: 0.9),
      ];

      final result = tracker.step(
        cursor: null,
        candidatesAtFrame: candidates,
        frameTimeMs: 0,
      );

      expect(result.state.phase, BallTrackingPhase.address);
      expect(result.state.u, 200);
      expect(result.state.v, 200);
      expect(result.cursor.hasLaunched, isFalse);
    });

    test('cursorがnullかつ信頼度条件を満たす候補が無い場合はArgumentErrorを投げる', () {
      const tracker = BallKalmanTracker(confidenceThreshold: 0.5);

      expect(
        () => tracker.step(
          cursor: null,
          candidatesAtFrame: [
            _detection(frameTimeMs: 0, u: 100, v: 100, confidence: 0.1),
          ],
          frameTimeMs: 0,
        ),
        throwsArgumentError,
      );
    });

    test('cursorありで予測位置に近い候補があれば追跡を継続する', () {
      const tracker = BallKalmanTracker();
      const cursor = BallTrackerCursor(
        u: 100,
        v: 100,
        du: 0,
        dv: 0,
        diameterPx: 20,
        frameTimeMs: 0,
        hasLaunched: false,
      );

      final result = tracker.step(
        cursor: cursor,
        candidatesAtFrame: [_detection(frameTimeMs: 33, u: 103, v: 98)],
        frameTimeMs: 33,
      );

      expect(result.state.phase, BallTrackingPhase.address);
      expect(result.state.u, closeTo(100, 5));
      expect(result.cursor.frameTimeMs, 33);
    });

    test('BallTrackerCursor.predictedCenterPxは速度から次フレームの位置を外挿する', () {
      const cursor = BallTrackerCursor(
        u: 100,
        v: 100,
        du: 1000,
        dv: 0,
        diameterPx: 20,
        frameTimeMs: 0,
        hasLaunched: true,
      );

      final predicted = cursor.predictedCenterPx(33);

      expect(predicted.dx, closeTo(133, 0.1));
      expect(predicted.dy, closeTo(100, 0.1));
    });
  });
```

- [ ] **Step 3: テストを実行し失敗を確認する**

Run: `fvm flutter test test/data/tracking/ball_kalman_tracker_test.dart`
Expected: FAIL(`step`/`BallTrackerCursor`が存在しない)

- [ ] **Step 4: `lib/data/tracking/ball_kalman_tracker.dart`をリファクタする**

ファイル全体を以下の内容に置き換える。

```dart
import 'dart:math' as math;
import 'dart:ui';

import '../../core/tracking_constants.dart';
import '../../domain/models/raw_ball_detection.dart';
import '../../domain/models/tracked_ball_state.dart';

/// [BallKalmanTracker.step]がフレームをまたいで引き回す内部状態。
/// [predictedCenterPx]をROI決定(次フレームのクロップ中心)に使う。
class BallTrackerCursor {
  const BallTrackerCursor({
    required this.u,
    required this.v,
    required this.du,
    required this.dv,
    required this.diameterPx,
    required this.frameTimeMs,
    required this.hasLaunched,
  });

  final double u;
  final double v;
  final double du;
  final double dv;
  final double diameterPx;
  final int frameTimeMs;
  final bool hasLaunched;

  /// 現在の位置・速度から、[atFrameTimeMs]時点の予測位置を等速直線運動で外挿する。
  Offset predictedCenterPx(int atFrameTimeMs) {
    final dtSeconds = (atFrameTimeMs - frameTimeMs) / 1000.0;
    return Offset(u + du * dtSeconds, v + dv * dtSeconds);
  }
}

/// [BallKalmanTracker.step]が返す、1フレーム分の更新結果。
class BallTrackerStepResult {
  const BallTrackerStepResult({required this.cursor, required this.state});

  final BallTrackerCursor cursor;
  final TrackedBallState state;
}

/// 手書きの簡易カルマンフィルタ(定速度モデル、g-h/alpha-betaフィルタ)による
/// ボール位置の平滑化・誤検出のゲーティング・フェーズ判定を行う。
///
/// 統計的に厳密なMahalanobis距離等は用いず、単純な閾値判定のゲーティングで
/// 十分とする方針(`docs/implementation-plan-analysis-pipeline.md`参照)。
class BallKalmanTracker {
  const BallKalmanTracker({
    this.confidenceThreshold = TrackingConstants.confidenceThreshold,
    this.gatingRadiusPx = TrackingConstants.gatingRadiusPx,
    this.launchSpeedThresholdPxPerSecond =
        TrackingConstants.launchSpeedThresholdPxPerSecond,
  });

  final double confidenceThreshold;
  final double gatingRadiusPx;
  final double launchSpeedThresholdPxPerSecond;

  /// 位置補正のゲイン(alpha)。予測と観測の残差をどれだけ位置に反映するか。
  static const double _positionGain = 0.6;

  /// 速度補正のゲイン(beta)。残差をどれだけ速度推定の更新に反映するか。
  static const double _velocityGain = 0.3;

  List<TrackedBallState> track(List<RawBallDetection> detections) {
    final byFrameTimeMs = <int, List<RawBallDetection>>{};
    for (final detection in detections) {
      (byFrameTimeMs[detection.frameTimeMs] ??= []).add(detection);
    }
    final sortedFrameTimes = byFrameTimeMs.keys.toList()..sort();

    final states = <TrackedBallState>[];
    BallTrackerCursor? cursor;

    for (final frameTimeMs in sortedFrameTimes) {
      final candidates = byFrameTimeMs[frameTimeMs]!;

      if (cursor == null &&
          candidates.every((d) => d.confidence < confidenceThreshold)) {
        continue;
      }
      if (cursor != null && frameTimeMs - cursor.frameTimeMs <= 0) {
        continue;
      }

      final result = step(
        cursor: cursor,
        candidatesAtFrame: candidates,
        frameTimeMs: frameTimeMs,
      );
      cursor = result.cursor;
      states.add(result.state);
    }

    return states;
  }

  /// 1フレーム分の検出候補からトラッカー状態を1ステップ進める。
  ///
  /// [cursor]が`null`の場合は追跡開始前とみなし、[candidatesAtFrame]の中で
  /// 信頼度が[confidenceThreshold]以上の候補のうち最も信頼度が高いものを
  /// 追跡開始点として採用する。信頼度条件を満たす候補が1件も無い状態で
  /// [cursor]が`null`のまま呼び出すことはできない(呼び出し側で候補が出るまで
  /// 呼び出しをスキップすること)。
  BallTrackerStepResult step({
    required BallTrackerCursor? cursor,
    required List<RawBallDetection> candidatesAtFrame,
    required int frameTimeMs,
  }) {
    final candidates = candidatesAtFrame
        .where((d) => d.confidence >= confidenceThreshold)
        .toList();

    if (cursor == null) {
      if (candidates.isEmpty) {
        throw ArgumentError(
          'cursorがnullの場合、candidatesAtFrameに信頼度条件を満たす候補が'
          '1件以上必要です',
        );
      }
      final best = candidates.reduce(
        (a, b) => a.confidence >= b.confidence ? a : b,
      );
      final newCursor = BallTrackerCursor(
        u: best.centerPx.dx,
        v: best.centerPx.dy,
        du: 0,
        dv: 0,
        diameterPx: best.diameterPx,
        frameTimeMs: frameTimeMs,
        hasLaunched: false,
      );
      final state = TrackedBallState(
        frameTimeMs: frameTimeMs,
        u: newCursor.u,
        v: newCursor.v,
        du: newCursor.du,
        dv: newCursor.dv,
        diameterPx: newCursor.diameterPx,
        phase: BallTrackingPhase.address,
      );
      return BallTrackerStepResult(cursor: newCursor, state: state);
    }

    final dtSeconds = (frameTimeMs - cursor.frameTimeMs) / 1000.0;
    final predicted = cursor.predictedCenterPx(frameTimeMs);
    final predictedU = predicted.dx;
    final predictedV = predicted.dy;

    RawBallDetection? matched;
    var matchedDistance = double.infinity;
    for (final candidate in candidates) {
      final dx = candidate.centerPx.dx - predictedU;
      final dy = candidate.centerPx.dy - predictedV;
      final distance = math.sqrt(dx * dx + dy * dy);
      if (distance <= gatingRadiusPx && distance < matchedDistance) {
        matched = candidate;
        matchedDistance = distance;
      }
    }

    if (matched == null) {
      final newCursor = BallTrackerCursor(
        u: predictedU,
        v: predictedV,
        du: cursor.du,
        dv: cursor.dv,
        diameterPx: cursor.diameterPx,
        frameTimeMs: frameTimeMs,
        hasLaunched: cursor.hasLaunched,
      );
      final state = TrackedBallState(
        frameTimeMs: frameTimeMs,
        u: newCursor.u,
        v: newCursor.v,
        du: newCursor.du,
        dv: newCursor.dv,
        diameterPx: newCursor.diameterPx,
        phase: BallTrackingPhase.lost,
      );
      return BallTrackerStepResult(cursor: newCursor, state: state);
    }

    final residualU = matched.centerPx.dx - predictedU;
    final residualV = matched.centerPx.dy - predictedV;

    final newU = predictedU + _positionGain * residualU;
    final newV = predictedV + _positionGain * residualV;
    final newDu = cursor.du + (_velocityGain / dtSeconds) * residualU;
    final newDv = cursor.dv + (_velocityGain / dtSeconds) * residualV;

    final speed = math.sqrt(newDu * newDu + newDv * newDv);
    final hasLaunched =
        cursor.hasLaunched || speed > launchSpeedThresholdPxPerSecond;

    final newCursor = BallTrackerCursor(
      u: newU,
      v: newV,
      du: newDu,
      dv: newDv,
      diameterPx: matched.diameterPx,
      frameTimeMs: frameTimeMs,
      hasLaunched: hasLaunched,
    );
    final state = TrackedBallState(
      frameTimeMs: frameTimeMs,
      u: newCursor.u,
      v: newCursor.v,
      du: newCursor.du,
      dv: newCursor.dv,
      diameterPx: newCursor.diameterPx,
      phase: hasLaunched
          ? BallTrackingPhase.launch
          : BallTrackingPhase.address,
    );
    return BallTrackerStepResult(cursor: newCursor, state: state);
  }
}
```

- [ ] **Step 5: テストを実行し、既存テスト・新規テストとも成功することを確認する**

Run: `fvm flutter test test/data/tracking/ball_kalman_tracker_test.dart`
Expected: PASS(既存4テスト+新規4テスト、計8テスト)

- [ ] **Step 6: コミット**

```bash
git add lib/data/tracking/ball_kalman_tracker.dart test/data/tracking/ball_kalman_tracker_test.dart
git commit -m "refactor: BallKalmanTrackerに逐次ステップAPI(step)を追加"
```

---

## Task 4: ShotAnalysisService/BallTrajectoryAnalysisServiceをROIベースのループに書き換え

`analyze()`にタップ位置を渡せるようにし、ループ内でFrameCropper・RoiSequencer・`tracker.step()`を結線する。**`buildShotResult()`のシグネチャ・既存テストは変更しない**(検出結果を集めた後の処理は従来通り)。

**Files:**
- Modify: `lib/domain/services/shot_analysis_service.dart`
- Modify: `lib/domain/services/ball_trajectory_analysis_service.dart:38-75`(コンストラクタと`analyze()`)
- Modify: `test/fakes/fake_shot_analysis_service.dart`

**Interfaces:**
- Consumes: `FrameCropper`(Task 1), `RoiSequencer`/`RoiConstants`(Task 2), `BallKalmanTracker.step`/`BallTrackerCursor`(Task 3)
- Produces: `abstract class ShotAnalysisService { Future<ShotResult> analyze(XFile video, {required Offset initialBallPositionPx}); }`

- [ ] **Step 1: `ShotAnalysisService`のシグネチャを変更する**

```dart
// lib/domain/services/shot_analysis_service.dart
import 'dart:ui';

import 'package:cross_file/cross_file.dart';

import '../models/shot_result.dart';

abstract class ShotAnalysisService {
  Future<ShotResult> analyze(
    XFile video, {
    required Offset initialBallPositionPx,
  });
}
```

- [ ] **Step 2: `FakeShotAnalysisService`を追随させる**

```dart
// test/fakes/fake_shot_analysis_service.dart
import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:dan_do/domain/models/shot_result.dart';
import 'package:dan_do/domain/services/shot_analysis_service.dart';

class FakeShotAnalysisService implements ShotAnalysisService {
  @override
  Future<ShotResult> analyze(
    XFile video, {
    required Offset initialBallPositionPx,
  }) async {
    return const ShotResult(
      carryDistanceMeters: 150,
      launchAngleDegrees: 15,
      launchDirectionDegrees: 0,
      measuredTrajectory: [],
      simulatedTrajectory: [],
    );
  }
}
```

- [ ] **Step 3: `dart analyze`を実行し、この時点でのコンパイルエラー箇所を確認する**

Run: `fvm dart analyze`
Expected: `BallTrajectoryAnalysisService`が抽象メソッドを実装していない旨のエラー、および`_ThrowingShotAnalysisService`(test内)のシグネチャ不一致エラーが出る(次のStepとTask 9で解消する)

- [ ] **Step 4: `BallTrajectoryAnalysisService`のコンストラクタに`tracker`を追加し、`analyze()`をROIループに書き換える**

`lib/domain/services/ball_trajectory_analysis_service.dart`の先頭importに以下を追加する。

```dart
import '../../core/roi_constants.dart';
import '../../data/ml/frame_cropper.dart';
import 'roi_sequencer.dart';
```

`BallTrajectoryAnalysisService`クラスのコンストラクタ・フィールド・`analyze()`メソッド(元の38〜75行目)を、以下の内容に置き換える。

```dart
class BallTrajectoryAnalysisService implements ShotAnalysisService {
  BallTrajectoryAnalysisService({
    required this.ballDetector,
    required this.videoDurationReader,
    required this.frameSourceFactory,
    this.tracker = const BallKalmanTracker(),
  });

  static const frameInterval = Duration(milliseconds: 33);

  final BallDetector ballDetector;
  final VideoDurationReader videoDurationReader;
  final VideoFrameSource Function(XFile video) frameSourceFactory;
  final BallKalmanTracker tracker;

  @override
  Future<ShotResult> analyze(
    XFile video, {
    required Offset initialBallPositionPx,
  }) async {
    final duration = await videoDurationReader.read(video);
    final frameSource = frameSourceFactory(video);

    final detections = <RawBallDetection>[];
    double? frameWidthPx;
    Offset? searchCenterPx = initialBallPositionPx;
    var cropSizePx = RoiConstants.initialCropSizePx;
    BallTrackerCursor? roiCursor;
    var consecutiveLostFrames = 0;

    for (var t = Duration.zero; t < duration; t += frameInterval) {
      final frameBytes = await frameSource.frameAt(t);
      frameWidthPx ??= await _decodeFrameWidthPx(frameBytes);

      final decision = RoiSequencer.decideNextRoi(
        searchCenterPx: searchCenterPx,
        cropSizePx: cropSizePx,
        consecutiveLostFrames: consecutiveLostFrames,
      );

      List<RawBallDetection> frameDetections;
      if (decision.useFullFrame) {
        frameDetections = await ballDetector.detect(frameBytes, frameTime: t);
      } else {
        final cropped = await FrameCropper.crop(
          frameBytes,
          centerPx: decision.centerPx!,
          cropSizePx: decision.cropSizePx,
        );
        final rawDetections = await ballDetector.detect(
          cropped.bytes,
          frameTime: t,
        );
        frameDetections = rawDetections
            .map((d) => FrameCropper.translateDetection(d, cropped.offsetPx))
            .toList();
      }

      detections.addAll(frameDetections);
      consecutiveLostFrames = frameDetections.isEmpty
          ? consecutiveLostFrames + 1
          : 0;

      if (roiCursor == null && frameDetections.isEmpty) {
        continue;
      }
      final stepResult = tracker.step(
        cursor: roiCursor,
        candidatesAtFrame: frameDetections,
        frameTimeMs: t.inMilliseconds,
      );
      roiCursor = stepResult.cursor;
      searchCenterPx = Offset(roiCursor.u, roiCursor.v);
      cropSizePx = RoiConstants.trackingCropSizePx;
    }

    debugPrint(
      'BallTrajectoryAnalysisService: sports ball detections=${detections.length}',
    );

    if (frameWidthPx == null) {
      throw const InsufficientTrajectoryDataException(
        '動画からフレームを取得できませんでした',
      );
    }

    return buildShotResult(detections: detections, frameWidthPx: frameWidthPx);
  }
```

`buildShotResult()`とその後ろの`_decodeFrameWidthPx()`・プロバイダ定義(`shotAnalysisServiceProvider`)はそのまま変更しない。

- [ ] **Step 5: 既存の`buildShotResult`テストが無改修のまま通ることを確認する**

Run: `fvm flutter test test/domain/services/ball_trajectory_analysis_service_test.dart`
Expected: PASS(このテストは`buildShotResult`のみを呼んでおり、`analyze()`の変更の影響を受けない)

- [ ] **Step 6: コミット**

```bash
git add lib/domain/services/shot_analysis_service.dart lib/domain/services/ball_trajectory_analysis_service.dart test/fakes/fake_shot_analysis_service.dart
git commit -m "feat: BallTrajectoryAnalysisServiceをROIベースの逐次検出+追跡ループに変更"
```

---

## Task 5: AnalysisController/AnalyzingScreenにinitialBallPositionPxを通す

**Files:**
- Modify: `lib/features/analyzing/analysis_controller.dart`
- Modify: `lib/features/analyzing/analyzing_screen.dart`

**Interfaces:**
- Consumes: `ShotAnalysisService.analyze(video, {required initialBallPositionPx})`(Task 4)
- Produces: `analysisControllerProvider(XFile video, Offset initialBallPositionPx)`(riverpod_generatorによる自動生成family)、`class AnalyzingScreen { const AnalyzingScreen({required XFile video, required Offset initialBallPositionPx}); }`

- [ ] **Step 1: `AnalysisController.build()`に`initialBallPositionPx`引数を追加する**

```dart
// lib/features/analyzing/analysis_controller.dart
import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/shot_result.dart';
import '../../domain/services/ball_trajectory_analysis_service.dart';

part 'analysis_controller.g.dart';

@riverpod
class AnalysisController extends _$AnalysisController {
  @override
  Future<ShotResult> build(XFile video, Offset initialBallPositionPx) async {
    final service = await ref.watch(shotAnalysisServiceProvider.future);
    return service.analyze(
      video,
      initialBallPositionPx: initialBallPositionPx,
    );
  }
}
```

- [ ] **Step 2: `AnalyzingScreen`が`initialBallPositionPx`を受け取り、プロバイダに渡すよう変更する**

```dart
// lib/features/analyzing/analyzing_screen.dart
import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/shot_result.dart';
import '../result/result_screen.dart';
import 'analysis_controller.dart';

class AnalyzingScreen extends ConsumerWidget {
  const AnalyzingScreen({
    super.key,
    required this.video,
    required this.initialBallPositionPx,
  });

  final XFile video;
  final Offset initialBallPositionPx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = analysisControllerProvider(video, initialBallPositionPx);

    ref.listen<AsyncValue<ShotResult>>(provider, (previous, next) {
      next.whenOrNull(
        data: (result) {
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(
              builder: (_) => ResultScreen(video: video, result: result),
            ),
          );
        },
      );
    });

    final state = ref.watch(provider);

    final showError = state.hasError && !state.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('解析中')),
      body: Center(
        child: showError
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('解析に失敗しました: ${state.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const Key('backToVideoSelectButton'),
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    child: const Text('別の動画を選ぶ'),
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
```

- [ ] **Step 3: コード生成を再実行する**

Run: `fvm dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/features/analyzing/analysis_controller.g.dart`が2引数familyに対応した内容で再生成される

- [ ] **Step 4: `dart analyze`でこの時点のエラーを確認する**

Run: `fvm dart analyze`
Expected: `VideoSelectScreen`(まだ`AnalyzingScreen`を1引数で呼んでいる)・`test/widget/video_analysis_flow_test.dart`(まだ`analyze()`を1引数で実装している)にエラーが残る(Task 8・9で解消)

- [ ] **Step 5: コミット**

```bash
git add lib/features/analyzing/analysis_controller.dart lib/features/analyzing/analysis_controller.g.dart lib/features/analyzing/analyzing_screen.dart
git commit -m "feat: AnalysisController/AnalyzingScreenにinitialBallPositionPxを通す"
```

---

## Task 6: FirstFrameReader(動画の最初のフレーム取得の抽象化)

`videoDurationReaderProvider`/`videoPickerProvider`と同じ「抽象インターフェース+実装+Riverpodプロバイダ」パターンで、動画の最初のフレームを取得する層を追加する。widgetテストではこれをFakeに差し替える。

**Files:**
- Create: `lib/data/video/first_frame_reader.dart`
- Create: `test/fakes/fake_first_frame_reader.dart`

**Interfaces:**
- Consumes: `VideoFrameSource`(既存、`lib/data/video/video_frame_source.dart`)、`GetThumbnailVideoFrameSource`(既存)
- Produces: `abstract class FirstFrameReader { Future<Uint8List> read(XFile video); }` / `firstFrameReaderProvider`(riverpod)

- [ ] **Step 1: 実装する**

```dart
// lib/data/video/first_frame_reader.dart
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'get_thumbnail_video_frame_source.dart';
import 'video_frame_source.dart';

part 'first_frame_reader.g.dart';

abstract class FirstFrameReader {
  Future<Uint8List> read(XFile video);
}

class VideoFrameSourceFirstFrameReader implements FirstFrameReader {
  const VideoFrameSourceFirstFrameReader(this.frameSourceFactory);

  final VideoFrameSource Function(XFile video) frameSourceFactory;

  @override
  Future<Uint8List> read(XFile video) {
    return frameSourceFactory(video).frameAt(Duration.zero);
  }
}

@riverpod
FirstFrameReader firstFrameReader(Ref ref) =>
    const VideoFrameSourceFirstFrameReader(GetThumbnailVideoFrameSource.new);
```

- [ ] **Step 2: Fakeを作成する**

```dart
// test/fakes/fake_first_frame_reader.dart
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:dan_do/data/video/first_frame_reader.dart';

class FakeFirstFrameReader implements FirstFrameReader {
  FakeFirstFrameReader(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List> read(XFile video) async => bytes;
}
```

- [ ] **Step 3: コード生成を実行する**

Run: `fvm dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/data/video/first_frame_reader.g.dart`が生成される

- [ ] **Step 4: `dart analyze`でエラーが無いことを確認する**

Run: `fvm dart analyze lib/data/video/first_frame_reader.dart lib/data/video/first_frame_reader.g.dart test/fakes/fake_first_frame_reader.dart`
Expected: `No issues found!`

- [ ] **Step 5: コミット**

```bash
git add lib/data/video/first_frame_reader.dart lib/data/video/first_frame_reader.g.dart test/fakes/fake_first_frame_reader.dart
git commit -m "feat: 動画の最初のフレームを取得するFirstFrameReaderを追加"
```

---

## Task 7: タップ位置⇔画像ピクセル座標の変換(純粋関数)

**Files:**
- Create: `lib/features/ball_position/tap_position_mapper.dart`
- Test: `test/features/ball_position/tap_position_mapper_test.dart`

**Interfaces:**
- Produces: `Offset mapDisplayPositionToImagePx({required Offset localPosition, required Size displaySize, required Size imageSize})` / `Offset mapImagePxToDisplayPosition({required Offset imagePx, required Size displaySize, required Size imageSize})`

- [ ] **Step 1: 失敗するテストを書く**

```dart
// test/features/ball_position/tap_position_mapper_test.dart
import 'package:dan_do/features/ball_position/tap_position_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapDisplayPositionToImagePx', () {
    test('displaySizeが画像と同アスペクト比なら等倍スケールでマップする', () {
      final result = mapDisplayPositionToImagePx(
        localPosition: const Offset(100, 50),
        displaySize: const Size(200, 100),
        imageSize: const Size(400, 200),
      );

      expect(result, const Offset(200, 100));
    });

    test('displaySizeが画像より横長の場合、左右の余白を差し引いてマップする', () {
      // imageSize 100x200(縦長)をdisplaySize 300x200にcontainで収めると、
      // 高さ基準でスケールされ幅150、左右75pxずつ余白ができる。
      final result = mapDisplayPositionToImagePx(
        localPosition: const Offset(75, 0),
        displaySize: const Size(300, 200),
        imageSize: const Size(100, 200),
      );

      expect(result.dx, closeTo(0, 0.001));
      expect(result.dy, closeTo(0, 0.001));
    });

    test('画像範囲外のタップはクランプされる', () {
      final result = mapDisplayPositionToImagePx(
        localPosition: const Offset(-50, -50),
        displaySize: const Size(200, 100),
        imageSize: const Size(400, 200),
      );

      expect(result, const Offset(0, 0));
    });
  });

  group('mapImagePxToDisplayPosition', () {
    test('mapDisplayPositionToImagePxの逆変換になる', () {
      const displaySize = Size(200, 100);
      const imageSize = Size(400, 200);
      const imagePx = Offset(200, 100);

      final displayPosition = mapImagePxToDisplayPosition(
        imagePx: imagePx,
        displaySize: displaySize,
        imageSize: imageSize,
      );

      expect(displayPosition, const Offset(100, 50));
    });
  });
}
```

- [ ] **Step 2: テストを実行し失敗を確認する**

Run: `fvm flutter test test/features/ball_position/tap_position_mapper_test.dart`
Expected: FAIL(`tap_position_mapper.dart`が存在しない)

- [ ] **Step 3: 実装する**

```dart
// lib/features/ball_position/tap_position_mapper.dart
import 'package:flutter/rendering.dart' show BoxFit, applyBoxFit;
import 'package:flutter/material.dart' show Offset, Size;

/// [BoxFit.contain]で[imageSize]の画像を[displaySize]の領域に表示したときの、
/// 実際の描画サイズと余白(レターボックス)を返す。
({Size renderedSize, Offset topLeft}) _fittedLayout(
  Size displaySize,
  Size imageSize,
) {
  final fitted = applyBoxFit(BoxFit.contain, imageSize, displaySize);
  final renderedSize = fitted.destination;
  final topLeft = Offset(
    (displaySize.width - renderedSize.width) / 2,
    (displaySize.height - renderedSize.height) / 2,
  );
  return (renderedSize: renderedSize, topLeft: topLeft);
}

/// 画面上の表示座標([localPosition])を、[BoxFit.contain]で表示された画像の
/// ピクセル座標系に変換する。画像範囲外は端にクランプする。
Offset mapDisplayPositionToImagePx({
  required Offset localPosition,
  required Size displaySize,
  required Size imageSize,
}) {
  final layout = _fittedLayout(displaySize, imageSize);
  final localInImage = localPosition - layout.topLeft;
  final scale = imageSize.width / layout.renderedSize.width;
  final dx = (localInImage.dx * scale).clamp(0.0, imageSize.width);
  final dy = (localInImage.dy * scale).clamp(0.0, imageSize.height);
  return Offset(dx, dy);
}

/// [mapDisplayPositionToImagePx]の逆変換。画像ピクセル座標を画面上の表示座標に
/// 変換する(マーカー描画に使う)。
Offset mapImagePxToDisplayPosition({
  required Offset imagePx,
  required Size displaySize,
  required Size imageSize,
}) {
  final layout = _fittedLayout(displaySize, imageSize);
  final scale = layout.renderedSize.width / imageSize.width;
  return layout.topLeft + imagePx * scale;
}
```

- [ ] **Step 4: テストを実行し成功を確認する**

Run: `fvm flutter test test/features/ball_position/tap_position_mapper_test.dart`
Expected: PASS

- [ ] **Step 5: コミット**

```bash
git add lib/features/ball_position/tap_position_mapper.dart test/features/ball_position/tap_position_mapper_test.dart
git commit -m "feat: タップ座標⇔画像ピクセル座標の変換関数を追加"
```

---

## Task 8: BallPositionPickerScreen(タップでボール位置を指定する画面)

**Files:**
- Create: `lib/features/ball_position/ball_position_picker_screen.dart`
- Modify: `lib/features/video_select/video_select_screen.dart:1-6,49-51`

**Interfaces:**
- Consumes: `firstFrameReaderProvider`(Task 6)、`mapDisplayPositionToImagePx`/`mapImagePxToDisplayPosition`(Task 7)、`AnalyzingScreen`(Task 5)
- Produces: `class BallPositionPickerScreen extends ConsumerStatefulWidget { const BallPositionPickerScreen({required XFile video}); }`。Key: `Key('ballPositionImage')`(タップ領域)、`Key('confirmBallPositionButton')`(確定ボタン)

- [ ] **Step 1: 実装する**

```dart
// lib/features/ball_position/ball_position_picker_screen.dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/video/first_frame_reader.dart';
import '../analyzing/analyzing_screen.dart';
import 'tap_position_mapper.dart';

class BallPositionPickerScreen extends ConsumerStatefulWidget {
  const BallPositionPickerScreen({super.key, required this.video});

  final XFile video;

  @override
  ConsumerState<BallPositionPickerScreen> createState() =>
      _BallPositionPickerScreenState();
}

class _BallPositionPickerScreenState
    extends ConsumerState<BallPositionPickerScreen> {
  Offset? _tappedImagePx;

  @override
  Widget build(BuildContext context) {
    final frameAsync = ref.watch(firstFrameReaderProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ボール位置を指定')),
      body: FutureBuilder<Uint8List>(
        future: ref.read(firstFrameReaderProvider).read(widget.video),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('フレームの取得に失敗しました: ${snapshot.error}'));
          }
          final bytes = snapshot.data;
          if (bytes == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _FramePicker(
            bytes: bytes,
            tappedImagePx: _tappedImagePx,
            onTapped: (px) => setState(() => _tappedImagePx = px),
            onConfirm: _tappedImagePx == null
                ? null
                : () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => AnalyzingScreen(
                        video: widget.video,
                        initialBallPositionPx: _tappedImagePx!,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _FramePicker extends StatelessWidget {
  const _FramePicker({
    required this.bytes,
    required this.tappedImagePx,
    required this.onTapped,
    required this.onConfirm,
  });

  final Uint8List bytes;
  final Offset? tappedImagePx;
  final ValueChanged<Offset> onTapped;
  final VoidCallback? onConfirm;

  Future<ui.Image> _decodeImage() async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _decodeImage(),
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final imageSize = Size(
          image.width.toDouble(),
          image.height.toDouble(),
        );

        return Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final displaySize = constraints.biggest;
                  return GestureDetector(
                    key: const Key('ballPositionImage'),
                    onTapDown: (details) => onTapped(
                      mapDisplayPositionToImagePx(
                        localPosition: details.localPosition,
                        displaySize: displaySize,
                        imageSize: imageSize,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(bytes, fit: BoxFit.contain),
                        if (tappedImagePx != null)
                          _Marker(
                            imagePx: tappedImagePx!,
                            displaySize: displaySize,
                            imageSize: imageSize,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                key: const Key('confirmBallPositionButton'),
                onPressed: onConfirm,
                child: const Text('この位置で解析する'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.imagePx,
    required this.displaySize,
    required this.imageSize,
  });

  final Offset imagePx;
  final Size displaySize;
  final Size imageSize;

  @override
  Widget build(BuildContext context) {
    final center = mapImagePxToDisplayPosition(
      imagePx: imagePx,
      displaySize: displaySize,
      imageSize: imageSize,
    );
    return Positioned(
      left: center.dx - 10,
      top: center.dy - 10,
      child: const IgnorePointer(
        child: Icon(Icons.circle, color: Colors.redAccent, size: 20),
      ),
    );
  }
}
```

- [ ] **Step 2: `VideoSelectScreen`の遷移先を変更する**

`lib/features/video_select/video_select_screen.dart`の先頭importに以下を追加する。

```dart
import '../ball_position/ball_position_picker_screen.dart';
```

`_pickVideo()`内の以下の箇所(元の49〜51行目)を書き換える。

```dart
      if (!mounted) return;
      setState(() => _isPicking = false);
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => BallPositionPickerScreen(video: video),
        ),
      );
```

`import '../analyzing/analyzing_screen.dart';`は不要になるため削除する。

- [ ] **Step 3: `dart analyze`でエラーが無いことを確認する**

Run: `fvm dart analyze`
Expected: `No issues found!`(Task 9で`video_analysis_flow_test.dart`を直すまでは、そのファイルにエラーが残っていてよい)

- [ ] **Step 4: コミット**

```bash
git add lib/features/ball_position/ball_position_picker_screen.dart lib/features/video_select/video_select_screen.dart
git commit -m "feat: ボール位置タップ指定画面BallPositionPickerScreenを追加"
```

---

## Task 9: E2Eウィジェットテストの更新、ドキュメント反映、最終確認

**Files:**
- Modify: `test/widget/video_analysis_flow_test.dart`
- Modify: `docs/todo-analysis-pipeline.md`

**Interfaces:**
- Consumes: `FakeFirstFrameReader`(Task 6)、`BallPositionPickerScreen`のKey(`ballPositionImage`/`confirmBallPositionButton`、Task 8)、`FakeShotAnalysisService`(Task 4、`analyze()`が新シグネチャ)

- [ ] **Step 1: `video_analysis_flow_test.dart`を新しい画面遷移に対応させる**

ファイル全体を以下の内容に置き換える。

```dart
// test/widget/video_analysis_flow_test.dart
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:dan_do/data/video/first_frame_reader.dart';
import 'package:dan_do/data/video/image_picker_video_picker.dart';
import 'package:dan_do/data/video/video_player_duration_reader.dart';
import 'package:dan_do/domain/models/shot_result.dart';
import 'package:dan_do/domain/services/ball_trajectory_analysis_service.dart';
import 'package:dan_do/domain/services/shot_analysis_service.dart';
import 'package:dan_do/features/result/result_screen.dart';
import 'package:dan_do/features/video_select/video_select_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../fakes/fake_first_frame_reader.dart';
import '../fakes/fake_shot_analysis_service.dart';
import '../fakes/fake_video_duration_reader.dart';
import '../fakes/fake_video_picker.dart';

class _ThrowingShotAnalysisService implements ShotAnalysisService {
  @override
  Future<ShotResult> analyze(
    XFile video, {
    required Offset initialBallPositionPx,
  }) async {
    throw Exception('解析エラーのテスト用');
  }
}

Future<Uint8List> _makeTestFramePng({int width = 100, int height = 80}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF000000),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

Future<void> _pickVideoAndTapBallPosition(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('pickVideoButton')));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('ballPositionImage')));
  await tester.pump();

  await tester.tap(find.byKey(const Key('confirmBallPositionButton')));
}

void main() {
  testWidgets('動画選択→ボール位置指定→解析中→結果画面まで遷移する', (tester) async {
    final fixtureVideo = XFile('fixture.mp4');
    final frameBytes = await _makeTestFramePng();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoPickerProvider.overrideWith(
            (ref) => FakeVideoPicker(fixtureVideo),
          ),
          videoDurationReaderProvider.overrideWith(
            (ref) => FakeVideoDurationReader(const Duration(seconds: 5)),
          ),
          firstFrameReaderProvider.overrideWith(
            (ref) => FakeFirstFrameReader(frameBytes),
          ),
          shotAnalysisServiceProvider.overrideWith(
            (ref) async => FakeShotAnalysisService(),
          ),
        ],
        child: const MaterialApp(home: VideoSelectScreen()),
      ),
    );

    await _pickVideoAndTapBallPosition(tester);

    // ResultScreen は video_player の初期化完了(または失敗)を待ってから
    // CircularProgressIndicator を消すが、テスト環境にはプラットフォーム
    // 実装がないため初期化 Future は例外を投げずに解決もしない
    // (無限アニメーションが残る)。そのため pumpAndSettle は使わず、
    // 画面遷移が完了するまで有限回だけ pump する。
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(ResultScreen).evaluate().isNotEmpty) break;
    }

    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.byKey(const Key('carryDistanceText')), findsOneWidget);
  });

  testWidgets('動画が長すぎる場合、VideoSelectScreenにエラーメッセージが表示される', (tester) async {
    final fixtureVideo = XFile('fixture.mp4');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoPickerProvider.overrideWith(
            (ref) => FakeVideoPicker(fixtureVideo),
          ),
          videoDurationReaderProvider.overrideWith(
            (ref) => FakeVideoDurationReader(const Duration(minutes: 2)),
          ),
        ],
        child: const MaterialApp(home: VideoSelectScreen()),
      ),
    );

    await tester.tap(find.byKey(const Key('pickVideoButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('videoSelectErrorText')), findsOneWidget);
  });

  testWidgets('解析が失敗した場合、AnalyzingScreenにエラー画面と「別の動画を選ぶ」ボタンが表示される', (
    tester,
  ) async {
    final fixtureVideo = XFile('fixture.mp4');
    final frameBytes = await _makeTestFramePng();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoPickerProvider.overrideWith(
            (ref) => FakeVideoPicker(fixtureVideo),
          ),
          videoDurationReaderProvider.overrideWith(
            (ref) => FakeVideoDurationReader(const Duration(seconds: 5)),
          ),
          firstFrameReaderProvider.overrideWith(
            (ref) => FakeFirstFrameReader(frameBytes),
          ),
          shotAnalysisServiceProvider.overrideWith(
            (ref) async => _ThrowingShotAnalysisService(),
          ),
        ],
        child: const MaterialApp(home: VideoSelectScreen()),
      ),
    );

    await _pickVideoAndTapBallPosition(tester);

    // AnalyzingScreen はエラー確定後もCircularProgressIndicatorの
    // 無限アニメーションが残り得るため、pumpAndSettle は使わず
    // 画面遷移が完了するまで有限回だけ pump する。
    // Riverpodのデフォルトリトライ(Exceptionはerror is Errorに該当せず
    // 対象となる)は最大10回・合計約38.2秒(200ms*2^n、6400ms上限)の
    // 指数バックオフを行うため、確定失敗までの猶予を十分に確保する
    // (fake clockのため実時間としては一瞬で進む)。
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find
          .byKey(const Key('backToVideoSelectButton'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const Key('backToVideoSelectButton')), findsOneWidget);
  });
}
```

- [ ] **Step 2: テストを実行し成功を確認する**

Run: `fvm flutter test test/widget/video_analysis_flow_test.dart`
Expected: PASS(3テストとも成功)

- [ ] **Step 3: プロジェクト全体のテストと静的解析を実行する**

Run: `fvm flutter test && fvm dart analyze`
Expected: 全テストPASS、`No issues found!`

- [ ] **Step 4: `docs/todo-analysis-pipeline.md`に本計画のPhaseを追記する**

`## Phase 4(将来、今回は着手しない)`の直前に、以下のセクションを挿入する。

```markdown
## Phase 3.5: 検出前処理(ROI限定・クロップ推論)

元計画: [implementation-plan-roi-crop-detection.md](implementation-plan-roi-crop-detection.md)
背景: [investigation-analyzing-screen-stuck.md](investigation-analyzing-screen-stuck.md) §6 対策案1

- [ ] `FrameCropper`(`dart:ui`によるフレームクロップ+座標変換)実装+単体テスト
- [ ] `RoiConstants`/`RoiSequencer`(次フレームのROI決定ロジック)実装+単体テスト
- [ ] `BallKalmanTracker`に逐次ステップAPI(`step`/`BallTrackerCursor`)を追加するリファクタ(既存`track()`テストは無改修のまま通す)
- [ ] `ShotAnalysisService`/`BallTrajectoryAnalysisService.analyze()`をROIベースの逐次検出+追跡ループに書き換え(`buildShotResult()`のシグネチャ・既存テストは変更しない)
- [ ] `AnalysisController`/`AnalyzingScreen`に`initialBallPositionPx`を通す
- [ ] `FirstFrameReader`(動画の最初のフレーム取得の抽象化)実装
- [ ] タップ座標⇔画像ピクセル座標の変換関数(`tap_position_mapper.dart`)実装+単体テスト
- [ ] `BallPositionPickerScreen`(タップでボール位置を指定する新規画面)実装、`VideoSelectScreen`からの導線を追加
- [ ] E2Eウィジェットテスト(`video_analysis_flow_test.dart`)を新しい画面遷移(VideoSelect→BallPositionPicker→Analyzing→Result)に更新
- [ ] Phase完了確認: `fvm flutter test`・`fvm dart analyze`が通ることを確認
- [ ] Phase完了確認: 実際のゴルフスイング動画(調査で使用した`IMG_3068.MOV`を含む)で、ROI導入前後の検出成功率・飛距離推定の妥当性を比較し、次フェーズ着手判断のための記録として残す(**実機iPhoneでの確認が必要なため、ユーザー側での実施が必要な項目として残っている**)
```

- [ ] **Step 5: コミット**

```bash
git add test/widget/video_analysis_flow_test.dart docs/todo-analysis-pipeline.md
git commit -m "test: ROIベース検出のE2Eフローに追随させ、TODOにPhase3.5を追記"
```

---

## Self-Review メモ

- **仕様カバレッジ**: 投資調査ドキュメント対策案1の2項目(探索範囲限定=Task 2/4、クロップ推論=Task 1/4)、および会話で確定した初期ROIの決め方(タップ指定=Task 6/7/8)をすべてタスク化した。ロスト時の全体フレームフォールバックはTask 2(`RoiSequencer`)とTask 4(`analyze()`ループ内の`consecutiveLostFrames`カウント)で実装している。
- **後方互換**: `BallKalmanTracker.track()`・`BallTrajectoryAnalysisService.buildShotResult()`のシグネチャと既存テストは無改修のまま残る設計にした(Task 3 Step1、Task 4 Step5で確認する)。
- **型の一貫性**: `BallTrackerCursor`/`BallTrackerStepResult`/`RoiDecision`/`CroppedFrame`のフィールド名・型は、Task 3・Task 2・Task 1で定義したものをTask 4がそのまま参照しており、命名の揺れは無い。
