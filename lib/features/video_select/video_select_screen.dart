import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/video/image_picker_video_picker.dart';
import '../../data/video/video_player_duration_reader.dart';
import '../analyzing/analyzing_screen.dart';

class VideoSelectScreen extends ConsumerStatefulWidget {
  const VideoSelectScreen({super.key});

  @override
  ConsumerState<VideoSelectScreen> createState() => _VideoSelectScreenState();
}

class _VideoSelectScreenState extends ConsumerState<VideoSelectScreen> {
  static const maxDuration = Duration(minutes: 1);

  String? _errorMessage;
  bool _isPicking = false;

  Future<void> _pickVideo() async {
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });

    try {
      final picker = ref.read(videoPickerProvider);
      final video = await picker.pickVideo();
      if (!mounted) return;
      if (video == null) {
        setState(() => _isPicking = false);
        return;
      }

      final durationReader = ref.read(videoDurationReaderProvider);
      final duration = await durationReader.read(video);
      if (!mounted) return;
      if (duration > maxDuration) {
        setState(() {
          _isPicking = false;
          _errorMessage = '動画が長すぎます(1分以内の動画を選んでください)';
        });
        return;
      }

      if (!mounted) return;
      setState(() => _isPicking = false);
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => AnalyzingScreen(video: video)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPicking = false;
        _errorMessage = '動画の選択に失敗しました: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('動画選択')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              key: const Key('pickVideoButton'),
              onPressed: _isPicking ? null : _pickVideo,
              child: const Text('動画を選ぶ'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, key: const Key('videoSelectErrorText')),
            ],
          ],
        ),
      ),
    );
  }
}
