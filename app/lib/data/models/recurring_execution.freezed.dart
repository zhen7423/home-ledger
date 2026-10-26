// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recurring_execution.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecurringExecution {

 int get id; DateTime get bizDate; int get transactionId; DateTime get executedDate; bool get backfilled;
/// Create a copy of RecurringExecution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecurringExecutionCopyWith<RecurringExecution> get copyWith => _$RecurringExecutionCopyWithImpl<RecurringExecution>(this as RecurringExecution, _$identity);

  /// Serializes this RecurringExecution to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RecurringExecution;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecurringExecution&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.bizDate, _this.bizDate) || other.bizDate == _this.bizDate)&&(identical(other.transactionId, _this.transactionId) || other.transactionId == _this.transactionId)&&(identical(other.executedDate, _this.executedDate) || other.executedDate == _this.executedDate)&&(identical(other.backfilled, _this.backfilled) || other.backfilled == _this.backfilled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecurringExecution;
  return Object.hash(runtimeType,_this.id,_this.bizDate,_this.transactionId,_this.executedDate,_this.backfilled);
}

@override
String toString() {
  final _this = this as RecurringExecution;
  return 'RecurringExecution(id: ${_this.id}, bizDate: ${_this.bizDate}, transactionId: ${_this.transactionId}, executedDate: ${_this.executedDate}, backfilled: ${_this.backfilled})';
}


}

/// @nodoc
abstract mixin class $RecurringExecutionCopyWith<$Res>  {
  factory $RecurringExecutionCopyWith(RecurringExecution value, $Res Function(RecurringExecution) _then) = _$RecurringExecutionCopyWithImpl;
@useResult
$Res call({
 int id, DateTime bizDate, int transactionId, DateTime executedDate, bool backfilled
});




}
/// @nodoc
class _$RecurringExecutionCopyWithImpl<$Res>
    implements $RecurringExecutionCopyWith<$Res> {
  _$RecurringExecutionCopyWithImpl(this._self, this._then);

  final RecurringExecution _self;
  final $Res Function(RecurringExecution) _then;

/// Create a copy of RecurringExecution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bizDate = null,Object? transactionId = null,Object? executedDate = null,Object? backfilled = null,}) {
  return _then(RecurringExecution(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,bizDate: null == bizDate ? _self.bizDate : bizDate // ignore: cast_nullable_to_non_nullable
as DateTime,transactionId: null == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as int,executedDate: null == executedDate ? _self.executedDate : executedDate // ignore: cast_nullable_to_non_nullable
as DateTime,backfilled: null == backfilled ? _self.backfilled : backfilled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RecurringExecution].
extension RecurringExecutionPatterns on RecurringExecution {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecurringExecution value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecurringExecution() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecurringExecution value)  $default,){
final _that = this;
switch (_that) {
case _RecurringExecution():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecurringExecution value)?  $default,){
final _that = this;
switch (_that) {
case _RecurringExecution() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  DateTime bizDate,  int transactionId,  DateTime executedDate,  bool backfilled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecurringExecution() when $default != null:
return $default(_that.id,_that.bizDate,_that.transactionId,_that.executedDate,_that.backfilled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  DateTime bizDate,  int transactionId,  DateTime executedDate,  bool backfilled)  $default,) {final _that = this;
switch (_that) {
case _RecurringExecution():
return $default(_that.id,_that.bizDate,_that.transactionId,_that.executedDate,_that.backfilled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  DateTime bizDate,  int transactionId,  DateTime executedDate,  bool backfilled)?  $default,) {final _that = this;
switch (_that) {
case _RecurringExecution() when $default != null:
return $default(_that.id,_that.bizDate,_that.transactionId,_that.executedDate,_that.backfilled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecurringExecution implements RecurringExecution {
  const _RecurringExecution({required this.id, required this.bizDate, required this.transactionId, required this.executedDate, required this.backfilled});
  factory _RecurringExecution.fromJson(Map<String, dynamic> json) => _$RecurringExecutionFromJson(json);

@override final  int id;
@override final  DateTime bizDate;
@override final  int transactionId;
@override final  DateTime executedDate;
@override final  bool backfilled;

/// Create a copy of RecurringExecution
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecurringExecutionCopyWith<_RecurringExecution> get copyWith => __$RecurringExecutionCopyWithImpl<_RecurringExecution>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecurringExecutionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecurringExecution&&(identical(other.id, id) || other.id == id)&&(identical(other.bizDate, bizDate) || other.bizDate == bizDate)&&(identical(other.transactionId, transactionId) || other.transactionId == transactionId)&&(identical(other.executedDate, executedDate) || other.executedDate == executedDate)&&(identical(other.backfilled, backfilled) || other.backfilled == backfilled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,bizDate,transactionId,executedDate,backfilled);
}

@override
String toString() {
    return 'RecurringExecution(id: $id, bizDate: $bizDate, transactionId: $transactionId, executedDate: $executedDate, backfilled: $backfilled)';
}


}

/// @nodoc
abstract mixin class _$RecurringExecutionCopyWith<$Res> implements $RecurringExecutionCopyWith<$Res> {
  factory _$RecurringExecutionCopyWith(_RecurringExecution value, $Res Function(_RecurringExecution) _then) = __$RecurringExecutionCopyWithImpl;
@override @useResult
$Res call({
 int id, DateTime bizDate, int transactionId, DateTime executedDate, bool backfilled
});




}
/// @nodoc
class __$RecurringExecutionCopyWithImpl<$Res>
    implements _$RecurringExecutionCopyWith<$Res> {
  __$RecurringExecutionCopyWithImpl(this._self, this._then);

  final _RecurringExecution _self;
  final $Res Function(_RecurringExecution) _then;

/// Create a copy of RecurringExecution
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bizDate = null,Object? transactionId = null,Object? executedDate = null,Object? backfilled = null,}) {
  return _then(_RecurringExecution(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,bizDate: null == bizDate ? _self.bizDate : bizDate // ignore: cast_nullable_to_non_nullable
as DateTime,transactionId: null == transactionId ? _self.transactionId : transactionId // ignore: cast_nullable_to_non_nullable
as int,executedDate: null == executedDate ? _self.executedDate : executedDate // ignore: cast_nullable_to_non_nullable
as DateTime,backfilled: null == backfilled ? _self.backfilled : backfilled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
