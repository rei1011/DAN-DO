import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import '../../domain/models/raw_ball_detection.dart';

class ModelLoadException implements Exception {
  const ModelLoadException(this.message);

  final String message;

  @override
  String toString() => 'ModelLoadException: $message';
}

class BallDetector {
  BallDetector({YOLO? yolo})
    : _yolo = yolo ?? YOLO(modelPath: customModelPath, task: YOLOTask.detect);

  /// golf-ball-detection-r3lqj(Roboflow Universe、CC BY 4.0)のデータセットで
  /// yolo26nをファインチューニングしたカスタムモデル(詳細: docs/model-provenance.md)。
  /// iOS向けにmlpackageをZIP化したFlutter asset形式で読み込む。
  static const customModelPath = 'assets/models/best.mlpackage.zip';
  static const golfBallClassName = 'Golf-ball';

  final YOLO _yolo;

  Future<void> loadModel() async {
    final success = await _yolo.loadModel();
    if (!success) {
      throw ModelLoadException('YOLOモデル($customModelPath)のロードに失敗しました');
    }
  }

  Future<List<RawBallDetection>> detect(
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
        .where((r) => r.className == golfBallClassName)
        .map(
          (r) => RawBallDetection(
            frameTimeMs: frameTime.inMilliseconds,
            centerPx: r.boundingBox.center,
            diameterPx: (r.boundingBox.width + r.boundingBox.height) / 2,
            confidence: r.confidence,
          ),
        )
        .toList();
  }
}
