// test/domain/services/club_swing_analysis_service_analyze_test.dart
//
// ClubSwingAnalysisService.analyze()(Phase1〜3の要素を結線するオーケストレーション)
// を対象にした結線テスト。ball_trajectory_analysis_service_analyze_test.dartと
// 同様、BallDetector/ClubDetectorは具象クラス(YOLOをラップ)でインターフェースが
// 無いため、detect()をオーバーライドするサブクラスとしてフェイクを用意する。
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:dan_do/core/club_constants.dart';
import 'package:dan_do/data/ml/ball_detector.dart';
import 'package:dan_do/data/ml/club_detector.dart';
import 'package:dan_do/data/video/video_frame_source.dart';
import 'package:dan_do/domain/models/raw_ball_detection.dart';
import 'package:dan_do/domain/models/raw_club_detection.dart';
import 'package:dan_do/domain/services/club_swing_analysis_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../../fakes/fake_video_duration_reader.dart';

typedef BallDetectScript =
    List<RawBallDetection> Function({
      required int callIndex,
      required Duration frameTime,
      required int imageWidth,
      required int imageHeight,
    });

typedef ClubDetectScript =
    List<RawClubDetection> Function({
      required int callIndex,
      required Duration frameTime,
    });

class FakeBallDetector extends BallDetector {
  FakeBallDetector(this._script)
    : super(
        yolo: YOLO(
          modelPath: 'fake-ball-model-for-test',
          task: YOLOTask.detect,
        ),
      );

  final BallDetectScript _script;
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

class FakeClubDetector extends ClubDetector {
  FakeClubDetector(this._script)
    : super(
        yolo: YOLO(
          modelPath: 'fake-club-model-for-test',
          task: YOLOTask.detect,
        ),
      );

  final ClubDetectScript _script;
  int callCount = 0;

  @override
  Future<List<RawClubDetection>> detect(
    Uint8List frameBytes, {
    required Duration frameTime,
  }) async {
    final result = _script(callIndex: callCount, frameTime: frameTime);
    callCount++;
    return result;
  }
}

/// 常に同じフル解像度画像(単色)を返すフェイクのフレームソース。
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
  const frameWidth = 2000;
  const frameHeight = 2000;
  const initialBallPositionPx = ui.Offset(1000, 1000);
  const frameInterval = Duration(milliseconds: 33);

  late Uint8List fullFrameBytes;

  setUpAll(() async {
    fullFrameBytes = await _makeSolidFramePng(frameWidth, frameHeight);
  });

  ClubSwingAnalysisService buildService({
    required BallDetectScript ballScript,
    required ClubDetectScript clubScript,
    required Duration duration,
  }) {
    return ClubSwingAnalysisService(
      ballDetector: FakeBallDetector(ballScript),
      clubDetector: FakeClubDetector(clubScript),
      videoDurationReader: FakeVideoDurationReader(duration),
      frameSourceFactory: (video) => FakeVideoFrameSource(fullFrameBytes),
    );
  }

  test('アドレス検出→クラブ追跡→インパクト特定→打ち出し検出の一連の結線で'
      '妥当なShotResultが得られる', () async {
    // クラブヘッドは、アドレス位置(フル座標系のinitialBallPositionPx)から
    // バックスイングで離れ(idx2でピーク)、ダウンスイングでアドレス位置付近
    // (idx4)に最接近した後、フォロースルーで再び離れる。
    // ハンドルはヘッドから可変オフセットで検出し、head-handle間距離(見かけの
    // シャフト長)がフレームごとに変化することで奥行き推定に必要な
    // Z方向の変化を作る。
    const headPositions = [
      ui.Offset(1000, 1000), // idx0: アドレス
      ui.Offset(900, 850), // idx1: バックスイング
      ui.Offset(700, 700), // idx2: バックスイングのピーク
      ui.Offset(850, 900), // idx3: ダウンスイング
      ui.Offset(1005, 1000), // idx4: インパクト(アドレス位置に最接近)
      ui.Offset(1150, 1100), // idx5: フォロースルー
      ui.Offset(1300, 1200), // idx6: フォロースルー継続
    ];
    const handleOffsets = [
      ui.Offset(0, 150),
      ui.Offset(10, 140),
      ui.Offset(-20, 160),
      ui.Offset(15, 130),
      ui.Offset(5, 120),
    ];
    const clubFrameCount = 7;
    const postImpactBallFrameCount = 3;
    final duration =
        frameInterval * (clubFrameCount + postImpactBallFrameCount + 2);

    List<RawClubDetection> clubScript({
      required int callIndex,
      required Duration frameTime,
    }) {
      if (callIndex >= headPositions.length) {
        return const [];
      }
      final head = headPositions[callIndex];
      final detections = [
        RawClubDetection(
          frameTimeMs: frameTime.inMilliseconds,
          centerPx: head,
          confidence: 0.9,
          part: ClubPart.head,
        ),
      ];
      if (callIndex < handleOffsets.length) {
        detections.add(
          RawClubDetection(
            frameTimeMs: frameTime.inMilliseconds,
            centerPx: head + handleOffsets[callIndex],
            confidence: 0.9,
            part: ClubPart.handle,
          ),
        );
      }
      return detections;
    }

    List<RawBallDetection> ballScript({
      required int callIndex,
      required Duration frameTime,
      required int imageWidth,
      required int imageHeight,
    }) {
      if (callIndex == 0) {
        // アドレス検出: クロップ中心=タップ位置。
        return [
          RawBallDetection(
            frameTimeMs: frameTime.inMilliseconds,
            centerPx: ui.Offset(imageWidth / 2, imageHeight / 2),
            diameterPx: 20,
            confidence: 0.9,
          ),
        ];
      }
      // インパクト直後: ボールが徐々に離れていく方向に検出位置をずらす。
      final k = callIndex - 1;
      return [
        RawBallDetection(
          frameTimeMs: frameTime.inMilliseconds,
          centerPx: ui.Offset(
            imageWidth / 2 + k * 12,
            imageHeight / 2 - k * 30,
          ),
          diameterPx: 18 - k * 0.5,
          confidence: 0.9,
        ),
      ];
    }

    final service = buildService(
      ballScript: ballScript,
      clubScript: clubScript,
      duration: duration,
    );

    final result = await service.analyze(
      XFile('fixture.mp4'),
      initialBallPositionPx: initialBallPositionPx,
      clubType: ClubType.driver,
    );

    expect(result.carryDistanceMeters, greaterThan(0));
    expect(result.launchAngleDegrees, isNotNull);
    expect(result.measuredTrajectory, isNotEmpty);
    expect(result.measuredTrajectory.every((p) => p.isMeasured), isTrue);
    expect(result.simulatedTrajectory, isNotEmpty);
  });

  test('クラブヘッドが1件も検出できない場合はClubSwingAnalysisExceptionを投げる', () async {
    List<RawBallDetection> ballScript({
      required int callIndex,
      required Duration frameTime,
      required int imageWidth,
      required int imageHeight,
    }) {
      return [
        RawBallDetection(
          frameTimeMs: frameTime.inMilliseconds,
          centerPx: ui.Offset(imageWidth / 2, imageHeight / 2),
          diameterPx: 20,
          confidence: 0.9,
        ),
      ];
    }

    List<RawClubDetection> clubScript({
      required int callIndex,
      required Duration frameTime,
    }) => const [];

    final service = buildService(
      ballScript: ballScript,
      clubScript: clubScript,
      duration: frameInterval * 10,
    );

    await expectLater(
      service.analyze(
        XFile('fixture.mp4'),
        initialBallPositionPx: initialBallPositionPx,
        clubType: ClubType.driver,
      ),
      throwsA(isA<ClubSwingAnalysisException>()),
    );
  });

  test('アドレス時にボールを検出できない場合はClubSwingAnalysisExceptionを投げる', () async {
    List<RawBallDetection> ballScript({
      required int callIndex,
      required Duration frameTime,
      required int imageWidth,
      required int imageHeight,
    }) => const [];

    List<RawClubDetection> clubScript({
      required int callIndex,
      required Duration frameTime,
    }) => const [];

    final service = buildService(
      ballScript: ballScript,
      clubScript: clubScript,
      duration: frameInterval * 10,
    );

    await expectLater(
      service.analyze(
        XFile('fixture.mp4'),
        initialBallPositionPx: initialBallPositionPx,
        clubType: ClubType.driver,
      ),
      throwsA(isA<ClubSwingAnalysisException>()),
    );
  });

  test('インパクト直後のボール検出が1点以下の場合はClubSwingAnalysisExceptionを投げる', () async {
    const headPositions = [
      ui.Offset(1000, 1000),
      ui.Offset(900, 850),
      ui.Offset(700, 700),
      ui.Offset(850, 900),
      ui.Offset(1005, 1000),
    ];
    const handleOffsets = [
      ui.Offset(0, 150),
      ui.Offset(10, 140),
      ui.Offset(-20, 160),
      ui.Offset(15, 130),
      ui.Offset(5, 120),
    ];

    List<RawClubDetection> clubScript({
      required int callIndex,
      required Duration frameTime,
    }) {
      if (callIndex >= headPositions.length) {
        return const [];
      }
      final head = headPositions[callIndex];
      return [
        RawClubDetection(
          frameTimeMs: frameTime.inMilliseconds,
          centerPx: head,
          confidence: 0.9,
          part: ClubPart.head,
        ),
        RawClubDetection(
          frameTimeMs: frameTime.inMilliseconds,
          centerPx: head + handleOffsets[callIndex],
          confidence: 0.9,
          part: ClubPart.handle,
        ),
      ];
    }

    List<RawBallDetection> ballScript({
      required int callIndex,
      required Duration frameTime,
      required int imageWidth,
      required int imageHeight,
    }) {
      if (callIndex == 0) {
        return [
          RawBallDetection(
            frameTimeMs: frameTime.inMilliseconds,
            centerPx: ui.Offset(imageWidth / 2, imageHeight / 2),
            diameterPx: 20,
            confidence: 0.9,
          ),
        ];
      }
      // インパクト直後は検出0件(ロストしたケースを想定)。
      return const [];
    }

    final service = buildService(
      ballScript: ballScript,
      clubScript: clubScript,
      duration: frameInterval * 15,
    );

    await expectLater(
      service.analyze(
        XFile('fixture.mp4'),
        initialBallPositionPx: initialBallPositionPx,
        clubType: ClubType.driver,
      ),
      throwsA(isA<ClubSwingAnalysisException>()),
    );
  });
}
