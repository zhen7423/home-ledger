// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'baby_vaccine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BabyVaccinePlan {

 int get id; int get babyId; String get vaccineName; String get doseNo; DateTime get dueDate; DateTime? get plannedDate; DateTime get effectiveDate; String get status; String? get skipReason; int? get recordId; bool get manual; String get displayStatus;
/// Create a copy of BabyVaccinePlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyVaccinePlanCopyWith<BabyVaccinePlan> get copyWith => _$BabyVaccinePlanCopyWithImpl<BabyVaccinePlan>(this as BabyVaccinePlan, _$identity);

  /// Serializes this BabyVaccinePlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyVaccinePlan;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyVaccinePlan&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.babyId, _this.babyId) || other.babyId == _this.babyId)&&(identical(other.vaccineName, _this.vaccineName) || other.vaccineName == _this.vaccineName)&&(identical(other.doseNo, _this.doseNo) || other.doseNo == _this.doseNo)&&(identical(other.dueDate, _this.dueDate) || other.dueDate == _this.dueDate)&&(identical(other.plannedDate, _this.plannedDate) || other.plannedDate == _this.plannedDate)&&(identical(other.effectiveDate, _this.effectiveDate) || other.effectiveDate == _this.effectiveDate)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.skipReason, _this.skipReason) || other.skipReason == _this.skipReason)&&(identical(other.recordId, _this.recordId) || other.recordId == _this.recordId)&&(identical(other.manual, _this.manual) || other.manual == _this.manual)&&(identical(other.displayStatus, _this.displayStatus) || other.displayStatus == _this.displayStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyVaccinePlan;
  return Object.hash(runtimeType,_this.id,_this.babyId,_this.vaccineName,_this.doseNo,_this.dueDate,_this.plannedDate,_this.effectiveDate,_this.status,_this.skipReason,_this.recordId,_this.manual,_this.displayStatus);
}

@override
String toString() {
  final _this = this as BabyVaccinePlan;
  return 'BabyVaccinePlan(id: ${_this.id}, babyId: ${_this.babyId}, vaccineName: ${_this.vaccineName}, doseNo: ${_this.doseNo}, dueDate: ${_this.dueDate}, plannedDate: ${_this.plannedDate}, effectiveDate: ${_this.effectiveDate}, status: ${_this.status}, skipReason: ${_this.skipReason}, recordId: ${_this.recordId}, manual: ${_this.manual}, displayStatus: ${_this.displayStatus})';
}


}

/// @nodoc
abstract mixin class $BabyVaccinePlanCopyWith<$Res>  {
  factory $BabyVaccinePlanCopyWith(BabyVaccinePlan value, $Res Function(BabyVaccinePlan) _then) = _$BabyVaccinePlanCopyWithImpl;
@useResult
$Res call({
 int id, int babyId, String vaccineName, String doseNo, DateTime dueDate, DateTime? plannedDate, DateTime effectiveDate, String status, String? skipReason, int? recordId, bool manual, String displayStatus
});




}
/// @nodoc
class _$BabyVaccinePlanCopyWithImpl<$Res>
    implements $BabyVaccinePlanCopyWith<$Res> {
  _$BabyVaccinePlanCopyWithImpl(this._self, this._then);

  final BabyVaccinePlan _self;
  final $Res Function(BabyVaccinePlan) _then;

/// Create a copy of BabyVaccinePlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? babyId = null,Object? vaccineName = null,Object? doseNo = null,Object? dueDate = null,Object? plannedDate = freezed,Object? effectiveDate = null,Object? status = null,Object? skipReason = freezed,Object? recordId = freezed,Object? manual = null,Object? displayStatus = null,}) {
  return _then(BabyVaccinePlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,vaccineName: null == vaccineName ? _self.vaccineName : vaccineName // ignore: cast_nullable_to_non_nullable
as String,doseNo: null == doseNo ? _self.doseNo : doseNo // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,plannedDate: freezed == plannedDate ? _self.plannedDate : plannedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,effectiveDate: null == effectiveDate ? _self.effectiveDate : effectiveDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,skipReason: freezed == skipReason ? _self.skipReason : skipReason // ignore: cast_nullable_to_non_nullable
as String?,recordId: freezed == recordId ? _self.recordId : recordId // ignore: cast_nullable_to_non_nullable
as int?,manual: null == manual ? _self.manual : manual // ignore: cast_nullable_to_non_nullable
as bool,displayStatus: null == displayStatus ? _self.displayStatus : displayStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyVaccinePlan].
extension BabyVaccinePlanPatterns on BabyVaccinePlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyVaccinePlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyVaccinePlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyVaccinePlan value)  $default,){
final _that = this;
switch (_that) {
case _BabyVaccinePlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyVaccinePlan value)?  $default,){
final _that = this;
switch (_that) {
case _BabyVaccinePlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int babyId,  String vaccineName,  String doseNo,  DateTime dueDate,  DateTime? plannedDate,  DateTime effectiveDate,  String status,  String? skipReason,  int? recordId,  bool manual,  String displayStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyVaccinePlan() when $default != null:
return $default(_that.id,_that.babyId,_that.vaccineName,_that.doseNo,_that.dueDate,_that.plannedDate,_that.effectiveDate,_that.status,_that.skipReason,_that.recordId,_that.manual,_that.displayStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int babyId,  String vaccineName,  String doseNo,  DateTime dueDate,  DateTime? plannedDate,  DateTime effectiveDate,  String status,  String? skipReason,  int? recordId,  bool manual,  String displayStatus)  $default,) {final _that = this;
switch (_that) {
case _BabyVaccinePlan():
return $default(_that.id,_that.babyId,_that.vaccineName,_that.doseNo,_that.dueDate,_that.plannedDate,_that.effectiveDate,_that.status,_that.skipReason,_that.recordId,_that.manual,_that.displayStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int babyId,  String vaccineName,  String doseNo,  DateTime dueDate,  DateTime? plannedDate,  DateTime effectiveDate,  String status,  String? skipReason,  int? recordId,  bool manual,  String displayStatus)?  $default,) {final _that = this;
switch (_that) {
case _BabyVaccinePlan() when $default != null:
return $default(_that.id,_that.babyId,_that.vaccineName,_that.doseNo,_that.dueDate,_that.plannedDate,_that.effectiveDate,_that.status,_that.skipReason,_that.recordId,_that.manual,_that.displayStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyVaccinePlan implements BabyVaccinePlan {
  const _BabyVaccinePlan({required this.id, required this.babyId, required this.vaccineName, required this.doseNo, required this.dueDate, this.plannedDate, required this.effectiveDate, required this.status, this.skipReason, this.recordId, required this.manual, required this.displayStatus});
  factory _BabyVaccinePlan.fromJson(Map<String, dynamic> json) => _$BabyVaccinePlanFromJson(json);

@override final  int id;
@override final  int babyId;
@override final  String vaccineName;
@override final  String doseNo;
@override final  DateTime dueDate;
@override final  DateTime? plannedDate;
@override final  DateTime effectiveDate;
@override final  String status;
@override final  String? skipReason;
@override final  int? recordId;
@override final  bool manual;
@override final  String displayStatus;

/// Create a copy of BabyVaccinePlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyVaccinePlanCopyWith<_BabyVaccinePlan> get copyWith => __$BabyVaccinePlanCopyWithImpl<_BabyVaccinePlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyVaccinePlanToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyVaccinePlan&&(identical(other.id, id) || other.id == id)&&(identical(other.babyId, babyId) || other.babyId == babyId)&&(identical(other.vaccineName, vaccineName) || other.vaccineName == vaccineName)&&(identical(other.doseNo, doseNo) || other.doseNo == doseNo)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.plannedDate, plannedDate) || other.plannedDate == plannedDate)&&(identical(other.effectiveDate, effectiveDate) || other.effectiveDate == effectiveDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.skipReason, skipReason) || other.skipReason == skipReason)&&(identical(other.recordId, recordId) || other.recordId == recordId)&&(identical(other.manual, manual) || other.manual == manual)&&(identical(other.displayStatus, displayStatus) || other.displayStatus == displayStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,babyId,vaccineName,doseNo,dueDate,plannedDate,effectiveDate,status,skipReason,recordId,manual,displayStatus);
}

@override
String toString() {
    return 'BabyVaccinePlan(id: $id, babyId: $babyId, vaccineName: $vaccineName, doseNo: $doseNo, dueDate: $dueDate, plannedDate: $plannedDate, effectiveDate: $effectiveDate, status: $status, skipReason: $skipReason, recordId: $recordId, manual: $manual, displayStatus: $displayStatus)';
}


}

/// @nodoc
abstract mixin class _$BabyVaccinePlanCopyWith<$Res> implements $BabyVaccinePlanCopyWith<$Res> {
  factory _$BabyVaccinePlanCopyWith(_BabyVaccinePlan value, $Res Function(_BabyVaccinePlan) _then) = __$BabyVaccinePlanCopyWithImpl;
@override @useResult
$Res call({
 int id, int babyId, String vaccineName, String doseNo, DateTime dueDate, DateTime? plannedDate, DateTime effectiveDate, String status, String? skipReason, int? recordId, bool manual, String displayStatus
});




}
/// @nodoc
class __$BabyVaccinePlanCopyWithImpl<$Res>
    implements _$BabyVaccinePlanCopyWith<$Res> {
  __$BabyVaccinePlanCopyWithImpl(this._self, this._then);

  final _BabyVaccinePlan _self;
  final $Res Function(_BabyVaccinePlan) _then;

/// Create a copy of BabyVaccinePlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? babyId = null,Object? vaccineName = null,Object? doseNo = null,Object? dueDate = null,Object? plannedDate = freezed,Object? effectiveDate = null,Object? status = null,Object? skipReason = freezed,Object? recordId = freezed,Object? manual = null,Object? displayStatus = null,}) {
  return _then(_BabyVaccinePlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,vaccineName: null == vaccineName ? _self.vaccineName : vaccineName // ignore: cast_nullable_to_non_nullable
as String,doseNo: null == doseNo ? _self.doseNo : doseNo // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,plannedDate: freezed == plannedDate ? _self.plannedDate : plannedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,effectiveDate: null == effectiveDate ? _self.effectiveDate : effectiveDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,skipReason: freezed == skipReason ? _self.skipReason : skipReason // ignore: cast_nullable_to_non_nullable
as String?,recordId: freezed == recordId ? _self.recordId : recordId // ignore: cast_nullable_to_non_nullable
as int?,manual: null == manual ? _self.manual : manual // ignore: cast_nullable_to_non_nullable
as bool,displayStatus: null == displayStatus ? _self.displayStatus : displayStatus // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BabyVaccineRecord {

 int get id; int get babyId; int? get planId; String get vaccineName; String get doseNo; DateTime get givenDate; String? get clinic; String? get batchNo; String? get reaction; DateTime? get nextDate; String? get remark;
/// Create a copy of BabyVaccineRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyVaccineRecordCopyWith<BabyVaccineRecord> get copyWith => _$BabyVaccineRecordCopyWithImpl<BabyVaccineRecord>(this as BabyVaccineRecord, _$identity);

  /// Serializes this BabyVaccineRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyVaccineRecord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyVaccineRecord&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.babyId, _this.babyId) || other.babyId == _this.babyId)&&(identical(other.planId, _this.planId) || other.planId == _this.planId)&&(identical(other.vaccineName, _this.vaccineName) || other.vaccineName == _this.vaccineName)&&(identical(other.doseNo, _this.doseNo) || other.doseNo == _this.doseNo)&&(identical(other.givenDate, _this.givenDate) || other.givenDate == _this.givenDate)&&(identical(other.clinic, _this.clinic) || other.clinic == _this.clinic)&&(identical(other.batchNo, _this.batchNo) || other.batchNo == _this.batchNo)&&(identical(other.reaction, _this.reaction) || other.reaction == _this.reaction)&&(identical(other.nextDate, _this.nextDate) || other.nextDate == _this.nextDate)&&(identical(other.remark, _this.remark) || other.remark == _this.remark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyVaccineRecord;
  return Object.hash(runtimeType,_this.id,_this.babyId,_this.planId,_this.vaccineName,_this.doseNo,_this.givenDate,_this.clinic,_this.batchNo,_this.reaction,_this.nextDate,_this.remark);
}

@override
String toString() {
  final _this = this as BabyVaccineRecord;
  return 'BabyVaccineRecord(id: ${_this.id}, babyId: ${_this.babyId}, planId: ${_this.planId}, vaccineName: ${_this.vaccineName}, doseNo: ${_this.doseNo}, givenDate: ${_this.givenDate}, clinic: ${_this.clinic}, batchNo: ${_this.batchNo}, reaction: ${_this.reaction}, nextDate: ${_this.nextDate}, remark: ${_this.remark})';
}


}

/// @nodoc
abstract mixin class $BabyVaccineRecordCopyWith<$Res>  {
  factory $BabyVaccineRecordCopyWith(BabyVaccineRecord value, $Res Function(BabyVaccineRecord) _then) = _$BabyVaccineRecordCopyWithImpl;
@useResult
$Res call({
 int id, int babyId, int? planId, String vaccineName, String doseNo, DateTime givenDate, String? clinic, String? batchNo, String? reaction, DateTime? nextDate, String? remark
});




}
/// @nodoc
class _$BabyVaccineRecordCopyWithImpl<$Res>
    implements $BabyVaccineRecordCopyWith<$Res> {
  _$BabyVaccineRecordCopyWithImpl(this._self, this._then);

  final BabyVaccineRecord _self;
  final $Res Function(BabyVaccineRecord) _then;

/// Create a copy of BabyVaccineRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? babyId = null,Object? planId = freezed,Object? vaccineName = null,Object? doseNo = null,Object? givenDate = null,Object? clinic = freezed,Object? batchNo = freezed,Object? reaction = freezed,Object? nextDate = freezed,Object? remark = freezed,}) {
  return _then(BabyVaccineRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,planId: freezed == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as int?,vaccineName: null == vaccineName ? _self.vaccineName : vaccineName // ignore: cast_nullable_to_non_nullable
as String,doseNo: null == doseNo ? _self.doseNo : doseNo // ignore: cast_nullable_to_non_nullable
as String,givenDate: null == givenDate ? _self.givenDate : givenDate // ignore: cast_nullable_to_non_nullable
as DateTime,clinic: freezed == clinic ? _self.clinic : clinic // ignore: cast_nullable_to_non_nullable
as String?,batchNo: freezed == batchNo ? _self.batchNo : batchNo // ignore: cast_nullable_to_non_nullable
as String?,reaction: freezed == reaction ? _self.reaction : reaction // ignore: cast_nullable_to_non_nullable
as String?,nextDate: freezed == nextDate ? _self.nextDate : nextDate // ignore: cast_nullable_to_non_nullable
as DateTime?,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyVaccineRecord].
extension BabyVaccineRecordPatterns on BabyVaccineRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyVaccineRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyVaccineRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyVaccineRecord value)  $default,){
final _that = this;
switch (_that) {
case _BabyVaccineRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyVaccineRecord value)?  $default,){
final _that = this;
switch (_that) {
case _BabyVaccineRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int babyId,  int? planId,  String vaccineName,  String doseNo,  DateTime givenDate,  String? clinic,  String? batchNo,  String? reaction,  DateTime? nextDate,  String? remark)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyVaccineRecord() when $default != null:
return $default(_that.id,_that.babyId,_that.planId,_that.vaccineName,_that.doseNo,_that.givenDate,_that.clinic,_that.batchNo,_that.reaction,_that.nextDate,_that.remark);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int babyId,  int? planId,  String vaccineName,  String doseNo,  DateTime givenDate,  String? clinic,  String? batchNo,  String? reaction,  DateTime? nextDate,  String? remark)  $default,) {final _that = this;
switch (_that) {
case _BabyVaccineRecord():
return $default(_that.id,_that.babyId,_that.planId,_that.vaccineName,_that.doseNo,_that.givenDate,_that.clinic,_that.batchNo,_that.reaction,_that.nextDate,_that.remark);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int babyId,  int? planId,  String vaccineName,  String doseNo,  DateTime givenDate,  String? clinic,  String? batchNo,  String? reaction,  DateTime? nextDate,  String? remark)?  $default,) {final _that = this;
switch (_that) {
case _BabyVaccineRecord() when $default != null:
return $default(_that.id,_that.babyId,_that.planId,_that.vaccineName,_that.doseNo,_that.givenDate,_that.clinic,_that.batchNo,_that.reaction,_that.nextDate,_that.remark);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyVaccineRecord implements BabyVaccineRecord {
  const _BabyVaccineRecord({required this.id, required this.babyId, this.planId, required this.vaccineName, required this.doseNo, required this.givenDate, this.clinic, this.batchNo, this.reaction, this.nextDate, this.remark});
  factory _BabyVaccineRecord.fromJson(Map<String, dynamic> json) => _$BabyVaccineRecordFromJson(json);

@override final  int id;
@override final  int babyId;
@override final  int? planId;
@override final  String vaccineName;
@override final  String doseNo;
@override final  DateTime givenDate;
@override final  String? clinic;
@override final  String? batchNo;
@override final  String? reaction;
@override final  DateTime? nextDate;
@override final  String? remark;

/// Create a copy of BabyVaccineRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyVaccineRecordCopyWith<_BabyVaccineRecord> get copyWith => __$BabyVaccineRecordCopyWithImpl<_BabyVaccineRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyVaccineRecordToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyVaccineRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.babyId, babyId) || other.babyId == babyId)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.vaccineName, vaccineName) || other.vaccineName == vaccineName)&&(identical(other.doseNo, doseNo) || other.doseNo == doseNo)&&(identical(other.givenDate, givenDate) || other.givenDate == givenDate)&&(identical(other.clinic, clinic) || other.clinic == clinic)&&(identical(other.batchNo, batchNo) || other.batchNo == batchNo)&&(identical(other.reaction, reaction) || other.reaction == reaction)&&(identical(other.nextDate, nextDate) || other.nextDate == nextDate)&&(identical(other.remark, remark) || other.remark == remark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,babyId,planId,vaccineName,doseNo,givenDate,clinic,batchNo,reaction,nextDate,remark);
}

@override
String toString() {
    return 'BabyVaccineRecord(id: $id, babyId: $babyId, planId: $planId, vaccineName: $vaccineName, doseNo: $doseNo, givenDate: $givenDate, clinic: $clinic, batchNo: $batchNo, reaction: $reaction, nextDate: $nextDate, remark: $remark)';
}


}

/// @nodoc
abstract mixin class _$BabyVaccineRecordCopyWith<$Res> implements $BabyVaccineRecordCopyWith<$Res> {
  factory _$BabyVaccineRecordCopyWith(_BabyVaccineRecord value, $Res Function(_BabyVaccineRecord) _then) = __$BabyVaccineRecordCopyWithImpl;
@override @useResult
$Res call({
 int id, int babyId, int? planId, String vaccineName, String doseNo, DateTime givenDate, String? clinic, String? batchNo, String? reaction, DateTime? nextDate, String? remark
});




}
/// @nodoc
class __$BabyVaccineRecordCopyWithImpl<$Res>
    implements _$BabyVaccineRecordCopyWith<$Res> {
  __$BabyVaccineRecordCopyWithImpl(this._self, this._then);

  final _BabyVaccineRecord _self;
  final $Res Function(_BabyVaccineRecord) _then;

/// Create a copy of BabyVaccineRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? babyId = null,Object? planId = freezed,Object? vaccineName = null,Object? doseNo = null,Object? givenDate = null,Object? clinic = freezed,Object? batchNo = freezed,Object? reaction = freezed,Object? nextDate = freezed,Object? remark = freezed,}) {
  return _then(_BabyVaccineRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,planId: freezed == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as int?,vaccineName: null == vaccineName ? _self.vaccineName : vaccineName // ignore: cast_nullable_to_non_nullable
as String,doseNo: null == doseNo ? _self.doseNo : doseNo // ignore: cast_nullable_to_non_nullable
as String,givenDate: null == givenDate ? _self.givenDate : givenDate // ignore: cast_nullable_to_non_nullable
as DateTime,clinic: freezed == clinic ? _self.clinic : clinic // ignore: cast_nullable_to_non_nullable
as String?,batchNo: freezed == batchNo ? _self.batchNo : batchNo // ignore: cast_nullable_to_non_nullable
as String?,reaction: freezed == reaction ? _self.reaction : reaction // ignore: cast_nullable_to_non_nullable
as String?,nextDate: freezed == nextDate ? _self.nextDate : nextDate // ignore: cast_nullable_to_non_nullable
as DateTime?,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
