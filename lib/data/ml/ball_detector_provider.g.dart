// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ball_detector_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ballDetector)
final ballDetectorProvider = BallDetectorProvider._();

final class BallDetectorProvider
    extends
        $FunctionalProvider<
          AsyncValue<BallDetector>,
          BallDetector,
          FutureOr<BallDetector>
        >
    with $FutureModifier<BallDetector>, $FutureProvider<BallDetector> {
  BallDetectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ballDetectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ballDetectorHash();

  @$internal
  @override
  $FutureProviderElement<BallDetector> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BallDetector> create(Ref ref) {
    return ballDetector(ref);
  }
}

String _$ballDetectorHash() => r'f6407b13245d1d224a99b0ff959a728aba96d30e';
