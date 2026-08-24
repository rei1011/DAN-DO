import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

import 'video_duration_reader.dart';

part 'video_player_duration_reader.g.dart';

class VideoPlayerDurationReader implements VideoDurationReader {
  const VideoPlayerDurationReader();

  @override
  Future<Duration> read(XFile video) async {
    final controller = VideoPlayerController.file(File(video.path));
    try {
      await controller.initialize();
      return controller.value.duration;
    } finally {
      await controller.dispose();
    }
  }
}

@riverpod
VideoDurationReader videoDurationReader(Ref ref) =>
    const VideoPlayerDurationReader();
