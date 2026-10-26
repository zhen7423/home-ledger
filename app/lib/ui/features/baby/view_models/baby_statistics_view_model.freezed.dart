// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'baby_statistics_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BabyStatisticsState {

/// 体格段：每个宝宝的最新一档与三段增量。
 BabyGrowthStatistics? get growth;/// 疫苗段：完成率、四态计数、待种与逾期两张小列表，外加跨宝宝的里程碑时间轴。
 BabyVaccineStatistics? get vaccine;
/// Create a copy of BabyStatisticsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyStatisticsStateCopyWith<BabyStatisticsState> get copyWith => _$BabyStatisticsStateCopyWithImpl<BabyStatisticsState>(this as BabyStatisticsState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BabyStatisticsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyStatisticsState&&(identical(other.growth, _this.growth) || other.growth == _this.growth)&&(identical(other.vaccine, _this.vaccine) || other.vaccine == _this.vaccine));
}


@override
int get hashCode {
  final _this = this as BabyStatisticsState;
  return Object.hash(runtimeType,_this.growth,_this.vaccine);
}

@override
String toString() {
  final _this = this as BabyStatisticsState;
  return 'BabyStatisticsState(growth: ${_this.growth}, vaccine: ${_this.vaccine})';
}


}

/// @nodoc
abstract mixin class $BabyStatisticsStateCopyWith<$Res>  {
  factory $BabyStatisticsStateCopyWith(BabyStatisticsState value, $Res Function(BabyStatisticsState) _then) = _$BabyStatisticsStateCopyWithImpl;
@useResult
$Res call({
 BabyGrowthStatistics? growth, BabyVaccineStatistics? vaccine
});


$BabyGrowthStatisticsCopyWith<$Res>? get growth;$BabyVaccineStatisticsCopyWith<$Res>? get vaccine;

}
/// @nodoc
class _$BabyStatisticsStateCopyWithImpl<$Res>
    implements $BabyStatisticsStateCopyWith<$Res> {
  _$BabyStatisticsStateCopyWithImpl(this._self, this._then);

  final BabyStatisticsState _self;
  final $Res Function(BabyStatisticsState) _then;

/// Create a copy of BabyStatisticsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? growth = freezed,Object? vaccine = freezed,}) {
  return _then(BabyStatisticsState(
growth: freezed == growth ? _self.growth : growth // ignore: cast_nullable_to_non_nullable
as BabyGrowthStatistics?,vaccine: freezed == vaccine ? _self.vaccine : vaccine // ignore: cast_nullable_to_non_nullable
as BabyVaccineStatistics?,
  ));
}
/// Create a copy of BabyStatisticsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthStatisticsCopyWith<$Res>? get growth {
    if (_self.growth == null) {
    return null;
  }

  return $BabyGrowthStatisticsCopyWith<$Res>(_self.growth!, (value) {
    return _then(_self.copyWith(growth: value));
  });
}/// Create a copy of BabyStatisticsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyVaccineStatisticsCopyWith<$Res>? get vaccine {
    if (_self.vaccine == null) {
    return null;
  }

  return $BabyVaccineStatisticsCopyWith<$Res>(_self.vaccine!, (value) {
    return _then(_self.copyWith(vaccine: value));
  });
}
}


/// Adds pattern-matching-related methods to [BabyStatisticsState].
extension BabyStatisticsStatePatterns on BabyStatisticsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyStatisticsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyStatisticsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyStatisticsState value)  $default,){
final _that = this;
switch (_that) {
case _BabyStatisticsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyStatisticsState value)?  $default,){
final _that = this;
switch (_that) {
case _BabyStatisticsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BabyGrowthStatistics? growth,  BabyVaccineStatistics? vaccine)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyStatisticsState() when $default != null:
return $default(_that.growth,_that.vaccine);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BabyGrowthStatistics? growth,  BabyVaccineStatistics? vaccine)  $default,) {final _that = this;
switch (_that) {
case _BabyStatisticsState():
return $default(_that.growth,_that.vaccine);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BabyGrowthStatistics? growth,  BabyVaccineStatistics? vaccine)?  $default,) {final _that = this;
switch (_that) {
case _BabyStatisticsState() when $default != null:
return $default(_that.growth,_that.vaccine);case _:
  return null;

}
}

}

/// @nodoc


class _BabyStatisticsState implements BabyStatisticsState {
  const _BabyStatisticsState({this.growth, this.vaccine});
  

/// 体格段：每个宝宝的最新一档与三段增量。
@override final  BabyGrowthStatistics? growth;
/// 疫苗段：完成率、四态计数、待种与逾期两张小列表，外加跨宝宝的里程碑时间轴。
@override final  BabyVaccineStatistics? vaccine;

/// Create a copy of BabyStatisticsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyStatisticsStateCopyWith<_BabyStatisticsState> get copyWith => __$BabyStatisticsStateCopyWithImpl<_BabyStatisticsState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyStatisticsState&&(identical(other.growth, growth) || other.growth == growth)&&(identical(other.vaccine, vaccine) || other.vaccine == vaccine));
}


@override
int get hashCode {
    return Object.hash(runtimeType,growth,vaccine);
}

@override
String toString() {
    return 'BabyStatisticsState(growth: $growth, vaccine: $vaccine)';
}


}

/// @nodoc
abstract mixin class _$BabyStatisticsStateCopyWith<$Res> implements $BabyStatisticsStateCopyWith<$Res> {
  factory _$BabyStatisticsStateCopyWith(_BabyStatisticsState value, $Res Function(_BabyStatisticsState) _then) = __$BabyStatisticsStateCopyWithImpl;
@override @useResult
$Res call({
 BabyGrowthStatistics? growth, BabyVaccineStatistics? vaccine
});


@override $BabyGrowthStatisticsCopyWith<$Res>? get growth;@override $BabyVaccineStatisticsCopyWith<$Res>? get vaccine;

}
/// @nodoc
class __$BabyStatisticsStateCopyWithImpl<$Res>
    implements _$BabyStatisticsStateCopyWith<$Res> {
  __$BabyStatisticsStateCopyWithImpl(this._self, this._then);

  final _BabyStatisticsState _self;
  final $Res Function(_BabyStatisticsState) _then;

/// Create a copy of BabyStatisticsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? growth = freezed,Object? vaccine = freezed,}) {
  return _then(_BabyStatisticsState(
growth: freezed == growth ? _self.growth : growth // ignore: cast_nullable_to_non_nullable
as BabyGrowthStatistics?,vaccine: freezed == vaccine ? _self.vaccine : vaccine // ignore: cast_nullable_to_non_nullable
as BabyVaccineStatistics?,
  ));
}

/// Create a copy of BabyStatisticsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthStatisticsCopyWith<$Res>? get growth {
    if (_self.growth == null) {
    return null;
  }

  return $BabyGrowthStatisticsCopyWith<$Res>(_self.growth!, (value) {
    return _then(_self.copyWith(growth: value));
  });
}/// Create a copy of BabyStatisticsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyVaccineStatisticsCopyWith<$Res>? get vaccine {
    if (_self.vaccine == null) {
    return null;
  }

  return $BabyVaccineStatisticsCopyWith<$Res>(_self.vaccine!, (value) {
    return _then(_self.copyWith(vaccine: value));
  });
}
}

// dart format on
