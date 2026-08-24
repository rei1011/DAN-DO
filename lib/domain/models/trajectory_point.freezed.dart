// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trajectory_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrajectoryPoint {

 double get t; double get x; double get y; double get z; bool get isMeasured;
/// Create a copy of TrajectoryPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrajectoryPointCopyWith<TrajectoryPoint> get copyWith => _$TrajectoryPointCopyWithImpl<TrajectoryPoint>(this as TrajectoryPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrajectoryPoint&&(identical(other.t, t) || other.t == t)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.z, z) || other.z == z)&&(identical(other.isMeasured, isMeasured) || other.isMeasured == isMeasured));
}


@override
int get hashCode => Object.hash(runtimeType,t,x,y,z,isMeasured);

@override
String toString() {
  return 'TrajectoryPoint(t: $t, x: $x, y: $y, z: $z, isMeasured: $isMeasured)';
}


}

/// @nodoc
abstract mixin class $TrajectoryPointCopyWith<$Res>  {
  factory $TrajectoryPointCopyWith(TrajectoryPoint value, $Res Function(TrajectoryPoint) _then) = _$TrajectoryPointCopyWithImpl;
@useResult
$Res call({
 double t, double x, double y, double z, bool isMeasured
});




}
/// @nodoc
class _$TrajectoryPointCopyWithImpl<$Res>
    implements $TrajectoryPointCopyWith<$Res> {
  _$TrajectoryPointCopyWithImpl(this._self, this._then);

  final TrajectoryPoint _self;
  final $Res Function(TrajectoryPoint) _then;

/// Create a copy of TrajectoryPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? t = null,Object? x = null,Object? y = null,Object? z = null,Object? isMeasured = null,}) {
  return _then(_self.copyWith(
t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as double,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,z: null == z ? _self.z : z // ignore: cast_nullable_to_non_nullable
as double,isMeasured: null == isMeasured ? _self.isMeasured : isMeasured // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TrajectoryPoint].
extension TrajectoryPointPatterns on TrajectoryPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrajectoryPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrajectoryPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrajectoryPoint value)  $default,){
final _that = this;
switch (_that) {
case _TrajectoryPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrajectoryPoint value)?  $default,){
final _that = this;
switch (_that) {
case _TrajectoryPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double t,  double x,  double y,  double z,  bool isMeasured)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrajectoryPoint() when $default != null:
return $default(_that.t,_that.x,_that.y,_that.z,_that.isMeasured);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double t,  double x,  double y,  double z,  bool isMeasured)  $default,) {final _that = this;
switch (_that) {
case _TrajectoryPoint():
return $default(_that.t,_that.x,_that.y,_that.z,_that.isMeasured);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double t,  double x,  double y,  double z,  bool isMeasured)?  $default,) {final _that = this;
switch (_that) {
case _TrajectoryPoint() when $default != null:
return $default(_that.t,_that.x,_that.y,_that.z,_that.isMeasured);case _:
  return null;

}
}

}

/// @nodoc


class _TrajectoryPoint implements TrajectoryPoint {
  const _TrajectoryPoint({required this.t, required this.x, required this.y, required this.z, required this.isMeasured});
  

@override final  double t;
@override final  double x;
@override final  double y;
@override final  double z;
@override final  bool isMeasured;

/// Create a copy of TrajectoryPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrajectoryPointCopyWith<_TrajectoryPoint> get copyWith => __$TrajectoryPointCopyWithImpl<_TrajectoryPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrajectoryPoint&&(identical(other.t, t) || other.t == t)&&(identical(other.x, x) || other.x == x)&&(identical(other.y, y) || other.y == y)&&(identical(other.z, z) || other.z == z)&&(identical(other.isMeasured, isMeasured) || other.isMeasured == isMeasured));
}


@override
int get hashCode => Object.hash(runtimeType,t,x,y,z,isMeasured);

@override
String toString() {
  return 'TrajectoryPoint(t: $t, x: $x, y: $y, z: $z, isMeasured: $isMeasured)';
}


}

/// @nodoc
abstract mixin class _$TrajectoryPointCopyWith<$Res> implements $TrajectoryPointCopyWith<$Res> {
  factory _$TrajectoryPointCopyWith(_TrajectoryPoint value, $Res Function(_TrajectoryPoint) _then) = __$TrajectoryPointCopyWithImpl;
@override @useResult
$Res call({
 double t, double x, double y, double z, bool isMeasured
});




}
/// @nodoc
class __$TrajectoryPointCopyWithImpl<$Res>
    implements _$TrajectoryPointCopyWith<$Res> {
  __$TrajectoryPointCopyWithImpl(this._self, this._then);

  final _TrajectoryPoint _self;
  final $Res Function(_TrajectoryPoint) _then;

/// Create a copy of TrajectoryPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? t = null,Object? x = null,Object? y = null,Object? z = null,Object? isMeasured = null,}) {
  return _then(_TrajectoryPoint(
t: null == t ? _self.t : t // ignore: cast_nullable_to_non_nullable
as double,x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,z: null == z ? _self.z : z // ignore: cast_nullable_to_non_nullable
as double,isMeasured: null == isMeasured ? _self.isMeasured : isMeasured // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
