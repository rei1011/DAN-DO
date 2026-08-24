import 'package:cross_file/cross_file.dart';

abstract class VideoDurationReader {
  Future<Duration> read(XFile video);
}
