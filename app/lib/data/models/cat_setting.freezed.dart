// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cat_setting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatSetting {

 int get internalMonths; int get externalMonths; int? get estimatedDailyGrams; bool get estimateTakenOverByHistory;
/// Create a copy of CatSetting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatSettingCopyWith<CatSetting> get copyWith => _$CatSettingCopyWithImpl<CatSetting>(this as CatSetting, _$identity);

  /// Serializes this CatSetting to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatSetting;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatSetting&&(identical(other.internalMonths, _this.internalMonths) || other.internalMonths == _this.internalMonths)&&(identical(other.externalMonths, _this.externalMonths) || other.externalMonths == _this.externalMonths)&&(identical(other.estimatedDailyGrams, _this.estimatedDailyGrams) || other.estimatedDailyGrams == _this.estimatedDailyGrams)&&(identical(other.estimateTakenOverByHistory, _this.estimateTakenOverByHistory) || other.estimateTakenOverByHistory == _this.estimateTakenOverByHistory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatSetting;
  return Object.hash(runtimeType,_this.internalMonths,_this.externalMonths,_this.estimatedDailyGrams,_this.estimateTakenOverByHistory);
}

@override
String toString() {
  final _this = this as CatSetting;
  return 'CatSetting(internalMonths: ${_this.internalMonths}, externalMonths: ${_this.externalMonths}, estimatedDailyGrams: ${_this.estimatedDailyGrams}, estimateTakenOverByHistory: ${_this.estimateTakenOverByHistory})';
}


}

/// @nodoc
abstract mixin class $CatSettingCopyWith<$Res>  {
  factory $CatSettingCopyWith(CatSetting value, $Res Function(CatSetting) _then) = _$CatSettingCopyWithImpl;
@useResult
$Res call({
 int internalMonths, int externalMonths, int? estimatedDailyGrams, bool estimateTakenOverByHistory
});




}
/// @nodoc
class _$CatSettingCopyWithImpl<$Res>
    implements $CatSettingCopyWith<$Res> {
  _$CatSettingCopyWithImpl(this._self, this._then);

  final CatSetting _self;
  final $Res Function(CatSetting) _then;

/// Create a copy of CatSetting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? internalMonths = null,Object? externalMonths = null,Object? estimatedDailyGrams = freezed,Object? estimateTakenOverByHistory = null,}) {
  return _then(CatSetting(
internalMonths: null == internalMonths ? _self.internalMonths : internalMonths // ignore: cast_nullable_to_non_nullable
as int,externalMonths: null == externalMonths ? _self.externalMonths : externalMonths // ignore: cast_nullable_to_non_nullable
as int,estimatedDailyGrams: freezed == estimatedDailyGrams ? _self.estimatedDailyGrams : estimatedDailyGrams // ignore: cast_nullable_to_non_nullable
as int?,estimateTakenOverByHistory: null == estimateTakenOverByHistory ? _self.estimateTakenOverByHistory : estimateTakenOverByHistory // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CatSetting].
extension CatSettingPatterns on CatSetting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatSetting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatSetting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatSetting value)  $default,){
final _that = this;
switch (_that) {
case _CatSetting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatSetting value)?  $default,){
final _that = this;
switch (_that) {
case _CatSetting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int internalMonths,  int externalMonths,  int? estimatedDailyGrams,  bool estimateTakenOverByHistory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatSetting() when $default != null:
return $default(_that.internalMonths,_that.externalMonths,_that.estimatedDailyGrams,_that.estimateTakenOverByHistory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int internalMonths,  int externalMonths,  int? estimatedDailyGrams,  bool estimateTakenOverByHistory)  $default,) {final _that = this;
switch (_that) {
case _CatSetting():
return $default(_that.internalMonths,_that.externalMonths,_that.estimatedDailyGrams,_that.estimateTakenOverByHistory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int internalMonths,  int externalMonths,  int? estimatedDailyGrams,  bool estimateTakenOverByHistory)?  $default,) {final _that = this;
switch (_that) {
case _CatSetting() when $default != null:
return $default(_that.internalMonths,_that.externalMonths,_that.estimatedDailyGrams,_that.estimateTakenOverByHistory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatSetting implements CatSetting {
  const _CatSetting({this.internalMonths = 3, this.externalMonths = 1, this.estimatedDailyGrams, this.estimateTakenOverByHistory = false});
  factory _CatSetting.fromJson(Map<String, dynamic> json) => _$CatSettingFromJson(json);

@override@JsonKey() final  int internalMonths;
@override@JsonKey() final  int externalMonths;
@override final  int? estimatedDailyGrams;
@override@JsonKey() final  bool estimateTakenOverByHistory;

/// Create a copy of CatSetting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatSettingCopyWith<_CatSetting> get copyWith => __$CatSettingCopyWithImpl<_CatSetting>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatSettingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatSetting&&(identical(other.internalMonths, internalMonths) || other.internalMonths == internalMonths)&&(identical(other.externalMonths, externalMonths) || other.externalMonths == externalMonths)&&(identical(other.estimatedDailyGrams, estimatedDailyGrams) || other.estimatedDailyGrams == estimatedDailyGrams)&&(identical(other.estimateTakenOverByHistory, estimateTakenOverByHistory) || other.estimateTakenOverByHistory == estimateTakenOverByHistory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,internalMonths,externalMonths,estimatedDailyGrams,estimateTakenOverByHistory);
}

@override
String toString() {
    return 'CatSetting(internalMonths: $internalMonths, externalMonths: $externalMonths, estimatedDailyGrams: $estimatedDailyGrams, estimateTakenOverByHistory: $estimateTakenOverByHistory)';
}


}

/// @nodoc
abstract mixin class _$CatSettingCopyWith<$Res> implements $CatSettingCopyWith<$Res> {
  factory _$CatSettingCopyWith(_CatSetting value, $Res Function(_CatSetting) _then) = __$CatSettingCopyWithImpl;
@override @useResult
$Res call({
 int internalMonths, int externalMonths, int? estimatedDailyGrams, bool estimateTakenOverByHistory
});




}
/// @nodoc
class __$CatSettingCopyWithImpl<$Res>
    implements _$CatSettingCopyWith<$Res> {
  __$CatSettingCopyWithImpl(this._self, this._then);

  final _CatSetting _self;
  final $Res Function(_CatSetting) _then;

/// Create a copy of CatSetting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? internalMonths = null,Object? externalMonths = null,Object? estimatedDailyGrams = freezed,Object? estimateTakenOverByHistory = null,}) {
  return _then(_CatSetting(
internalMonths: null == internalMonths ? _self.internalMonths : internalMonths // ignore: cast_nullable_to_non_nullable
as int,externalMonths: null == externalMonths ? _self.externalMonths : externalMonths // ignore: cast_nullable_to_non_nullable
as int,estimatedDailyGrams: freezed == estimatedDailyGrams ? _self.estimatedDailyGrams : estimatedDailyGrams // ignore: cast_nullable_to_non_nullable
as int?,estimateTakenOverByHistory: null == estimateTakenOverByHistory ? _self.estimateTakenOverByHistory : estimateTakenOverByHistory // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
