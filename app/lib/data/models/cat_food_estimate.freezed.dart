// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cat_food_estimate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatFoodEstimate {

 int get usedDays; int get dailyAverage; int get consumedGrams; int get remainingGrams; int get remainingPercent; int get daysLeft; DateTime get depletionDate; bool get fromHistory; bool get overEstimate;
/// Create a copy of CatFoodEstimate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatFoodEstimateCopyWith<CatFoodEstimate> get copyWith => _$CatFoodEstimateCopyWithImpl<CatFoodEstimate>(this as CatFoodEstimate, _$identity);

  /// Serializes this CatFoodEstimate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatFoodEstimate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatFoodEstimate&&(identical(other.usedDays, _this.usedDays) || other.usedDays == _this.usedDays)&&(identical(other.dailyAverage, _this.dailyAverage) || other.dailyAverage == _this.dailyAverage)&&(identical(other.consumedGrams, _this.consumedGrams) || other.consumedGrams == _this.consumedGrams)&&(identical(other.remainingGrams, _this.remainingGrams) || other.remainingGrams == _this.remainingGrams)&&(identical(other.remainingPercent, _this.remainingPercent) || other.remainingPercent == _this.remainingPercent)&&(identical(other.daysLeft, _this.daysLeft) || other.daysLeft == _this.daysLeft)&&(identical(other.depletionDate, _this.depletionDate) || other.depletionDate == _this.depletionDate)&&(identical(other.fromHistory, _this.fromHistory) || other.fromHistory == _this.fromHistory)&&(identical(other.overEstimate, _this.overEstimate) || other.overEstimate == _this.overEstimate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatFoodEstimate;
  return Object.hash(runtimeType,_this.usedDays,_this.dailyAverage,_this.consumedGrams,_this.remainingGrams,_this.remainingPercent,_this.daysLeft,_this.depletionDate,_this.fromHistory,_this.overEstimate);
}

@override
String toString() {
  final _this = this as CatFoodEstimate;
  return 'CatFoodEstimate(usedDays: ${_this.usedDays}, dailyAverage: ${_this.dailyAverage}, consumedGrams: ${_this.consumedGrams}, remainingGrams: ${_this.remainingGrams}, remainingPercent: ${_this.remainingPercent}, daysLeft: ${_this.daysLeft}, depletionDate: ${_this.depletionDate}, fromHistory: ${_this.fromHistory}, overEstimate: ${_this.overEstimate})';
}


}

/// @nodoc
abstract mixin class $CatFoodEstimateCopyWith<$Res>  {
  factory $CatFoodEstimateCopyWith(CatFoodEstimate value, $Res Function(CatFoodEstimate) _then) = _$CatFoodEstimateCopyWithImpl;
@useResult
$Res call({
 int usedDays, int dailyAverage, int consumedGrams, int remainingGrams, int remainingPercent, int daysLeft, DateTime depletionDate, bool fromHistory, bool overEstimate
});




}
/// @nodoc
class _$CatFoodEstimateCopyWithImpl<$Res>
    implements $CatFoodEstimateCopyWith<$Res> {
  _$CatFoodEstimateCopyWithImpl(this._self, this._then);

  final CatFoodEstimate _self;
  final $Res Function(CatFoodEstimate) _then;

/// Create a copy of CatFoodEstimate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? usedDays = null,Object? dailyAverage = null,Object? consumedGrams = null,Object? remainingGrams = null,Object? remainingPercent = null,Object? daysLeft = null,Object? depletionDate = null,Object? fromHistory = null,Object? overEstimate = null,}) {
  return _then(CatFoodEstimate(
usedDays: null == usedDays ? _self.usedDays : usedDays // ignore: cast_nullable_to_non_nullable
as int,dailyAverage: null == dailyAverage ? _self.dailyAverage : dailyAverage // ignore: cast_nullable_to_non_nullable
as int,consumedGrams: null == consumedGrams ? _self.consumedGrams : consumedGrams // ignore: cast_nullable_to_non_nullable
as int,remainingGrams: null == remainingGrams ? _self.remainingGrams : remainingGrams // ignore: cast_nullable_to_non_nullable
as int,remainingPercent: null == remainingPercent ? _self.remainingPercent : remainingPercent // ignore: cast_nullable_to_non_nullable
as int,daysLeft: null == daysLeft ? _self.daysLeft : daysLeft // ignore: cast_nullable_to_non_nullable
as int,depletionDate: null == depletionDate ? _self.depletionDate : depletionDate // ignore: cast_nullable_to_non_nullable
as DateTime,fromHistory: null == fromHistory ? _self.fromHistory : fromHistory // ignore: cast_nullable_to_non_nullable
as bool,overEstimate: null == overEstimate ? _self.overEstimate : overEstimate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CatFoodEstimate].
extension CatFoodEstimatePatterns on CatFoodEstimate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatFoodEstimate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatFoodEstimate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatFoodEstimate value)  $default,){
final _that = this;
switch (_that) {
case _CatFoodEstimate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatFoodEstimate value)?  $default,){
final _that = this;
switch (_that) {
case _CatFoodEstimate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int usedDays,  int dailyAverage,  int consumedGrams,  int remainingGrams,  int remainingPercent,  int daysLeft,  DateTime depletionDate,  bool fromHistory,  bool overEstimate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatFoodEstimate() when $default != null:
return $default(_that.usedDays,_that.dailyAverage,_that.consumedGrams,_that.remainingGrams,_that.remainingPercent,_that.daysLeft,_that.depletionDate,_that.fromHistory,_that.overEstimate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int usedDays,  int dailyAverage,  int consumedGrams,  int remainingGrams,  int remainingPercent,  int daysLeft,  DateTime depletionDate,  bool fromHistory,  bool overEstimate)  $default,) {final _that = this;
switch (_that) {
case _CatFoodEstimate():
return $default(_that.usedDays,_that.dailyAverage,_that.consumedGrams,_that.remainingGrams,_that.remainingPercent,_that.daysLeft,_that.depletionDate,_that.fromHistory,_that.overEstimate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int usedDays,  int dailyAverage,  int consumedGrams,  int remainingGrams,  int remainingPercent,  int daysLeft,  DateTime depletionDate,  bool fromHistory,  bool overEstimate)?  $default,) {final _that = this;
switch (_that) {
case _CatFoodEstimate() when $default != null:
return $default(_that.usedDays,_that.dailyAverage,_that.consumedGrams,_that.remainingGrams,_that.remainingPercent,_that.daysLeft,_that.depletionDate,_that.fromHistory,_that.overEstimate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatFoodEstimate implements CatFoodEstimate {
  const _CatFoodEstimate({required this.usedDays, required this.dailyAverage, required this.consumedGrams, required this.remainingGrams, required this.remainingPercent, required this.daysLeft, required this.depletionDate, required this.fromHistory, required this.overEstimate});
  factory _CatFoodEstimate.fromJson(Map<String, dynamic> json) => _$CatFoodEstimateFromJson(json);

@override final  int usedDays;
@override final  int dailyAverage;
@override final  int consumedGrams;
@override final  int remainingGrams;
@override final  int remainingPercent;
@override final  int daysLeft;
@override final  DateTime depletionDate;
@override final  bool fromHistory;
@override final  bool overEstimate;

/// Create a copy of CatFoodEstimate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatFoodEstimateCopyWith<_CatFoodEstimate> get copyWith => __$CatFoodEstimateCopyWithImpl<_CatFoodEstimate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatFoodEstimateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatFoodEstimate&&(identical(other.usedDays, usedDays) || other.usedDays == usedDays)&&(identical(other.dailyAverage, dailyAverage) || other.dailyAverage == dailyAverage)&&(identical(other.consumedGrams, consumedGrams) || other.consumedGrams == consumedGrams)&&(identical(other.remainingGrams, remainingGrams) || other.remainingGrams == remainingGrams)&&(identical(other.remainingPercent, remainingPercent) || other.remainingPercent == remainingPercent)&&(identical(other.daysLeft, daysLeft) || other.daysLeft == daysLeft)&&(identical(other.depletionDate, depletionDate) || other.depletionDate == depletionDate)&&(identical(other.fromHistory, fromHistory) || other.fromHistory == fromHistory)&&(identical(other.overEstimate, overEstimate) || other.overEstimate == overEstimate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,usedDays,dailyAverage,consumedGrams,remainingGrams,remainingPercent,daysLeft,depletionDate,fromHistory,overEstimate);
}

@override
String toString() {
    return 'CatFoodEstimate(usedDays: $usedDays, dailyAverage: $dailyAverage, consumedGrams: $consumedGrams, remainingGrams: $remainingGrams, remainingPercent: $remainingPercent, daysLeft: $daysLeft, depletionDate: $depletionDate, fromHistory: $fromHistory, overEstimate: $overEstimate)';
}


}

/// @nodoc
abstract mixin class _$CatFoodEstimateCopyWith<$Res> implements $CatFoodEstimateCopyWith<$Res> {
  factory _$CatFoodEstimateCopyWith(_CatFoodEstimate value, $Res Function(_CatFoodEstimate) _then) = __$CatFoodEstimateCopyWithImpl;
@override @useResult
$Res call({
 int usedDays, int dailyAverage, int consumedGrams, int remainingGrams, int remainingPercent, int daysLeft, DateTime depletionDate, bool fromHistory, bool overEstimate
});




}
/// @nodoc
class __$CatFoodEstimateCopyWithImpl<$Res>
    implements _$CatFoodEstimateCopyWith<$Res> {
  __$CatFoodEstimateCopyWithImpl(this._self, this._then);

  final _CatFoodEstimate _self;
  final $Res Function(_CatFoodEstimate) _then;

/// Create a copy of CatFoodEstimate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? usedDays = null,Object? dailyAverage = null,Object? consumedGrams = null,Object? remainingGrams = null,Object? remainingPercent = null,Object? daysLeft = null,Object? depletionDate = null,Object? fromHistory = null,Object? overEstimate = null,}) {
  return _then(_CatFoodEstimate(
usedDays: null == usedDays ? _self.usedDays : usedDays // ignore: cast_nullable_to_non_nullable
as int,dailyAverage: null == dailyAverage ? _self.dailyAverage : dailyAverage // ignore: cast_nullable_to_non_nullable
as int,consumedGrams: null == consumedGrams ? _self.consumedGrams : consumedGrams // ignore: cast_nullable_to_non_nullable
as int,remainingGrams: null == remainingGrams ? _self.remainingGrams : remainingGrams // ignore: cast_nullable_to_non_nullable
as int,remainingPercent: null == remainingPercent ? _self.remainingPercent : remainingPercent // ignore: cast_nullable_to_non_nullable
as int,daysLeft: null == daysLeft ? _self.daysLeft : daysLeft // ignore: cast_nullable_to_non_nullable
as int,depletionDate: null == depletionDate ? _self.depletionDate : depletionDate // ignore: cast_nullable_to_non_nullable
as DateTime,fromHistory: null == fromHistory ? _self.fromHistory : fromHistory // ignore: cast_nullable_to_non_nullable
as bool,overEstimate: null == overEstimate ? _self.overEstimate : overEstimate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
