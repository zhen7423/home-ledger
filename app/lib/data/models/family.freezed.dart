// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Family {

 int get id; String get name; int get ownerUserId; bool get inviteEnabled; String? get inviteCode; DateTime? get inviteCodeExpireAt; List<Member> get members;
/// Create a copy of Family
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilyCopyWith<Family> get copyWith => _$FamilyCopyWithImpl<Family>(this as Family, _$identity);

  /// Serializes this Family to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Family;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Family&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.ownerUserId, _this.ownerUserId) || other.ownerUserId == _this.ownerUserId)&&(identical(other.inviteEnabled, _this.inviteEnabled) || other.inviteEnabled == _this.inviteEnabled)&&(identical(other.inviteCode, _this.inviteCode) || other.inviteCode == _this.inviteCode)&&(identical(other.inviteCodeExpireAt, _this.inviteCodeExpireAt) || other.inviteCodeExpireAt == _this.inviteCodeExpireAt)&&const DeepCollectionEquality().equals(other.members, _this.members));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Family;
  return Object.hash(runtimeType,_this.id,_this.name,_this.ownerUserId,_this.inviteEnabled,_this.inviteCode,_this.inviteCodeExpireAt,const DeepCollectionEquality().hash(_this.members));
}

@override
String toString() {
  final _this = this as Family;
  return 'Family(id: ${_this.id}, name: ${_this.name}, ownerUserId: ${_this.ownerUserId}, inviteEnabled: ${_this.inviteEnabled}, inviteCode: ${_this.inviteCode}, inviteCodeExpireAt: ${_this.inviteCodeExpireAt}, members: ${_this.members})';
}


}

/// @nodoc
abstract mixin class $FamilyCopyWith<$Res>  {
  factory $FamilyCopyWith(Family value, $Res Function(Family) _then) = _$FamilyCopyWithImpl;
@useResult
$Res call({
 int id, String name, int ownerUserId, bool inviteEnabled, String? inviteCode, DateTime? inviteCodeExpireAt, List<Member> members
});




}
/// @nodoc
class _$FamilyCopyWithImpl<$Res>
    implements $FamilyCopyWith<$Res> {
  _$FamilyCopyWithImpl(this._self, this._then);

  final Family _self;
  final $Res Function(Family) _then;

/// Create a copy of Family
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? ownerUserId = null,Object? inviteEnabled = null,Object? inviteCode = freezed,Object? inviteCodeExpireAt = freezed,Object? members = null,}) {
  return _then(Family(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownerUserId: null == ownerUserId ? _self.ownerUserId : ownerUserId // ignore: cast_nullable_to_non_nullable
as int,inviteEnabled: null == inviteEnabled ? _self.inviteEnabled : inviteEnabled // ignore: cast_nullable_to_non_nullable
as bool,inviteCode: freezed == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String?,inviteCodeExpireAt: freezed == inviteCodeExpireAt ? _self.inviteCodeExpireAt : inviteCodeExpireAt // ignore: cast_nullable_to_non_nullable
as DateTime?,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<Member>,
  ));
}

}


/// Adds pattern-matching-related methods to [Family].
extension FamilyPatterns on Family {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Family value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Family() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Family value)  $default,){
final _that = this;
switch (_that) {
case _Family():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Family value)?  $default,){
final _that = this;
switch (_that) {
case _Family() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  int ownerUserId,  bool inviteEnabled,  String? inviteCode,  DateTime? inviteCodeExpireAt,  List<Member> members)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Family() when $default != null:
return $default(_that.id,_that.name,_that.ownerUserId,_that.inviteEnabled,_that.inviteCode,_that.inviteCodeExpireAt,_that.members);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  int ownerUserId,  bool inviteEnabled,  String? inviteCode,  DateTime? inviteCodeExpireAt,  List<Member> members)  $default,) {final _that = this;
switch (_that) {
case _Family():
return $default(_that.id,_that.name,_that.ownerUserId,_that.inviteEnabled,_that.inviteCode,_that.inviteCodeExpireAt,_that.members);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  int ownerUserId,  bool inviteEnabled,  String? inviteCode,  DateTime? inviteCodeExpireAt,  List<Member> members)?  $default,) {final _that = this;
switch (_that) {
case _Family() when $default != null:
return $default(_that.id,_that.name,_that.ownerUserId,_that.inviteEnabled,_that.inviteCode,_that.inviteCodeExpireAt,_that.members);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Family implements Family {
  const _Family({required this.id, required this.name, required this.ownerUserId, required this.inviteEnabled, this.inviteCode, this.inviteCodeExpireAt, required  List<Member> members}): _members = members;
  factory _Family.fromJson(Map<String, dynamic> json) => _$FamilyFromJson(json);

@override final  int id;
@override final  String name;
@override final  int ownerUserId;
@override final  bool inviteEnabled;
@override final  String? inviteCode;
@override final  DateTime? inviteCodeExpireAt;
 final  List<Member> _members;
@override List<Member> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}


/// Create a copy of Family
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilyCopyWith<_Family> get copyWith => __$FamilyCopyWithImpl<_Family>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FamilyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Family&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.ownerUserId, ownerUserId) || other.ownerUserId == ownerUserId)&&(identical(other.inviteEnabled, inviteEnabled) || other.inviteEnabled == inviteEnabled)&&(identical(other.inviteCode, inviteCode) || other.inviteCode == inviteCode)&&(identical(other.inviteCodeExpireAt, inviteCodeExpireAt) || other.inviteCodeExpireAt == inviteCodeExpireAt)&&const DeepCollectionEquality().equals(other.members, _members));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,ownerUserId,inviteEnabled,inviteCode,inviteCodeExpireAt,const DeepCollectionEquality().hash(_members));
}

@override
String toString() {
    return 'Family(id: $id, name: $name, ownerUserId: $ownerUserId, inviteEnabled: $inviteEnabled, inviteCode: $inviteCode, inviteCodeExpireAt: $inviteCodeExpireAt, members: $members)';
}


}

/// @nodoc
abstract mixin class _$FamilyCopyWith<$Res> implements $FamilyCopyWith<$Res> {
  factory _$FamilyCopyWith(_Family value, $Res Function(_Family) _then) = __$FamilyCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, int ownerUserId, bool inviteEnabled, String? inviteCode, DateTime? inviteCodeExpireAt, List<Member> members
});




}
/// @nodoc
class __$FamilyCopyWithImpl<$Res>
    implements _$FamilyCopyWith<$Res> {
  __$FamilyCopyWithImpl(this._self, this._then);

  final _Family _self;
  final $Res Function(_Family) _then;

/// Create a copy of Family
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? ownerUserId = null,Object? inviteEnabled = null,Object? inviteCode = freezed,Object? inviteCodeExpireAt = freezed,Object? members = null,}) {
  return _then(_Family(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownerUserId: null == ownerUserId ? _self.ownerUserId : ownerUserId // ignore: cast_nullable_to_non_nullable
as int,inviteEnabled: null == inviteEnabled ? _self.inviteEnabled : inviteEnabled // ignore: cast_nullable_to_non_nullable
as bool,inviteCode: freezed == inviteCode ? _self.inviteCode : inviteCode // ignore: cast_nullable_to_non_nullable
as String?,inviteCodeExpireAt: freezed == inviteCodeExpireAt ? _self.inviteCodeExpireAt : inviteCodeExpireAt // ignore: cast_nullable_to_non_nullable
as DateTime?,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<Member>,
  ));
}


}

// dart format on
