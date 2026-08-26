import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'club_detector.dart';

part 'club_detector_provider.g.dart';

@Riverpod(keepAlive: true)
Future<ClubDetector> clubDetector(Ref ref) async {
  final detector = ClubDetector();
  await detector.loadModel();
  return detector;
}
