import 'package:cross_file/cross_file.dart';
import 'package:dan_do/data/video/video_picker.dart';

class FakeVideoPicker implements VideoPicker {
  FakeVideoPicker(this.result);

  final XFile? result;

  @override
  Future<XFile?> pickVideo() async => result;
}
