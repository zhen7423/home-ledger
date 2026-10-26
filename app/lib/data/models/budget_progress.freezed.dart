// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BudgetProgress {

 String get month; String get scope; int? get categoryId; String? get categoryName; int? get memberUserId; String? get memberName; String get amount; String get used; String get remaining; int get usedPercent; String get level; int get remainingDays;
/// Create a copy of BudgetProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetProgressCopyWith<BudgetProgress> get copyWith => _$BudgetProgressCopyWithImpl<BudgetProgress>(this as BudgetProgress, _$identity);

  /// Serializes this BudgetProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BudgetProgress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BudgetProgress&&(identical(other.month, _this.month) || other.month == _this.month)&&(identical(other.scope, _this.scope) || other.scope == _this.scope)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.categoryName, _this.categoryName) || other.categoryName == _this.categoryName)&&(identical(other.memberUserId, _this.memberUserId) || other.memberUserId == _this.memberUserId)&&(identical(other.memberName, _this.memberName) || other.memberName == _this.memberName)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.used, _this.used) || other.used == _this.used)&&(identical(other.remaining, _this.remaining) || other.remaining == _this.remaining)&&(identical(other.usedPercent, _this.usedPercent) || other.usedPercent == _this.usedPercent)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.remainingDays, _this.remainingDays) || other.remainingDays == _this.remainingDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BudgetProgress;
  return Object.hash(runtimeType,_this.month,_this.scope,_this.categoryId,_this.categoryName,_this.memberUserId,_this.memberName,_this.amount,_this.used,_this.remaining,_this.usedPercent,_this.level,_this.remainingDays);
}

@override
String toString() {
  final _this = this as BudgetProgress;
  return 'BudgetProgress(month: ${_this.month}, scope: ${_this.scope}, categoryId: ${_this.categoryId}, categoryName: ${_this.categoryName}, memberUserId: ${_this.memberUserId}, memberName: ${_this.memberName}, amount: ${_this.amount}, used: ${_this.used}, remaining: ${_this.remaining}, usedPercent: ${_this.usedPercent}, level: ${_this.level}, remainingDays: ${_this.remainingDays})';
}


}

/// @nodoc
abstract mixin class $BudgetProgressCopyWith<$Res>  {
  factory $BudgetProgressCopyWith(BudgetProgress value, $Res Function(BudgetProgress) _then) = _$BudgetProgressCopyWithImpl;
@useResult
$Res call({
 String month, String scope, int? categoryId, String? categoryName, int? memberUserId, String? memberName, String amount, String used, String remaining, int usedPercent, String level, int remainingDays
});




}
/// @nodoc
class _$BudgetProgressCopyWithImpl<$Res>
    implements $BudgetProgressCopyWith<$Res> {
  _$BudgetProgressCopyWithImpl(this._self, this._then);

  final BudgetProgress _self;
  final $Res Function(BudgetProgress) _then;

/// Create a copy of BudgetProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? scope = null,Object? categoryId = freezed,Object? categoryName = freezed,Object? memberUserId = freezed,Object? memberName = freezed,Object? amount = null,Object? used = null,Object? remaining = null,Object? usedPercent = null,Object? level = null,Object? remainingDays = null,}) {
  return _then(BudgetProgress(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,memberUserId: freezed == memberUserId ? _self.memberUserId : memberUserId // ignore: cast_nullable_to_non_nullable
as int?,memberName: freezed == memberName ? _self.memberName : memberName // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,used: null == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as String,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as String,usedPercent: null == usedPercent ? _self.usedPercent : usedPercent // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,remainingDays: null == remainingDays ? _self.remainingDays : remainingDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BudgetProgress].
extension BudgetProgressPatterns on BudgetProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BudgetProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BudgetProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BudgetProgress value)  $default,){
final _that = this;
switch (_that) {
case _BudgetProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BudgetProgress value)?  $default,){
final _that = this;
switch (_that) {
case _BudgetProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String month,  String scope,  int? categoryId,  String? categoryName,  int? memberUserId,  String? memberName,  String amount,  String used,  String remaining,  int usedPercent,  String level,  int remainingDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BudgetProgress() when $default != null:
return $default(_that.month,_that.scope,_that.categoryId,_that.categoryName,_that.memberUserId,_that.memberName,_that.amount,_that.used,_that.remaining,_that.usedPercent,_that.level,_that.remainingDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String month,  String scope,  int? categoryId,  String? categoryName,  int? memberUserId,  String? memberName,  String amount,  String used,  String remaining,  int usedPercent,  String level,  int remainingDays)  $default,) {final _that = this;
switch (_that) {
case _BudgetProgress():
return $default(_that.month,_that.scope,_that.categoryId,_that.categoryName,_that.memberUserId,_that.memberName,_that.amount,_that.used,_that.remaining,_that.usedPercent,_that.level,_that.remainingDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String month,  String scope,  int? categoryId,  String? categoryName,  int? memberUserId,  String? memberName,  String amount,  String used,  String remaining,  int usedPercent,  String level,  int remainingDays)?  $default,) {final _that = this;
switch (_that) {
case _BudgetProgress() when $default != null:
return $default(_that.month,_that.scope,_that.categoryId,_that.categoryName,_that.memberUserId,_that.memberName,_that.amount,_that.used,_that.remaining,_that.usedPercent,_that.level,_that.remainingDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BudgetProgress implements BudgetProgress {
  const _BudgetProgress({required this.month, required this.scope, this.categoryId, this.categoryName, this.memberUserId, this.memberName, required this.amount, required this.used, required this.remaining, required this.usedPercent, required this.level, required this.remainingDays});
  factory _BudgetProgress.fromJson(Map<String, dynamic> json) => _$BudgetProgressFromJson(json);

@override final  String month;
@override final  String scope;
@override final  int? categoryId;
@override final  String? categoryName;
@override final  int? memberUserId;
@override final  String? memberName;
@override final  String amount;
@override final  String used;
@override final  String remaining;
@override final  int usedPercent;
@override final  String level;
@override final  int remainingDays;

/// Create a copy of BudgetProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetProgressCopyWith<_BudgetProgress> get copyWith => __$BudgetProgressCopyWithImpl<_BudgetProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetProgressToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BudgetProgress&&(identical(other.month, month) || other.month == month)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.memberUserId, memberUserId) || other.memberUserId == memberUserId)&&(identical(other.memberName, memberName) || other.memberName == memberName)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.used, used) || other.used == used)&&(identical(other.remaining, remaining) || other.remaining == remaining)&&(identical(other.usedPercent, usedPercent) || other.usedPercent == usedPercent)&&(identical(other.level, level) || other.level == level)&&(identical(other.remainingDays, remainingDays) || other.remainingDays == remainingDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,month,scope,categoryId,categoryName,memberUserId,memberName,amount,used,remaining,usedPercent,level,remainingDays);
}

@override
String toString() {
    return 'BudgetProgress(month: $month, scope: $scope, categoryId: $categoryId, categoryName: $categoryName, memberUserId: $memberUserId, memberName: $memberName, amount: $amount, used: $used, remaining: $remaining, usedPercent: $usedPercent, level: $level, remainingDays: $remainingDays)';
}


}

/// @nodoc
abstract mixin class _$BudgetProgressCopyWith<$Res> implements $BudgetProgressCopyWith<$Res> {
  factory _$BudgetProgressCopyWith(_BudgetProgress value, $Res Function(_BudgetProgress) _then) = __$BudgetProgressCopyWithImpl;
@override @useResult
$Res call({
 String month, String scope, int? categoryId, String? categoryName, int? memberUserId, String? memberName, String amount, String used, String remaining, int usedPercent, String level, int remainingDays
});




}
/// @nodoc
class __$BudgetProgressCopyWithImpl<$Res>
    implements _$BudgetProgressCopyWith<$Res> {
  __$BudgetProgressCopyWithImpl(this._self, this._then);

  final _BudgetProgress _self;
  final $Res Function(_BudgetProgress) _then;

/// Create a copy of BudgetProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? scope = null,Object? categoryId = freezed,Object? categoryName = freezed,Object? memberUserId = freezed,Object? memberName = freezed,Object? amount = null,Object? used = null,Object? remaining = null,Object? usedPercent = null,Object? level = null,Object? remainingDays = null,}) {
  return _then(_BudgetProgress(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,memberUserId: freezed == memberUserId ? _self.memberUserId : memberUserId // ignore: cast_nullable_to_non_nullable
as int?,memberName: freezed == memberName ? _self.memberName : memberName // ignore: cast_nullable_to_non_nullable
as String?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,used: null == used ? _self.used : used // ignore: cast_nullable_to_non_nullable
as String,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as String,usedPercent: null == usedPercent ? _self.usedPercent : usedPercent // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,remainingDays: null == remainingDays ? _self.remainingDays : remainingDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
