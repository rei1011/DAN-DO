import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'ball_detector.dart';

part 'ball_detector_provider.g.dart';

@Riverpod(keepAlive: true)
Future<BallDetector> ballDetector(Ref ref) async {
  final detector = BallDetector();
  await detector.loadModel();
  return detector;
}
