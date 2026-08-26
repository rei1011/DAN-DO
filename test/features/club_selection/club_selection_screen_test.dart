import 'package:cross_file/cross_file.dart';
import 'package:dan_do/core/club_constants.dart';
import 'package:dan_do/features/analyzing/analyzing_screen.dart';
import 'package:dan_do/features/club_selection/club_selection_screen.dart';
import 'package:dan_do/domain/services/ball_trajectory_analysis_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../fakes/fake_shot_analysis_service.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        shotAnalysisServiceProvider.overrideWith(
          (ref) async => FakeShotAnalysisService(),
        ),
      ],
      child: MaterialApp(
        home: ClubSelectionScreen(
          video: XFile('fixture.mp4'),
          ballPositionPx: const Offset(100, 100),
        ),
      ),
    ),
  );

  testWidgets('5種類のクラブ種別が選択肢として表示される', (tester) async {
    await pumpScreen(tester);

    for (final clubType in ClubType.values) {
      expect(
        find.byKey(Key('clubTypeOption_${clubType.name}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('クラブ種別をタップすると選択した種別でAnalyzingScreenへ遷移する', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('clubTypeOption_wedge')));
    // AnalyzingScreenは解析完了までCircularProgressIndicatorの無限アニメーションが
    // 残るため、pumpAndSettleは使わず画面遷移が完了するまで有限回だけpumpする。
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(AnalyzingScreen).evaluate().isNotEmpty) break;
    }

    expect(find.byType(AnalyzingScreen), findsOneWidget);
    final analyzingScreen = tester.widget<AnalyzingScreen>(
      find.byType(AnalyzingScreen),
    );
    expect(analyzingScreen.clubType, ClubType.wedge);
    expect(analyzingScreen.initialBallPositionPx, const Offset(100, 100));
  });
}
