// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'period_value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PeriodValue {

 int? get intervalDays; List<int>? get weekdays; List<int>? get daysOfMonth; int? get month;
/// Create a copy of PeriodValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodValueCopyWith<PeriodValue> get copyWith => _$PeriodValueCopyWithImpl<PeriodValue>(this as PeriodValue, _$identity);

  /// Serializes this PeriodValue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PeriodValue;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodValue&&(identical(other.intervalDays, _this.intervalDays) || other.intervalDays == _this.intervalDays)&&const DeepCollectionEquality().equals(other.weekdays, _this.weekdays)&&const DeepCollectionEquality().equals(other.daysOfMonth, _this.daysOfMonth)&&(identical(other.month, _this.month) || other.month == _this.month));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PeriodValue;
  return Object.hash(runtimeType,_this.intervalDays,const DeepCollectionEquality().hash(_this.weekdays),const DeepCollectionEquality().hash(_this.daysOfMonth),_this.month);
}

@override
String toString() {
  final _this = this as PeriodValue;
  return 'PeriodValue(intervalDays: ${_this.intervalDays}, weekdays: ${_this.weekdays}, daysOfMonth: ${_this.daysOfMonth}, month: ${_this.month})';
}


}

/// @nodoc
abstract mixin class $PeriodValueCopyWith<$Res>  {
  factory $PeriodValueCopyWith(PeriodValue value, $Res Function(PeriodValue) _then) = _$PeriodValueCopyWithImpl;
@useResult
$Res call({
 int? intervalDays, List<int>? weekdays, List<int>? daysOfMonth, int? month
});




}
/// @nodoc
class _$PeriodValueCopyWithImpl<$Res>
    implements $PeriodValueCopyWith<$Res> {
  _$PeriodValueCopyWithImpl(this._self, this._then);

  final PeriodValue _self;
  final $Res Function(PeriodValue) _then;

/// Create a copy of PeriodValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? intervalDays = freezed,Object? weekdays = freezed,Object? daysOfMonth = freezed,Object? month = freezed,}) {
  return _then(PeriodValue(
intervalDays: freezed == intervalDays ? _self.intervalDays : intervalDays // ignore: cast_nullable_to_non_nullable
as int?,weekdays: freezed == weekdays ? _self.weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>?,daysOfMonth: freezed == daysOfMonth ? _self.daysOfMonth : daysOfMonth // ignore: cast_nullable_to_non_nullable
as List<int>?,month: freezed == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodValue].
extension PeriodValuePatterns on PeriodValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodValue value)  $default,){
final _that = this;
switch (_that) {
case _PeriodValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodValue value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? intervalDays,  List<int>? weekdays,  List<int>? daysOfMonth,  int? month)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodValue() when $default != null:
return $default(_that.intervalDays,_that.weekdays,_that.daysOfMonth,_that.month);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? intervalDays,  List<int>? weekdays,  List<int>? daysOfMonth,  int? month)  $default,) {final _that = this;
switch (_that) {
case _PeriodValue():
return $default(_that.intervalDays,_that.weekdays,_that.daysOfMonth,_that.month);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? intervalDays,  List<int>? weekdays,  List<int>? daysOfMonth,  int? month)?  $default,) {final _that = this;
switch (_that) {
case _PeriodValue() when $default != null:
return $default(_that.intervalDays,_that.weekdays,_that.daysOfMonth,_that.month);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodValue implements PeriodValue {
  const _PeriodValue({this.intervalDays,  List<int>? weekdays,  List<int>? daysOfMonth, this.month}): _weekdays = weekdays,_daysOfMonth = daysOfMonth;
  factory _PeriodValue.fromJson(Map<String, dynamic> json) => _$PeriodValueFromJson(json);

@override final  int? intervalDays;
 final  List<int>? _weekdays;
@override List<int>? get weekdays {
  final value = _weekdays;
  if (value == null) return null;
  if (_weekdays is EqualUnmodifiableListView) return _weekdays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<int>? _daysOfMonth;
@override List<int>? get daysOfMonth {
  final value = _daysOfMonth;
  if (value == null) return null;
  if (_daysOfMonth is EqualUnmodifiableListView) return _daysOfMonth;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? month;

/// Create a copy of PeriodValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodValueCopyWith<_PeriodValue> get copyWith => __$PeriodValueCopyWithImpl<_PeriodValue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodValueToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodValue&&(identical(other.intervalDays, intervalDays) || other.intervalDays == intervalDays)&&const DeepCollectionEquality().equals(other.weekdays, _weekdays)&&const DeepCollectionEquality().equals(other.daysOfMonth, _daysOfMonth)&&(identical(other.month, month) || other.month == month));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,intervalDays,const DeepCollectionEquality().hash(_weekdays),const DeepCollectionEquality().hash(_daysOfMonth),month);
}

@override
String toString() {
    return 'PeriodValue(intervalDays: $intervalDays, weekdays: $weekdays, daysOfMonth: $daysOfMonth, month: $month)';
}


}

/// @nodoc
abstract mixin class _$PeriodValueCopyWith<$Res> implements $PeriodValueCopyWith<$Res> {
  factory _$PeriodValueCopyWith(_PeriodValue value, $Res Function(_PeriodValue) _then) = __$PeriodValueCopyWithImpl;
@override @useResult
$Res call({
 int? intervalDays, List<int>? weekdays, List<int>? daysOfMonth, int? month
});




}
/// @nodoc
class __$PeriodValueCopyWithImpl<$Res>
    implements _$PeriodValueCopyWith<$Res> {
  __$PeriodValueCopyWithImpl(this._self, this._then);

  final _PeriodValue _self;
  final $Res Function(_PeriodValue) _then;

/// Create a copy of PeriodValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? intervalDays = freezed,Object? weekdays = freezed,Object? daysOfMonth = freezed,Object? month = freezed,}) {
  return _then(_PeriodValue(
intervalDays: freezed == intervalDays ? _self.intervalDays : intervalDays // ignore: cast_nullable_to_non_nullable
as int?,weekdays: freezed == weekdays ? _self._weekdays : weekdays // ignore: cast_nullable_to_non_nullable
as List<int>?,daysOfMonth: freezed == daysOfMonth ? _self._daysOfMonth : daysOfMonth // ignore: cast_nullable_to_non_nullable
as List<int>?,month: freezed == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
