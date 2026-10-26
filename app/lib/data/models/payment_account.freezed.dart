// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentAccount {

 int get id; String get name; int get sortNo; bool get isDefault; bool get enabled;
/// Create a copy of PaymentAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentAccountCopyWith<PaymentAccount> get copyWith => _$PaymentAccountCopyWithImpl<PaymentAccount>(this as PaymentAccount, _$identity);

  /// Serializes this PaymentAccount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaymentAccount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentAccount&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.sortNo, _this.sortNo) || other.sortNo == _this.sortNo)&&(identical(other.isDefault, _this.isDefault) || other.isDefault == _this.isDefault)&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaymentAccount;
  return Object.hash(runtimeType,_this.id,_this.name,_this.sortNo,_this.isDefault,_this.enabled);
}

@override
String toString() {
  final _this = this as PaymentAccount;
  return 'PaymentAccount(id: ${_this.id}, name: ${_this.name}, sortNo: ${_this.sortNo}, isDefault: ${_this.isDefault}, enabled: ${_this.enabled})';
}


}

/// @nodoc
abstract mixin class $PaymentAccountCopyWith<$Res>  {
  factory $PaymentAccountCopyWith(PaymentAccount value, $Res Function(PaymentAccount) _then) = _$PaymentAccountCopyWithImpl;
@useResult
$Res call({
 int id, String name, int sortNo, bool isDefault, bool enabled
});




}
/// @nodoc
class _$PaymentAccountCopyWithImpl<$Res>
    implements $PaymentAccountCopyWith<$Res> {
  _$PaymentAccountCopyWithImpl(this._self, this._then);

  final PaymentAccount _self;
  final $Res Function(PaymentAccount) _then;

/// Create a copy of PaymentAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? sortNo = null,Object? isDefault = null,Object? enabled = null,}) {
  return _then(PaymentAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sortNo: null == sortNo ? _self.sortNo : sortNo // ignore: cast_nullable_to_non_nullable
as int,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentAccount].
extension PaymentAccountPatterns on PaymentAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentAccount value)  $default,){
final _that = this;
switch (_that) {
case _PaymentAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentAccount value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  int sortNo,  bool isDefault,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentAccount() when $default != null:
return $default(_that.id,_that.name,_that.sortNo,_that.isDefault,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  int sortNo,  bool isDefault,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _PaymentAccount():
return $default(_that.id,_that.name,_that.sortNo,_that.isDefault,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  int sortNo,  bool isDefault,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _PaymentAccount() when $default != null:
return $default(_that.id,_that.name,_that.sortNo,_that.isDefault,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentAccount implements PaymentAccount {
  const _PaymentAccount({required this.id, required this.name, required this.sortNo, required this.isDefault, required this.enabled});
  factory _PaymentAccount.fromJson(Map<String, dynamic> json) => _$PaymentAccountFromJson(json);

@override final  int id;
@override final  String name;
@override final  int sortNo;
@override final  bool isDefault;
@override final  bool enabled;

/// Create a copy of PaymentAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentAccountCopyWith<_PaymentAccount> get copyWith => __$PaymentAccountCopyWithImpl<_PaymentAccount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentAccountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sortNo, sortNo) || other.sortNo == sortNo)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,sortNo,isDefault,enabled);
}

@override
String toString() {
    return 'PaymentAccount(id: $id, name: $name, sortNo: $sortNo, isDefault: $isDefault, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$PaymentAccountCopyWith<$Res> implements $PaymentAccountCopyWith<$Res> {
  factory _$PaymentAccountCopyWith(_PaymentAccount value, $Res Function(_PaymentAccount) _then) = __$PaymentAccountCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, int sortNo, bool isDefault, bool enabled
});




}
/// @nodoc
class __$PaymentAccountCopyWithImpl<$Res>
    implements _$PaymentAccountCopyWith<$Res> {
  __$PaymentAccountCopyWithImpl(this._self, this._then);

  final _PaymentAccount _self;
  final $Res Function(_PaymentAccount) _then;

/// Create a copy of PaymentAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? sortNo = null,Object? isDefault = null,Object? enabled = null,}) {
  return _then(_PaymentAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sortNo: null == sortNo ? _self.sortNo : sortNo // ignore: cast_nullable_to_non_nullable
as int,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
