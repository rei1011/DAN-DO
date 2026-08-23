// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(userName)
final userNameProvider = UserNameFamily._();

final class UserNameProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  UserNameProvider._({
    required UserNameFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'userNameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userNameHash();

  @override
  String toString() {
    return r'userNameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as int;
    return userName(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserNameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userNameHash() => r'345d47a3133193b6bcd4ce24dca9517727cdf1ce';

final class UserNameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, int> {
  UserNameFamily._()
    : super(
        retry: null,
        name: r'userNameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserNameProvider call(int userId) =>
      UserNameProvider._(argument: userId, from: this);

  @override
  String toString() => r'userNameProvider';
}
