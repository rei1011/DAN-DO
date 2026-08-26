import 'package:flutter/foundation.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../../domain/models/raw_club_detection.dart';
import 'ball_detector.dart';

class ClubDetector {
  ClubDetector({YOLO? yolo})
    : _yolo = yolo ?? YOLO(modelPath: customModelPath, task: YOLOTask.detect);

  /// Golf Driver Tracker(Roboflow Universe、CC BY 4.0)のデータセットで
  /// yolo26nをファインチューニングしたカスタムモデル(詳細: docs/model-provenance.md)。
  /// iOS向けにmlpackageをZIP化したFlutter asset形式で読み込む。
  static const customModelPath = 'assets/models/best_club.mlpackage.zip';
  static const clubHeadClassName = 'golf club-head';
  static const clubHandleClassName = 'golf club-handle';

  final YOLO _yolo;

  Future<void> loadModel() async {
    final success = await _yolo.loadModel();
    if (!success) {
      throw ModelLoadException('YOLOモデル($customModelPath)のロードに失敗しました');
    }
  }

  Future<List<RawClubDetection>> detect(
    Uint8List frameBytes, {
    required Duration frameTime,
  }) async {
    final result = await _yolo.predict(frameBytes);
    final rawDetections = result['detections'] as List<dynamic>? ?? const [];
    final parsed = rawDetections
        .map((raw) => YOLOResult.fromMap(raw as Map))
        .toList();
    debugPrint(
      '[diag-raw] resultKeys=${result.keys.toList()} rawCount=${rawDetections.length} '
      '${parsed.map((r) => "(class=\"${r.className}\",conf=${r.confidence.toStringAsFixed(2)})").join(" ")}',
    );

    return parsed
        .map((r) => (r, _classNameToPart(r.className)))
        .where((entry) => entry.$2 != null)
        .map(
          (entry) => RawClubDetection(
            frameTimeMs: frameTime.inMilliseconds,
            centerPx: entry.$1.boundingBox.center,
            confidence: entry.$1.confidence,
            part: entry.$2!,
          ),
        )
        .toList();
  }

  ClubPart? _classNameToPart(String className) {
    switch (className) {
      case clubHeadClassName:
        return ClubPart.head;
      case clubHandleClassName:
        return ClubPart.handle;
      default:
        return null;
    }
  }
}
