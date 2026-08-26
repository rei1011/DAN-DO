// test/domain/services/ball_trajectory_analysis_service_analyze_test.dart
//
// BallTrajectoryAnalysisService.analyze()自体(ROIループの結線)を対象にした
// 回帰テスト。既存のball_trajectory_analysis_service_test.dartは
// buildShotResult()(純粋関数)のみを対象にしており、analyze()のループ自体は
// これまでテストされていなかった(最終レビューFinding4)。
//
// BallDetectorは具象クラス(YOLOをラップ)でインターフェースが無いため、
// detect()をオーバーライドするサブクラスとしてFakeBallDetectorを用意する。
// YOLOのコンストラクタ自体はプラットフォームチャネルを叩かないため、
// テスト用のダミーmodelPathで安全にインスタンス化できる。
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:dan_do/core/club_constants.dart';
import 'package:dan_do/core/roi_constants.dart';
import 'package:dan_do/core/tracking_constants.dart';
import 'package:dan_do/data/ml/ball_detector.dart';
import 'package:dan_do/data/video/video_frame_source.dart';
import 'package:dan_do/domain/models/raw_ball_detection.dart';
import 'package:dan_do/domain/services/ball_trajectory_analysis_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../../fakes/fake_video_duration_reader.dart';

/// [FakeBallDetector]に渡すスクリプト関数の型。
/// [callIndex]は0始まりの呼び出し回数、[imageWidth]/[imageHeight]は
/// 実際にdetect()へ渡された画像(クロップ後 or フル解像度)のデコード後サイズ。
typedef DetectScript =
    List<RawBallDetection> Function({
      required int callIndex,
      required Duration frameTime,
      required int imageWidth,
      required int imageHeight,
    });

/// [BallDetector]は具象クラスのため、detect()をオーバーライドして
/// YOLO推論を経由せずスクリプトされた検出結果を返すフェイク。
class FakeBallDetector extends BallDetector {
  FakeBallDetector(this._script)
    : super(
        yolo: YOLO(modelPath: 'fake-model-for-test', task: YOLOTask.detect),
      );

  final DetectScript _script;

  /// 呼び出しごとにdetect()へ渡された画像の幅(px)。
  /// フルフレームかクロップかを判別するために使う。
  final List<int> callWidths = [];

  int _callCount = 0;

  @override
  Future<List<RawBallDetection>> detect(
    Uint8List frameBytes, {
    required Duration frameTime,
  }) async {
    final codec = await ui.instantiateImageCodec(frameBytes);
    final frame = await codec.getNextFrame();
    final width = frame.image.width;
    final height = frame.image.height;
    frame.image.dispose();
    codec.dispose();

    callWidths.add(width);
    final result = _script(
      callIndex: _callCount,
      frameTime: frameTime,
      imageWidth: width,
      imageHeight: height,
    );
    _callCount++;
    return result;
  }
}

/// 常に同じフル解像度画像(単色)を返すフェイクのフレームソース。
/// 実際の画素内容はスクリプトされた検出結果に影響しないため、
/// デコード可能なPNGでありさえすればよい。
class FakeVideoFrameSource implements VideoFrameSource {
  FakeVideoFrameSource(this._bytes);

  final Uint8List _bytes;
  final List<Duration> requestedTimes = [];

  @override
  Future<Uint8List> frameAt(Duration t) async {
    requestedTimes.add(t);
    return _bytes;
  }
}

Future<Uint8List> _makeSolidFramePng(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF222222),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return byteData!.buffer.asUint8List();
}

void main() {
  // フル解像度フレームのサイズ。タップ位置(1000,1000)を中心に置いても
  // クロップ(最大240px)や追跡ドリフトでフレーム端のクランプが発生しない
  // 十分な大きさにしている。
  const frameWidth = 2000;
  const frameHeight = 2000;
  const initialBallPositionPx = Offset(1000, 1000);

  late Uint8List fullFrameBytes;

  setUpAll(() async {
    fullFrameBytes = await _makeSolidFramePng(frameWidth, frameHeight);
  });

  BallTrajectoryAnalysisService buildService({
    required DetectScript script,
    required Duration duration,
  }) {
    final detector = FakeBallDetector(script);
    return BallTrajectoryAnalysisService(
      ballDetector: detector,
      videoDurationReader: FakeVideoDurationReader(duration),
      frameSourceFactory: (video) => FakeVideoFrameSource(fullFrameBytes),
    );
  }

  group('BallTrajectoryAnalysisService.analyze (ROIループの結線)', () {
    test('フルフレームではなくタップ位置中心のクロップが使われ、'
        'オフセット変換を経て妥当なShotResultが得られる(初期クロップ→追跡クロップの遷移)', () async {
      // クロップは常に「直前のトラッカー位置」を中心に再設定されるため、
      // クロップ中心からの相対オフセット(K)を固定で返し続ければ、
      // クロップの絶対座標を再現しなくても一貫した並進運動を作れる。
      //
      // BallKalmanTracker.stepの残差は residual_n = K - V_{n-1}*dt
      // (V=速度)、速度更新は V_n = 0.7*V_{n-1} + (beta/dt)*K という
      // 一次線形漸化式になるため、Kを一定値に固定すると速度は
      // V_ss = (beta/dt)/(1-0.7) * K = (beta/(dt*0.3)) * K
      // (=1/dt * K, beta=0.3のため) に単調収束する。launch閾値
      // (800px/s)を確実に超えるよう、定常速度が十分大きくなるKを選ぶ。
      const kDx = 15.0;
      const kDy = -40.0;
      const totalCalls = 9; // idx0(address確立) + idx1..8(追跡)

      List<RawBallDetection> script({
        required int callIndex,
        required Duration frameTime,
        required int imageWidth,
        required int imageHeight,
      }) {
        final localCenter = Offset(
          imageWidth / 2 + (callIndex == 0 ? 0 : kDx),
          imageHeight / 2 + (callIndex == 0 ? 0 : kDy),
        );
        return [
          RawBallDetection(
            frameTimeMs: frameTime.inMilliseconds,
            centerPx: localCenter,
            diameterPx: 20,
            confidence: 0.9,
          ),
        ];
      }

      final duration = BallTrajectoryAnalysisService.frameInterval * totalCalls;
      final service = buildService(script: script, duration: duration);
      final detector = service.ballDetector as FakeBallDetector;

      final result = await service.analyze(
        XFile('fixture.mp4'),
        initialBallPositionPx: initialBallPositionPx,
        clubType: ClubType.driver,
      );

      // 呼び出し回数: 最初はinitialCropSizePx(240)、
      // トラッカー確立後はtrackingCropSizePx(160)。
      // フルフレーム(2000px)は一度も使われていないことを確認する。
      expect(detector.callWidths, hasLength(totalCalls));
      expect(detector.callWidths.first, RoiConstants.initialCropSizePx.round());
      expect(
        detector.callWidths.skip(1),
        everyElement(RoiConstants.trackingCropSizePx.round()),
      );
      expect(detector.callWidths, isNot(contains(frameWidth)));

      // オフセット変換(FrameCropper.translateDetection)が正しく機能して
      // いなければ、ゲーティング半径を外れて追跡がlostし続け、
      // 十分なlaunch区間の観測が得られずInsufficientTrajectoryDataExceptionに
      // なるはずである。ここで妥当なShotResultが返ることが、
      // クロップ→座標変換の結線が正しいことの間接的な証拠となる。
      expect(result.carryDistanceMeters, greaterThan(0));
      expect(result.launchAngleDegrees, greaterThan(0));
      expect(result.launchAngleDegrees, lessThan(90));
      expect(result.measuredTrajectory, isNotEmpty);
      expect(result.measuredTrajectory.every((p) => p.isMeasured), isTrue);
      expect(result.simulatedTrajectory, isNotEmpty);
    });

    test('5フレーム連続でロストするとフルフレーム探索にフォールバックし、'
        '再検出後はクロップ探索に復帰する', () async {
      // idx0: アドレス確立(クロップ240)
      // idx1-5: 検出なし(ロスト5回連続、クロップ160)
      // idx6: consecutiveLostFrames==maxLostFramesBeforeFullFrameFallbackに
      //       達し、フルフレーム探索にフォールバック。同じ地点で再検出。
      // idx7: ロストがリセットされ、クロップ探索(160)に戻る。
      const totalCalls = 8;
      assert(
        RoiConstants.maxLostFramesBeforeFullFrameFallback == 5,
        'このテストはmaxLostFramesBeforeFullFrameFallback=5を前提にしている',
      );

      List<RawBallDetection> script({
        required int callIndex,
        required Duration frameTime,
        required int imageWidth,
        required int imageHeight,
      }) {
        if (callIndex == 0) {
          // アドレス確立: クロップ中心=タップ位置。
          return [
            RawBallDetection(
              frameTimeMs: frameTime.inMilliseconds,
              centerPx: Offset(imageWidth / 2, imageHeight / 2),
              diameterPx: 20,
              confidence: 0.9,
            ),
          ];
        }
        if (callIndex >= 1 && callIndex <= 5) {
          // ロスト: 検出候補なし。
          return const [];
        }
        if (callIndex == 6) {
          // フルフレーム探索での再検出。フルフレームパスは
          // translateDetectionを経由しないため、座標はそのままフル
          // フレーム座標系(タップ位置と同じ場所)を返す。
          return [
            RawBallDetection(
              frameTimeMs: frameTime.inMilliseconds,
              centerPx: initialBallPositionPx,
              diameterPx: 20,
              confidence: 0.9,
            ),
          ];
        }
        // idx7以降: クロップに戻っているはずなので、再びクロップ中心を返す。
        return [
          RawBallDetection(
            frameTimeMs: frameTime.inMilliseconds,
            centerPx: Offset(imageWidth / 2, imageHeight / 2),
            diameterPx: 20,
            confidence: 0.9,
          ),
        ];
      }

      final duration = BallTrajectoryAnalysisService.frameInterval * totalCalls;
      final service = buildService(script: script, duration: duration);
      final detector = service.ballDetector as FakeBallDetector;

      // 静止シナリオのため打球区間が無く、飛球区間不足の例外は許容する
      // (このテストの目的はフォールバック挙動自体の検証であり、
      // ShotResultの成否ではない)。
      try {
        await service.analyze(
          XFile('fixture.mp4'),
          initialBallPositionPx: initialBallPositionPx,
          clubType: ClubType.driver,
        );
      } on InsufficientTrajectoryDataException {
        // 想定内: 静止シナリオでは飛球区間が発生しない。
      }

      expect(detector.callWidths, hasLength(totalCalls));
      expect(detector.callWidths[0], RoiConstants.initialCropSizePx.round());
      for (var i = 1; i <= 5; i++) {
        expect(
          detector.callWidths[i],
          RoiConstants.trackingCropSizePx.round(),
          reason: 'callWidths[$i]はロスト中のクロップ探索(160px)のはず',
        );
      }
      expect(
        detector.callWidths[6],
        frameWidth,
        reason: '5回ロストした直後の呼び出しはフルフレーム探索(2000px)にフォールバックするはず',
      );
      expect(
        detector.callWidths[7],
        RoiConstants.trackingCropSizePx.round(),
        reason: '再検出後はクロップ探索(160px)に復帰するはず',
      );
    });

    test('信頼度がconfidenceThreshold未満の検出のみでroiCursorがnullのフレームは'
        'ArgumentErrorを投げずスキップされ、後続フレームで正常に追跡が続く', () async {
      // idx0: 信頼度0.1(<confidenceThreshold=0.3)のみ。roiCursorがnullの
      //       ままtracker.step()を呼ぶと、修正前はArgumentErrorで
      //       クラッシュしていた(Finding1)。
      // idx1: 信頼度0.9でアドレス確立。cropSizePxはまだ更新されていない
      //       (idx0はcontinueでスキップされているため)ので、idx1も
      //       initialCropSizePx(240)のまま。
      // idx2以降: 一定オフセットで追跡を継続し、launch区間を作る
      // (定常速度への収束についてはテスト1のコメントを参照)。
      expect(0.1, lessThan(TrackingConstants.confidenceThreshold));

      const kDx = 15.0;
      const kDy = -40.0;
      const totalCalls = 10;

      List<RawBallDetection> script({
        required int callIndex,
        required Duration frameTime,
        required int imageWidth,
        required int imageHeight,
      }) {
        if (callIndex == 0) {
          return [
            RawBallDetection(
              frameTimeMs: frameTime.inMilliseconds,
              centerPx: Offset(imageWidth / 2, imageHeight / 2),
              diameterPx: 20,
              confidence: 0.1,
            ),
          ];
        }
        final isEstablishingFrame = callIndex == 1;
        final localCenter = Offset(
          imageWidth / 2 + (isEstablishingFrame ? 0 : kDx),
          imageHeight / 2 + (isEstablishingFrame ? 0 : kDy),
        );
        return [
          RawBallDetection(
            frameTimeMs: frameTime.inMilliseconds,
            centerPx: localCenter,
            diameterPx: 20,
            confidence: 0.9,
          ),
        ];
      }

      final duration = BallTrajectoryAnalysisService.frameInterval * totalCalls;
      final service = buildService(script: script, duration: duration);
      final detector = service.ballDetector as FakeBallDetector;

      // ArgumentErrorは元より、いかなる例外も投げずに完走することを
      // 確認する(Finding1の再現シナリオ)。
      final result = await service.analyze(
        XFile('fixture.mp4'),
        initialBallPositionPx: initialBallPositionPx,
        clubType: ClubType.driver,
      );

      expect(detector.callWidths, hasLength(totalCalls));
      // idx0, idx1はどちらもinitialCropSizePx(240)のまま
      // (idx0がcontinueでcropSizePxの更新をスキップするため)。
      expect(
        detector.callWidths.take(2),
        everyElement(RoiConstants.initialCropSizePx.round()),
      );
      expect(
        detector.callWidths.skip(2),
        everyElement(RoiConstants.trackingCropSizePx.round()),
      );

      expect(result.carryDistanceMeters, greaterThan(0));
      expect(result.launchAngleDegrees, greaterThan(0));
      expect(result.launchAngleDegrees, lessThan(90));
      expect(result.measuredTrajectory, isNotEmpty);
    });

    test('roiCursorがnullのまま確信度不足の検出が5フレーム連続しても'
        'フルフレーム探索にフォールバックし、再検出後はクロップ探索に復帰する', () async {
      // idx0-4: 初期クロップ(240px)内で確信度不足(0.1)の検出のみが続き、
      //         roiCursorはnullのまま(トラッキング未確立)。
      //         修正前はこの分岐でconsecutiveLostFramesが更新されず、
      //         フォールバックが永久に発生しなかった
      //         (docs/todo-analysis-pipeline.mdのフォローアップ課題)。
      // idx5: 修正後はconsecutiveLostFrames==5に達し、フルフレーム探索
      //       (2000px)にフォールバックするはず。検出はフルフレームで
      //       呼ばれた場合にのみ返すようスクリプトし、
      //       フォールバックが実際に発生したことを直接検証する。
      // idx6: アドレス確立後なので、クロップ探索(160px)に復帰するはず。
      assert(
        RoiConstants.maxLostFramesBeforeFullFrameFallback == 5,
        'このテストはmaxLostFramesBeforeFullFrameFallback=5を前提にしている',
      );
      const totalCalls = 7;

      List<RawBallDetection> script({
        required int callIndex,
        required Duration frameTime,
        required int imageWidth,
        required int imageHeight,
      }) {
        if (callIndex <= 4) {
          return [
            RawBallDetection(
              frameTimeMs: frameTime.inMilliseconds,
              centerPx: Offset(imageWidth / 2, imageHeight / 2),
              diameterPx: 20,
              confidence: 0.1,
            ),
          ];
        }
        if (callIndex == 5) {
          if (imageWidth != frameWidth) {
            // まだフルフレーム探索にフォールバックしていなければ検出無し。
            return const [];
          }
          return [
            RawBallDetection(
              frameTimeMs: frameTime.inMilliseconds,
              centerPx: initialBallPositionPx,
              diameterPx: 20,
              confidence: 0.9,
            ),
          ];
        }
        return [
          RawBallDetection(
            frameTimeMs: frameTime.inMilliseconds,
            centerPx: Offset(imageWidth / 2, imageHeight / 2),
            diameterPx: 20,
            confidence: 0.9,
          ),
        ];
      }

      final duration = BallTrajectoryAnalysisService.frameInterval * totalCalls;
      final service = buildService(script: script, duration: duration);
      final detector = service.ballDetector as FakeBallDetector;

      // 静止シナリオのため打球区間が無く、飛球区間不足の例外は許容する
      // (このテストの目的はフォールバック挙動自体の検証であり、
      // ShotResultの成否ではない)。
      try {
        await service.analyze(
          XFile('fixture.mp4'),
          initialBallPositionPx: initialBallPositionPx,
          clubType: ClubType.driver,
        );
      } on InsufficientTrajectoryDataException {
        // 想定内: 静止シナリオでは飛球区間が発生しない。
      }

      expect(detector.callWidths, hasLength(totalCalls));
      for (var i = 0; i <= 4; i++) {
        expect(
          detector.callWidths[i],
          RoiConstants.initialCropSizePx.round(),
          reason: 'callWidths[$i]はroiCursor未確立のクロップ探索(240px)のはず',
        );
      }
      expect(
        detector.callWidths[5],
        frameWidth,
        reason:
            'roiCursorがnullのまま5回連続で確信度不足だった直後の呼び出しは'
            'フルフレーム探索(2000px)にフォールバックするはず',
      );
      expect(
        detector.callWidths[6],
        RoiConstants.trackingCropSizePx.round(),
        reason: '再検出後はクロップ探索(160px)に復帰するはず',
      );
    });
  });
}
