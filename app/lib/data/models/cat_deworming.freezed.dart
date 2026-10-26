// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cat_deworming.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatDeworming {

 int get id; int get catId; String get catName; String get type; DateTime get doneDate; String get medicine; String? get dosage; DateTime get nextDate; int? get daysToDue; int? get overdueDays; String? get remark;
/// Create a copy of CatDeworming
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatDewormingCopyWith<CatDeworming> get copyWith => _$CatDewormingCopyWithImpl<CatDeworming>(this as CatDeworming, _$identity);

  /// Serializes this CatDeworming to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatDeworming;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatDeworming&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.catId, _this.catId) || other.catId == _this.catId)&&(identical(other.catName, _this.catName) || other.catName == _this.catName)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.doneDate, _this.doneDate) || other.doneDate == _this.doneDate)&&(identical(other.medicine, _this.medicine) || other.medicine == _this.medicine)&&(identical(other.dosage, _this.dosage) || other.dosage == _this.dosage)&&(identical(other.nextDate, _this.nextDate) || other.nextDate == _this.nextDate)&&(identical(other.daysToDue, _this.daysToDue) || other.daysToDue == _this.daysToDue)&&(identical(other.overdueDays, _this.overdueDays) || other.overdueDays == _this.overdueDays)&&(identical(other.remark, _this.remark) || other.remark == _this.remark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatDeworming;
  return Object.hash(runtimeType,_this.id,_this.catId,_this.catName,_this.type,_this.doneDate,_this.medicine,_this.dosage,_this.nextDate,_this.daysToDue,_this.overdueDays,_this.remark);
}

@override
String toString() {
  final _this = this as CatDeworming;
  return 'CatDeworming(id: ${_this.id}, catId: ${_this.catId}, catName: ${_this.catName}, type: ${_this.type}, doneDate: ${_this.doneDate}, medicine: ${_this.medicine}, dosage: ${_this.dosage}, nextDate: ${_this.nextDate}, daysToDue: ${_this.daysToDue}, overdueDays: ${_this.overdueDays}, remark: ${_this.remark})';
}


}

/// @nodoc
abstract mixin class $CatDewormingCopyWith<$Res>  {
  factory $CatDewormingCopyWith(CatDeworming value, $Res Function(CatDeworming) _then) = _$CatDewormingCopyWithImpl;
@useResult
$Res call({
 int id, int catId, String catName, String type, DateTime doneDate, String medicine, String? dosage, DateTime nextDate, int? daysToDue, int? overdueDays, String? remark
});




}
/// @nodoc
class _$CatDewormingCopyWithImpl<$Res>
    implements $CatDewormingCopyWith<$Res> {
  _$CatDewormingCopyWithImpl(this._self, this._then);

  final CatDeworming _self;
  final $Res Function(CatDeworming) _then;

/// Create a copy of CatDeworming
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? catId = null,Object? catName = null,Object? type = null,Object? doneDate = null,Object? medicine = null,Object? dosage = freezed,Object? nextDate = null,Object? daysToDue = freezed,Object? overdueDays = freezed,Object? remark = freezed,}) {
  return _then(CatDeworming(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,catId: null == catId ? _self.catId : catId // ignore: cast_nullable_to_non_nullable
as int,catName: null == catName ? _self.catName : catName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,doneDate: null == doneDate ? _self.doneDate : doneDate // ignore: cast_nullable_to_non_nullable
as DateTime,medicine: null == medicine ? _self.medicine : medicine // ignore: cast_nullable_to_non_nullable
as String,dosage: freezed == dosage ? _self.dosage : dosage // ignore: cast_nullable_to_non_nullable
as String?,nextDate: null == nextDate ? _self.nextDate : nextDate // ignore: cast_nullable_to_non_nullable
as DateTime,daysToDue: freezed == daysToDue ? _self.daysToDue : daysToDue // ignore: cast_nullable_to_non_nullable
as int?,overdueDays: freezed == overdueDays ? _self.overdueDays : overdueDays // ignore: cast_nullable_to_non_nullable
as int?,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatDeworming].
extension CatDewormingPatterns on CatDeworming {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatDeworming value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatDeworming() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatDeworming value)  $default,){
final _that = this;
switch (_that) {
case _CatDeworming():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatDeworming value)?  $default,){
final _that = this;
switch (_that) {
case _CatDeworming() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int catId,  String catName,  String type,  DateTime doneDate,  String medicine,  String? dosage,  DateTime nextDate,  int? daysToDue,  int? overdueDays,  String? remark)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatDeworming() when $default != null:
return $default(_that.id,_that.catId,_that.catName,_that.type,_that.doneDate,_that.medicine,_that.dosage,_that.nextDate,_that.daysToDue,_that.overdueDays,_that.remark);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int catId,  String catName,  String type,  DateTime doneDate,  String medicine,  String? dosage,  DateTime nextDate,  int? daysToDue,  int? overdueDays,  String? remark)  $default,) {final _that = this;
switch (_that) {
case _CatDeworming():
return $default(_that.id,_that.catId,_that.catName,_that.type,_that.doneDate,_that.medicine,_that.dosage,_that.nextDate,_that.daysToDue,_that.overdueDays,_that.remark);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int catId,  String catName,  String type,  DateTime doneDate,  String medicine,  String? dosage,  DateTime nextDate,  int? daysToDue,  int? overdueDays,  String? remark)?  $default,) {final _that = this;
switch (_that) {
case _CatDeworming() when $default != null:
return $default(_that.id,_that.catId,_that.catName,_that.type,_that.doneDate,_that.medicine,_that.dosage,_that.nextDate,_that.daysToDue,_that.overdueDays,_that.remark);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatDeworming implements CatDeworming {
  const _CatDeworming({required this.id, required this.catId, required this.catName, required this.type, required this.doneDate, required this.medicine, this.dosage, required this.nextDate, this.daysToDue, this.overdueDays, this.remark});
  factory _CatDeworming.fromJson(Map<String, dynamic> json) => _$CatDewormingFromJson(json);

@override final  int id;
@override final  int catId;
@override final  String catName;
@override final  String type;
@override final  DateTime doneDate;
@override final  String medicine;
@override final  String? dosage;
@override final  DateTime nextDate;
@override final  int? daysToDue;
@override final  int? overdueDays;
@override final  String? remark;

/// Create a copy of CatDeworming
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatDewormingCopyWith<_CatDeworming> get copyWith => __$CatDewormingCopyWithImpl<_CatDeworming>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatDewormingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatDeworming&&(identical(other.id, id) || other.id == id)&&(identical(other.catId, catId) || other.catId == catId)&&(identical(other.catName, catName) || other.catName == catName)&&(identical(other.type, type) || other.type == type)&&(identical(other.doneDate, doneDate) || other.doneDate == doneDate)&&(identical(other.medicine, medicine) || other.medicine == medicine)&&(identical(other.dosage, dosage) || other.dosage == dosage)&&(identical(other.nextDate, nextDate) || other.nextDate == nextDate)&&(identical(other.daysToDue, daysToDue) || other.daysToDue == daysToDue)&&(identical(other.overdueDays, overdueDays) || other.overdueDays == overdueDays)&&(identical(other.remark, remark) || other.remark == remark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,catId,catName,type,doneDate,medicine,dosage,nextDate,daysToDue,overdueDays,remark);
}

@override
String toString() {
    return 'CatDeworming(id: $id, catId: $catId, catName: $catName, type: $type, doneDate: $doneDate, medicine: $medicine, dosage: $dosage, nextDate: $nextDate, daysToDue: $daysToDue, overdueDays: $overdueDays, remark: $remark)';
}


}

/// @nodoc
abstract mixin class _$CatDewormingCopyWith<$Res> implements $CatDewormingCopyWith<$Res> {
  factory _$CatDewormingCopyWith(_CatDeworming value, $Res Function(_CatDeworming) _then) = __$CatDewormingCopyWithImpl;
@override @useResult
$Res call({
 int id, int catId, String catName, String type, DateTime doneDate, String medicine, String? dosage, DateTime nextDate, int? daysToDue, int? overdueDays, String? remark
});




}
/// @nodoc
class __$CatDewormingCopyWithImpl<$Res>
    implements _$CatDewormingCopyWith<$Res> {
  __$CatDewormingCopyWithImpl(this._self, this._then);

  final _CatDeworming _self;
  final $Res Function(_CatDeworming) _then;

/// Create a copy of CatDeworming
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? catId = null,Object? catName = null,Object? type = null,Object? doneDate = null,Object? medicine = null,Object? dosage = freezed,Object? nextDate = null,Object? daysToDue = freezed,Object? overdueDays = freezed,Object? remark = freezed,}) {
  return _then(_CatDeworming(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,catId: null == catId ? _self.catId : catId // ignore: cast_nullable_to_non_nullable
as int,catName: null == catName ? _self.catName : catName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,doneDate: null == doneDate ? _self.doneDate : doneDate // ignore: cast_nullable_to_non_nullable
as DateTime,medicine: null == medicine ? _self.medicine : medicine // ignore: cast_nullable_to_non_nullable
as String,dosage: freezed == dosage ? _self.dosage : dosage // ignore: cast_nullable_to_non_nullable
as String?,nextDate: null == nextDate ? _self.nextDate : nextDate // ignore: cast_nullable_to_non_nullable
as DateTime,daysToDue: freezed == daysToDue ? _self.daysToDue : daysToDue // ignore: cast_nullable_to_non_nullable
as int?,overdueDays: freezed == overdueDays ? _self.overdueDays : overdueDays // ignore: cast_nullable_to_non_nullable
as int?,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
