import 'dart:typed_data';

abstract class VideoFrameSource {
  Future<Uint8List> frameAt(Duration t);
}
