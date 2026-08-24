import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:dan_do/data/video/first_frame_reader.dart';

class FakeFirstFrameReader implements FirstFrameReader {
  FakeFirstFrameReader(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List> read(XFile video) async => bytes;
}
