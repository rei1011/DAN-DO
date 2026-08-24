// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'raw_ball_detection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RawBallDetection {

 int get frameTimeMs; Offset get centerPx; double get diameterPx; double get confidence;
/// Create a copy of RawBallDetection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RawBallDetectionCopyWith<RawBallDetection> get copyWith => _$RawBallDetectionCopyWithImpl<RawBallDetection>(this as RawBallDetection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RawBallDetection&&(identical(other.frameTimeMs, frameTimeMs) || other.frameTimeMs == frameTimeMs)&&(identical(other.centerPx, centerPx) || other.centerPx == centerPx)&&(identical(other.diameterPx, diameterPx) || other.diameterPx == diameterPx)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,frameTimeMs,centerPx,diameterPx,confidence);

@override
String toString() {
  return 'RawBallDetection(frameTimeMs: $frameTimeMs, centerPx: $centerPx, diameterPx: $diameterPx, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class $RawBallDetectionCopyWith<$Res>  {
  factory $RawBallDetectionCopyWith(RawBallDetection value, $Res Function(RawBallDetection) _then) = _$RawBallDetectionCopyWithImpl;
@useResult
$Res call({
 int frameTimeMs, Offset centerPx, double diameterPx, double confidence
});




}
/// @nodoc
class _$RawBallDetectionCopyWithImpl<$Res>
    implements $RawBallDetectionCopyWith<$Res> {
  _$RawBallDetectionCopyWithImpl(this._self, this._then);

  final RawBallDetection _self;
  final $Res Function(RawBallDetection) _then;

/// Create a copy of RawBallDetection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? frameTimeMs = null,Object? centerPx = null,Object? diameterPx = null,Object? confidence = null,}) {
  return _then(_self.copyWith(
frameTimeMs: null == frameTimeMs ? _self.frameTimeMs : frameTimeMs // ignore: cast_nullable_to_non_nullable
as int,centerPx: null == centerPx ? _self.centerPx : centerPx // ignore: cast_nullable_to_non_nullable
as Offset,diameterPx: null == diameterPx ? _self.diameterPx : diameterPx // ignore: cast_nullable_to_non_nullable
as double,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [RawBallDetection].
extension RawBallDetectionPatterns on RawBallDetection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RawBallDetection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RawBallDetection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RawBallDetection value)  $default,){
final _that = this;
switch (_that) {
case _RawBallDetection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RawBallDetection value)?  $default,){
final _that = this;
switch (_that) {
case _RawBallDetection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int frameTimeMs,  Offset centerPx,  double diameterPx,  double confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RawBallDetection() when $default != null:
return $default(_that.frameTimeMs,_that.centerPx,_that.diameterPx,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int frameTimeMs,  Offset centerPx,  double diameterPx,  double confidence)  $default,) {final _that = this;
switch (_that) {
case _RawBallDetection():
return $default(_that.frameTimeMs,_that.centerPx,_that.diameterPx,_that.confidence);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int frameTimeMs,  Offset centerPx,  double diameterPx,  double confidence)?  $default,) {final _that = this;
switch (_that) {
case _RawBallDetection() when $default != null:
return $default(_that.frameTimeMs,_that.centerPx,_that.diameterPx,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc


class _RawBallDetection implements RawBallDetection {
  const _RawBallDetection({required this.frameTimeMs, required this.centerPx, required this.diameterPx, required this.confidence});
  

@override final  int frameTimeMs;
@override final  Offset centerPx;
@override final  double diameterPx;
@override final  double confidence;

/// Create a copy of RawBallDetection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RawBallDetectionCopyWith<_RawBallDetection> get copyWith => __$RawBallDetectionCopyWithImpl<_RawBallDetection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RawBallDetection&&(identical(other.frameTimeMs, frameTimeMs) || other.frameTimeMs == frameTimeMs)&&(identical(other.centerPx, centerPx) || other.centerPx == centerPx)&&(identical(other.diameterPx, diameterPx) || other.diameterPx == diameterPx)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,frameTimeMs,centerPx,diameterPx,confidence);

@override
String toString() {
  return 'RawBallDetection(frameTimeMs: $frameTimeMs, centerPx: $centerPx, diameterPx: $diameterPx, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$RawBallDetectionCopyWith<$Res> implements $RawBallDetectionCopyWith<$Res> {
  factory _$RawBallDetectionCopyWith(_RawBallDetection value, $Res Function(_RawBallDetection) _then) = __$RawBallDetectionCopyWithImpl;
@override @useResult
$Res call({
 int frameTimeMs, Offset centerPx, double diameterPx, double confidence
});




}
/// @nodoc
class __$RawBallDetectionCopyWithImpl<$Res>
    implements _$RawBallDetectionCopyWith<$Res> {
  __$RawBallDetectionCopyWithImpl(this._self, this._then);

  final _RawBallDetection _self;
  final $Res Function(_RawBallDetection) _then;

/// Create a copy of RawBallDetection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? frameTimeMs = null,Object? centerPx = null,Object? diameterPx = null,Object? confidence = null,}) {
  return _then(_RawBallDetection(
frameTimeMs: null == frameTimeMs ? _self.frameTimeMs : frameTimeMs // ignore: cast_nullable_to_non_nullable
as int,centerPx: null == centerPx ? _self.centerPx : centerPx // ignore: cast_nullable_to_non_nullable
as Offset,diameterPx: null == diameterPx ? _self.diameterPx : diameterPx // ignore: cast_nullable_to_non_nullable
as double,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
