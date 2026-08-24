import 'package:cross_file/cross_file.dart';
import 'package:dan_do/data/video/video_duration_reader.dart';

class FakeVideoDurationReader implements VideoDurationReader {
  FakeVideoDurationReader(this.duration);

  final Duration duration;

  @override
  Future<Duration> read(XFile video) async => duration;
}
