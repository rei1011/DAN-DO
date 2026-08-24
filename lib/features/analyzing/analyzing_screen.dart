import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../domain/models/shot_result.dart';
import '../result/result_screen.dart';
import 'analysis_controller.dart';

class AnalyzingScreen extends ConsumerWidget {
  const AnalyzingScreen({super.key, required this.video});

  final XFile video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<ShotResult>>(analysisControllerProvider(video), (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (result) {
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute(
              builder: (_) => ResultScreen(video: video, result: result),
            ),
          );
        },
      );
    });

    final state = ref.watch(analysisControllerProvider(video));

    final showError = state.hasError && !state.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('解析中')),
      body: Center(
        child: showError
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('解析に失敗しました: ${state.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    key: const Key('backToVideoSelectButton'),
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    child: const Text('別の動画を選ぶ'),
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
