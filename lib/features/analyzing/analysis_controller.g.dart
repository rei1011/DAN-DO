// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnalysisController)
final analysisControllerProvider = AnalysisControllerFamily._();

final class AnalysisControllerProvider
    extends $AsyncNotifierProvider<AnalysisController, ShotResult> {
  AnalysisControllerProvider._({
    required AnalysisControllerFamily super.from,
    required (XFile, Offset, ClubType) super.argument,
  }) : super(
         retry: analysisRetryPolicy,
         name: r'analysisControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$analysisControllerHash();

  @override
  String toString() {
    return r'analysisControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  AnalysisController create() => AnalysisController();

  @override
  bool operator ==(Object other) {
    return other is AnalysisControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$analysisControllerHash() =>
    r'825c75355370660fb486f6b7b096e4af699b625a';

final class AnalysisControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AnalysisController,
          AsyncValue<ShotResult>,
          ShotResult,
          FutureOr<ShotResult>,
          (XFile, Offset, ClubType)
        > {
  AnalysisControllerFamily._()
    : super(
        retry: analysisRetryPolicy,
        name: r'analysisControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AnalysisControllerProvider call(
    XFile video,
    Offset initialBallPositionPx,
    ClubType clubType,
  ) => AnalysisControllerProvider._(
    argument: (video, initialBallPositionPx, clubType),
    from: this,
  );

  @override
  String toString() => r'analysisControllerProvider';
}

abstract class _$AnalysisController extends $AsyncNotifier<ShotResult> {
  late final _$args = ref.$arg as (XFile, Offset, ClubType);
  XFile get video => _$args.$1;
  Offset get initialBallPositionPx => _$args.$2;
  ClubType get clubType => _$args.$3;

  FutureOr<ShotResult> build(
    XFile video,
    Offset initialBallPositionPx,
    ClubType clubType,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ShotResult>, ShotResult>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ShotResult>, ShotResult>,
              AsyncValue<ShotResult>,
              Object?,
              Object?
            >;
    return element.handleCreate(
      ref,
      () => build(_$args.$1, _$args.$2, _$args.$3),
    );
  }
}
