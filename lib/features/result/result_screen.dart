import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../domain/models/shot_result.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.video, required this.result});

  final XFile video;
  final ShotResult result;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  VideoPlayerController? _controller;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.file(File(widget.video.path));
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(title: const Text('結果')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (controller != null && controller.value.isInitialized)
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    controller.value.isPlaying
                        ? controller.pause()
                        : controller.play();
                  });
                },
                child: VideoPlayer(controller),
              ),
            )
          else if (_videoFailed)
            const Text('動画を再生できませんでした', key: Key('videoFailedText'))
          else
            const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 24),
          Text(
            '飛距離: ${widget.result.carryDistanceMeters.toStringAsFixed(1)} m',
            key: const Key('carryDistanceText'),
          ),
          Text(
            '打ち出し角度: ${widget.result.launchAngleDegrees.toStringAsFixed(1)} 度',
            key: const Key('launchAngleText'),
          ),
          Text(
            '打ち出し方向: ${widget.result.launchDirectionDegrees.toStringAsFixed(1)} 度',
            key: const Key('launchDirectionText'),
          ),
        ],
      ),
    );
  }
}
