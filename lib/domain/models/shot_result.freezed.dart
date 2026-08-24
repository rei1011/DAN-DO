// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shot_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShotResult {

 double get carryDistanceMeters; double get launchAngleDegrees; double get launchDirectionDegrees; List<TrajectoryPoint> get measuredTrajectory; List<TrajectoryPoint> get simulatedTrajectory;
/// Create a copy of ShotResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShotResultCopyWith<ShotResult> get copyWith => _$ShotResultCopyWithImpl<ShotResult>(this as ShotResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShotResult&&(identical(other.carryDistanceMeters, carryDistanceMeters) || other.carryDistanceMeters == carryDistanceMeters)&&(identical(other.launchAngleDegrees, launchAngleDegrees) || other.launchAngleDegrees == launchAngleDegrees)&&(identical(other.launchDirectionDegrees, launchDirectionDegrees) || other.launchDirectionDegrees == launchDirectionDegrees)&&const DeepCollectionEquality().equals(other.measuredTrajectory, measuredTrajectory)&&const DeepCollectionEquality().equals(other.simulatedTrajectory, simulatedTrajectory));
}


@override
int get hashCode => Object.hash(runtimeType,carryDistanceMeters,launchAngleDegrees,launchDirectionDegrees,const DeepCollectionEquality().hash(measuredTrajectory),const DeepCollectionEquality().hash(simulatedTrajectory));

@override
String toString() {
  return 'ShotResult(carryDistanceMeters: $carryDistanceMeters, launchAngleDegrees: $launchAngleDegrees, launchDirectionDegrees: $launchDirectionDegrees, measuredTrajectory: $measuredTrajectory, simulatedTrajectory: $simulatedTrajectory)';
}


}

/// @nodoc
abstract mixin class $ShotResultCopyWith<$Res>  {
  factory $ShotResultCopyWith(ShotResult value, $Res Function(ShotResult) _then) = _$ShotResultCopyWithImpl;
@useResult
$Res call({
 double carryDistanceMeters, double launchAngleDegrees, double launchDirectionDegrees, List<TrajectoryPoint> measuredTrajectory, List<TrajectoryPoint> simulatedTrajectory
});




}
/// @nodoc
class _$ShotResultCopyWithImpl<$Res>
    implements $ShotResultCopyWith<$Res> {
  _$ShotResultCopyWithImpl(this._self, this._then);

  final ShotResult _self;
  final $Res Function(ShotResult) _then;

/// Create a copy of ShotResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? carryDistanceMeters = null,Object? launchAngleDegrees = null,Object? launchDirectionDegrees = null,Object? measuredTrajectory = null,Object? simulatedTrajectory = null,}) {
  return _then(_self.copyWith(
carryDistanceMeters: null == carryDistanceMeters ? _self.carryDistanceMeters : carryDistanceMeters // ignore: cast_nullable_to_non_nullable
as double,launchAngleDegrees: null == launchAngleDegrees ? _self.launchAngleDegrees : launchAngleDegrees // ignore: cast_nullable_to_non_nullable
as double,launchDirectionDegrees: null == launchDirectionDegrees ? _self.launchDirectionDegrees : launchDirectionDegrees // ignore: cast_nullable_to_non_nullable
as double,measuredTrajectory: null == measuredTrajectory ? _self.measuredTrajectory : measuredTrajectory // ignore: cast_nullable_to_non_nullable
as List<TrajectoryPoint>,simulatedTrajectory: null == simulatedTrajectory ? _self.simulatedTrajectory : simulatedTrajectory // ignore: cast_nullable_to_non_nullable
as List<TrajectoryPoint>,
  ));
}

}


/// Adds pattern-matching-related methods to [ShotResult].
extension ShotResultPatterns on ShotResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShotResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShotResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShotResult value)  $default,){
final _that = this;
switch (_that) {
case _ShotResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShotResult value)?  $default,){
final _that = this;
switch (_that) {
case _ShotResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double carryDistanceMeters,  double launchAngleDegrees,  double launchDirectionDegrees,  List<TrajectoryPoint> measuredTrajectory,  List<TrajectoryPoint> simulatedTrajectory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShotResult() when $default != null:
return $default(_that.carryDistanceMeters,_that.launchAngleDegrees,_that.launchDirectionDegrees,_that.measuredTrajectory,_that.simulatedTrajectory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double carryDistanceMeters,  double launchAngleDegrees,  double launchDirectionDegrees,  List<TrajectoryPoint> measuredTrajectory,  List<TrajectoryPoint> simulatedTrajectory)  $default,) {final _that = this;
switch (_that) {
case _ShotResult():
return $default(_that.carryDistanceMeters,_that.launchAngleDegrees,_that.launchDirectionDegrees,_that.measuredTrajectory,_that.simulatedTrajectory);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double carryDistanceMeters,  double launchAngleDegrees,  double launchDirectionDegrees,  List<TrajectoryPoint> measuredTrajectory,  List<TrajectoryPoint> simulatedTrajectory)?  $default,) {final _that = this;
switch (_that) {
case _ShotResult() when $default != null:
return $default(_that.carryDistanceMeters,_that.launchAngleDegrees,_that.launchDirectionDegrees,_that.measuredTrajectory,_that.simulatedTrajectory);case _:
  return null;

}
}

}

/// @nodoc


class _ShotResult implements ShotResult {
  const _ShotResult({required this.carryDistanceMeters, required this.launchAngleDegrees, required this.launchDirectionDegrees, required final  List<TrajectoryPoint> measuredTrajectory, required final  List<TrajectoryPoint> simulatedTrajectory}): _measuredTrajectory = measuredTrajectory,_simulatedTrajectory = simulatedTrajectory;
  

@override final  double carryDistanceMeters;
@override final  double launchAngleDegrees;
@override final  double launchDirectionDegrees;
 final  List<TrajectoryPoint> _measuredTrajectory;
@override List<TrajectoryPoint> get measuredTrajectory {
  if (_measuredTrajectory is EqualUnmodifiableListView) return _measuredTrajectory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_measuredTrajectory);
}

 final  List<TrajectoryPoint> _simulatedTrajectory;
@override List<TrajectoryPoint> get simulatedTrajectory {
  if (_simulatedTrajectory is EqualUnmodifiableListView) return _simulatedTrajectory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_simulatedTrajectory);
}


/// Create a copy of ShotResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShotResultCopyWith<_ShotResult> get copyWith => __$ShotResultCopyWithImpl<_ShotResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShotResult&&(identical(other.carryDistanceMeters, carryDistanceMeters) || other.carryDistanceMeters == carryDistanceMeters)&&(identical(other.launchAngleDegrees, launchAngleDegrees) || other.launchAngleDegrees == launchAngleDegrees)&&(identical(other.launchDirectionDegrees, launchDirectionDegrees) || other.launchDirectionDegrees == launchDirectionDegrees)&&const DeepCollectionEquality().equals(other._measuredTrajectory, _measuredTrajectory)&&const DeepCollectionEquality().equals(other._simulatedTrajectory, _simulatedTrajectory));
}


@override
int get hashCode => Object.hash(runtimeType,carryDistanceMeters,launchAngleDegrees,launchDirectionDegrees,const DeepCollectionEquality().hash(_measuredTrajectory),const DeepCollectionEquality().hash(_simulatedTrajectory));

@override
String toString() {
  return 'ShotResult(carryDistanceMeters: $carryDistanceMeters, launchAngleDegrees: $launchAngleDegrees, launchDirectionDegrees: $launchDirectionDegrees, measuredTrajectory: $measuredTrajectory, simulatedTrajectory: $simulatedTrajectory)';
}


}

/// @nodoc
abstract mixin class _$ShotResultCopyWith<$Res> implements $ShotResultCopyWith<$Res> {
  factory _$ShotResultCopyWith(_ShotResult value, $Res Function(_ShotResult) _then) = __$ShotResultCopyWithImpl;
@override @useResult
$Res call({
 double carryDistanceMeters, double launchAngleDegrees, double launchDirectionDegrees, List<TrajectoryPoint> measuredTrajectory, List<TrajectoryPoint> simulatedTrajectory
});




}
/// @nodoc
class __$ShotResultCopyWithImpl<$Res>
    implements _$ShotResultCopyWith<$Res> {
  __$ShotResultCopyWithImpl(this._self, this._then);

  final _ShotResult _self;
  final $Res Function(_ShotResult) _then;

/// Create a copy of ShotResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? carryDistanceMeters = null,Object? launchAngleDegrees = null,Object? launchDirectionDegrees = null,Object? measuredTrajectory = null,Object? simulatedTrajectory = null,}) {
  return _then(_ShotResult(
carryDistanceMeters: null == carryDistanceMeters ? _self.carryDistanceMeters : carryDistanceMeters // ignore: cast_nullable_to_non_nullable
as double,launchAngleDegrees: null == launchAngleDegrees ? _self.launchAngleDegrees : launchAngleDegrees // ignore: cast_nullable_to_non_nullable
as double,launchDirectionDegrees: null == launchDirectionDegrees ? _self.launchDirectionDegrees : launchDirectionDegrees // ignore: cast_nullable_to_non_nullable
as double,measuredTrajectory: null == measuredTrajectory ? _self._measuredTrajectory : measuredTrajectory // ignore: cast_nullable_to_non_nullable
as List<TrajectoryPoint>,simulatedTrajectory: null == simulatedTrajectory ? _self._simulatedTrajectory : simulatedTrajectory // ignore: cast_nullable_to_non_nullable
as List<TrajectoryPoint>,
  ));
}


}

// dart format on
