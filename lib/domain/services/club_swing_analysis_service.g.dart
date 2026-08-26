// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'club_swing_analysis_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(clubSwingAnalysisService)
final clubSwingAnalysisServiceProvider = ClubSwingAnalysisServiceProvider._();

final class ClubSwingAnalysisServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<ShotAnalysisService>,
          ShotAnalysisService,
          FutureOr<ShotAnalysisService>
        >
    with
        $FutureModifier<ShotAnalysisService>,
        $FutureProvider<ShotAnalysisService> {
  ClubSwingAnalysisServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clubSwingAnalysisServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clubSwingAnalysisServiceHash();

  @$internal
  @override
  $FutureProviderElement<ShotAnalysisService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ShotAnalysisService> create(Ref ref) {
    return clubSwingAnalysisService(ref);
  }
}

String _$clubSwingAnalysisServiceHash() =>
    r'f0c56892388c6a7fdc3903ee920e3559e4ccc38e';
