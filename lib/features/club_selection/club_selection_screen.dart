import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';

import '../../core/club_constants.dart';
import '../analyzing/analyzing_screen.dart';

class ClubSelectionScreen extends StatelessWidget {
  const ClubSelectionScreen({
    super.key,
    required this.video,
    required this.ballPositionPx,
  });

  final XFile video;
  final Offset ballPositionPx;

  static const _labels = {
    ClubType.driver: 'ドライバー',
    ClubType.fairwayWood: 'フェアウェイウッド',
    ClubType.utility: 'ユーティリティ',
    ClubType.iron: 'アイアン',
    ClubType.wedge: 'ウェッジ',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('クラブ種別を選択')),
      body: ListView(
        children: [
          for (final clubType in ClubType.values)
            ListTile(
              key: Key('clubTypeOption_${clubType.name}'),
              title: Text(_labels[clubType]!),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => AnalyzingScreen(
                    video: video,
                    initialBallPositionPx: ballPositionPx,
                    clubType: clubType,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
