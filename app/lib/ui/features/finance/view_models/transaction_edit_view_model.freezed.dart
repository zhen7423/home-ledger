// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_edit_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionEditState {

 bool get loading; bool get submitting; Transaction? get original;
/// Create a copy of TransactionEditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionEditStateCopyWith<TransactionEditState> get copyWith => _$TransactionEditStateCopyWithImpl<TransactionEditState>(this as TransactionEditState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TransactionEditState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionEditState&&(identical(other.loading, _this.loading) || other.loading == _this.loading)&&(identical(other.submitting, _this.submitting) || other.submitting == _this.submitting)&&(identical(other.original, _this.original) || other.original == _this.original));
}


@override
int get hashCode {
  final _this = this as TransactionEditState;
  return Object.hash(runtimeType,_this.loading,_this.submitting,_this.original);
}

@override
String toString() {
  final _this = this as TransactionEditState;
  return 'TransactionEditState(loading: ${_this.loading}, submitting: ${_this.submitting}, original: ${_this.original})';
}


}

/// @nodoc
abstract mixin class $TransactionEditStateCopyWith<$Res>  {
  factory $TransactionEditStateCopyWith(TransactionEditState value, $Res Function(TransactionEditState) _then) = _$TransactionEditStateCopyWithImpl;
@useResult
$Res call({
 bool loading, bool submitting, Transaction? original
});


$TransactionCopyWith<$Res>? get original;

}
/// @nodoc
class _$TransactionEditStateCopyWithImpl<$Res>
    implements $TransactionEditStateCopyWith<$Res> {
  _$TransactionEditStateCopyWithImpl(this._self, this._then);

  final TransactionEditState _self;
  final $Res Function(TransactionEditState) _then;

/// Create a copy of TransactionEditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loading = null,Object? submitting = null,Object? original = freezed,}) {
  return _then(TransactionEditState(
loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,original: freezed == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as Transaction?,
  ));
}
/// Create a copy of TransactionEditState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionCopyWith<$Res>? get original {
    if (_self.original == null) {
    return null;
  }

  return $TransactionCopyWith<$Res>(_self.original!, (value) {
    return _then(_self.copyWith(original: value));
  });
}
}


/// Adds pattern-matching-related methods to [TransactionEditState].
extension TransactionEditStatePatterns on TransactionEditState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionEditState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionEditState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionEditState value)  $default,){
final _that = this;
switch (_that) {
case _TransactionEditState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionEditState value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionEditState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool loading,  bool submitting,  Transaction? original)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionEditState() when $default != null:
return $default(_that.loading,_that.submitting,_that.original);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool loading,  bool submitting,  Transaction? original)  $default,) {final _that = this;
switch (_that) {
case _TransactionEditState():
return $default(_that.loading,_that.submitting,_that.original);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool loading,  bool submitting,  Transaction? original)?  $default,) {final _that = this;
switch (_that) {
case _TransactionEditState() when $default != null:
return $default(_that.loading,_that.submitting,_that.original);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionEditState implements TransactionEditState {
  const _TransactionEditState({this.loading = false, this.submitting = false, this.original});
  

@override@JsonKey() final  bool loading;
@override@JsonKey() final  bool submitting;
@override final  Transaction? original;

/// Create a copy of TransactionEditState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionEditStateCopyWith<_TransactionEditState> get copyWith => __$TransactionEditStateCopyWithImpl<_TransactionEditState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionEditState&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.original, original) || other.original == original));
}


@override
int get hashCode {
    return Object.hash(runtimeType,loading,submitting,original);
}

@override
String toString() {
    return 'TransactionEditState(loading: $loading, submitting: $submitting, original: $original)';
}


}

/// @nodoc
abstract mixin class _$TransactionEditStateCopyWith<$Res> implements $TransactionEditStateCopyWith<$Res> {
  factory _$TransactionEditStateCopyWith(_TransactionEditState value, $Res Function(_TransactionEditState) _then) = __$TransactionEditStateCopyWithImpl;
@override @useResult
$Res call({
 bool loading, bool submitting, Transaction? original
});


@override $TransactionCopyWith<$Res>? get original;

}
/// @nodoc
class __$TransactionEditStateCopyWithImpl<$Res>
    implements _$TransactionEditStateCopyWith<$Res> {
  __$TransactionEditStateCopyWithImpl(this._self, this._then);

  final _TransactionEditState _self;
  final $Res Function(_TransactionEditState) _then;

/// Create a copy of TransactionEditState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loading = null,Object? submitting = null,Object? original = freezed,}) {
  return _then(_TransactionEditState(
loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,original: freezed == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as Transaction?,
  ));
}

/// Create a copy of TransactionEditState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionCopyWith<$Res>? get original {
    if (_self.original == null) {
    return null;
  }

  return $TransactionCopyWith<$Res>(_self.original!, (value) {
    return _then(_self.copyWith(original: value));
  });
}
}

// dart format on
