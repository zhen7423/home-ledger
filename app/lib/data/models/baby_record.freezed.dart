// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'baby_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BabyMilestone {

 int get id; int get babyId; DateTime get occurDate; String get title; String? get description;
/// Create a copy of BabyMilestone
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyMilestoneCopyWith<BabyMilestone> get copyWith => _$BabyMilestoneCopyWithImpl<BabyMilestone>(this as BabyMilestone, _$identity);

  /// Serializes this BabyMilestone to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyMilestone;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyMilestone&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.babyId, _this.babyId) || other.babyId == _this.babyId)&&(identical(other.occurDate, _this.occurDate) || other.occurDate == _this.occurDate)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyMilestone;
  return Object.hash(runtimeType,_this.id,_this.babyId,_this.occurDate,_this.title,_this.description);
}

@override
String toString() {
  final _this = this as BabyMilestone;
  return 'BabyMilestone(id: ${_this.id}, babyId: ${_this.babyId}, occurDate: ${_this.occurDate}, title: ${_this.title}, description: ${_this.description})';
}


}

/// @nodoc
abstract mixin class $BabyMilestoneCopyWith<$Res>  {
  factory $BabyMilestoneCopyWith(BabyMilestone value, $Res Function(BabyMilestone) _then) = _$BabyMilestoneCopyWithImpl;
@useResult
$Res call({
 int id, int babyId, DateTime occurDate, String title, String? description
});




}
/// @nodoc
class _$BabyMilestoneCopyWithImpl<$Res>
    implements $BabyMilestoneCopyWith<$Res> {
  _$BabyMilestoneCopyWithImpl(this._self, this._then);

  final BabyMilestone _self;
  final $Res Function(BabyMilestone) _then;

/// Create a copy of BabyMilestone
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? babyId = null,Object? occurDate = null,Object? title = null,Object? description = freezed,}) {
  return _then(BabyMilestone(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,occurDate: null == occurDate ? _self.occurDate : occurDate // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyMilestone].
extension BabyMilestonePatterns on BabyMilestone {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyMilestone value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyMilestone() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyMilestone value)  $default,){
final _that = this;
switch (_that) {
case _BabyMilestone():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyMilestone value)?  $default,){
final _that = this;
switch (_that) {
case _BabyMilestone() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int babyId,  DateTime occurDate,  String title,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyMilestone() when $default != null:
return $default(_that.id,_that.babyId,_that.occurDate,_that.title,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int babyId,  DateTime occurDate,  String title,  String? description)  $default,) {final _that = this;
switch (_that) {
case _BabyMilestone():
return $default(_that.id,_that.babyId,_that.occurDate,_that.title,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int babyId,  DateTime occurDate,  String title,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _BabyMilestone() when $default != null:
return $default(_that.id,_that.babyId,_that.occurDate,_that.title,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyMilestone implements BabyMilestone {
  const _BabyMilestone({required this.id, required this.babyId, required this.occurDate, required this.title, this.description});
  factory _BabyMilestone.fromJson(Map<String, dynamic> json) => _$BabyMilestoneFromJson(json);

@override final  int id;
@override final  int babyId;
@override final  DateTime occurDate;
@override final  String title;
@override final  String? description;

/// Create a copy of BabyMilestone
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyMilestoneCopyWith<_BabyMilestone> get copyWith => __$BabyMilestoneCopyWithImpl<_BabyMilestone>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyMilestoneToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyMilestone&&(identical(other.id, id) || other.id == id)&&(identical(other.babyId, babyId) || other.babyId == babyId)&&(identical(other.occurDate, occurDate) || other.occurDate == occurDate)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,babyId,occurDate,title,description);
}

@override
String toString() {
    return 'BabyMilestone(id: $id, babyId: $babyId, occurDate: $occurDate, title: $title, description: $description)';
}


}

/// @nodoc
abstract mixin class _$BabyMilestoneCopyWith<$Res> implements $BabyMilestoneCopyWith<$Res> {
  factory _$BabyMilestoneCopyWith(_BabyMilestone value, $Res Function(_BabyMilestone) _then) = __$BabyMilestoneCopyWithImpl;
@override @useResult
$Res call({
 int id, int babyId, DateTime occurDate, String title, String? description
});




}
/// @nodoc
class __$BabyMilestoneCopyWithImpl<$Res>
    implements _$BabyMilestoneCopyWith<$Res> {
  __$BabyMilestoneCopyWithImpl(this._self, this._then);

  final _BabyMilestone _self;
  final $Res Function(_BabyMilestone) _then;

/// Create a copy of BabyMilestone
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? babyId = null,Object? occurDate = null,Object? title = null,Object? description = freezed,}) {
  return _then(_BabyMilestone(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,occurDate: null == occurDate ? _self.occurDate : occurDate // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BabyMedical {

 int get id; int get babyId; DateTime get visitDate; String? get hospital; String? get department; String? get diagnosis; String? get medicine; String? get costAmount; String? get remark;
/// Create a copy of BabyMedical
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyMedicalCopyWith<BabyMedical> get copyWith => _$BabyMedicalCopyWithImpl<BabyMedical>(this as BabyMedical, _$identity);

  /// Serializes this BabyMedical to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyMedical;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyMedical&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.babyId, _this.babyId) || other.babyId == _this.babyId)&&(identical(other.visitDate, _this.visitDate) || other.visitDate == _this.visitDate)&&(identical(other.hospital, _this.hospital) || other.hospital == _this.hospital)&&(identical(other.department, _this.department) || other.department == _this.department)&&(identical(other.diagnosis, _this.diagnosis) || other.diagnosis == _this.diagnosis)&&(identical(other.medicine, _this.medicine) || other.medicine == _this.medicine)&&(identical(other.costAmount, _this.costAmount) || other.costAmount == _this.costAmount)&&(identical(other.remark, _this.remark) || other.remark == _this.remark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyMedical;
  return Object.hash(runtimeType,_this.id,_this.babyId,_this.visitDate,_this.hospital,_this.department,_this.diagnosis,_this.medicine,_this.costAmount,_this.remark);
}

@override
String toString() {
  final _this = this as BabyMedical;
  return 'BabyMedical(id: ${_this.id}, babyId: ${_this.babyId}, visitDate: ${_this.visitDate}, hospital: ${_this.hospital}, department: ${_this.department}, diagnosis: ${_this.diagnosis}, medicine: ${_this.medicine}, costAmount: ${_this.costAmount}, remark: ${_this.remark})';
}


}

/// @nodoc
abstract mixin class $BabyMedicalCopyWith<$Res>  {
  factory $BabyMedicalCopyWith(BabyMedical value, $Res Function(BabyMedical) _then) = _$BabyMedicalCopyWithImpl;
@useResult
$Res call({
 int id, int babyId, DateTime visitDate, String? hospital, String? department, String? diagnosis, String? medicine, String? costAmount, String? remark
});




}
/// @nodoc
class _$BabyMedicalCopyWithImpl<$Res>
    implements $BabyMedicalCopyWith<$Res> {
  _$BabyMedicalCopyWithImpl(this._self, this._then);

  final BabyMedical _self;
  final $Res Function(BabyMedical) _then;

/// Create a copy of BabyMedical
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? babyId = null,Object? visitDate = null,Object? hospital = freezed,Object? department = freezed,Object? diagnosis = freezed,Object? medicine = freezed,Object? costAmount = freezed,Object? remark = freezed,}) {
  return _then(BabyMedical(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,visitDate: null == visitDate ? _self.visitDate : visitDate // ignore: cast_nullable_to_non_nullable
as DateTime,hospital: freezed == hospital ? _self.hospital : hospital // ignore: cast_nullable_to_non_nullable
as String?,department: freezed == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String?,diagnosis: freezed == diagnosis ? _self.diagnosis : diagnosis // ignore: cast_nullable_to_non_nullable
as String?,medicine: freezed == medicine ? _self.medicine : medicine // ignore: cast_nullable_to_non_nullable
as String?,costAmount: freezed == costAmount ? _self.costAmount : costAmount // ignore: cast_nullable_to_non_nullable
as String?,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyMedical].
extension BabyMedicalPatterns on BabyMedical {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyMedical value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyMedical() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyMedical value)  $default,){
final _that = this;
switch (_that) {
case _BabyMedical():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyMedical value)?  $default,){
final _that = this;
switch (_that) {
case _BabyMedical() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int babyId,  DateTime visitDate,  String? hospital,  String? department,  String? diagnosis,  String? medicine,  String? costAmount,  String? remark)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyMedical() when $default != null:
return $default(_that.id,_that.babyId,_that.visitDate,_that.hospital,_that.department,_that.diagnosis,_that.medicine,_that.costAmount,_that.remark);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int babyId,  DateTime visitDate,  String? hospital,  String? department,  String? diagnosis,  String? medicine,  String? costAmount,  String? remark)  $default,) {final _that = this;
switch (_that) {
case _BabyMedical():
return $default(_that.id,_that.babyId,_that.visitDate,_that.hospital,_that.department,_that.diagnosis,_that.medicine,_that.costAmount,_that.remark);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int babyId,  DateTime visitDate,  String? hospital,  String? department,  String? diagnosis,  String? medicine,  String? costAmount,  String? remark)?  $default,) {final _that = this;
switch (_that) {
case _BabyMedical() when $default != null:
return $default(_that.id,_that.babyId,_that.visitDate,_that.hospital,_that.department,_that.diagnosis,_that.medicine,_that.costAmount,_that.remark);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyMedical implements BabyMedical {
  const _BabyMedical({required this.id, required this.babyId, required this.visitDate, this.hospital, this.department, this.diagnosis, this.medicine, this.costAmount, this.remark});
  factory _BabyMedical.fromJson(Map<String, dynamic> json) => _$BabyMedicalFromJson(json);

@override final  int id;
@override final  int babyId;
@override final  DateTime visitDate;
@override final  String? hospital;
@override final  String? department;
@override final  String? diagnosis;
@override final  String? medicine;
@override final  String? costAmount;
@override final  String? remark;

/// Create a copy of BabyMedical
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyMedicalCopyWith<_BabyMedical> get copyWith => __$BabyMedicalCopyWithImpl<_BabyMedical>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyMedicalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyMedical&&(identical(other.id, id) || other.id == id)&&(identical(other.babyId, babyId) || other.babyId == babyId)&&(identical(other.visitDate, visitDate) || other.visitDate == visitDate)&&(identical(other.hospital, hospital) || other.hospital == hospital)&&(identical(other.department, department) || other.department == department)&&(identical(other.diagnosis, diagnosis) || other.diagnosis == diagnosis)&&(identical(other.medicine, medicine) || other.medicine == medicine)&&(identical(other.costAmount, costAmount) || other.costAmount == costAmount)&&(identical(other.remark, remark) || other.remark == remark));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,babyId,visitDate,hospital,department,diagnosis,medicine,costAmount,remark);
}

@override
String toString() {
    return 'BabyMedical(id: $id, babyId: $babyId, visitDate: $visitDate, hospital: $hospital, department: $department, diagnosis: $diagnosis, medicine: $medicine, costAmount: $costAmount, remark: $remark)';
}


}

/// @nodoc
abstract mixin class _$BabyMedicalCopyWith<$Res> implements $BabyMedicalCopyWith<$Res> {
  factory _$BabyMedicalCopyWith(_BabyMedical value, $Res Function(_BabyMedical) _then) = __$BabyMedicalCopyWithImpl;
@override @useResult
$Res call({
 int id, int babyId, DateTime visitDate, String? hospital, String? department, String? diagnosis, String? medicine, String? costAmount, String? remark
});




}
/// @nodoc
class __$BabyMedicalCopyWithImpl<$Res>
    implements _$BabyMedicalCopyWith<$Res> {
  __$BabyMedicalCopyWithImpl(this._self, this._then);

  final _BabyMedical _self;
  final $Res Function(_BabyMedical) _then;

/// Create a copy of BabyMedical
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? babyId = null,Object? visitDate = null,Object? hospital = freezed,Object? department = freezed,Object? diagnosis = freezed,Object? medicine = freezed,Object? costAmount = freezed,Object? remark = freezed,}) {
  return _then(_BabyMedical(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,visitDate: null == visitDate ? _self.visitDate : visitDate // ignore: cast_nullable_to_non_nullable
as DateTime,hospital: freezed == hospital ? _self.hospital : hospital // ignore: cast_nullable_to_non_nullable
as String?,department: freezed == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String?,diagnosis: freezed == diagnosis ? _self.diagnosis : diagnosis // ignore: cast_nullable_to_non_nullable
as String?,medicine: freezed == medicine ? _self.medicine : medicine // ignore: cast_nullable_to_non_nullable
as String?,costAmount: freezed == costAmount ? _self.costAmount : costAmount // ignore: cast_nullable_to_non_nullable
as String?,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
