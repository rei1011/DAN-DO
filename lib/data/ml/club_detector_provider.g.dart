// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club_detector_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(clubDetector)
final clubDetectorProvider = ClubDetectorProvider._();

final class ClubDetectorProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClubDetector>,
          ClubDetector,
          FutureOr<ClubDetector>
        >
    with $FutureModifier<ClubDetector>, $FutureProvider<ClubDetector> {
  ClubDetectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clubDetectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clubDetectorHash();

  @$internal
  @override
  $FutureProviderElement<ClubDetector> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClubDetector> create(Ref ref) {
    return clubDetector(ref);
  }
}

String _$clubDetectorHash() => r'd94789abef789d6d11d9847b9a8da24cbd366628';
