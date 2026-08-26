import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'raw_club_detection.freezed.dart';

/// クラブ検出モデルが区別する部位。
enum ClubPart {
  /// クラブヘッド。
  head,

  /// クラブハンドル(グリップ側)。
  handle,
}

@freezed
sealed class RawClubDetection with _$RawClubDetection {
  const factory RawClubDetection({
    required int frameTimeMs,
    required Offset centerPx,
    required double confidence,
    required ClubPart part,
  }) = _RawClubDetection;
}
