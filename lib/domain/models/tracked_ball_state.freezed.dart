// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracked_ball_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrackedBallState {

 int get frameTimeMs; double get u; double get v; double get du; double get dv; double get diameterPx; BallTrackingPhase get phase;
/// Create a copy of TrackedBallState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackedBallStateCopyWith<TrackedBallState> get copyWith => _$TrackedBallStateCopyWithImpl<TrackedBallState>(this as TrackedBallState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackedBallState&&(identical(other.frameTimeMs, frameTimeMs) || other.frameTimeMs == frameTimeMs)&&(identical(other.u, u) || other.u == u)&&(identical(other.v, v) || other.v == v)&&(identical(other.du, du) || other.du == du)&&(identical(other.dv, dv) || other.dv == dv)&&(identical(other.diameterPx, diameterPx) || other.diameterPx == diameterPx)&&(identical(other.phase, phase) || other.phase == phase));
}


@override
int get hashCode => Object.hash(runtimeType,frameTimeMs,u,v,du,dv,diameterPx,phase);

@override
String toString() {
  return 'TrackedBallState(frameTimeMs: $frameTimeMs, u: $u, v: $v, du: $du, dv: $dv, diameterPx: $diameterPx, phase: $phase)';
}


}

/// @nodoc
abstract mixin class $TrackedBallStateCopyWith<$Res>  {
  factory $TrackedBallStateCopyWith(TrackedBallState value, $Res Function(TrackedBallState) _then) = _$TrackedBallStateCopyWithImpl;
@useResult
$Res call({
 int frameTimeMs, double u, double v, double du, double dv, double diameterPx, BallTrackingPhase phase
});




}
/// @nodoc
class _$TrackedBallStateCopyWithImpl<$Res>
    implements $TrackedBallStateCopyWith<$Res> {
  _$TrackedBallStateCopyWithImpl(this._self, this._then);

  final TrackedBallState _self;
  final $Res Function(TrackedBallState) _then;

/// Create a copy of TrackedBallState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? frameTimeMs = null,Object? u = null,Object? v = null,Object? du = null,Object? dv = null,Object? diameterPx = null,Object? phase = null,}) {
  return _then(_self.copyWith(
frameTimeMs: null == frameTimeMs ? _self.frameTimeMs : frameTimeMs // ignore: cast_nullable_to_non_nullable
as int,u: null == u ? _self.u : u // ignore: cast_nullable_to_non_nullable
as double,v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as double,du: null == du ? _self.du : du // ignore: cast_nullable_to_non_nullable
as double,dv: null == dv ? _self.dv : dv // ignore: cast_nullable_to_non_nullable
as double,diameterPx: null == diameterPx ? _self.diameterPx : diameterPx // ignore: cast_nullable_to_non_nullable
as double,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as BallTrackingPhase,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackedBallState].
extension TrackedBallStatePatterns on TrackedBallState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackedBallState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackedBallState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackedBallState value)  $default,){
final _that = this;
switch (_that) {
case _TrackedBallState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackedBallState value)?  $default,){
final _that = this;
switch (_that) {
case _TrackedBallState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int frameTimeMs,  double u,  double v,  double du,  double dv,  double diameterPx,  BallTrackingPhase phase)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackedBallState() when $default != null:
return $default(_that.frameTimeMs,_that.u,_that.v,_that.du,_that.dv,_that.diameterPx,_that.phase);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int frameTimeMs,  double u,  double v,  double du,  double dv,  double diameterPx,  BallTrackingPhase phase)  $default,) {final _that = this;
switch (_that) {
case _TrackedBallState():
return $default(_that.frameTimeMs,_that.u,_that.v,_that.du,_that.dv,_that.diameterPx,_that.phase);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int frameTimeMs,  double u,  double v,  double du,  double dv,  double diameterPx,  BallTrackingPhase phase)?  $default,) {final _that = this;
switch (_that) {
case _TrackedBallState() when $default != null:
return $default(_that.frameTimeMs,_that.u,_that.v,_that.du,_that.dv,_that.diameterPx,_that.phase);case _:
  return null;

}
}

}

/// @nodoc


class _TrackedBallState implements TrackedBallState {
  const _TrackedBallState({required this.frameTimeMs, required this.u, required this.v, required this.du, required this.dv, required this.diameterPx, required this.phase});
  

@override final  int frameTimeMs;
@override final  double u;
@override final  double v;
@override final  double du;
@override final  double dv;
@override final  double diameterPx;
@override final  BallTrackingPhase phase;

/// Create a copy of TrackedBallState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackedBallStateCopyWith<_TrackedBallState> get copyWith => __$TrackedBallStateCopyWithImpl<_TrackedBallState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackedBallState&&(identical(other.frameTimeMs, frameTimeMs) || other.frameTimeMs == frameTimeMs)&&(identical(other.u, u) || other.u == u)&&(identical(other.v, v) || other.v == v)&&(identical(other.du, du) || other.du == du)&&(identical(other.dv, dv) || other.dv == dv)&&(identical(other.diameterPx, diameterPx) || other.diameterPx == diameterPx)&&(identical(other.phase, phase) || other.phase == phase));
}


@override
int get hashCode => Object.hash(runtimeType,frameTimeMs,u,v,du,dv,diameterPx,phase);

@override
String toString() {
  return 'TrackedBallState(frameTimeMs: $frameTimeMs, u: $u, v: $v, du: $du, dv: $dv, diameterPx: $diameterPx, phase: $phase)';
}


}

/// @nodoc
abstract mixin class _$TrackedBallStateCopyWith<$Res> implements $TrackedBallStateCopyWith<$Res> {
  factory _$TrackedBallStateCopyWith(_TrackedBallState value, $Res Function(_TrackedBallState) _then) = __$TrackedBallStateCopyWithImpl;
@override @useResult
$Res call({
 int frameTimeMs, double u, double v, double du, double dv, double diameterPx, BallTrackingPhase phase
});




}
/// @nodoc
class __$TrackedBallStateCopyWithImpl<$Res>
    implements _$TrackedBallStateCopyWith<$Res> {
  __$TrackedBallStateCopyWithImpl(this._self, this._then);

  final _TrackedBallState _self;
  final $Res Function(_TrackedBallState) _then;

/// Create a copy of TrackedBallState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? frameTimeMs = null,Object? u = null,Object? v = null,Object? du = null,Object? dv = null,Object? diameterPx = null,Object? phase = null,}) {
  return _then(_TrackedBallState(
frameTimeMs: null == frameTimeMs ? _self.frameTimeMs : frameTimeMs // ignore: cast_nullable_to_non_nullable
as int,u: null == u ? _self.u : u // ignore: cast_nullable_to_non_nullable
as double,v: null == v ? _self.v : v // ignore: cast_nullable_to_non_nullable
as double,du: null == du ? _self.du : du // ignore: cast_nullable_to_non_nullable
as double,dv: null == dv ? _self.dv : dv // ignore: cast_nullable_to_non_nullable
as double,diameterPx: null == diameterPx ? _self.diameterPx : diameterPx // ignore: cast_nullable_to_non_nullable
as double,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as BallTrackingPhase,
  ));
}


}

// dart format on
