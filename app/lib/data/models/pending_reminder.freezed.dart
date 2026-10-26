// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_reminder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingReminder {

 String get type; String get module; String get key; String get title; String get body; String get route; DateTime? get fireAt; DateTime? get fireDate;
/// Create a copy of PendingReminder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingReminderCopyWith<PendingReminder> get copyWith => _$PendingReminderCopyWithImpl<PendingReminder>(this as PendingReminder, _$identity);

  /// Serializes this PendingReminder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PendingReminder;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingReminder&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.module, _this.module) || other.module == _this.module)&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body)&&(identical(other.route, _this.route) || other.route == _this.route)&&(identical(other.fireAt, _this.fireAt) || other.fireAt == _this.fireAt)&&(identical(other.fireDate, _this.fireDate) || other.fireDate == _this.fireDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PendingReminder;
  return Object.hash(runtimeType,_this.type,_this.module,_this.key,_this.title,_this.body,_this.route,_this.fireAt,_this.fireDate);
}

@override
String toString() {
  final _this = this as PendingReminder;
  return 'PendingReminder(type: ${_this.type}, module: ${_this.module}, key: ${_this.key}, title: ${_this.title}, body: ${_this.body}, route: ${_this.route}, fireAt: ${_this.fireAt}, fireDate: ${_this.fireDate})';
}


}

/// @nodoc
abstract mixin class $PendingReminderCopyWith<$Res>  {
  factory $PendingReminderCopyWith(PendingReminder value, $Res Function(PendingReminder) _then) = _$PendingReminderCopyWithImpl;
@useResult
$Res call({
 String type, String module, String key, String title, String body, String route, DateTime? fireAt, DateTime? fireDate
});




}
/// @nodoc
class _$PendingReminderCopyWithImpl<$Res>
    implements $PendingReminderCopyWith<$Res> {
  _$PendingReminderCopyWithImpl(this._self, this._then);

  final PendingReminder _self;
  final $Res Function(PendingReminder) _then;

/// Create a copy of PendingReminder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? module = null,Object? key = null,Object? title = null,Object? body = null,Object? route = null,Object? fireAt = freezed,Object? fireDate = freezed,}) {
  return _then(PendingReminder(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,module: null == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,fireAt: freezed == fireAt ? _self.fireAt : fireAt // ignore: cast_nullable_to_non_nullable
as DateTime?,fireDate: freezed == fireDate ? _self.fireDate : fireDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingReminder].
extension PendingReminderPatterns on PendingReminder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingReminder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingReminder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingReminder value)  $default,){
final _that = this;
switch (_that) {
case _PendingReminder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingReminder value)?  $default,){
final _that = this;
switch (_that) {
case _PendingReminder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String module,  String key,  String title,  String body,  String route,  DateTime? fireAt,  DateTime? fireDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingReminder() when $default != null:
return $default(_that.type,_that.module,_that.key,_that.title,_that.body,_that.route,_that.fireAt,_that.fireDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String module,  String key,  String title,  String body,  String route,  DateTime? fireAt,  DateTime? fireDate)  $default,) {final _that = this;
switch (_that) {
case _PendingReminder():
return $default(_that.type,_that.module,_that.key,_that.title,_that.body,_that.route,_that.fireAt,_that.fireDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String module,  String key,  String title,  String body,  String route,  DateTime? fireAt,  DateTime? fireDate)?  $default,) {final _that = this;
switch (_that) {
case _PendingReminder() when $default != null:
return $default(_that.type,_that.module,_that.key,_that.title,_that.body,_that.route,_that.fireAt,_that.fireDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingReminder implements PendingReminder {
  const _PendingReminder({required this.type, required this.module, required this.key, required this.title, required this.body, required this.route, this.fireAt, this.fireDate});
  factory _PendingReminder.fromJson(Map<String, dynamic> json) => _$PendingReminderFromJson(json);

@override final  String type;
@override final  String module;
@override final  String key;
@override final  String title;
@override final  String body;
@override final  String route;
@override final  DateTime? fireAt;
@override final  DateTime? fireDate;

/// Create a copy of PendingReminder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingReminderCopyWith<_PendingReminder> get copyWith => __$PendingReminderCopyWithImpl<_PendingReminder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingReminderToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingReminder&&(identical(other.type, type) || other.type == type)&&(identical(other.module, module) || other.module == module)&&(identical(other.key, key) || other.key == key)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.route, route) || other.route == route)&&(identical(other.fireAt, fireAt) || other.fireAt == fireAt)&&(identical(other.fireDate, fireDate) || other.fireDate == fireDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,module,key,title,body,route,fireAt,fireDate);
}

@override
String toString() {
    return 'PendingReminder(type: $type, module: $module, key: $key, title: $title, body: $body, route: $route, fireAt: $fireAt, fireDate: $fireDate)';
}


}

/// @nodoc
abstract mixin class _$PendingReminderCopyWith<$Res> implements $PendingReminderCopyWith<$Res> {
  factory _$PendingReminderCopyWith(_PendingReminder value, $Res Function(_PendingReminder) _then) = __$PendingReminderCopyWithImpl;
@override @useResult
$Res call({
 String type, String module, String key, String title, String body, String route, DateTime? fireAt, DateTime? fireDate
});




}
/// @nodoc
class __$PendingReminderCopyWithImpl<$Res>
    implements _$PendingReminderCopyWith<$Res> {
  __$PendingReminderCopyWithImpl(this._self, this._then);

  final _PendingReminder _self;
  final $Res Function(_PendingReminder) _then;

/// Create a copy of PendingReminder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? module = null,Object? key = null,Object? title = null,Object? body = null,Object? route = null,Object? fireAt = freezed,Object? fireDate = freezed,}) {
  return _then(_PendingReminder(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,module: null == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,fireAt: freezed == fireAt ? _self.fireAt : fireAt // ignore: cast_nullable_to_non_nullable
as DateTime?,fireDate: freezed == fireDate ? _self.fireDate : fireDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
