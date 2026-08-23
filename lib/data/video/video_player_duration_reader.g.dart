// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_player_duration_reader.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(videoDurationReader)
final videoDurationReaderProvider = VideoDurationReaderProvider._();

final class VideoDurationReaderProvider
    extends
        $FunctionalProvider<
          VideoDurationReader,
          VideoDurationReader,
          VideoDurationReader
        >
    with $Provider<VideoDurationReader> {
  VideoDurationReaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoDurationReaderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoDurationReaderHash();

  @$internal
  @override
  $ProviderElement<VideoDurationReader> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VideoDurationReader create(Ref ref) {
    return videoDurationReader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoDurationReader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoDurationReader>(value),
    );
  }
}

String _$videoDurationReaderHash() =>
    r'94141de3246848c3b1902b44a938696acdf3be88';
