// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_rule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecurringRule {

 int get id; String get name; String get type; String get amount; int get categoryId; String get categoryName; int? get subCategoryId; String? get subCategoryName; int get accountId; String get accountName; String get periodType; PeriodValue get periodValue; DateTime get startDate; DateTime? get endDate; bool get enabled; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of RecurringRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringRuleCopyWith<RecurringRule> get copyWith => _$RecurringRuleCopyWithImpl<RecurringRule>(this as RecurringRule, _$identity);

  /// Serializes this RecurringRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RecurringRule;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringRule&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.categoryName, _this.categoryName) || other.categoryName == _this.categoryName)&&(identical(other.subCategoryId, _this.subCategoryId) || other.subCategoryId == _this.subCategoryId)&&(identical(other.subCategoryName, _this.subCategoryName) || other.subCategoryName == _this.subCategoryName)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.accountName, _this.accountName) || other.accountName == _this.accountName)&&(identical(other.periodType, _this.periodType) || other.periodType == _this.periodType)&&(identical(other.periodValue, _this.periodValue) || other.periodValue == _this.periodValue)&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecurringRule;
  return Object.hash(runtimeType,_this.id,_this.name,_this.type,_this.amount,_this.categoryId,_this.categoryName,_this.subCategoryId,_this.subCategoryName,_this.accountId,_this.accountName,_this.periodType,_this.periodValue,_this.startDate,_this.endDate,_this.enabled,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as RecurringRule;
  return 'RecurringRule(id: ${_this.id}, name: ${_this.name}, type: ${_this.type}, amount: ${_this.amount}, categoryId: ${_this.categoryId}, categoryName: ${_this.categoryName}, subCategoryId: ${_this.subCategoryId}, subCategoryName: ${_this.subCategoryName}, accountId: ${_this.accountId}, accountName: ${_this.accountName}, periodType: ${_this.periodType}, periodValue: ${_this.periodValue}, startDate: ${_this.startDate}, endDate: ${_this.endDate}, enabled: ${_this.enabled}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $RecurringRuleCopyWith<$Res>  {
  factory $RecurringRuleCopyWith(RecurringRule value, $Res Function(RecurringRule) _then) = _$RecurringRuleCopyWithImpl;
@useResult
$Res call({
 int id, String name, String type, String amount, int categoryId, String categoryName, int? subCategoryId, String? subCategoryName, int accountId, String accountName, String periodType, PeriodValue periodValue, DateTime startDate, DateTime? endDate, bool enabled, DateTime createdAt, DateTime updatedAt
});


$PeriodValueCopyWith<$Res> get periodValue;

}
/// @nodoc
class _$RecurringRuleCopyWithImpl<$Res>
    implements $RecurringRuleCopyWith<$Res> {
  _$RecurringRuleCopyWithImpl(this._self, this._then);

  final RecurringRule _self;
  final $Res Function(RecurringRule) _then;

/// Create a copy of RecurringRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? amount = null,Object? categoryId = null,Object? categoryName = null,Object? subCategoryId = freezed,Object? subCategoryName = freezed,Object? accountId = null,Object? accountName = null,Object? periodType = null,Object? periodValue = null,Object? startDate = null,Object? endDate = freezed,Object? enabled = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(RecurringRule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,subCategoryId: freezed == subCategoryId ? _self.subCategoryId : subCategoryId // ignore: cast_nullable_to_non_nullable
as int?,subCategoryName: freezed == subCategoryName ? _self.subCategoryName : subCategoryName // ignore: cast_nullable_to_non_nullable
as String?,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,periodType: null == periodType ? _self.periodType : periodType // ignore: cast_nullable_to_non_nullable
as String,periodValue: null == periodValue ? _self.periodValue : periodValue // ignore: cast_nullable_to_non_nullable
as PeriodValue,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of RecurringRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodValueCopyWith<$Res> get periodValue {
  
  return $PeriodValueCopyWith<$Res>(_self.periodValue, (value) {
    return _then(_self.copyWith(periodValue: value));
  });
}
}


/// Adds pattern-matching-related methods to [RecurringRule].
extension RecurringRulePatterns on RecurringRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringRule value)  $default,){
final _that = this;
switch (_that) {
case _RecurringRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringRule value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String type,  String amount,  int categoryId,  String categoryName,  int? subCategoryId,  String? subCategoryName,  int accountId,  String accountName,  String periodType,  PeriodValue periodValue,  DateTime startDate,  DateTime? endDate,  bool enabled,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringRule() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.amount,_that.categoryId,_that.categoryName,_that.subCategoryId,_that.subCategoryName,_that.accountId,_that.accountName,_that.periodType,_that.periodValue,_that.startDate,_that.endDate,_that.enabled,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String type,  String amount,  int categoryId,  String categoryName,  int? subCategoryId,  String? subCategoryName,  int accountId,  String accountName,  String periodType,  PeriodValue periodValue,  DateTime startDate,  DateTime? endDate,  bool enabled,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RecurringRule():
return $default(_that.id,_that.name,_that.type,_that.amount,_that.categoryId,_that.categoryName,_that.subCategoryId,_that.subCategoryName,_that.accountId,_that.accountName,_that.periodType,_that.periodValue,_that.startDate,_that.endDate,_that.enabled,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String type,  String amount,  int categoryId,  String categoryName,  int? subCategoryId,  String? subCategoryName,  int accountId,  String accountName,  String periodType,  PeriodValue periodValue,  DateTime startDate,  DateTime? endDate,  bool enabled,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RecurringRule() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.amount,_that.categoryId,_that.categoryName,_that.subCategoryId,_that.subCategoryName,_that.accountId,_that.accountName,_that.periodType,_that.periodValue,_that.startDate,_that.endDate,_that.enabled,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecurringRule implements RecurringRule {
  const _RecurringRule({required this.id, required this.name, required this.type, required this.amount, required this.categoryId, required this.categoryName, this.subCategoryId, this.subCategoryName, required this.accountId, required this.accountName, required this.periodType, required this.periodValue, required this.startDate, this.endDate, required this.enabled, required this.createdAt, required this.updatedAt});
  factory _RecurringRule.fromJson(Map<String, dynamic> json) => _$RecurringRuleFromJson(json);

@override final  int id;
@override final  String name;
@override final  String type;
@override final  String amount;
@override final  int categoryId;
@override final  String categoryName;
@override final  int? subCategoryId;
@override final  String? subCategoryName;
@override final  int accountId;
@override final  String accountName;
@override final  String periodType;
@override final  PeriodValue periodValue;
@override final  DateTime startDate;
@override final  DateTime? endDate;
@override final  bool enabled;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of RecurringRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringRuleCopyWith<_RecurringRule> get copyWith => __$RecurringRuleCopyWithImpl<_RecurringRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecurringRuleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringRule&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.subCategoryId, subCategoryId) || other.subCategoryId == subCategoryId)&&(identical(other.subCategoryName, subCategoryName) || other.subCategoryName == subCategoryName)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.periodType, periodType) || other.periodType == periodType)&&(identical(other.periodValue, periodValue) || other.periodValue == periodValue)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,type,amount,categoryId,categoryName,subCategoryId,subCategoryName,accountId,accountName,periodType,periodValue,startDate,endDate,enabled,createdAt,updatedAt);
}

@override
String toString() {
    return 'RecurringRule(id: $id, name: $name, type: $type, amount: $amount, categoryId: $categoryId, categoryName: $categoryName, subCategoryId: $subCategoryId, subCategoryName: $subCategoryName, accountId: $accountId, accountName: $accountName, periodType: $periodType, periodValue: $periodValue, startDate: $startDate, endDate: $endDate, enabled: $enabled, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RecurringRuleCopyWith<$Res> implements $RecurringRuleCopyWith<$Res> {
  factory _$RecurringRuleCopyWith(_RecurringRule value, $Res Function(_RecurringRule) _then) = __$RecurringRuleCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String type, String amount, int categoryId, String categoryName, int? subCategoryId, String? subCategoryName, int accountId, String accountName, String periodType, PeriodValue periodValue, DateTime startDate, DateTime? endDate, bool enabled, DateTime createdAt, DateTime updatedAt
});


@override $PeriodValueCopyWith<$Res> get periodValue;

}
/// @nodoc
class __$RecurringRuleCopyWithImpl<$Res>
    implements _$RecurringRuleCopyWith<$Res> {
  __$RecurringRuleCopyWithImpl(this._self, this._then);

  final _RecurringRule _self;
  final $Res Function(_RecurringRule) _then;

/// Create a copy of RecurringRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? amount = null,Object? categoryId = null,Object? categoryName = null,Object? subCategoryId = freezed,Object? subCategoryName = freezed,Object? accountId = null,Object? accountName = null,Object? periodType = null,Object? periodValue = null,Object? startDate = null,Object? endDate = freezed,Object? enabled = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_RecurringRule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,subCategoryId: freezed == subCategoryId ? _self.subCategoryId : subCategoryId // ignore: cast_nullable_to_non_nullable
as int?,subCategoryName: freezed == subCategoryName ? _self.subCategoryName : subCategoryName // ignore: cast_nullable_to_non_nullable
as String?,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,periodType: null == periodType ? _self.periodType : periodType // ignore: cast_nullable_to_non_nullable
as String,periodValue: null == periodValue ? _self.periodValue : periodValue // ignore: cast_nullable_to_non_nullable
as PeriodValue,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of RecurringRule
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodValueCopyWith<$Res> get periodValue {
  
  return $PeriodValueCopyWith<$Res>(_self.periodValue, (value) {
    return _then(_self.copyWith(periodValue: value));
  });
}
}

// dart format on
