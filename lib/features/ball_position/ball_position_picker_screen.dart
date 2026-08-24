import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/video/first_frame_reader.dart';
import '../analyzing/analyzing_screen.dart';
import 'tap_position_mapper.dart';

class BallPositionPickerScreen extends ConsumerStatefulWidget {
  const BallPositionPickerScreen({super.key, required this.video});

  final XFile video;

  @override
  ConsumerState<BallPositionPickerScreen> createState() =>
      _BallPositionPickerScreenState();
}

class _BallPositionPickerScreenState
    extends ConsumerState<BallPositionPickerScreen> {
  Offset? _tappedImagePx;
  late final Future<Uint8List> _frameFuture;

  @override
  void initState() {
    super.initState();
    _frameFuture = ref.read(firstFrameReaderProvider).read(widget.video);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ボール位置を指定')),
      body: FutureBuilder<Uint8List>(
        future: _frameFuture,
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
            tappedImagePx: _tappedImagePx,
            onTapped: (px) => setState(() => _tappedImagePx = px),
            onConfirm: _tappedImagePx == null
                ? null
                : () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => AnalyzingScreen(
                        video: widget.video,
                        initialBallPositionPx: _tappedImagePx!,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _FramePicker extends StatefulWidget {
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

  @override
  State<_FramePicker> createState() => _FramePickerState();
}

class _FramePickerState extends State<_FramePicker> {
  late final Future<ui.Image> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _decodeImage(widget.bytes);
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('画像のデコードに失敗しました: ${snapshot.error}'));
        }
        final image = snapshot.data;
        if (image == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final imageSize = Size(
          image.width.toDouble(),
          image.height.toDouble(),
        );

        return Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final displaySize = constraints.biggest;
                  return GestureDetector(
                    key: const Key('ballPositionImage'),
                    onTapDown: (details) => widget.onTapped(
                      mapDisplayPositionToImagePx(
                        localPosition: details.localPosition,
                        displaySize: displaySize,
                        imageSize: imageSize,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(widget.bytes, fit: BoxFit.contain),
                        if (widget.tappedImagePx != null)
                          _Marker(
                            imagePx: widget.tappedImagePx!,
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
                onPressed: widget.onConfirm,
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
