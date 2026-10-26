// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Transaction {

 int get id; String get type; String get amount; int get categoryId; String get categoryName; int? get subCategoryId; String? get subCategoryName; int get accountId; String get accountName; DateTime get bizDate; String? get remark; int get createdBy; String get recorderName; int? get ruleId; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionCopyWith<Transaction> get copyWith => _$TransactionCopyWithImpl<Transaction>(this as Transaction, _$identity);

  /// Serializes this Transaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Transaction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transaction&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.categoryName, _this.categoryName) || other.categoryName == _this.categoryName)&&(identical(other.subCategoryId, _this.subCategoryId) || other.subCategoryId == _this.subCategoryId)&&(identical(other.subCategoryName, _this.subCategoryName) || other.subCategoryName == _this.subCategoryName)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.accountName, _this.accountName) || other.accountName == _this.accountName)&&(identical(other.bizDate, _this.bizDate) || other.bizDate == _this.bizDate)&&(identical(other.remark, _this.remark) || other.remark == _this.remark)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.recorderName, _this.recorderName) || other.recorderName == _this.recorderName)&&(identical(other.ruleId, _this.ruleId) || other.ruleId == _this.ruleId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Transaction;
  return Object.hash(runtimeType,_this.id,_this.type,_this.amount,_this.categoryId,_this.categoryName,_this.subCategoryId,_this.subCategoryName,_this.accountId,_this.accountName,_this.bizDate,_this.remark,_this.createdBy,_this.recorderName,_this.ruleId,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Transaction;
  return 'Transaction(id: ${_this.id}, type: ${_this.type}, amount: ${_this.amount}, categoryId: ${_this.categoryId}, categoryName: ${_this.categoryName}, subCategoryId: ${_this.subCategoryId}, subCategoryName: ${_this.subCategoryName}, accountId: ${_this.accountId}, accountName: ${_this.accountName}, bizDate: ${_this.bizDate}, remark: ${_this.remark}, createdBy: ${_this.createdBy}, recorderName: ${_this.recorderName}, ruleId: ${_this.ruleId}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $TransactionCopyWith<$Res>  {
  factory $TransactionCopyWith(Transaction value, $Res Function(Transaction) _then) = _$TransactionCopyWithImpl;
@useResult
$Res call({
 int id, String type, String amount, int categoryId, String categoryName, int? subCategoryId, String? subCategoryName, int accountId, String accountName, DateTime bizDate, String? remark, int createdBy, String recorderName, int? ruleId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$TransactionCopyWithImpl<$Res>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._self, this._then);

  final Transaction _self;
  final $Res Function(Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? amount = null,Object? categoryId = null,Object? categoryName = null,Object? subCategoryId = freezed,Object? subCategoryName = freezed,Object? accountId = null,Object? accountName = null,Object? bizDate = null,Object? remark = freezed,Object? createdBy = null,Object? recorderName = null,Object? ruleId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(Transaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,subCategoryId: freezed == subCategoryId ? _self.subCategoryId : subCategoryId // ignore: cast_nullable_to_non_nullable
as int?,subCategoryName: freezed == subCategoryName ? _self.subCategoryName : subCategoryName // ignore: cast_nullable_to_non_nullable
as String?,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,bizDate: null == bizDate ? _self.bizDate : bizDate // ignore: cast_nullable_to_non_nullable
as DateTime,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as int,recorderName: null == recorderName ? _self.recorderName : recorderName // ignore: cast_nullable_to_non_nullable
as String,ruleId: freezed == ruleId ? _self.ruleId : ruleId // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Transaction].
extension TransactionPatterns on Transaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transaction value)  $default,){
final _that = this;
switch (_that) {
case _Transaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transaction value)?  $default,){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String type,  String amount,  int categoryId,  String categoryName,  int? subCategoryId,  String? subCategoryName,  int accountId,  String accountName,  DateTime bizDate,  String? remark,  int createdBy,  String recorderName,  int? ruleId,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.type,_that.amount,_that.categoryId,_that.categoryName,_that.subCategoryId,_that.subCategoryName,_that.accountId,_that.accountName,_that.bizDate,_that.remark,_that.createdBy,_that.recorderName,_that.ruleId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String type,  String amount,  int categoryId,  String categoryName,  int? subCategoryId,  String? subCategoryName,  int accountId,  String accountName,  DateTime bizDate,  String? remark,  int createdBy,  String recorderName,  int? ruleId,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Transaction():
return $default(_that.id,_that.type,_that.amount,_that.categoryId,_that.categoryName,_that.subCategoryId,_that.subCategoryName,_that.accountId,_that.accountName,_that.bizDate,_that.remark,_that.createdBy,_that.recorderName,_that.ruleId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String type,  String amount,  int categoryId,  String categoryName,  int? subCategoryId,  String? subCategoryName,  int accountId,  String accountName,  DateTime bizDate,  String? remark,  int createdBy,  String recorderName,  int? ruleId,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.type,_that.amount,_that.categoryId,_that.categoryName,_that.subCategoryId,_that.subCategoryName,_that.accountId,_that.accountName,_that.bizDate,_that.remark,_that.createdBy,_that.recorderName,_that.ruleId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Transaction extends Transaction {
  const _Transaction({required this.id, required this.type, required this.amount, required this.categoryId, required this.categoryName, this.subCategoryId, this.subCategoryName, required this.accountId, required this.accountName, required this.bizDate, this.remark, required this.createdBy, required this.recorderName, this.ruleId, required this.createdAt, required this.updatedAt}): super._();
  factory _Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

@override final  int id;
@override final  String type;
@override final  String amount;
@override final  int categoryId;
@override final  String categoryName;
@override final  int? subCategoryId;
@override final  String? subCategoryName;
@override final  int accountId;
@override final  String accountName;
@override final  DateTime bizDate;
@override final  String? remark;
@override final  int createdBy;
@override final  String recorderName;
@override final  int? ruleId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionCopyWith<_Transaction> get copyWith => __$TransactionCopyWithImpl<_Transaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.subCategoryId, subCategoryId) || other.subCategoryId == subCategoryId)&&(identical(other.subCategoryName, subCategoryName) || other.subCategoryName == subCategoryName)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.accountName, accountName) || other.accountName == accountName)&&(identical(other.bizDate, bizDate) || other.bizDate == bizDate)&&(identical(other.remark, remark) || other.remark == remark)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.recorderName, recorderName) || other.recorderName == recorderName)&&(identical(other.ruleId, ruleId) || other.ruleId == ruleId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,amount,categoryId,categoryName,subCategoryId,subCategoryName,accountId,accountName,bizDate,remark,createdBy,recorderName,ruleId,createdAt,updatedAt);
}

@override
String toString() {
    return 'Transaction(id: $id, type: $type, amount: $amount, categoryId: $categoryId, categoryName: $categoryName, subCategoryId: $subCategoryId, subCategoryName: $subCategoryName, accountId: $accountId, accountName: $accountName, bizDate: $bizDate, remark: $remark, createdBy: $createdBy, recorderName: $recorderName, ruleId: $ruleId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TransactionCopyWith<$Res> implements $TransactionCopyWith<$Res> {
  factory _$TransactionCopyWith(_Transaction value, $Res Function(_Transaction) _then) = __$TransactionCopyWithImpl;
@override @useResult
$Res call({
 int id, String type, String amount, int categoryId, String categoryName, int? subCategoryId, String? subCategoryName, int accountId, String accountName, DateTime bizDate, String? remark, int createdBy, String recorderName, int? ruleId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$TransactionCopyWithImpl<$Res>
    implements _$TransactionCopyWith<$Res> {
  __$TransactionCopyWithImpl(this._self, this._then);

  final _Transaction _self;
  final $Res Function(_Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? amount = null,Object? categoryId = null,Object? categoryName = null,Object? subCategoryId = freezed,Object? subCategoryName = freezed,Object? accountId = null,Object? accountName = null,Object? bizDate = null,Object? remark = freezed,Object? createdBy = null,Object? recorderName = null,Object? ruleId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Transaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,subCategoryId: freezed == subCategoryId ? _self.subCategoryId : subCategoryId // ignore: cast_nullable_to_non_nullable
as int?,subCategoryName: freezed == subCategoryName ? _self.subCategoryName : subCategoryName // ignore: cast_nullable_to_non_nullable
as String?,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,accountName: null == accountName ? _self.accountName : accountName // ignore: cast_nullable_to_non_nullable
as String,bizDate: null == bizDate ? _self.bizDate : bizDate // ignore: cast_nullable_to_non_nullable
as DateTime,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as int,recorderName: null == recorderName ? _self.recorderName : recorderName // ignore: cast_nullable_to_non_nullable
as String,ruleId: freezed == ruleId ? _self.ruleId : ruleId // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
