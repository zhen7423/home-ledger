// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'baby_home_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BabyHomeState {

 List<Baby> get babies;/// 每张宝宝卡上的最新体格与百分位段。`vaccineTodo` 的 `upcoming` / `overdueList`
/// 是疫苗待办那一卡的两栏——总览页不为它们另起一次请求（§5.4 快照的前提）。
 BabyGrowthStatistics? get latestGrowth; BabyVaccineStatistics? get vaccineTodo;/// 数据来自快照而不是这次请求（§5.4）。为 true 时页面挂离线横幅并显示「数据截至 XX」。
 bool get fromCache; DateTime? get savedAt;
/// Create a copy of BabyHomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyHomeStateCopyWith<BabyHomeState> get copyWith => _$BabyHomeStateCopyWithImpl<BabyHomeState>(this as BabyHomeState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BabyHomeState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyHomeState&&const DeepCollectionEquality().equals(other.babies, _this.babies)&&(identical(other.latestGrowth, _this.latestGrowth) || other.latestGrowth == _this.latestGrowth)&&(identical(other.vaccineTodo, _this.vaccineTodo) || other.vaccineTodo == _this.vaccineTodo)&&(identical(other.fromCache, _this.fromCache) || other.fromCache == _this.fromCache)&&(identical(other.savedAt, _this.savedAt) || other.savedAt == _this.savedAt));
}


@override
int get hashCode {
  final _this = this as BabyHomeState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.babies),_this.latestGrowth,_this.vaccineTodo,_this.fromCache,_this.savedAt);
}

@override
String toString() {
  final _this = this as BabyHomeState;
  return 'BabyHomeState(babies: ${_this.babies}, latestGrowth: ${_this.latestGrowth}, vaccineTodo: ${_this.vaccineTodo}, fromCache: ${_this.fromCache}, savedAt: ${_this.savedAt})';
}


}

/// @nodoc
abstract mixin class $BabyHomeStateCopyWith<$Res>  {
  factory $BabyHomeStateCopyWith(BabyHomeState value, $Res Function(BabyHomeState) _then) = _$BabyHomeStateCopyWithImpl;
@useResult
$Res call({
 List<Baby> babies, BabyGrowthStatistics? latestGrowth, BabyVaccineStatistics? vaccineTodo, bool fromCache, DateTime? savedAt
});


$BabyGrowthStatisticsCopyWith<$Res>? get latestGrowth;$BabyVaccineStatisticsCopyWith<$Res>? get vaccineTodo;

}
/// @nodoc
class _$BabyHomeStateCopyWithImpl<$Res>
    implements $BabyHomeStateCopyWith<$Res> {
  _$BabyHomeStateCopyWithImpl(this._self, this._then);

  final BabyHomeState _self;
  final $Res Function(BabyHomeState) _then;

/// Create a copy of BabyHomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? babies = null,Object? latestGrowth = freezed,Object? vaccineTodo = freezed,Object? fromCache = null,Object? savedAt = freezed,}) {
  return _then(BabyHomeState(
babies: null == babies ? _self.babies : babies // ignore: cast_nullable_to_non_nullable
as List<Baby>,latestGrowth: freezed == latestGrowth ? _self.latestGrowth : latestGrowth // ignore: cast_nullable_to_non_nullable
as BabyGrowthStatistics?,vaccineTodo: freezed == vaccineTodo ? _self.vaccineTodo : vaccineTodo // ignore: cast_nullable_to_non_nullable
as BabyVaccineStatistics?,fromCache: null == fromCache ? _self.fromCache : fromCache // ignore: cast_nullable_to_non_nullable
as bool,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of BabyHomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthStatisticsCopyWith<$Res>? get latestGrowth {
    if (_self.latestGrowth == null) {
    return null;
  }

  return $BabyGrowthStatisticsCopyWith<$Res>(_self.latestGrowth!, (value) {
    return _then(_self.copyWith(latestGrowth: value));
  });
}/// Create a copy of BabyHomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyVaccineStatisticsCopyWith<$Res>? get vaccineTodo {
    if (_self.vaccineTodo == null) {
    return null;
  }

  return $BabyVaccineStatisticsCopyWith<$Res>(_self.vaccineTodo!, (value) {
    return _then(_self.copyWith(vaccineTodo: value));
  });
}
}


/// Adds pattern-matching-related methods to [BabyHomeState].
extension BabyHomeStatePatterns on BabyHomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyHomeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyHomeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyHomeState value)  $default,){
final _that = this;
switch (_that) {
case _BabyHomeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyHomeState value)?  $default,){
final _that = this;
switch (_that) {
case _BabyHomeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Baby> babies,  BabyGrowthStatistics? latestGrowth,  BabyVaccineStatistics? vaccineTodo,  bool fromCache,  DateTime? savedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyHomeState() when $default != null:
return $default(_that.babies,_that.latestGrowth,_that.vaccineTodo,_that.fromCache,_that.savedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Baby> babies,  BabyGrowthStatistics? latestGrowth,  BabyVaccineStatistics? vaccineTodo,  bool fromCache,  DateTime? savedAt)  $default,) {final _that = this;
switch (_that) {
case _BabyHomeState():
return $default(_that.babies,_that.latestGrowth,_that.vaccineTodo,_that.fromCache,_that.savedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Baby> babies,  BabyGrowthStatistics? latestGrowth,  BabyVaccineStatistics? vaccineTodo,  bool fromCache,  DateTime? savedAt)?  $default,) {final _that = this;
switch (_that) {
case _BabyHomeState() when $default != null:
return $default(_that.babies,_that.latestGrowth,_that.vaccineTodo,_that.fromCache,_that.savedAt);case _:
  return null;

}
}

}

/// @nodoc


class _BabyHomeState implements BabyHomeState {
  const _BabyHomeState({ List<Baby> babies = const <Baby>[], this.latestGrowth, this.vaccineTodo, this.fromCache = false, this.savedAt}): _babies = babies;
  

 final  List<Baby> _babies;
@override@JsonKey() List<Baby> get babies {
  if (_babies is EqualUnmodifiableListView) return _babies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_babies);
}

/// 每张宝宝卡上的最新体格与百分位段。`vaccineTodo` 的 `upcoming` / `overdueList`
/// 是疫苗待办那一卡的两栏——总览页不为它们另起一次请求（§5.4 快照的前提）。
@override final  BabyGrowthStatistics? latestGrowth;
@override final  BabyVaccineStatistics? vaccineTodo;
/// 数据来自快照而不是这次请求（§5.4）。为 true 时页面挂离线横幅并显示「数据截至 XX」。
@override@JsonKey() final  bool fromCache;
@override final  DateTime? savedAt;

/// Create a copy of BabyHomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyHomeStateCopyWith<_BabyHomeState> get copyWith => __$BabyHomeStateCopyWithImpl<_BabyHomeState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyHomeState&&const DeepCollectionEquality().equals(other.babies, _babies)&&(identical(other.latestGrowth, latestGrowth) || other.latestGrowth == latestGrowth)&&(identical(other.vaccineTodo, vaccineTodo) || other.vaccineTodo == vaccineTodo)&&(identical(other.fromCache, fromCache) || other.fromCache == fromCache)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_babies),latestGrowth,vaccineTodo,fromCache,savedAt);
}

@override
String toString() {
    return 'BabyHomeState(babies: $babies, latestGrowth: $latestGrowth, vaccineTodo: $vaccineTodo, fromCache: $fromCache, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class _$BabyHomeStateCopyWith<$Res> implements $BabyHomeStateCopyWith<$Res> {
  factory _$BabyHomeStateCopyWith(_BabyHomeState value, $Res Function(_BabyHomeState) _then) = __$BabyHomeStateCopyWithImpl;
@override @useResult
$Res call({
 List<Baby> babies, BabyGrowthStatistics? latestGrowth, BabyVaccineStatistics? vaccineTodo, bool fromCache, DateTime? savedAt
});


@override $BabyGrowthStatisticsCopyWith<$Res>? get latestGrowth;@override $BabyVaccineStatisticsCopyWith<$Res>? get vaccineTodo;

}
/// @nodoc
class __$BabyHomeStateCopyWithImpl<$Res>
    implements _$BabyHomeStateCopyWith<$Res> {
  __$BabyHomeStateCopyWithImpl(this._self, this._then);

  final _BabyHomeState _self;
  final $Res Function(_BabyHomeState) _then;

/// Create a copy of BabyHomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? babies = null,Object? latestGrowth = freezed,Object? vaccineTodo = freezed,Object? fromCache = null,Object? savedAt = freezed,}) {
  return _then(_BabyHomeState(
babies: null == babies ? _self._babies : babies // ignore: cast_nullable_to_non_nullable
as List<Baby>,latestGrowth: freezed == latestGrowth ? _self.latestGrowth : latestGrowth // ignore: cast_nullable_to_non_nullable
as BabyGrowthStatistics?,vaccineTodo: freezed == vaccineTodo ? _self.vaccineTodo : vaccineTodo // ignore: cast_nullable_to_non_nullable
as BabyVaccineStatistics?,fromCache: null == fromCache ? _self.fromCache : fromCache // ignore: cast_nullable_to_non_nullable
as bool,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of BabyHomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthStatisticsCopyWith<$Res>? get latestGrowth {
    if (_self.latestGrowth == null) {
    return null;
  }

  return $BabyGrowthStatisticsCopyWith<$Res>(_self.latestGrowth!, (value) {
    return _then(_self.copyWith(latestGrowth: value));
  });
}/// Create a copy of BabyHomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyVaccineStatisticsCopyWith<$Res>? get vaccineTodo {
    if (_self.vaccineTodo == null) {
    return null;
  }

  return $BabyVaccineStatisticsCopyWith<$Res>(_self.vaccineTodo!, (value) {
    return _then(_self.copyWith(vaccineTodo: value));
  });
}
}

// dart format on
