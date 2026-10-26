// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cat_overview_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CatOverviewState {

 List<Cat> get cats;/// 余量卡的两半：那一袋是什么牌子、还能吃多久。同时为 null 就是「一袋都还没开过」。
 CatFoodBag? get bag; CatFoodEstimate? get estimate; List<CatDueCountdownItem> get dueCountdown;/// 数据来自快照而不是这次请求（§5.4、验收用例 33）。为 true 时页面挂离线横幅并显示「数据截至 XX」。
 bool get fromCache; DateTime? get savedAt;
/// Create a copy of CatOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatOverviewStateCopyWith<CatOverviewState> get copyWith => _$CatOverviewStateCopyWithImpl<CatOverviewState>(this as CatOverviewState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CatOverviewState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatOverviewState&&const DeepCollectionEquality().equals(other.cats, _this.cats)&&(identical(other.bag, _this.bag) || other.bag == _this.bag)&&(identical(other.estimate, _this.estimate) || other.estimate == _this.estimate)&&const DeepCollectionEquality().equals(other.dueCountdown, _this.dueCountdown)&&(identical(other.fromCache, _this.fromCache) || other.fromCache == _this.fromCache)&&(identical(other.savedAt, _this.savedAt) || other.savedAt == _this.savedAt));
}


@override
int get hashCode {
  final _this = this as CatOverviewState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.cats),_this.bag,_this.estimate,const DeepCollectionEquality().hash(_this.dueCountdown),_this.fromCache,_this.savedAt);
}

@override
String toString() {
  final _this = this as CatOverviewState;
  return 'CatOverviewState(cats: ${_this.cats}, bag: ${_this.bag}, estimate: ${_this.estimate}, dueCountdown: ${_this.dueCountdown}, fromCache: ${_this.fromCache}, savedAt: ${_this.savedAt})';
}


}

/// @nodoc
abstract mixin class $CatOverviewStateCopyWith<$Res>  {
  factory $CatOverviewStateCopyWith(CatOverviewState value, $Res Function(CatOverviewState) _then) = _$CatOverviewStateCopyWithImpl;
@useResult
$Res call({
 List<Cat> cats, CatFoodBag? bag, CatFoodEstimate? estimate, List<CatDueCountdownItem> dueCountdown, bool fromCache, DateTime? savedAt
});


$CatFoodBagCopyWith<$Res>? get bag;$CatFoodEstimateCopyWith<$Res>? get estimate;

}
/// @nodoc
class _$CatOverviewStateCopyWithImpl<$Res>
    implements $CatOverviewStateCopyWith<$Res> {
  _$CatOverviewStateCopyWithImpl(this._self, this._then);

  final CatOverviewState _self;
  final $Res Function(CatOverviewState) _then;

/// Create a copy of CatOverviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cats = null,Object? bag = freezed,Object? estimate = freezed,Object? dueCountdown = null,Object? fromCache = null,Object? savedAt = freezed,}) {
  return _then(CatOverviewState(
cats: null == cats ? _self.cats : cats // ignore: cast_nullable_to_non_nullable
as List<Cat>,bag: freezed == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as CatFoodBag?,estimate: freezed == estimate ? _self.estimate : estimate // ignore: cast_nullable_to_non_nullable
as CatFoodEstimate?,dueCountdown: null == dueCountdown ? _self.dueCountdown : dueCountdown // ignore: cast_nullable_to_non_nullable
as List<CatDueCountdownItem>,fromCache: null == fromCache ? _self.fromCache : fromCache // ignore: cast_nullable_to_non_nullable
as bool,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of CatOverviewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatFoodBagCopyWith<$Res>? get bag {
    if (_self.bag == null) {
    return null;
  }

  return $CatFoodBagCopyWith<$Res>(_self.bag!, (value) {
    return _then(_self.copyWith(bag: value));
  });
}/// Create a copy of CatOverviewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatFoodEstimateCopyWith<$Res>? get estimate {
    if (_self.estimate == null) {
    return null;
  }

  return $CatFoodEstimateCopyWith<$Res>(_self.estimate!, (value) {
    return _then(_self.copyWith(estimate: value));
  });
}
}


/// Adds pattern-matching-related methods to [CatOverviewState].
extension CatOverviewStatePatterns on CatOverviewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatOverviewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatOverviewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatOverviewState value)  $default,){
final _that = this;
switch (_that) {
case _CatOverviewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatOverviewState value)?  $default,){
final _that = this;
switch (_that) {
case _CatOverviewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Cat> cats,  CatFoodBag? bag,  CatFoodEstimate? estimate,  List<CatDueCountdownItem> dueCountdown,  bool fromCache,  DateTime? savedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatOverviewState() when $default != null:
return $default(_that.cats,_that.bag,_that.estimate,_that.dueCountdown,_that.fromCache,_that.savedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Cat> cats,  CatFoodBag? bag,  CatFoodEstimate? estimate,  List<CatDueCountdownItem> dueCountdown,  bool fromCache,  DateTime? savedAt)  $default,) {final _that = this;
switch (_that) {
case _CatOverviewState():
return $default(_that.cats,_that.bag,_that.estimate,_that.dueCountdown,_that.fromCache,_that.savedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Cat> cats,  CatFoodBag? bag,  CatFoodEstimate? estimate,  List<CatDueCountdownItem> dueCountdown,  bool fromCache,  DateTime? savedAt)?  $default,) {final _that = this;
switch (_that) {
case _CatOverviewState() when $default != null:
return $default(_that.cats,_that.bag,_that.estimate,_that.dueCountdown,_that.fromCache,_that.savedAt);case _:
  return null;

}
}

}

/// @nodoc


class _CatOverviewState implements CatOverviewState {
  const _CatOverviewState({ List<Cat> cats = const <Cat>[], this.bag, this.estimate,  List<CatDueCountdownItem> dueCountdown = const <CatDueCountdownItem>[], this.fromCache = false, this.savedAt}): _cats = cats,_dueCountdown = dueCountdown;
  

 final  List<Cat> _cats;
@override@JsonKey() List<Cat> get cats {
  if (_cats is EqualUnmodifiableListView) return _cats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cats);
}

/// 余量卡的两半：那一袋是什么牌子、还能吃多久。同时为 null 就是「一袋都还没开过」。
@override final  CatFoodBag? bag;
@override final  CatFoodEstimate? estimate;
 final  List<CatDueCountdownItem> _dueCountdown;
@override@JsonKey() List<CatDueCountdownItem> get dueCountdown {
  if (_dueCountdown is EqualUnmodifiableListView) return _dueCountdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dueCountdown);
}

/// 数据来自快照而不是这次请求（§5.4、验收用例 33）。为 true 时页面挂离线横幅并显示「数据截至 XX」。
@override@JsonKey() final  bool fromCache;
@override final  DateTime? savedAt;

/// Create a copy of CatOverviewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatOverviewStateCopyWith<_CatOverviewState> get copyWith => __$CatOverviewStateCopyWithImpl<_CatOverviewState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatOverviewState&&const DeepCollectionEquality().equals(other.cats, _cats)&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.estimate, estimate) || other.estimate == estimate)&&const DeepCollectionEquality().equals(other.dueCountdown, _dueCountdown)&&(identical(other.fromCache, fromCache) || other.fromCache == fromCache)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_cats),bag,estimate,const DeepCollectionEquality().hash(_dueCountdown),fromCache,savedAt);
}

@override
String toString() {
    return 'CatOverviewState(cats: $cats, bag: $bag, estimate: $estimate, dueCountdown: $dueCountdown, fromCache: $fromCache, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class _$CatOverviewStateCopyWith<$Res> implements $CatOverviewStateCopyWith<$Res> {
  factory _$CatOverviewStateCopyWith(_CatOverviewState value, $Res Function(_CatOverviewState) _then) = __$CatOverviewStateCopyWithImpl;
@override @useResult
$Res call({
 List<Cat> cats, CatFoodBag? bag, CatFoodEstimate? estimate, List<CatDueCountdownItem> dueCountdown, bool fromCache, DateTime? savedAt
});


@override $CatFoodBagCopyWith<$Res>? get bag;@override $CatFoodEstimateCopyWith<$Res>? get estimate;

}
/// @nodoc
class __$CatOverviewStateCopyWithImpl<$Res>
    implements _$CatOverviewStateCopyWith<$Res> {
  __$CatOverviewStateCopyWithImpl(this._self, this._then);

  final _CatOverviewState _self;
  final $Res Function(_CatOverviewState) _then;

/// Create a copy of CatOverviewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cats = null,Object? bag = freezed,Object? estimate = freezed,Object? dueCountdown = null,Object? fromCache = null,Object? savedAt = freezed,}) {
  return _then(_CatOverviewState(
cats: null == cats ? _self._cats : cats // ignore: cast_nullable_to_non_nullable
as List<Cat>,bag: freezed == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as CatFoodBag?,estimate: freezed == estimate ? _self.estimate : estimate // ignore: cast_nullable_to_non_nullable
as CatFoodEstimate?,dueCountdown: null == dueCountdown ? _self._dueCountdown : dueCountdown // ignore: cast_nullable_to_non_nullable
as List<CatDueCountdownItem>,fromCache: null == fromCache ? _self.fromCache : fromCache // ignore: cast_nullable_to_non_nullable
as bool,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of CatOverviewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatFoodBagCopyWith<$Res>? get bag {
    if (_self.bag == null) {
    return null;
  }

  return $CatFoodBagCopyWith<$Res>(_self.bag!, (value) {
    return _then(_self.copyWith(bag: value));
  });
}/// Create a copy of CatOverviewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatFoodEstimateCopyWith<$Res>? get estimate {
    if (_self.estimate == null) {
    return null;
  }

  return $CatFoodEstimateCopyWith<$Res>(_self.estimate!, (value) {
    return _then(_self.copyWith(estimate: value));
  });
}
}

// dart format on
