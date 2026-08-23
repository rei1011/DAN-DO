import 'package:cross_file/cross_file.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'video_picker.dart';

part 'image_picker_video_picker.g.dart';

class ImagePickerVideoPicker implements VideoPicker {
  ImagePickerVideoPicker() : _picker = ImagePicker();

  final ImagePicker _picker;

  @override
  Future<XFile?> pickVideo() {
    return _picker.pickVideo(source: ImageSource.gallery);
  }
}

@riverpod
VideoPicker videoPicker(Ref ref) => ImagePickerVideoPicker();
