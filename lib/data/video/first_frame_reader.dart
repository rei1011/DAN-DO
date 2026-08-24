import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'get_thumbnail_video_frame_source.dart';
import 'video_frame_source.dart';

part 'first_frame_reader.g.dart';

abstract class FirstFrameReader {
  Future<Uint8List> read(XFile video);
}

class VideoFrameSourceFirstFrameReader implements FirstFrameReader {
  const VideoFrameSourceFirstFrameReader(this.frameSourceFactory);

  final VideoFrameSource Function(XFile video) frameSourceFactory;

  @override
  Future<Uint8List> read(XFile video) {
    return frameSourceFactory(video).frameAt(Duration.zero);
  }
}

@riverpod
FirstFrameReader firstFrameReader(Ref ref) =>
    const VideoFrameSourceFirstFrameReader(GetThumbnailVideoFrameSource.new);
