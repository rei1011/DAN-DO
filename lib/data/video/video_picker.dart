import 'package:cross_file/cross_file.dart';

abstract class VideoPicker {
  Future<XFile?> pickVideo();
}
