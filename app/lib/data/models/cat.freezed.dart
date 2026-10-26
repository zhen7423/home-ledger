// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cat.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Cat {

 int get id; String get name; String get gender; DateTime? get birthday; bool get birthdayEstimated; String? get breed; String? get weightKg; String get neutered; String? get remark;/// S10 档案照片相对路径（§4.3.1 / A6），形如 `/photos/<uuid>.jpg`，读取要带登录态。
/// 为空 = 还没有照片。展示端拼上服务器基址后经 AuthImage 读取。
 String? get photoUrl; bool get archived; DateTime get createdAt;
/// Create a copy of Cat
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatCopyWith<Cat> get copyWith => _$CatCopyWithImpl<Cat>(this as Cat, _$identity);

  /// Serializes this Cat to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Cat;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Cat&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.gender, _this.gender) || other.gender == _this.gender)&&(identical(other.birthday, _this.birthday) || other.birthday == _this.birthday)&&(identical(other.birthdayEstimated, _this.birthdayEstimated) || other.birthdayEstimated == _this.birthdayEstimated)&&(identical(other.breed, _this.breed) || other.breed == _this.breed)&&(identical(other.weightKg, _this.weightKg) || other.weightKg == _this.weightKg)&&(identical(other.neutered, _this.neutered) || other.neutered == _this.neutered)&&(identical(other.remark, _this.remark) || other.remark == _this.remark)&&(identical(other.photoUrl, _this.photoUrl) || other.photoUrl == _this.photoUrl)&&(identical(other.archived, _this.archived) || other.archived == _this.archived)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Cat;
  return Object.hash(runtimeType,_this.id,_this.name,_this.gender,_this.birthday,_this.birthdayEstimated,_this.breed,_this.weightKg,_this.neutered,_this.remark,_this.photoUrl,_this.archived,_this.createdAt);
}

@override
String toString() {
  final _this = this as Cat;
  return 'Cat(id: ${_this.id}, name: ${_this.name}, gender: ${_this.gender}, birthday: ${_this.birthday}, birthdayEstimated: ${_this.birthdayEstimated}, breed: ${_this.breed}, weightKg: ${_this.weightKg}, neutered: ${_this.neutered}, remark: ${_this.remark}, photoUrl: ${_this.photoUrl}, archived: ${_this.archived}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $CatCopyWith<$Res>  {
  factory $CatCopyWith(Cat value, $Res Function(Cat) _then) = _$CatCopyWithImpl;
@useResult
$Res call({
 int id, String name, String gender, DateTime? birthday, bool birthdayEstimated, String? breed, String? weightKg, String neutered, String? remark, String? photoUrl, bool archived, DateTime createdAt
});




}
/// @nodoc
class _$CatCopyWithImpl<$Res>
    implements $CatCopyWith<$Res> {
  _$CatCopyWithImpl(this._self, this._then);

  final Cat _self;
  final $Res Function(Cat) _then;

/// Create a copy of Cat
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? gender = null,Object? birthday = freezed,Object? birthdayEstimated = null,Object? breed = freezed,Object? weightKg = freezed,Object? neutered = null,Object? remark = freezed,Object? photoUrl = freezed,Object? archived = null,Object? createdAt = null,}) {
  return _then(Cat(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as DateTime?,birthdayEstimated: null == birthdayEstimated ? _self.birthdayEstimated : birthdayEstimated // ignore: cast_nullable_to_non_nullable
as bool,breed: freezed == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as String?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as String?,neutered: null == neutered ? _self.neutered : neutered // ignore: cast_nullable_to_non_nullable
as String,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Cat].
extension CatPatterns on Cat {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Cat value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Cat() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Cat value)  $default,){
final _that = this;
switch (_that) {
case _Cat():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Cat value)?  $default,){
final _that = this;
switch (_that) {
case _Cat() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String gender,  DateTime? birthday,  bool birthdayEstimated,  String? breed,  String? weightKg,  String neutered,  String? remark,  String? photoUrl,  bool archived,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Cat() when $default != null:
return $default(_that.id,_that.name,_that.gender,_that.birthday,_that.birthdayEstimated,_that.breed,_that.weightKg,_that.neutered,_that.remark,_that.photoUrl,_that.archived,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String gender,  DateTime? birthday,  bool birthdayEstimated,  String? breed,  String? weightKg,  String neutered,  String? remark,  String? photoUrl,  bool archived,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Cat():
return $default(_that.id,_that.name,_that.gender,_that.birthday,_that.birthdayEstimated,_that.breed,_that.weightKg,_that.neutered,_that.remark,_that.photoUrl,_that.archived,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String gender,  DateTime? birthday,  bool birthdayEstimated,  String? breed,  String? weightKg,  String neutered,  String? remark,  String? photoUrl,  bool archived,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Cat() when $default != null:
return $default(_that.id,_that.name,_that.gender,_that.birthday,_that.birthdayEstimated,_that.breed,_that.weightKg,_that.neutered,_that.remark,_that.photoUrl,_that.archived,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Cat implements Cat {
  const _Cat({required this.id, required this.name, required this.gender, this.birthday, required this.birthdayEstimated, this.breed, this.weightKg, required this.neutered, this.remark, this.photoUrl, required this.archived, required this.createdAt});
  factory _Cat.fromJson(Map<String, dynamic> json) => _$CatFromJson(json);

@override final  int id;
@override final  String name;
@override final  String gender;
@override final  DateTime? birthday;
@override final  bool birthdayEstimated;
@override final  String? breed;
@override final  String? weightKg;
@override final  String neutered;
@override final  String? remark;
/// S10 档案照片相对路径（§4.3.1 / A6），形如 `/photos/<uuid>.jpg`，读取要带登录态。
/// 为空 = 还没有照片。展示端拼上服务器基址后经 AuthImage 读取。
@override final  String? photoUrl;
@override final  bool archived;
@override final  DateTime createdAt;

/// Create a copy of Cat
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatCopyWith<_Cat> get copyWith => __$CatCopyWithImpl<_Cat>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Cat&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.birthdayEstimated, birthdayEstimated) || other.birthdayEstimated == birthdayEstimated)&&(identical(other.breed, breed) || other.breed == breed)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.neutered, neutered) || other.neutered == neutered)&&(identical(other.remark, remark) || other.remark == remark)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,gender,birthday,birthdayEstimated,breed,weightKg,neutered,remark,photoUrl,archived,createdAt);
}

@override
String toString() {
    return 'Cat(id: $id, name: $name, gender: $gender, birthday: $birthday, birthdayEstimated: $birthdayEstimated, breed: $breed, weightKg: $weightKg, neutered: $neutered, remark: $remark, photoUrl: $photoUrl, archived: $archived, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CatCopyWith<$Res> implements $CatCopyWith<$Res> {
  factory _$CatCopyWith(_Cat value, $Res Function(_Cat) _then) = __$CatCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String gender, DateTime? birthday, bool birthdayEstimated, String? breed, String? weightKg, String neutered, String? remark, String? photoUrl, bool archived, DateTime createdAt
});




}
/// @nodoc
class __$CatCopyWithImpl<$Res>
    implements _$CatCopyWith<$Res> {
  __$CatCopyWithImpl(this._self, this._then);

  final _Cat _self;
  final $Res Function(_Cat) _then;

/// Create a copy of Cat
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? gender = null,Object? birthday = freezed,Object? birthdayEstimated = null,Object? breed = freezed,Object? weightKg = freezed,Object? neutered = null,Object? remark = freezed,Object? photoUrl = freezed,Object? archived = null,Object? createdAt = null,}) {
  return _then(_Cat(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as DateTime?,birthdayEstimated: null == birthdayEstimated ? _self.birthdayEstimated : birthdayEstimated // ignore: cast_nullable_to_non_nullable
as bool,breed: freezed == breed ? _self.breed : breed // ignore: cast_nullable_to_non_nullable
as String?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as String?,neutered: null == neutered ? _self.neutered : neutered // ignore: cast_nullable_to_non_nullable
as String,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
