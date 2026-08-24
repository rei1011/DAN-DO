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
    required XFile super.argument,
  }) : super(
         retry: null,
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
        '($argument)';
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
    r'bdef4202c6343f7570353a8c83f664b688e180ff';

final class AnalysisControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          AnalysisController,
          AsyncValue<ShotResult>,
          ShotResult,
          FutureOr<ShotResult>,
          XFile
        > {
  AnalysisControllerFamily._()
    : super(
        retry: null,
        name: r'analysisControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AnalysisControllerProvider call(XFile video) =>
      AnalysisControllerProvider._(argument: video, from: this);

  @override
  String toString() => r'analysisControllerProvider';
}

abstract class _$AnalysisController extends $AsyncNotifier<ShotResult> {
  late final _$args = ref.$arg as XFile;
  XFile get video => _$args;

  FutureOr<ShotResult> build(XFile video);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}
