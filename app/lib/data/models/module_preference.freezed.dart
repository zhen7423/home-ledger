// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'module_preference.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ModulePreference {

 String get moduleKey; String get label; bool get enabled; int get sortNo;
/// Create a copy of ModulePreference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModulePreferenceCopyWith<ModulePreference> get copyWith => _$ModulePreferenceCopyWithImpl<ModulePreference>(this as ModulePreference, _$identity);

  /// Serializes this ModulePreference to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ModulePreference;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModulePreference&&(identical(other.moduleKey, _this.moduleKey) || other.moduleKey == _this.moduleKey)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.sortNo, _this.sortNo) || other.sortNo == _this.sortNo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ModulePreference;
  return Object.hash(runtimeType,_this.moduleKey,_this.label,_this.enabled,_this.sortNo);
}

@override
String toString() {
  final _this = this as ModulePreference;
  return 'ModulePreference(moduleKey: ${_this.moduleKey}, label: ${_this.label}, enabled: ${_this.enabled}, sortNo: ${_this.sortNo})';
}


}

/// @nodoc
abstract mixin class $ModulePreferenceCopyWith<$Res>  {
  factory $ModulePreferenceCopyWith(ModulePreference value, $Res Function(ModulePreference) _then) = _$ModulePreferenceCopyWithImpl;
@useResult
$Res call({
 String moduleKey, String label, bool enabled, int sortNo
});




}
/// @nodoc
class _$ModulePreferenceCopyWithImpl<$Res>
    implements $ModulePreferenceCopyWith<$Res> {
  _$ModulePreferenceCopyWithImpl(this._self, this._then);

  final ModulePreference _self;
  final $Res Function(ModulePreference) _then;

/// Create a copy of ModulePreference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? moduleKey = null,Object? label = null,Object? enabled = null,Object? sortNo = null,}) {
  return _then(ModulePreference(
moduleKey: null == moduleKey ? _self.moduleKey : moduleKey // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,sortNo: null == sortNo ? _self.sortNo : sortNo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ModulePreference].
extension ModulePreferencePatterns on ModulePreference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModulePreference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModulePreference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModulePreference value)  $default,){
final _that = this;
switch (_that) {
case _ModulePreference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModulePreference value)?  $default,){
final _that = this;
switch (_that) {
case _ModulePreference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String moduleKey,  String label,  bool enabled,  int sortNo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModulePreference() when $default != null:
return $default(_that.moduleKey,_that.label,_that.enabled,_that.sortNo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String moduleKey,  String label,  bool enabled,  int sortNo)  $default,) {final _that = this;
switch (_that) {
case _ModulePreference():
return $default(_that.moduleKey,_that.label,_that.enabled,_that.sortNo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String moduleKey,  String label,  bool enabled,  int sortNo)?  $default,) {final _that = this;
switch (_that) {
case _ModulePreference() when $default != null:
return $default(_that.moduleKey,_that.label,_that.enabled,_that.sortNo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModulePreference implements ModulePreference {
  const _ModulePreference({required this.moduleKey, required this.label, required this.enabled, required this.sortNo});
  factory _ModulePreference.fromJson(Map<String, dynamic> json) => _$ModulePreferenceFromJson(json);

@override final  String moduleKey;
@override final  String label;
@override final  bool enabled;
@override final  int sortNo;

/// Create a copy of ModulePreference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModulePreferenceCopyWith<_ModulePreference> get copyWith => __$ModulePreferenceCopyWithImpl<_ModulePreference>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModulePreferenceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModulePreference&&(identical(other.moduleKey, moduleKey) || other.moduleKey == moduleKey)&&(identical(other.label, label) || other.label == label)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.sortNo, sortNo) || other.sortNo == sortNo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,moduleKey,label,enabled,sortNo);
}

@override
String toString() {
    return 'ModulePreference(moduleKey: $moduleKey, label: $label, enabled: $enabled, sortNo: $sortNo)';
}


}

/// @nodoc
abstract mixin class _$ModulePreferenceCopyWith<$Res> implements $ModulePreferenceCopyWith<$Res> {
  factory _$ModulePreferenceCopyWith(_ModulePreference value, $Res Function(_ModulePreference) _then) = __$ModulePreferenceCopyWithImpl;
@override @useResult
$Res call({
 String moduleKey, String label, bool enabled, int sortNo
});




}
/// @nodoc
class __$ModulePreferenceCopyWithImpl<$Res>
    implements _$ModulePreferenceCopyWith<$Res> {
  __$ModulePreferenceCopyWithImpl(this._self, this._then);

  final _ModulePreference _self;
  final $Res Function(_ModulePreference) _then;

/// Create a copy of ModulePreference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? moduleKey = null,Object? label = null,Object? enabled = null,Object? sortNo = null,}) {
  return _then(_ModulePreference(
moduleKey: null == moduleKey ? _self.moduleKey : moduleKey // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,sortNo: null == sortNo ? _self.sortNo : sortNo // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
