// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cat_statistics_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatStatisticsState {

 StatisticsRange get range; DateTime? get customStart; DateTime? get customEnd; CatFoodConsumption? get food; CatDewormingStatistics? get deworming;
/// Create a copy of CatStatisticsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatStatisticsStateCopyWith<CatStatisticsState> get copyWith => _$CatStatisticsStateCopyWithImpl<CatStatisticsState>(this as CatStatisticsState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CatStatisticsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatStatisticsState&&(identical(other.range, _this.range) || other.range == _this.range)&&(identical(other.customStart, _this.customStart) || other.customStart == _this.customStart)&&(identical(other.customEnd, _this.customEnd) || other.customEnd == _this.customEnd)&&(identical(other.food, _this.food) || other.food == _this.food)&&(identical(other.deworming, _this.deworming) || other.deworming == _this.deworming));
}


@override
int get hashCode {
  final _this = this as CatStatisticsState;
  return Object.hash(runtimeType,_this.range,_this.customStart,_this.customEnd,_this.food,_this.deworming);
}

@override
String toString() {
  final _this = this as CatStatisticsState;
  return 'CatStatisticsState(range: ${_this.range}, customStart: ${_this.customStart}, customEnd: ${_this.customEnd}, food: ${_this.food}, deworming: ${_this.deworming})';
}


}

/// @nodoc
abstract mixin class $CatStatisticsStateCopyWith<$Res>  {
  factory $CatStatisticsStateCopyWith(CatStatisticsState value, $Res Function(CatStatisticsState) _then) = _$CatStatisticsStateCopyWithImpl;
@useResult
$Res call({
 StatisticsRange range, DateTime? customStart, DateTime? customEnd, CatFoodConsumption? food, CatDewormingStatistics? deworming
});


$CatFoodConsumptionCopyWith<$Res>? get food;$CatDewormingStatisticsCopyWith<$Res>? get deworming;

}
/// @nodoc
class _$CatStatisticsStateCopyWithImpl<$Res>
    implements $CatStatisticsStateCopyWith<$Res> {
  _$CatStatisticsStateCopyWithImpl(this._self, this._then);

  final CatStatisticsState _self;
  final $Res Function(CatStatisticsState) _then;

/// Create a copy of CatStatisticsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? range = null,Object? customStart = freezed,Object? customEnd = freezed,Object? food = freezed,Object? deworming = freezed,}) {
  return _then(CatStatisticsState(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as StatisticsRange,customStart: freezed == customStart ? _self.customStart : customStart // ignore: cast_nullable_to_non_nullable
as DateTime?,customEnd: freezed == customEnd ? _self.customEnd : customEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,food: freezed == food ? _self.food : food // ignore: cast_nullable_to_non_nullable
as CatFoodConsumption?,deworming: freezed == deworming ? _self.deworming : deworming // ignore: cast_nullable_to_non_nullable
as CatDewormingStatistics?,
  ));
}
/// Create a copy of CatStatisticsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatFoodConsumptionCopyWith<$Res>? get food {
    if (_self.food == null) {
    return null;
  }

  return $CatFoodConsumptionCopyWith<$Res>(_self.food!, (value) {
    return _then(_self.copyWith(food: value));
  });
}/// Create a copy of CatStatisticsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatDewormingStatisticsCopyWith<$Res>? get deworming {
    if (_self.deworming == null) {
    return null;
  }

  return $CatDewormingStatisticsCopyWith<$Res>(_self.deworming!, (value) {
    return _then(_self.copyWith(deworming: value));
  });
}
}


/// Adds pattern-matching-related methods to [CatStatisticsState].
extension CatStatisticsStatePatterns on CatStatisticsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatStatisticsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatStatisticsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatStatisticsState value)  $default,){
final _that = this;
switch (_that) {
case _CatStatisticsState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatStatisticsState value)?  $default,){
final _that = this;
switch (_that) {
case _CatStatisticsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StatisticsRange range,  DateTime? customStart,  DateTime? customEnd,  CatFoodConsumption? food,  CatDewormingStatistics? deworming)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatStatisticsState() when $default != null:
return $default(_that.range,_that.customStart,_that.customEnd,_that.food,_that.deworming);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StatisticsRange range,  DateTime? customStart,  DateTime? customEnd,  CatFoodConsumption? food,  CatDewormingStatistics? deworming)  $default,) {final _that = this;
switch (_that) {
case _CatStatisticsState():
return $default(_that.range,_that.customStart,_that.customEnd,_that.food,_that.deworming);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StatisticsRange range,  DateTime? customStart,  DateTime? customEnd,  CatFoodConsumption? food,  CatDewormingStatistics? deworming)?  $default,) {final _that = this;
switch (_that) {
case _CatStatisticsState() when $default != null:
return $default(_that.range,_that.customStart,_that.customEnd,_that.food,_that.deworming);case _:
  return null;

}
}

}

/// @nodoc


class _CatStatisticsState implements CatStatisticsState {
  const _CatStatisticsState({this.range = StatisticsRange.thisMonth, this.customStart, this.customEnd, this.food, this.deworming});
  

@override@JsonKey() final  StatisticsRange range;
@override final  DateTime? customStart;
@override final  DateTime? customEnd;
@override final  CatFoodConsumption? food;
@override final  CatDewormingStatistics? deworming;

/// Create a copy of CatStatisticsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatStatisticsStateCopyWith<_CatStatisticsState> get copyWith => __$CatStatisticsStateCopyWithImpl<_CatStatisticsState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatStatisticsState&&(identical(other.range, range) || other.range == range)&&(identical(other.customStart, customStart) || other.customStart == customStart)&&(identical(other.customEnd, customEnd) || other.customEnd == customEnd)&&(identical(other.food, food) || other.food == food)&&(identical(other.deworming, deworming) || other.deworming == deworming));
}


@override
int get hashCode {
    return Object.hash(runtimeType,range,customStart,customEnd,food,deworming);
}

@override
String toString() {
    return 'CatStatisticsState(range: $range, customStart: $customStart, customEnd: $customEnd, food: $food, deworming: $deworming)';
}


}

/// @nodoc
abstract mixin class _$CatStatisticsStateCopyWith<$Res> implements $CatStatisticsStateCopyWith<$Res> {
  factory _$CatStatisticsStateCopyWith(_CatStatisticsState value, $Res Function(_CatStatisticsState) _then) = __$CatStatisticsStateCopyWithImpl;
@override @useResult
$Res call({
 StatisticsRange range, DateTime? customStart, DateTime? customEnd, CatFoodConsumption? food, CatDewormingStatistics? deworming
});


@override $CatFoodConsumptionCopyWith<$Res>? get food;@override $CatDewormingStatisticsCopyWith<$Res>? get deworming;

}
/// @nodoc
class __$CatStatisticsStateCopyWithImpl<$Res>
    implements _$CatStatisticsStateCopyWith<$Res> {
  __$CatStatisticsStateCopyWithImpl(this._self, this._then);

  final _CatStatisticsState _self;
  final $Res Function(_CatStatisticsState) _then;

/// Create a copy of CatStatisticsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? range = null,Object? customStart = freezed,Object? customEnd = freezed,Object? food = freezed,Object? deworming = freezed,}) {
  return _then(_CatStatisticsState(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as StatisticsRange,customStart: freezed == customStart ? _self.customStart : customStart // ignore: cast_nullable_to_non_nullable
as DateTime?,customEnd: freezed == customEnd ? _self.customEnd : customEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,food: freezed == food ? _self.food : food // ignore: cast_nullable_to_non_nullable
as CatFoodConsumption?,deworming: freezed == deworming ? _self.deworming : deworming // ignore: cast_nullable_to_non_nullable
as CatDewormingStatistics?,
  ));
}

/// Create a copy of CatStatisticsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatFoodConsumptionCopyWith<$Res>? get food {
    if (_self.food == null) {
    return null;
  }

  return $CatFoodConsumptionCopyWith<$Res>(_self.food!, (value) {
    return _then(_self.copyWith(food: value));
  });
}/// Create a copy of CatStatisticsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatDewormingStatisticsCopyWith<$Res>? get deworming {
    if (_self.deworming == null) {
    return null;
  }

  return $CatDewormingStatisticsCopyWith<$Res>(_self.deworming!, (value) {
    return _then(_self.copyWith(deworming: value));
  });
}
}

// dart format on
