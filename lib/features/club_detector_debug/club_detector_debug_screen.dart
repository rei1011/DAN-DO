import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/ml/club_detector_provider.dart';
import '../../data/video/get_thumbnail_video_frame_source.dart';
import '../../data/video/image_picker_video_picker.dart';
import '../../data/video/video_player_duration_reader.dart';
import '../../domain/models/raw_club_detection.dart';

/// Phase 2(design-club-swing-analysis.md)の実機検証専用の使い捨てデバッグ画面。
/// ClubSwingAnalysisService(Phase 4)実装後は不要になるため、検証完了後に削除してよい。
class ClubDetectorDebugScreen extends HookConsumerWidget {
  const ClubDetectorDebugScreen({super.key});

  static const sampleInterval = Duration(milliseconds: 100);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = useState(false);
    final errorMessage = useState<String?>(null);
    final results = useState<List<RawClubDetection>>(const []);
    final progressText = useState<String?>(null);

    Future<void> pickAndRun() async {
      errorMessage.value = null;
      results.value = const [];
      progressText.value = null;
      isProcessing.value = true;

      try {
        final picker = ref.read(videoPickerProvider);
        final video = await picker.pickVideo();
        if (video == null) {
          isProcessing.value = false;
          return;
        }

        final durationReader = ref.read(videoDurationReaderProvider);
        final duration = await durationReader.read(video);
        final detector = await ref.read(clubDetectorProvider.future);
        final frameSource = GetThumbnailVideoFrameSource(video);

        final collected = <RawClubDetection>[];
        var t = Duration.zero;
        var frameCount = 0;
        while (t < duration) {
          frameCount++;
          progressText.value =
              '処理中: ${t.inMilliseconds}ms / ${duration.inMilliseconds}ms'
              '($frameCount フレーム目)';
          final bytes = await frameSource.frameAt(t);
          final detections = await detector.detect(bytes, frameTime: t);
          collected.addAll(detections);
          results.value = List.of(collected);
          t += sampleInterval;
        }
        progressText.value = '完了: $frameCount フレームを処理しました';
      } catch (e) {
        errorMessage.value = '検証中にエラーが発生しました: $e';
      } finally {
        isProcessing.value = false;
      }
    }

    final headCount = results.value
        .where((d) => d.part == ClubPart.head)
        .length;
    final handleCount = results.value
        .where((d) => d.part == ClubPart.handle)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('[デバッグ] クラブ検出テスト')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              key: const Key('runClubDetectorDebugButton'),
              onPressed: isProcessing.value ? null : pickAndRun,
              child: const Text('動画を選んで検証開始'),
            ),
            if (progressText.value != null) ...[
              const SizedBox(height: 8),
              Text(progressText.value!),
            ],
            if (errorMessage.value != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage.value!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'head検出: $headCount件 / handle検出: $handleCount件',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: results.value.length,
                itemBuilder: (context, index) {
                  final d = results.value[index];
                  return Text(
                    't=${d.frameTimeMs}ms part=${d.part.name} '
                    'conf=${d.confidence.toStringAsFixed(2)} '
                    'pos=(${d.centerPx.dx.toStringAsFixed(0)},'
                    '${d.centerPx.dy.toStringAsFixed(0)})',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
