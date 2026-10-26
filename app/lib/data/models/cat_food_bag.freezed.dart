// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cat_food_bag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatFoodBag {

 int get id; String get brand; int get packGrams; DateTime get startedDate; int? get usageDays; int? get dailyAverage; bool get current; String? get remark;
/// Create a copy of CatFoodBag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatFoodBagCopyWith<CatFoodBag> get copyWith => _$CatFoodBagCopyWithImpl<CatFoodBag>(this as CatFoodBag, _$identity);

  /// Serializes this CatFoodBag to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatFoodBag;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatFoodBag&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.brand, _this.brand) || other.brand == _this.brand)&&(identical(other.packGrams, _this.packGrams) || other.packGrams == _this.packGrams)&&(identical(other.startedDate, _this.startedDate) || other.startedDate == _this.startedDate)&&(identical(other.usageDays, _this.usageDays) || other.usageDays == _this.usageDays)&&(identical(other.dailyAverage, _this.dailyAverage) || other.dailyAverage == _this.dailyAverage)&&(identical(other.current, _this.current) || other.current == _this.current)&&(identical(other.remark, _this.remark) || other.remark == _this.remark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatFoodBag;
  return Object.hash(runtimeType,_this.id,_this.brand,_this.packGrams,_this.startedDate,_this.usageDays,_this.dailyAverage,_this.current,_this.remark);
}

@override
String toString() {
  final _this = this as CatFoodBag;
  return 'CatFoodBag(id: ${_this.id}, brand: ${_this.brand}, packGrams: ${_this.packGrams}, startedDate: ${_this.startedDate}, usageDays: ${_this.usageDays}, dailyAverage: ${_this.dailyAverage}, current: ${_this.current}, remark: ${_this.remark})';
}


}

/// @nodoc
abstract mixin class $CatFoodBagCopyWith<$Res>  {
  factory $CatFoodBagCopyWith(CatFoodBag value, $Res Function(CatFoodBag) _then) = _$CatFoodBagCopyWithImpl;
@useResult
$Res call({
 int id, String brand, int packGrams, DateTime startedDate, int? usageDays, int? dailyAverage, bool current, String? remark
});




}
/// @nodoc
class _$CatFoodBagCopyWithImpl<$Res>
    implements $CatFoodBagCopyWith<$Res> {
  _$CatFoodBagCopyWithImpl(this._self, this._then);

  final CatFoodBag _self;
  final $Res Function(CatFoodBag) _then;

/// Create a copy of CatFoodBag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? brand = null,Object? packGrams = null,Object? startedDate = null,Object? usageDays = freezed,Object? dailyAverage = freezed,Object? current = null,Object? remark = freezed,}) {
  return _then(CatFoodBag(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,packGrams: null == packGrams ? _self.packGrams : packGrams // ignore: cast_nullable_to_non_nullable
as int,startedDate: null == startedDate ? _self.startedDate : startedDate // ignore: cast_nullable_to_non_nullable
as DateTime,usageDays: freezed == usageDays ? _self.usageDays : usageDays // ignore: cast_nullable_to_non_nullable
as int?,dailyAverage: freezed == dailyAverage ? _self.dailyAverage : dailyAverage // ignore: cast_nullable_to_non_nullable
as int?,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatFoodBag].
extension CatFoodBagPatterns on CatFoodBag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatFoodBag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatFoodBag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatFoodBag value)  $default,){
final _that = this;
switch (_that) {
case _CatFoodBag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatFoodBag value)?  $default,){
final _that = this;
switch (_that) {
case _CatFoodBag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String brand,  int packGrams,  DateTime startedDate,  int? usageDays,  int? dailyAverage,  bool current,  String? remark)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatFoodBag() when $default != null:
return $default(_that.id,_that.brand,_that.packGrams,_that.startedDate,_that.usageDays,_that.dailyAverage,_that.current,_that.remark);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String brand,  int packGrams,  DateTime startedDate,  int? usageDays,  int? dailyAverage,  bool current,  String? remark)  $default,) {final _that = this;
switch (_that) {
case _CatFoodBag():
return $default(_that.id,_that.brand,_that.packGrams,_that.startedDate,_that.usageDays,_that.dailyAverage,_that.current,_that.remark);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String brand,  int packGrams,  DateTime startedDate,  int? usageDays,  int? dailyAverage,  bool current,  String? remark)?  $default,) {final _that = this;
switch (_that) {
case _CatFoodBag() when $default != null:
return $default(_that.id,_that.brand,_that.packGrams,_that.startedDate,_that.usageDays,_that.dailyAverage,_that.current,_that.remark);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatFoodBag implements CatFoodBag {
  const _CatFoodBag({required this.id, required this.brand, required this.packGrams, required this.startedDate, this.usageDays, this.dailyAverage, required this.current, this.remark});
  factory _CatFoodBag.fromJson(Map<String, dynamic> json) => _$CatFoodBagFromJson(json);

@override final  int id;
@override final  String brand;
@override final  int packGrams;
@override final  DateTime startedDate;
@override final  int? usageDays;
@override final  int? dailyAverage;
@override final  bool current;
@override final  String? remark;

/// Create a copy of CatFoodBag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatFoodBagCopyWith<_CatFoodBag> get copyWith => __$CatFoodBagCopyWithImpl<_CatFoodBag>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatFoodBagToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatFoodBag&&(identical(other.id, id) || other.id == id)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.packGrams, packGrams) || other.packGrams == packGrams)&&(identical(other.startedDate, startedDate) || other.startedDate == startedDate)&&(identical(other.usageDays, usageDays) || other.usageDays == usageDays)&&(identical(other.dailyAverage, dailyAverage) || other.dailyAverage == dailyAverage)&&(identical(other.current, current) || other.current == current)&&(identical(other.remark, remark) || other.remark == remark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,brand,packGrams,startedDate,usageDays,dailyAverage,current,remark);
}

@override
String toString() {
    return 'CatFoodBag(id: $id, brand: $brand, packGrams: $packGrams, startedDate: $startedDate, usageDays: $usageDays, dailyAverage: $dailyAverage, current: $current, remark: $remark)';
}


}

/// @nodoc
abstract mixin class _$CatFoodBagCopyWith<$Res> implements $CatFoodBagCopyWith<$Res> {
  factory _$CatFoodBagCopyWith(_CatFoodBag value, $Res Function(_CatFoodBag) _then) = __$CatFoodBagCopyWithImpl;
@override @useResult
$Res call({
 int id, String brand, int packGrams, DateTime startedDate, int? usageDays, int? dailyAverage, bool current, String? remark
});




}
/// @nodoc
class __$CatFoodBagCopyWithImpl<$Res>
    implements _$CatFoodBagCopyWith<$Res> {
  __$CatFoodBagCopyWithImpl(this._self, this._then);

  final _CatFoodBag _self;
  final $Res Function(_CatFoodBag) _then;

/// Create a copy of CatFoodBag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? brand = null,Object? packGrams = null,Object? startedDate = null,Object? usageDays = freezed,Object? dailyAverage = freezed,Object? current = null,Object? remark = freezed,}) {
  return _then(_CatFoodBag(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,packGrams: null == packGrams ? _self.packGrams : packGrams // ignore: cast_nullable_to_non_nullable
as int,startedDate: null == startedDate ? _self.startedDate : startedDate // ignore: cast_nullable_to_non_nullable
as DateTime,usageDays: freezed == usageDays ? _self.usageDays : usageDays // ignore: cast_nullable_to_non_nullable
as int?,dailyAverage: freezed == dailyAverage ? _self.dailyAverage : dailyAverage // ignore: cast_nullable_to_non_nullable
as int?,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CatFoodCurrent {

 CatFoodBag? get bag; CatFoodEstimate? get estimate;
/// Create a copy of CatFoodCurrent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatFoodCurrentCopyWith<CatFoodCurrent> get copyWith => _$CatFoodCurrentCopyWithImpl<CatFoodCurrent>(this as CatFoodCurrent, _$identity);

  /// Serializes this CatFoodCurrent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatFoodCurrent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatFoodCurrent&&(identical(other.bag, _this.bag) || other.bag == _this.bag)&&(identical(other.estimate, _this.estimate) || other.estimate == _this.estimate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatFoodCurrent;
  return Object.hash(runtimeType,_this.bag,_this.estimate);
}

@override
String toString() {
  final _this = this as CatFoodCurrent;
  return 'CatFoodCurrent(bag: ${_this.bag}, estimate: ${_this.estimate})';
}


}

/// @nodoc
abstract mixin class $CatFoodCurrentCopyWith<$Res>  {
  factory $CatFoodCurrentCopyWith(CatFoodCurrent value, $Res Function(CatFoodCurrent) _then) = _$CatFoodCurrentCopyWithImpl;
@useResult
$Res call({
 CatFoodBag? bag, CatFoodEstimate? estimate
});


$CatFoodBagCopyWith<$Res>? get bag;$CatFoodEstimateCopyWith<$Res>? get estimate;

}
/// @nodoc
class _$CatFoodCurrentCopyWithImpl<$Res>
    implements $CatFoodCurrentCopyWith<$Res> {
  _$CatFoodCurrentCopyWithImpl(this._self, this._then);

  final CatFoodCurrent _self;
  final $Res Function(CatFoodCurrent) _then;

/// Create a copy of CatFoodCurrent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bag = freezed,Object? estimate = freezed,}) {
  return _then(CatFoodCurrent(
bag: freezed == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as CatFoodBag?,estimate: freezed == estimate ? _self.estimate : estimate // ignore: cast_nullable_to_non_nullable
as CatFoodEstimate?,
  ));
}
/// Create a copy of CatFoodCurrent
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
}/// Create a copy of CatFoodCurrent
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


/// Adds pattern-matching-related methods to [CatFoodCurrent].
extension CatFoodCurrentPatterns on CatFoodCurrent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatFoodCurrent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatFoodCurrent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatFoodCurrent value)  $default,){
final _that = this;
switch (_that) {
case _CatFoodCurrent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatFoodCurrent value)?  $default,){
final _that = this;
switch (_that) {
case _CatFoodCurrent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CatFoodBag? bag,  CatFoodEstimate? estimate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatFoodCurrent() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CatFoodBag? bag,  CatFoodEstimate? estimate)  $default,) {final _that = this;
switch (_that) {
case _CatFoodCurrent():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CatFoodBag? bag,  CatFoodEstimate? estimate)?  $default,) {final _that = this;
switch (_that) {
case _CatFoodCurrent() when $default != null:
return $default(_that.bag,_that.estimate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatFoodCurrent implements CatFoodCurrent {
  const _CatFoodCurrent({this.bag, this.estimate});
  factory _CatFoodCurrent.fromJson(Map<String, dynamic> json) => _$CatFoodCurrentFromJson(json);

@override final  CatFoodBag? bag;
@override final  CatFoodEstimate? estimate;

/// Create a copy of CatFoodCurrent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatFoodCurrentCopyWith<_CatFoodCurrent> get copyWith => __$CatFoodCurrentCopyWithImpl<_CatFoodCurrent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatFoodCurrentToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatFoodCurrent&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.estimate, estimate) || other.estimate == estimate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,bag,estimate);
}

@override
String toString() {
    return 'CatFoodCurrent(bag: $bag, estimate: $estimate)';
}


}

/// @nodoc
abstract mixin class _$CatFoodCurrentCopyWith<$Res> implements $CatFoodCurrentCopyWith<$Res> {
  factory _$CatFoodCurrentCopyWith(_CatFoodCurrent value, $Res Function(_CatFoodCurrent) _then) = __$CatFoodCurrentCopyWithImpl;
@override @useResult
$Res call({
 CatFoodBag? bag, CatFoodEstimate? estimate
});


@override $CatFoodBagCopyWith<$Res>? get bag;@override $CatFoodEstimateCopyWith<$Res>? get estimate;

}
/// @nodoc
class __$CatFoodCurrentCopyWithImpl<$Res>
    implements _$CatFoodCurrentCopyWith<$Res> {
  __$CatFoodCurrentCopyWithImpl(this._self, this._then);

  final _CatFoodCurrent _self;
  final $Res Function(_CatFoodCurrent) _then;

/// Create a copy of CatFoodCurrent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bag = freezed,Object? estimate = freezed,}) {
  return _then(_CatFoodCurrent(
bag: freezed == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as CatFoodBag?,estimate: freezed == estimate ? _self.estimate : estimate // ignore: cast_nullable_to_non_nullable
as CatFoodEstimate?,
  ));
}

/// Create a copy of CatFoodCurrent
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
}/// Create a copy of CatFoodCurrent
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
