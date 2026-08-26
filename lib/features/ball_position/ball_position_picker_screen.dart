import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/video/first_frame_reader.dart';
import '../club_selection/club_selection_screen.dart';
import 'tap_position_mapper.dart';

class BallPositionPickerScreen extends HookConsumerWidget {
  const BallPositionPickerScreen({super.key, required this.video});

  final XFile video;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tappedImagePx = useState<Offset?>(null);
    final frameFuture = useMemoized(
      () => ref.read(firstFrameReaderProvider).read(video),
      [video],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('ボール位置を指定')),
      body: FutureBuilder<Uint8List>(
        future: frameFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('フレームの取得に失敗しました: ${snapshot.error}'));
          }
          final bytes = snapshot.data;
          if (bytes == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _FramePicker(
            bytes: bytes,
            tappedImagePx: tappedImagePx.value,
            onTapped: (px) => tappedImagePx.value = px,
            onConfirm: tappedImagePx.value == null
                ? null
                : () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => ClubSelectionScreen(
                        video: video,
                        ballPositionPx: tappedImagePx.value!,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _FramePicker extends HookWidget {
  const _FramePicker({
    required this.bytes,
    required this.tappedImagePx,
    required this.onTapped,
    required this.onConfirm,
  });

  final Uint8List bytes;
  final Offset? tappedImagePx;
  final ValueChanged<Offset> onTapped;
  final VoidCallback? onConfirm;

  static Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    final imageFuture = useMemoized(() => _decodeImage(bytes), [bytes]);

    // 表示にはbytesをImage.memoryで直接使うため、このui.Imageは座標変換用の
    // width/height取得にしか使わない。デコード結果は破棄時にdispose()で解放する。
    useEffect(() {
      ui.Image? decoded;
      imageFuture.then((image) => decoded = image);
      return () => decoded?.dispose();
    }, [bytes]);

    return FutureBuilder<ui.Image>(
      future: imageFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('画像のデコードに失敗しました: ${snapshot.error}'));
        }
        final image = snapshot.data;
        if (image == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final imageSize = Size(image.width.toDouble(), image.height.toDouble());

        return Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final displaySize = constraints.biggest;
                  return GestureDetector(
                    key: const Key('ballPositionImage'),
                    onTapDown: (details) => onTapped(
                      mapDisplayPositionToImagePx(
                        localPosition: details.localPosition,
                        displaySize: displaySize,
                        imageSize: imageSize,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(bytes, fit: BoxFit.contain),
                        if (tappedImagePx != null)
                          _Marker(
                            imagePx: tappedImagePx!,
                            displaySize: displaySize,
                            imageSize: imageSize,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                key: const Key('confirmBallPositionButton'),
                onPressed: onConfirm,
                child: const Text('この位置で解析する'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.imagePx,
    required this.displaySize,
    required this.imageSize,
  });

  final Offset imagePx;
  final Size displaySize;
  final Size imageSize;

  @override
  Widget build(BuildContext context) {
    final center = mapImagePxToDisplayPosition(
      imagePx: imagePx,
      displaySize: displaySize,
      imageSize: imageSize,
    );
    return Positioned(
      left: center.dx - 10,
      top: center.dy - 10,
      child: const IgnorePointer(
        child: Icon(Icons.circle, color: Colors.redAccent, size: 20),
      ),
    );
  }
}
