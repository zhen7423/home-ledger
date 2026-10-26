// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder_setting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReminderSetting {

 String get type; String get label; bool get enabled; bool get pushed;
/// Create a copy of ReminderSetting
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReminderSettingCopyWith<ReminderSetting> get copyWith => _$ReminderSettingCopyWithImpl<ReminderSetting>(this as ReminderSetting, _$identity);

  /// Serializes this ReminderSetting to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReminderSetting;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReminderSetting&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.pushed, _this.pushed) || other.pushed == _this.pushed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReminderSetting;
  return Object.hash(runtimeType,_this.type,_this.label,_this.enabled,_this.pushed);
}

@override
String toString() {
  final _this = this as ReminderSetting;
  return 'ReminderSetting(type: ${_this.type}, label: ${_this.label}, enabled: ${_this.enabled}, pushed: ${_this.pushed})';
}


}

/// @nodoc
abstract mixin class $ReminderSettingCopyWith<$Res>  {
  factory $ReminderSettingCopyWith(ReminderSetting value, $Res Function(ReminderSetting) _then) = _$ReminderSettingCopyWithImpl;
@useResult
$Res call({
 String type, String label, bool enabled, bool pushed
});




}
/// @nodoc
class _$ReminderSettingCopyWithImpl<$Res>
    implements $ReminderSettingCopyWith<$Res> {
  _$ReminderSettingCopyWithImpl(this._self, this._then);

  final ReminderSetting _self;
  final $Res Function(ReminderSetting) _then;

/// Create a copy of ReminderSetting
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? label = null,Object? enabled = null,Object? pushed = null,}) {
  return _then(ReminderSetting(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,pushed: null == pushed ? _self.pushed : pushed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ReminderSetting].
extension ReminderSettingPatterns on ReminderSetting {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReminderSetting value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReminderSetting() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReminderSetting value)  $default,){
final _that = this;
switch (_that) {
case _ReminderSetting():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReminderSetting value)?  $default,){
final _that = this;
switch (_that) {
case _ReminderSetting() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String label,  bool enabled,  bool pushed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReminderSetting() when $default != null:
return $default(_that.type,_that.label,_that.enabled,_that.pushed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String label,  bool enabled,  bool pushed)  $default,) {final _that = this;
switch (_that) {
case _ReminderSetting():
return $default(_that.type,_that.label,_that.enabled,_that.pushed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String label,  bool enabled,  bool pushed)?  $default,) {final _that = this;
switch (_that) {
case _ReminderSetting() when $default != null:
return $default(_that.type,_that.label,_that.enabled,_that.pushed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReminderSetting implements ReminderSetting {
  const _ReminderSetting({required this.type, required this.label, required this.enabled, required this.pushed});
  factory _ReminderSetting.fromJson(Map<String, dynamic> json) => _$ReminderSettingFromJson(json);

@override final  String type;
@override final  String label;
@override final  bool enabled;
@override final  bool pushed;

/// Create a copy of ReminderSetting
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReminderSettingCopyWith<_ReminderSetting> get copyWith => __$ReminderSettingCopyWithImpl<_ReminderSetting>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReminderSettingToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReminderSetting&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.pushed, pushed) || other.pushed == pushed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,label,enabled,pushed);
}

@override
String toString() {
    return 'ReminderSetting(type: $type, label: $label, enabled: $enabled, pushed: $pushed)';
}


}

/// @nodoc
abstract mixin class _$ReminderSettingCopyWith<$Res> implements $ReminderSettingCopyWith<$Res> {
  factory _$ReminderSettingCopyWith(_ReminderSetting value, $Res Function(_ReminderSetting) _then) = __$ReminderSettingCopyWithImpl;
@override @useResult
$Res call({
 String type, String label, bool enabled, bool pushed
});




}
/// @nodoc
class __$ReminderSettingCopyWithImpl<$Res>
    implements _$ReminderSettingCopyWith<$Res> {
  __$ReminderSettingCopyWithImpl(this._self, this._then);

  final _ReminderSetting _self;
  final $Res Function(_ReminderSetting) _then;

/// Create a copy of ReminderSetting
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? label = null,Object? enabled = null,Object? pushed = null,}) {
  return _then(_ReminderSetting(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,pushed: null == pushed ? _self.pushed : pushed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
