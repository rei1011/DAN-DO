// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ball_trajectory_analysis_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shotAnalysisService)
final shotAnalysisServiceProvider = ShotAnalysisServiceProvider._();

final class ShotAnalysisServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<ShotAnalysisService>,
          ShotAnalysisService,
          FutureOr<ShotAnalysisService>
        >
    with
        $FutureModifier<ShotAnalysisService>,
        $FutureProvider<ShotAnalysisService> {
  ShotAnalysisServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shotAnalysisServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shotAnalysisServiceHash();

  @$internal
  @override
  $FutureProviderElement<ShotAnalysisService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ShotAnalysisService> create(Ref ref) {
    return shotAnalysisService(ref);
  }
}

String _$shotAnalysisServiceHash() =>
    r'732241869e4aea5c58586dcac062e377ce0d70ed';
