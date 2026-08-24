import 'dart:typed_data';

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
    : _yolo = yolo ?? YOLO(modelPath: officialModelId, task: YOLOTask.detect);

  /// 公式モデルID。導入済みultralytics_yolo 0.6.13ではyolo11系の自動ダウンロードが
  /// 未サポート(yolo26系のみ)と判明したため、元計画のyolo11nからyolo26nに変更した。
  static const officialModelId = 'yolo26n';
  static const sportsBallClassName = 'sports ball';

  final YOLO _yolo;

  Future<void> loadModel() async {
    final success = await _yolo.loadModel();
    if (!success) {
      throw ModelLoadException('YOLOモデル($officialModelId)のロードに失敗しました');
    }
  }

  Future<List<RawBallDetection>> detect(
    Uint8List frameBytes, {
    required Duration frameTime,
  }) async {
    final result = await _yolo.predict(frameBytes);
    final rawDetections = result['detections'] as List<dynamic>? ?? const [];

    return rawDetections
        .map((raw) => YOLOResult.fromMap(raw as Map))
        .where((r) => r.className == sportsBallClassName)
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
