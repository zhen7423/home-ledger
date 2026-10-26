// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'baby.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Baby {

 int get id; String get name; String get gender; DateTime get birthDate; String? get birthHeight; String? get birthWeight; String? get remark;/// S10 档案照片相对路径（§4.4.1 / A6），读取要带登录态，为空 = 还没有照片。
 String? get photoUrl; bool get archived; String get ageText;
/// Create a copy of Baby
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyCopyWith<Baby> get copyWith => _$BabyCopyWithImpl<Baby>(this as Baby, _$identity);

  /// Serializes this Baby to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Baby;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Baby&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.gender, _this.gender) || other.gender == _this.gender)&&(identical(other.birthDate, _this.birthDate) || other.birthDate == _this.birthDate)&&(identical(other.birthHeight, _this.birthHeight) || other.birthHeight == _this.birthHeight)&&(identical(other.birthWeight, _this.birthWeight) || other.birthWeight == _this.birthWeight)&&(identical(other.remark, _this.remark) || other.remark == _this.remark)&&(identical(other.photoUrl, _this.photoUrl) || other.photoUrl == _this.photoUrl)&&(identical(other.archived, _this.archived) || other.archived == _this.archived)&&(identical(other.ageText, _this.ageText) || other.ageText == _this.ageText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Baby;
  return Object.hash(runtimeType,_this.id,_this.name,_this.gender,_this.birthDate,_this.birthHeight,_this.birthWeight,_this.remark,_this.photoUrl,_this.archived,_this.ageText);
}

@override
String toString() {
  final _this = this as Baby;
  return 'Baby(id: ${_this.id}, name: ${_this.name}, gender: ${_this.gender}, birthDate: ${_this.birthDate}, birthHeight: ${_this.birthHeight}, birthWeight: ${_this.birthWeight}, remark: ${_this.remark}, photoUrl: ${_this.photoUrl}, archived: ${_this.archived}, ageText: ${_this.ageText})';
}


}

/// @nodoc
abstract mixin class $BabyCopyWith<$Res>  {
  factory $BabyCopyWith(Baby value, $Res Function(Baby) _then) = _$BabyCopyWithImpl;
@useResult
$Res call({
 int id, String name, String gender, DateTime birthDate, String? birthHeight, String? birthWeight, String? remark, String? photoUrl, bool archived, String ageText
});




}
/// @nodoc
class _$BabyCopyWithImpl<$Res>
    implements $BabyCopyWith<$Res> {
  _$BabyCopyWithImpl(this._self, this._then);

  final Baby _self;
  final $Res Function(Baby) _then;

/// Create a copy of Baby
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? gender = null,Object? birthDate = null,Object? birthHeight = freezed,Object? birthWeight = freezed,Object? remark = freezed,Object? photoUrl = freezed,Object? archived = null,Object? ageText = null,}) {
  return _then(Baby(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,birthDate: null == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime,birthHeight: freezed == birthHeight ? _self.birthHeight : birthHeight // ignore: cast_nullable_to_non_nullable
as String?,birthWeight: freezed == birthWeight ? _self.birthWeight : birthWeight // ignore: cast_nullable_to_non_nullable
as String?,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,ageText: null == ageText ? _self.ageText : ageText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Baby].
extension BabyPatterns on Baby {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Baby value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Baby() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Baby value)  $default,){
final _that = this;
switch (_that) {
case _Baby():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Baby value)?  $default,){
final _that = this;
switch (_that) {
case _Baby() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String gender,  DateTime birthDate,  String? birthHeight,  String? birthWeight,  String? remark,  String? photoUrl,  bool archived,  String ageText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Baby() when $default != null:
return $default(_that.id,_that.name,_that.gender,_that.birthDate,_that.birthHeight,_that.birthWeight,_that.remark,_that.photoUrl,_that.archived,_that.ageText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String gender,  DateTime birthDate,  String? birthHeight,  String? birthWeight,  String? remark,  String? photoUrl,  bool archived,  String ageText)  $default,) {final _that = this;
switch (_that) {
case _Baby():
return $default(_that.id,_that.name,_that.gender,_that.birthDate,_that.birthHeight,_that.birthWeight,_that.remark,_that.photoUrl,_that.archived,_that.ageText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String gender,  DateTime birthDate,  String? birthHeight,  String? birthWeight,  String? remark,  String? photoUrl,  bool archived,  String ageText)?  $default,) {final _that = this;
switch (_that) {
case _Baby() when $default != null:
return $default(_that.id,_that.name,_that.gender,_that.birthDate,_that.birthHeight,_that.birthWeight,_that.remark,_that.photoUrl,_that.archived,_that.ageText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Baby implements Baby {
  const _Baby({required this.id, required this.name, required this.gender, required this.birthDate, this.birthHeight, this.birthWeight, this.remark, this.photoUrl, required this.archived, required this.ageText});
  factory _Baby.fromJson(Map<String, dynamic> json) => _$BabyFromJson(json);

@override final  int id;
@override final  String name;
@override final  String gender;
@override final  DateTime birthDate;
@override final  String? birthHeight;
@override final  String? birthWeight;
@override final  String? remark;
/// S10 档案照片相对路径（§4.4.1 / A6），读取要带登录态，为空 = 还没有照片。
@override final  String? photoUrl;
@override final  bool archived;
@override final  String ageText;

/// Create a copy of Baby
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyCopyWith<_Baby> get copyWith => __$BabyCopyWithImpl<_Baby>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Baby&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.birthHeight, birthHeight) || other.birthHeight == birthHeight)&&(identical(other.birthWeight, birthWeight) || other.birthWeight == birthWeight)&&(identical(other.remark, remark) || other.remark == remark)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.ageText, ageText) || other.ageText == ageText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,gender,birthDate,birthHeight,birthWeight,remark,photoUrl,archived,ageText);
}

@override
String toString() {
    return 'Baby(id: $id, name: $name, gender: $gender, birthDate: $birthDate, birthHeight: $birthHeight, birthWeight: $birthWeight, remark: $remark, photoUrl: $photoUrl, archived: $archived, ageText: $ageText)';
}


}

/// @nodoc
abstract mixin class _$BabyCopyWith<$Res> implements $BabyCopyWith<$Res> {
  factory _$BabyCopyWith(_Baby value, $Res Function(_Baby) _then) = __$BabyCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String gender, DateTime birthDate, String? birthHeight, String? birthWeight, String? remark, String? photoUrl, bool archived, String ageText
});




}
/// @nodoc
class __$BabyCopyWithImpl<$Res>
    implements _$BabyCopyWith<$Res> {
  __$BabyCopyWithImpl(this._self, this._then);

  final _Baby _self;
  final $Res Function(_Baby) _then;

/// Create a copy of Baby
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? gender = null,Object? birthDate = null,Object? birthHeight = freezed,Object? birthWeight = freezed,Object? remark = freezed,Object? photoUrl = freezed,Object? archived = null,Object? ageText = null,}) {
  return _then(_Baby(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,birthDate: null == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as DateTime,birthHeight: freezed == birthHeight ? _self.birthHeight : birthHeight // ignore: cast_nullable_to_non_nullable
as String?,birthWeight: freezed == birthWeight ? _self.birthWeight : birthWeight // ignore: cast_nullable_to_non_nullable
as String?,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,ageText: null == ageText ? _self.ageText : ageText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BabyOverview {

 DateTime get savedAt; List<Baby> get babies; BabyGrowthStatistics? get latestGrowth; BabyVaccineStatistics? get vaccineTodo;
/// Create a copy of BabyOverview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyOverviewCopyWith<BabyOverview> get copyWith => _$BabyOverviewCopyWithImpl<BabyOverview>(this as BabyOverview, _$identity);

  /// Serializes this BabyOverview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyOverview;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyOverview&&(identical(other.savedAt, _this.savedAt) || other.savedAt == _this.savedAt)&&const DeepCollectionEquality().equals(other.babies, _this.babies)&&(identical(other.latestGrowth, _this.latestGrowth) || other.latestGrowth == _this.latestGrowth)&&(identical(other.vaccineTodo, _this.vaccineTodo) || other.vaccineTodo == _this.vaccineTodo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyOverview;
  return Object.hash(runtimeType,_this.savedAt,const DeepCollectionEquality().hash(_this.babies),_this.latestGrowth,_this.vaccineTodo);
}

@override
String toString() {
  final _this = this as BabyOverview;
  return 'BabyOverview(savedAt: ${_this.savedAt}, babies: ${_this.babies}, latestGrowth: ${_this.latestGrowth}, vaccineTodo: ${_this.vaccineTodo})';
}


}

/// @nodoc
abstract mixin class $BabyOverviewCopyWith<$Res>  {
  factory $BabyOverviewCopyWith(BabyOverview value, $Res Function(BabyOverview) _then) = _$BabyOverviewCopyWithImpl;
@useResult
$Res call({
 DateTime savedAt, List<Baby> babies, BabyGrowthStatistics? latestGrowth, BabyVaccineStatistics? vaccineTodo
});


$BabyGrowthStatisticsCopyWith<$Res>? get latestGrowth;$BabyVaccineStatisticsCopyWith<$Res>? get vaccineTodo;

}
/// @nodoc
class _$BabyOverviewCopyWithImpl<$Res>
    implements $BabyOverviewCopyWith<$Res> {
  _$BabyOverviewCopyWithImpl(this._self, this._then);

  final BabyOverview _self;
  final $Res Function(BabyOverview) _then;

/// Create a copy of BabyOverview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? savedAt = null,Object? babies = null,Object? latestGrowth = freezed,Object? vaccineTodo = freezed,}) {
  return _then(BabyOverview(
savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,babies: null == babies ? _self.babies : babies // ignore: cast_nullable_to_non_nullable
as List<Baby>,latestGrowth: freezed == latestGrowth ? _self.latestGrowth : latestGrowth // ignore: cast_nullable_to_non_nullable
as BabyGrowthStatistics?,vaccineTodo: freezed == vaccineTodo ? _self.vaccineTodo : vaccineTodo // ignore: cast_nullable_to_non_nullable
as BabyVaccineStatistics?,
  ));
}
/// Create a copy of BabyOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthStatisticsCopyWith<$Res>? get latestGrowth {
    if (_self.latestGrowth == null) {
    return null;
  }

  return $BabyGrowthStatisticsCopyWith<$Res>(_self.latestGrowth!, (value) {
    return _then(_self.copyWith(latestGrowth: value));
  });
}/// Create a copy of BabyOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyVaccineStatisticsCopyWith<$Res>? get vaccineTodo {
    if (_self.vaccineTodo == null) {
    return null;
  }

  return $BabyVaccineStatisticsCopyWith<$Res>(_self.vaccineTodo!, (value) {
    return _then(_self.copyWith(vaccineTodo: value));
  });
}
}


/// Adds pattern-matching-related methods to [BabyOverview].
extension BabyOverviewPatterns on BabyOverview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyOverview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyOverview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyOverview value)  $default,){
final _that = this;
switch (_that) {
case _BabyOverview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyOverview value)?  $default,){
final _that = this;
switch (_that) {
case _BabyOverview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime savedAt,  List<Baby> babies,  BabyGrowthStatistics? latestGrowth,  BabyVaccineStatistics? vaccineTodo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyOverview() when $default != null:
return $default(_that.savedAt,_that.babies,_that.latestGrowth,_that.vaccineTodo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime savedAt,  List<Baby> babies,  BabyGrowthStatistics? latestGrowth,  BabyVaccineStatistics? vaccineTodo)  $default,) {final _that = this;
switch (_that) {
case _BabyOverview():
return $default(_that.savedAt,_that.babies,_that.latestGrowth,_that.vaccineTodo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime savedAt,  List<Baby> babies,  BabyGrowthStatistics? latestGrowth,  BabyVaccineStatistics? vaccineTodo)?  $default,) {final _that = this;
switch (_that) {
case _BabyOverview() when $default != null:
return $default(_that.savedAt,_that.babies,_that.latestGrowth,_that.vaccineTodo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyOverview implements BabyOverview {
  const _BabyOverview({required this.savedAt, required  List<Baby> babies, this.latestGrowth, this.vaccineTodo}): _babies = babies;
  factory _BabyOverview.fromJson(Map<String, dynamic> json) => _$BabyOverviewFromJson(json);

@override final  DateTime savedAt;
 final  List<Baby> _babies;
@override List<Baby> get babies {
  if (_babies is EqualUnmodifiableListView) return _babies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_babies);
}

@override final  BabyGrowthStatistics? latestGrowth;
@override final  BabyVaccineStatistics? vaccineTodo;

/// Create a copy of BabyOverview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyOverviewCopyWith<_BabyOverview> get copyWith => __$BabyOverviewCopyWithImpl<_BabyOverview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyOverviewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyOverview&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&const DeepCollectionEquality().equals(other.babies, _babies)&&(identical(other.latestGrowth, latestGrowth) || other.latestGrowth == latestGrowth)&&(identical(other.vaccineTodo, vaccineTodo) || other.vaccineTodo == vaccineTodo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,savedAt,const DeepCollectionEquality().hash(_babies),latestGrowth,vaccineTodo);
}

@override
String toString() {
    return 'BabyOverview(savedAt: $savedAt, babies: $babies, latestGrowth: $latestGrowth, vaccineTodo: $vaccineTodo)';
}


}

/// @nodoc
abstract mixin class _$BabyOverviewCopyWith<$Res> implements $BabyOverviewCopyWith<$Res> {
  factory _$BabyOverviewCopyWith(_BabyOverview value, $Res Function(_BabyOverview) _then) = __$BabyOverviewCopyWithImpl;
@override @useResult
$Res call({
 DateTime savedAt, List<Baby> babies, BabyGrowthStatistics? latestGrowth, BabyVaccineStatistics? vaccineTodo
});


@override $BabyGrowthStatisticsCopyWith<$Res>? get latestGrowth;@override $BabyVaccineStatisticsCopyWith<$Res>? get vaccineTodo;

}
/// @nodoc
class __$BabyOverviewCopyWithImpl<$Res>
    implements _$BabyOverviewCopyWith<$Res> {
  __$BabyOverviewCopyWithImpl(this._self, this._then);

  final _BabyOverview _self;
  final $Res Function(_BabyOverview) _then;

/// Create a copy of BabyOverview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? savedAt = null,Object? babies = null,Object? latestGrowth = freezed,Object? vaccineTodo = freezed,}) {
  return _then(_BabyOverview(
savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,babies: null == babies ? _self._babies : babies // ignore: cast_nullable_to_non_nullable
as List<Baby>,latestGrowth: freezed == latestGrowth ? _self.latestGrowth : latestGrowth // ignore: cast_nullable_to_non_nullable
as BabyGrowthStatistics?,vaccineTodo: freezed == vaccineTodo ? _self.vaccineTodo : vaccineTodo // ignore: cast_nullable_to_non_nullable
as BabyVaccineStatistics?,
  ));
}

/// Create a copy of BabyOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthStatisticsCopyWith<$Res>? get latestGrowth {
    if (_self.latestGrowth == null) {
    return null;
  }

  return $BabyGrowthStatisticsCopyWith<$Res>(_self.latestGrowth!, (value) {
    return _then(_self.copyWith(latestGrowth: value));
  });
}/// Create a copy of BabyOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyVaccineStatisticsCopyWith<$Res>? get vaccineTodo {
    if (_self.vaccineTodo == null) {
    return null;
  }

  return $BabyVaccineStatisticsCopyWith<$Res>(_self.vaccineTodo!, (value) {
    return _then(_self.copyWith(vaccineTodo: value));
  });
}
}

// dart format on
