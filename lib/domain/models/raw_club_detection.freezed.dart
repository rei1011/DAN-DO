// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'raw_club_detection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RawClubDetection {

 int get frameTimeMs; Offset get centerPx; double get confidence; ClubPart get part;
/// Create a copy of RawClubDetection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RawClubDetectionCopyWith<RawClubDetection> get copyWith => _$RawClubDetectionCopyWithImpl<RawClubDetection>(this as RawClubDetection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RawClubDetection&&(identical(other.frameTimeMs, frameTimeMs) || other.frameTimeMs == frameTimeMs)&&(identical(other.centerPx, centerPx) || other.centerPx == centerPx)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.part, part) || other.part == part));
}


@override
int get hashCode => Object.hash(runtimeType,frameTimeMs,centerPx,confidence,part);

@override
String toString() {
  return 'RawClubDetection(frameTimeMs: $frameTimeMs, centerPx: $centerPx, confidence: $confidence, part: $part)';
}


}

/// @nodoc
abstract mixin class $RawClubDetectionCopyWith<$Res>  {
  factory $RawClubDetectionCopyWith(RawClubDetection value, $Res Function(RawClubDetection) _then) = _$RawClubDetectionCopyWithImpl;
@useResult
$Res call({
 int frameTimeMs, Offset centerPx, double confidence, ClubPart part
});




}
/// @nodoc
class _$RawClubDetectionCopyWithImpl<$Res>
    implements $RawClubDetectionCopyWith<$Res> {
  _$RawClubDetectionCopyWithImpl(this._self, this._then);

  final RawClubDetection _self;
  final $Res Function(RawClubDetection) _then;

/// Create a copy of RawClubDetection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? frameTimeMs = null,Object? centerPx = null,Object? confidence = null,Object? part = null,}) {
  return _then(_self.copyWith(
frameTimeMs: null == frameTimeMs ? _self.frameTimeMs : frameTimeMs // ignore: cast_nullable_to_non_nullable
as int,centerPx: null == centerPx ? _self.centerPx : centerPx // ignore: cast_nullable_to_non_nullable
as Offset,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as ClubPart,
  ));
}

}


/// Adds pattern-matching-related methods to [RawClubDetection].
extension RawClubDetectionPatterns on RawClubDetection {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RawClubDetection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RawClubDetection() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RawClubDetection value)  $default,){
final _that = this;
switch (_that) {
case _RawClubDetection():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RawClubDetection value)?  $default,){
final _that = this;
switch (_that) {
case _RawClubDetection() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int frameTimeMs,  Offset centerPx,  double confidence,  ClubPart part)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RawClubDetection() when $default != null:
return $default(_that.frameTimeMs,_that.centerPx,_that.confidence,_that.part);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int frameTimeMs,  Offset centerPx,  double confidence,  ClubPart part)  $default,) {final _that = this;
switch (_that) {
case _RawClubDetection():
return $default(_that.frameTimeMs,_that.centerPx,_that.confidence,_that.part);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int frameTimeMs,  Offset centerPx,  double confidence,  ClubPart part)?  $default,) {final _that = this;
switch (_that) {
case _RawClubDetection() when $default != null:
return $default(_that.frameTimeMs,_that.centerPx,_that.confidence,_that.part);case _:
  return null;

}
}

}

/// @nodoc


class _RawClubDetection implements RawClubDetection {
  const _RawClubDetection({required this.frameTimeMs, required this.centerPx, required this.confidence, required this.part});
  

@override final  int frameTimeMs;
@override final  Offset centerPx;
@override final  double confidence;
@override final  ClubPart part;

/// Create a copy of RawClubDetection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RawClubDetectionCopyWith<_RawClubDetection> get copyWith => __$RawClubDetectionCopyWithImpl<_RawClubDetection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RawClubDetection&&(identical(other.frameTimeMs, frameTimeMs) || other.frameTimeMs == frameTimeMs)&&(identical(other.centerPx, centerPx) || other.centerPx == centerPx)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.part, part) || other.part == part));
}


@override
int get hashCode => Object.hash(runtimeType,frameTimeMs,centerPx,confidence,part);

@override
String toString() {
  return 'RawClubDetection(frameTimeMs: $frameTimeMs, centerPx: $centerPx, confidence: $confidence, part: $part)';
}


}

/// @nodoc
abstract mixin class _$RawClubDetectionCopyWith<$Res> implements $RawClubDetectionCopyWith<$Res> {
  factory _$RawClubDetectionCopyWith(_RawClubDetection value, $Res Function(_RawClubDetection) _then) = __$RawClubDetectionCopyWithImpl;
@override @useResult
$Res call({
 int frameTimeMs, Offset centerPx, double confidence, ClubPart part
});




}
/// @nodoc
class __$RawClubDetectionCopyWithImpl<$Res>
    implements _$RawClubDetectionCopyWith<$Res> {
  __$RawClubDetectionCopyWithImpl(this._self, this._then);

  final _RawClubDetection _self;
  final $Res Function(_RawClubDetection) _then;

/// Create a copy of RawClubDetection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? frameTimeMs = null,Object? centerPx = null,Object? confidence = null,Object? part = null,}) {
  return _then(_RawClubDetection(
frameTimeMs: null == frameTimeMs ? _self.frameTimeMs : frameTimeMs // ignore: cast_nullable_to_non_nullable
as int,centerPx: null == centerPx ? _self.centerPx : centerPx // ignore: cast_nullable_to_non_nullable
as Offset,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as ClubPart,
  ));
}


}

// dart format on
