// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reminder_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReminderState {

 Map<String, String> get notified; Map<String, String> get dismissed; bool get batteryGuideShown;
/// Create a copy of ReminderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReminderStateCopyWith<ReminderState> get copyWith => _$ReminderStateCopyWithImpl<ReminderState>(this as ReminderState, _$identity);

  /// Serializes this ReminderState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReminderState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReminderState&&const DeepCollectionEquality().equals(other.notified, _this.notified)&&const DeepCollectionEquality().equals(other.dismissed, _this.dismissed)&&(identical(other.batteryGuideShown, _this.batteryGuideShown) || other.batteryGuideShown == _this.batteryGuideShown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReminderState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.notified),const DeepCollectionEquality().hash(_this.dismissed),_this.batteryGuideShown);
}

@override
String toString() {
  final _this = this as ReminderState;
  return 'ReminderState(notified: ${_this.notified}, dismissed: ${_this.dismissed}, batteryGuideShown: ${_this.batteryGuideShown})';
}


}

/// @nodoc
abstract mixin class $ReminderStateCopyWith<$Res>  {
  factory $ReminderStateCopyWith(ReminderState value, $Res Function(ReminderState) _then) = _$ReminderStateCopyWithImpl;
@useResult
$Res call({
 Map<String, String> notified, Map<String, String> dismissed, bool batteryGuideShown
});




}
/// @nodoc
class _$ReminderStateCopyWithImpl<$Res>
    implements $ReminderStateCopyWith<$Res> {
  _$ReminderStateCopyWithImpl(this._self, this._then);

  final ReminderState _self;
  final $Res Function(ReminderState) _then;

/// Create a copy of ReminderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notified = null,Object? dismissed = null,Object? batteryGuideShown = null,}) {
  return _then(ReminderState(
notified: null == notified ? _self.notified : notified // ignore: cast_nullable_to_non_nullable
as Map<String, String>,dismissed: null == dismissed ? _self.dismissed : dismissed // ignore: cast_nullable_to_non_nullable
as Map<String, String>,batteryGuideShown: null == batteryGuideShown ? _self.batteryGuideShown : batteryGuideShown // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ReminderState].
extension ReminderStatePatterns on ReminderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReminderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReminderState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReminderState value)  $default,){
final _that = this;
switch (_that) {
case _ReminderState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReminderState value)?  $default,){
final _that = this;
switch (_that) {
case _ReminderState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, String> notified,  Map<String, String> dismissed,  bool batteryGuideShown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReminderState() when $default != null:
return $default(_that.notified,_that.dismissed,_that.batteryGuideShown);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, String> notified,  Map<String, String> dismissed,  bool batteryGuideShown)  $default,) {final _that = this;
switch (_that) {
case _ReminderState():
return $default(_that.notified,_that.dismissed,_that.batteryGuideShown);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, String> notified,  Map<String, String> dismissed,  bool batteryGuideShown)?  $default,) {final _that = this;
switch (_that) {
case _ReminderState() when $default != null:
return $default(_that.notified,_that.dismissed,_that.batteryGuideShown);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReminderState implements ReminderState {
  const _ReminderState({ Map<String, String> notified = const <String, String>{},  Map<String, String> dismissed = const <String, String>{}, this.batteryGuideShown = false}): _notified = notified,_dismissed = dismissed;
  factory _ReminderState.fromJson(Map<String, dynamic> json) => _$ReminderStateFromJson(json);

 final  Map<String, String> _notified;
@override@JsonKey() Map<String, String> get notified {
  if (_notified is EqualUnmodifiableMapView) return _notified;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_notified);
}

 final  Map<String, String> _dismissed;
@override@JsonKey() Map<String, String> get dismissed {
  if (_dismissed is EqualUnmodifiableMapView) return _dismissed;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dismissed);
}

@override@JsonKey() final  bool batteryGuideShown;

/// Create a copy of ReminderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReminderStateCopyWith<_ReminderState> get copyWith => __$ReminderStateCopyWithImpl<_ReminderState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReminderStateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReminderState&&const DeepCollectionEquality().equals(other.notified, _notified)&&const DeepCollectionEquality().equals(other.dismissed, _dismissed)&&(identical(other.batteryGuideShown, batteryGuideShown) || other.batteryGuideShown == batteryGuideShown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_notified),const DeepCollectionEquality().hash(_dismissed),batteryGuideShown);
}

@override
String toString() {
    return 'ReminderState(notified: $notified, dismissed: $dismissed, batteryGuideShown: $batteryGuideShown)';
}


}

/// @nodoc
abstract mixin class _$ReminderStateCopyWith<$Res> implements $ReminderStateCopyWith<$Res> {
  factory _$ReminderStateCopyWith(_ReminderState value, $Res Function(_ReminderState) _then) = __$ReminderStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, String> notified, Map<String, String> dismissed, bool batteryGuideShown
});




}
/// @nodoc
class __$ReminderStateCopyWithImpl<$Res>
    implements _$ReminderStateCopyWith<$Res> {
  __$ReminderStateCopyWithImpl(this._self, this._then);

  final _ReminderState _self;
  final $Res Function(_ReminderState) _then;

/// Create a copy of ReminderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notified = null,Object? dismissed = null,Object? batteryGuideShown = null,}) {
  return _then(_ReminderState(
notified: null == notified ? _self._notified : notified // ignore: cast_nullable_to_non_nullable
as Map<String, String>,dismissed: null == dismissed ? _self._dismissed : dismissed // ignore: cast_nullable_to_non_nullable
as Map<String, String>,batteryGuideShown: null == batteryGuideShown ? _self.batteryGuideShown : batteryGuideShown // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
