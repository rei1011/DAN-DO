import 'package:flutter/material.dart';

import '../../domain/models/trajectory_point.dart';

/// 弾道の側面図(z=前後方向を横軸、y=高さを縦軸)としてキャンバスに射影する。
///
/// 実測区間・シミュレーション区間を線種で区別せず一律描画する方針
/// (`docs/implementation-plan-analysis-pipeline.md` Phase 3参照)のため、
/// 結合済みの点列をそのまま1本の線として射影する。
List<Offset> projectTrajectoryToCanvasOffsets(
  List<TrajectoryPoint> points,
  Size size,
) {
  if (points.length < 2) return const [];

  const padding = 8.0;
  final maxZ = points.map((p) => p.z).reduce((a, b) => a > b ? a : b);
  final maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
  if (maxZ <= 0 || maxY <= 0) return const [];

  final scaleX = (size.width - padding * 2) / maxZ;
  final scaleY = (size.height - padding * 2) / maxY;

  return points
      .map(
        (p) => Offset(
          padding + p.z * scaleX,
          size.height - padding - p.y * scaleY,
        ),
      )
      .toList();
}

/// 弾道の側面図を描画するCustomPainter。
class TrajectoryPainter extends CustomPainter {
  const TrajectoryPainter(this.points);

  final List<TrajectoryPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final offsets = projectTrajectoryToCanvasOffsets(points, size);
    if (offsets.length < 2) return;

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final offset in offsets.skip(1)) {
      path.lineTo(offset.dx, offset.dy);
    }

    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TrajectoryPainter oldDelegate) =>
      oldDelegate.points != points;
}
