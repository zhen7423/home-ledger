// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'token_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TokenResponse {

 String get tokenType; String get accessToken; int get accessExpiresInSeconds; String get refreshToken; int get refreshExpiresInSeconds;
/// Create a copy of TokenResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TokenResponseCopyWith<TokenResponse> get copyWith => _$TokenResponseCopyWithImpl<TokenResponse>(this as TokenResponse, _$identity);

  /// Serializes this TokenResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TokenResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TokenResponse&&(identical(other.tokenType, _this.tokenType) || other.tokenType == _this.tokenType)&&(identical(other.accessToken, _this.accessToken) || other.accessToken == _this.accessToken)&&(identical(other.accessExpiresInSeconds, _this.accessExpiresInSeconds) || other.accessExpiresInSeconds == _this.accessExpiresInSeconds)&&(identical(other.refreshToken, _this.refreshToken) || other.refreshToken == _this.refreshToken)&&(identical(other.refreshExpiresInSeconds, _this.refreshExpiresInSeconds) || other.refreshExpiresInSeconds == _this.refreshExpiresInSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TokenResponse;
  return Object.hash(runtimeType,_this.tokenType,_this.accessToken,_this.accessExpiresInSeconds,_this.refreshToken,_this.refreshExpiresInSeconds);
}

@override
String toString() {
  final _this = this as TokenResponse;
  return 'TokenResponse(tokenType: ${_this.tokenType}, accessToken: ${_this.accessToken}, accessExpiresInSeconds: ${_this.accessExpiresInSeconds}, refreshToken: ${_this.refreshToken}, refreshExpiresInSeconds: ${_this.refreshExpiresInSeconds})';
}


}

/// @nodoc
abstract mixin class $TokenResponseCopyWith<$Res>  {
  factory $TokenResponseCopyWith(TokenResponse value, $Res Function(TokenResponse) _then) = _$TokenResponseCopyWithImpl;
@useResult
$Res call({
 String tokenType, String accessToken, int accessExpiresInSeconds, String refreshToken, int refreshExpiresInSeconds
});




}
/// @nodoc
class _$TokenResponseCopyWithImpl<$Res>
    implements $TokenResponseCopyWith<$Res> {
  _$TokenResponseCopyWithImpl(this._self, this._then);

  final TokenResponse _self;
  final $Res Function(TokenResponse) _then;

/// Create a copy of TokenResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tokenType = null,Object? accessToken = null,Object? accessExpiresInSeconds = null,Object? refreshToken = null,Object? refreshExpiresInSeconds = null,}) {
  return _then(TokenResponse(
tokenType: null == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,accessExpiresInSeconds: null == accessExpiresInSeconds ? _self.accessExpiresInSeconds : accessExpiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,refreshExpiresInSeconds: null == refreshExpiresInSeconds ? _self.refreshExpiresInSeconds : refreshExpiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TokenResponse].
extension TokenResponsePatterns on TokenResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TokenResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TokenResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TokenResponse value)  $default,){
final _that = this;
switch (_that) {
case _TokenResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TokenResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TokenResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tokenType,  String accessToken,  int accessExpiresInSeconds,  String refreshToken,  int refreshExpiresInSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TokenResponse() when $default != null:
return $default(_that.tokenType,_that.accessToken,_that.accessExpiresInSeconds,_that.refreshToken,_that.refreshExpiresInSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tokenType,  String accessToken,  int accessExpiresInSeconds,  String refreshToken,  int refreshExpiresInSeconds)  $default,) {final _that = this;
switch (_that) {
case _TokenResponse():
return $default(_that.tokenType,_that.accessToken,_that.accessExpiresInSeconds,_that.refreshToken,_that.refreshExpiresInSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tokenType,  String accessToken,  int accessExpiresInSeconds,  String refreshToken,  int refreshExpiresInSeconds)?  $default,) {final _that = this;
switch (_that) {
case _TokenResponse() when $default != null:
return $default(_that.tokenType,_that.accessToken,_that.accessExpiresInSeconds,_that.refreshToken,_that.refreshExpiresInSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TokenResponse implements TokenResponse {
  const _TokenResponse({required this.tokenType, required this.accessToken, required this.accessExpiresInSeconds, required this.refreshToken, required this.refreshExpiresInSeconds});
  factory _TokenResponse.fromJson(Map<String, dynamic> json) => _$TokenResponseFromJson(json);

@override final  String tokenType;
@override final  String accessToken;
@override final  int accessExpiresInSeconds;
@override final  String refreshToken;
@override final  int refreshExpiresInSeconds;

/// Create a copy of TokenResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokenResponseCopyWith<_TokenResponse> get copyWith => __$TokenResponseCopyWithImpl<_TokenResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TokenResponseToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TokenResponse&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType)&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.accessExpiresInSeconds, accessExpiresInSeconds) || other.accessExpiresInSeconds == accessExpiresInSeconds)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.refreshExpiresInSeconds, refreshExpiresInSeconds) || other.refreshExpiresInSeconds == refreshExpiresInSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,tokenType,accessToken,accessExpiresInSeconds,refreshToken,refreshExpiresInSeconds);
}

@override
String toString() {
    return 'TokenResponse(tokenType: $tokenType, accessToken: $accessToken, accessExpiresInSeconds: $accessExpiresInSeconds, refreshToken: $refreshToken, refreshExpiresInSeconds: $refreshExpiresInSeconds)';
}


}

/// @nodoc
abstract mixin class _$TokenResponseCopyWith<$Res> implements $TokenResponseCopyWith<$Res> {
  factory _$TokenResponseCopyWith(_TokenResponse value, $Res Function(_TokenResponse) _then) = __$TokenResponseCopyWithImpl;
@override @useResult
$Res call({
 String tokenType, String accessToken, int accessExpiresInSeconds, String refreshToken, int refreshExpiresInSeconds
});




}
/// @nodoc
class __$TokenResponseCopyWithImpl<$Res>
    implements _$TokenResponseCopyWith<$Res> {
  __$TokenResponseCopyWithImpl(this._self, this._then);

  final _TokenResponse _self;
  final $Res Function(_TokenResponse) _then;

/// Create a copy of TokenResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tokenType = null,Object? accessToken = null,Object? accessExpiresInSeconds = null,Object? refreshToken = null,Object? refreshExpiresInSeconds = null,}) {
  return _then(_TokenResponse(
tokenType: null == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String,accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,accessExpiresInSeconds: null == accessExpiresInSeconds ? _self.accessExpiresInSeconds : accessExpiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,refreshExpiresInSeconds: null == refreshExpiresInSeconds ? _self.refreshExpiresInSeconds : refreshExpiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
