// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_picker_video_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(videoPicker)
final videoPickerProvider = VideoPickerProvider._();

final class VideoPickerProvider
    extends $FunctionalProvider<VideoPicker, VideoPicker, VideoPicker>
    with $Provider<VideoPicker> {
  VideoPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoPickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoPickerHash();

  @$internal
  @override
  $ProviderElement<VideoPicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VideoPicker create(Ref ref) {
    return videoPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoPicker>(value),
    );
  }
}

String _$videoPickerHash() => r'a0e5dde12ffbc8e9667efe71b38a64c85c58c190';
