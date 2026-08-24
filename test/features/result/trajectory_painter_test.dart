import 'package:dan_do/domain/models/trajectory_point.dart';
import 'package:dan_do/features/result/trajectory_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('projectTrajectoryToCanvasOffsets', () {
    test('zを横軸、yを縦軸(上下反転)としてキャンバスサイズに収まるよう射影する', () {
      const points = [
        TrajectoryPoint(t: 0, x: 0, y: 0, z: 0, isMeasured: true),
        TrajectoryPoint(t: 1, x: 0, y: 5, z: 50, isMeasured: false),
      ];
      const size = Size(200, 100);

      final offsets = projectTrajectoryToCanvasOffsets(points, size);

      expect(offsets, hasLength(2));
      // 最初の点(z=0地点)は左端付近
      expect(offsets[0].dx, lessThan(offsets[1].dx));
      // 高さ(y)が大きいほどキャンバス上では上(dyが小さい)になる
      expect(offsets[1].dy, lessThan(offsets[0].dy));
      for (final offset in offsets) {
        expect(offset.dx, inInclusiveRange(0, size.width));
        expect(offset.dy, inInclusiveRange(0, size.height));
      }
    });

    test('点が1つ以下なら空リストを返す', () {
      const points = [
        TrajectoryPoint(t: 0, x: 0, y: 0, z: 0, isMeasured: true),
      ];
      final offsets = projectTrajectoryToCanvasOffsets(
        points,
        const Size(200, 100),
      );
      expect(offsets, isEmpty);
    });
  });
}
