import 'dart:ui';

import 'package:cross_file/cross_file.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/shot_result.dart';
import '../../domain/services/ball_trajectory_analysis_service.dart';

part 'analysis_controller.g.dart';

/// analyze()は同じ動画・同じタップ位置なら決定論的に失敗するため、
/// Riverpod標準のリトライ(既定で最大10回)を続けても結果は変わらない。
/// 実機では1回あたりの解析コスト(全フレームへの実推論)が大きく、
/// 10回リトライすると「解析中」画面が非常に長く止まって見えるため、
/// リトライ回数を3回までに制限する。
Duration? analysisRetryPolicy(int retryCount, Object error) =>
    ProviderContainer.defaultRetry(retryCount, error, maxRetries: 3);

@Riverpod(retry: analysisRetryPolicy)
class AnalysisController extends _$AnalysisController {
  @override
  Future<ShotResult> build(XFile video, Offset initialBallPositionPx) async {
    final service = await ref.watch(shotAnalysisServiceProvider.future);
    return service.analyze(video, initialBallPositionPx: initialBallPositionPx);
  }
}
