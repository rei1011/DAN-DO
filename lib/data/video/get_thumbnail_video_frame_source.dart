import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';

import 'video_frame_source.dart';

class GetThumbnailVideoFrameSource implements VideoFrameSource {
  GetThumbnailVideoFrameSource(this.video);

  final XFile video;

  @override
  Future<Uint8List> frameAt(Duration t) {
    return VideoThumbnail.thumbnailData(
      video: video.path,
      imageFormat: ImageFormat.JPEG,
      timeMs: t.inMilliseconds,
      quality: 90,
    );
  }
}
