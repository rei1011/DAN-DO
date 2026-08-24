// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'first_frame_reader.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(firstFrameReader)
final firstFrameReaderProvider = FirstFrameReaderProvider._();

final class FirstFrameReaderProvider
    extends
        $FunctionalProvider<
          FirstFrameReader,
          FirstFrameReader,
          FirstFrameReader
        >
    with $Provider<FirstFrameReader> {
  FirstFrameReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firstFrameReaderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firstFrameReaderHash();

  @$internal
  @override
  $ProviderElement<FirstFrameReader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirstFrameReader create(Ref ref) {
    return firstFrameReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirstFrameReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirstFrameReader>(value),
    );
  }
}

String _$firstFrameReaderHash() => r'2b6e6ce762793fa580f3552fc1e377b5411a450e';
