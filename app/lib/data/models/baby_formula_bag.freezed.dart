// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'baby_formula_bag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BabyFormulaBag {

 int get id; String get brand; int get packGrams; DateTime get startedDate; String? get startedTime; int? get estimatedDailyGrams; int? get usageDays; int? get dailyAverage; bool get current; String? get remark;
/// Create a copy of BabyFormulaBag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyFormulaBagCopyWith<BabyFormulaBag> get copyWith => _$BabyFormulaBagCopyWithImpl<BabyFormulaBag>(this as BabyFormulaBag, _$identity);

  /// Serializes this BabyFormulaBag to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyFormulaBag;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyFormulaBag&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.brand, _this.brand) || other.brand == _this.brand)&&(identical(other.packGrams, _this.packGrams) || other.packGrams == _this.packGrams)&&(identical(other.startedDate, _this.startedDate) || other.startedDate == _this.startedDate)&&(identical(other.startedTime, _this.startedTime) || other.startedTime == _this.startedTime)&&(identical(other.estimatedDailyGrams, _this.estimatedDailyGrams) || other.estimatedDailyGrams == _this.estimatedDailyGrams)&&(identical(other.usageDays, _this.usageDays) || other.usageDays == _this.usageDays)&&(identical(other.dailyAverage, _this.dailyAverage) || other.dailyAverage == _this.dailyAverage)&&(identical(other.current, _this.current) || other.current == _this.current)&&(identical(other.remark, _this.remark) || other.remark == _this.remark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyFormulaBag;
  return Object.hash(runtimeType,_this.id,_this.brand,_this.packGrams,_this.startedDate,_this.startedTime,_this.estimatedDailyGrams,_this.usageDays,_this.dailyAverage,_this.current,_this.remark);
}

@override
String toString() {
  final _this = this as BabyFormulaBag;
  return 'BabyFormulaBag(id: ${_this.id}, brand: ${_this.brand}, packGrams: ${_this.packGrams}, startedDate: ${_this.startedDate}, startedTime: ${_this.startedTime}, estimatedDailyGrams: ${_this.estimatedDailyGrams}, usageDays: ${_this.usageDays}, dailyAverage: ${_this.dailyAverage}, current: ${_this.current}, remark: ${_this.remark})';
}


}

/// @nodoc
abstract mixin class $BabyFormulaBagCopyWith<$Res>  {
  factory $BabyFormulaBagCopyWith(BabyFormulaBag value, $Res Function(BabyFormulaBag) _then) = _$BabyFormulaBagCopyWithImpl;
@useResult
$Res call({
 int id, String brand, int packGrams, DateTime startedDate, String? startedTime, int? estimatedDailyGrams, int? usageDays, int? dailyAverage, bool current, String? remark
});




}
/// @nodoc
class _$BabyFormulaBagCopyWithImpl<$Res>
    implements $BabyFormulaBagCopyWith<$Res> {
  _$BabyFormulaBagCopyWithImpl(this._self, this._then);

  final BabyFormulaBag _self;
  final $Res Function(BabyFormulaBag) _then;

/// Create a copy of BabyFormulaBag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? brand = null,Object? packGrams = null,Object? startedDate = null,Object? startedTime = freezed,Object? estimatedDailyGrams = freezed,Object? usageDays = freezed,Object? dailyAverage = freezed,Object? current = null,Object? remark = freezed,}) {
  return _then(BabyFormulaBag(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,packGrams: null == packGrams ? _self.packGrams : packGrams // ignore: cast_nullable_to_non_nullable
as int,startedDate: null == startedDate ? _self.startedDate : startedDate // ignore: cast_nullable_to_non_nullable
as DateTime,startedTime: freezed == startedTime ? _self.startedTime : startedTime // ignore: cast_nullable_to_non_nullable
as String?,estimatedDailyGrams: freezed == estimatedDailyGrams ? _self.estimatedDailyGrams : estimatedDailyGrams // ignore: cast_nullable_to_non_nullable
as int?,usageDays: freezed == usageDays ? _self.usageDays : usageDays // ignore: cast_nullable_to_non_nullable
as int?,dailyAverage: freezed == dailyAverage ? _self.dailyAverage : dailyAverage // ignore: cast_nullable_to_non_nullable
as int?,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyFormulaBag].
extension BabyFormulaBagPatterns on BabyFormulaBag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyFormulaBag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyFormulaBag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyFormulaBag value)  $default,){
final _that = this;
switch (_that) {
case _BabyFormulaBag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyFormulaBag value)?  $default,){
final _that = this;
switch (_that) {
case _BabyFormulaBag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String brand,  int packGrams,  DateTime startedDate,  String? startedTime,  int? estimatedDailyGrams,  int? usageDays,  int? dailyAverage,  bool current,  String? remark)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyFormulaBag() when $default != null:
return $default(_that.id,_that.brand,_that.packGrams,_that.startedDate,_that.startedTime,_that.estimatedDailyGrams,_that.usageDays,_that.dailyAverage,_that.current,_that.remark);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String brand,  int packGrams,  DateTime startedDate,  String? startedTime,  int? estimatedDailyGrams,  int? usageDays,  int? dailyAverage,  bool current,  String? remark)  $default,) {final _that = this;
switch (_that) {
case _BabyFormulaBag():
return $default(_that.id,_that.brand,_that.packGrams,_that.startedDate,_that.startedTime,_that.estimatedDailyGrams,_that.usageDays,_that.dailyAverage,_that.current,_that.remark);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String brand,  int packGrams,  DateTime startedDate,  String? startedTime,  int? estimatedDailyGrams,  int? usageDays,  int? dailyAverage,  bool current,  String? remark)?  $default,) {final _that = this;
switch (_that) {
case _BabyFormulaBag() when $default != null:
return $default(_that.id,_that.brand,_that.packGrams,_that.startedDate,_that.startedTime,_that.estimatedDailyGrams,_that.usageDays,_that.dailyAverage,_that.current,_that.remark);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyFormulaBag implements BabyFormulaBag {
  const _BabyFormulaBag({required this.id, required this.brand, required this.packGrams, required this.startedDate, this.startedTime, this.estimatedDailyGrams, this.usageDays, this.dailyAverage, required this.current, this.remark});
  factory _BabyFormulaBag.fromJson(Map<String, dynamic> json) => _$BabyFormulaBagFromJson(json);

@override final  int id;
@override final  String brand;
@override final  int packGrams;
@override final  DateTime startedDate;
@override final  String? startedTime;
@override final  int? estimatedDailyGrams;
@override final  int? usageDays;
@override final  int? dailyAverage;
@override final  bool current;
@override final  String? remark;

/// Create a copy of BabyFormulaBag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyFormulaBagCopyWith<_BabyFormulaBag> get copyWith => __$BabyFormulaBagCopyWithImpl<_BabyFormulaBag>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyFormulaBagToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyFormulaBag&&(identical(other.id, id) || other.id == id)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.packGrams, packGrams) || other.packGrams == packGrams)&&(identical(other.startedDate, startedDate) || other.startedDate == startedDate)&&(identical(other.startedTime, startedTime) || other.startedTime == startedTime)&&(identical(other.estimatedDailyGrams, estimatedDailyGrams) || other.estimatedDailyGrams == estimatedDailyGrams)&&(identical(other.usageDays, usageDays) || other.usageDays == usageDays)&&(identical(other.dailyAverage, dailyAverage) || other.dailyAverage == dailyAverage)&&(identical(other.current, current) || other.current == current)&&(identical(other.remark, remark) || other.remark == remark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,brand,packGrams,startedDate,startedTime,estimatedDailyGrams,usageDays,dailyAverage,current,remark);
}

@override
String toString() {
    return 'BabyFormulaBag(id: $id, brand: $brand, packGrams: $packGrams, startedDate: $startedDate, startedTime: $startedTime, estimatedDailyGrams: $estimatedDailyGrams, usageDays: $usageDays, dailyAverage: $dailyAverage, current: $current, remark: $remark)';
}


}

/// @nodoc
abstract mixin class _$BabyFormulaBagCopyWith<$Res> implements $BabyFormulaBagCopyWith<$Res> {
  factory _$BabyFormulaBagCopyWith(_BabyFormulaBag value, $Res Function(_BabyFormulaBag) _then) = __$BabyFormulaBagCopyWithImpl;
@override @useResult
$Res call({
 int id, String brand, int packGrams, DateTime startedDate, String? startedTime, int? estimatedDailyGrams, int? usageDays, int? dailyAverage, bool current, String? remark
});




}
/// @nodoc
class __$BabyFormulaBagCopyWithImpl<$Res>
    implements _$BabyFormulaBagCopyWith<$Res> {
  __$BabyFormulaBagCopyWithImpl(this._self, this._then);

  final _BabyFormulaBag _self;
  final $Res Function(_BabyFormulaBag) _then;

/// Create a copy of BabyFormulaBag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? brand = null,Object? packGrams = null,Object? startedDate = null,Object? startedTime = freezed,Object? estimatedDailyGrams = freezed,Object? usageDays = freezed,Object? dailyAverage = freezed,Object? current = null,Object? remark = freezed,}) {
  return _then(_BabyFormulaBag(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,packGrams: null == packGrams ? _self.packGrams : packGrams // ignore: cast_nullable_to_non_nullable
as int,startedDate: null == startedDate ? _self.startedDate : startedDate // ignore: cast_nullable_to_non_nullable
as DateTime,startedTime: freezed == startedTime ? _self.startedTime : startedTime // ignore: cast_nullable_to_non_nullable
as String?,estimatedDailyGrams: freezed == estimatedDailyGrams ? _self.estimatedDailyGrams : estimatedDailyGrams // ignore: cast_nullable_to_non_nullable
as int?,usageDays: freezed == usageDays ? _self.usageDays : usageDays // ignore: cast_nullable_to_non_nullable
as int?,dailyAverage: freezed == dailyAverage ? _self.dailyAverage : dailyAverage // ignore: cast_nullable_to_non_nullable
as int?,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BabyFormulaCurrent {

 BabyFormulaBag? get bag; BabyFormulaEstimate? get estimate;
/// Create a copy of BabyFormulaCurrent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyFormulaCurrentCopyWith<BabyFormulaCurrent> get copyWith => _$BabyFormulaCurrentCopyWithImpl<BabyFormulaCurrent>(this as BabyFormulaCurrent, _$identity);

  /// Serializes this BabyFormulaCurrent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyFormulaCurrent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyFormulaCurrent&&(identical(other.bag, _this.bag) || other.bag == _this.bag)&&(identical(other.estimate, _this.estimate) || other.estimate == _this.estimate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyFormulaCurrent;
  return Object.hash(runtimeType,_this.bag,_this.estimate);
}

@override
String toString() {
  final _this = this as BabyFormulaCurrent;
  return 'BabyFormulaCurrent(bag: ${_this.bag}, estimate: ${_this.estimate})';
}


}

/// @nodoc
abstract mixin class $BabyFormulaCurrentCopyWith<$Res>  {
  factory $BabyFormulaCurrentCopyWith(BabyFormulaCurrent value, $Res Function(BabyFormulaCurrent) _then) = _$BabyFormulaCurrentCopyWithImpl;
@useResult
$Res call({
 BabyFormulaBag? bag, BabyFormulaEstimate? estimate
});


$BabyFormulaBagCopyWith<$Res>? get bag;$BabyFormulaEstimateCopyWith<$Res>? get estimate;

}
/// @nodoc
class _$BabyFormulaCurrentCopyWithImpl<$Res>
    implements $BabyFormulaCurrentCopyWith<$Res> {
  _$BabyFormulaCurrentCopyWithImpl(this._self, this._then);

  final BabyFormulaCurrent _self;
  final $Res Function(BabyFormulaCurrent) _then;

/// Create a copy of BabyFormulaCurrent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bag = freezed,Object? estimate = freezed,}) {
  return _then(BabyFormulaCurrent(
bag: freezed == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as BabyFormulaBag?,estimate: freezed == estimate ? _self.estimate : estimate // ignore: cast_nullable_to_non_nullable
as BabyFormulaEstimate?,
  ));
}
/// Create a copy of BabyFormulaCurrent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyFormulaBagCopyWith<$Res>? get bag {
    if (_self.bag == null) {
    return null;
  }

  return $BabyFormulaBagCopyWith<$Res>(_self.bag!, (value) {
    return _then(_self.copyWith(bag: value));
  });
}/// Create a copy of BabyFormulaCurrent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyFormulaEstimateCopyWith<$Res>? get estimate {
    if (_self.estimate == null) {
    return null;
  }

  return $BabyFormulaEstimateCopyWith<$Res>(_self.estimate!, (value) {
    return _then(_self.copyWith(estimate: value));
  });
}
}


/// Adds pattern-matching-related methods to [BabyFormulaCurrent].
extension BabyFormulaCurrentPatterns on BabyFormulaCurrent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyFormulaCurrent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyFormulaCurrent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyFormulaCurrent value)  $default,){
final _that = this;
switch (_that) {
case _BabyFormulaCurrent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyFormulaCurrent value)?  $default,){
final _that = this;
switch (_that) {
case _BabyFormulaCurrent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BabyFormulaBag? bag,  BabyFormulaEstimate? estimate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyFormulaCurrent() when $default != null:
return $default(_that.bag,_that.estimate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BabyFormulaBag? bag,  BabyFormulaEstimate? estimate)  $default,) {final _that = this;
switch (_that) {
case _BabyFormulaCurrent():
return $default(_that.bag,_that.estimate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BabyFormulaBag? bag,  BabyFormulaEstimate? estimate)?  $default,) {final _that = this;
switch (_that) {
case _BabyFormulaCurrent() when $default != null:
return $default(_that.bag,_that.estimate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyFormulaCurrent implements BabyFormulaCurrent {
  const _BabyFormulaCurrent({this.bag, this.estimate});
  factory _BabyFormulaCurrent.fromJson(Map<String, dynamic> json) => _$BabyFormulaCurrentFromJson(json);

@override final  BabyFormulaBag? bag;
@override final  BabyFormulaEstimate? estimate;

/// Create a copy of BabyFormulaCurrent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyFormulaCurrentCopyWith<_BabyFormulaCurrent> get copyWith => __$BabyFormulaCurrentCopyWithImpl<_BabyFormulaCurrent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyFormulaCurrentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyFormulaCurrent&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.estimate, estimate) || other.estimate == estimate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,bag,estimate);
}

@override
String toString() {
    return 'BabyFormulaCurrent(bag: $bag, estimate: $estimate)';
}


}

/// @nodoc
abstract mixin class _$BabyFormulaCurrentCopyWith<$Res> implements $BabyFormulaCurrentCopyWith<$Res> {
  factory _$BabyFormulaCurrentCopyWith(_BabyFormulaCurrent value, $Res Function(_BabyFormulaCurrent) _then) = __$BabyFormulaCurrentCopyWithImpl;
@override @useResult
$Res call({
 BabyFormulaBag? bag, BabyFormulaEstimate? estimate
});


@override $BabyFormulaBagCopyWith<$Res>? get bag;@override $BabyFormulaEstimateCopyWith<$Res>? get estimate;

}
/// @nodoc
class __$BabyFormulaCurrentCopyWithImpl<$Res>
    implements _$BabyFormulaCurrentCopyWith<$Res> {
  __$BabyFormulaCurrentCopyWithImpl(this._self, this._then);

  final _BabyFormulaCurrent _self;
  final $Res Function(_BabyFormulaCurrent) _then;

/// Create a copy of BabyFormulaCurrent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bag = freezed,Object? estimate = freezed,}) {
  return _then(_BabyFormulaCurrent(
bag: freezed == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as BabyFormulaBag?,estimate: freezed == estimate ? _self.estimate : estimate // ignore: cast_nullable_to_non_nullable
as BabyFormulaEstimate?,
  ));
}

/// Create a copy of BabyFormulaCurrent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyFormulaBagCopyWith<$Res>? get bag {
    if (_self.bag == null) {
    return null;
  }

  return $BabyFormulaBagCopyWith<$Res>(_self.bag!, (value) {
    return _then(_self.copyWith(bag: value));
  });
}/// Create a copy of BabyFormulaCurrent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyFormulaEstimateCopyWith<$Res>? get estimate {
    if (_self.estimate == null) {
    return null;
  }

  return $BabyFormulaEstimateCopyWith<$Res>(_self.estimate!, (value) {
    return _then(_self.copyWith(estimate: value));
  });
}
}

// dart format on
