// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'baby_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BabyGrowthStatistics {

 List<BabyGrowthItem> get perBaby;
/// Create a copy of BabyGrowthStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyGrowthStatisticsCopyWith<BabyGrowthStatistics> get copyWith => _$BabyGrowthStatisticsCopyWithImpl<BabyGrowthStatistics>(this as BabyGrowthStatistics, _$identity);

  /// Serializes this BabyGrowthStatistics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyGrowthStatistics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyGrowthStatistics&&const DeepCollectionEquality().equals(other.perBaby, _this.perBaby));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyGrowthStatistics;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.perBaby));
}

@override
String toString() {
  final _this = this as BabyGrowthStatistics;
  return 'BabyGrowthStatistics(perBaby: ${_this.perBaby})';
}


}

/// @nodoc
abstract mixin class $BabyGrowthStatisticsCopyWith<$Res>  {
  factory $BabyGrowthStatisticsCopyWith(BabyGrowthStatistics value, $Res Function(BabyGrowthStatistics) _then) = _$BabyGrowthStatisticsCopyWithImpl;
@useResult
$Res call({
 List<BabyGrowthItem> perBaby
});




}
/// @nodoc
class _$BabyGrowthStatisticsCopyWithImpl<$Res>
    implements $BabyGrowthStatisticsCopyWith<$Res> {
  _$BabyGrowthStatisticsCopyWithImpl(this._self, this._then);

  final BabyGrowthStatistics _self;
  final $Res Function(BabyGrowthStatistics) _then;

/// Create a copy of BabyGrowthStatistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? perBaby = null,}) {
  return _then(BabyGrowthStatistics(
perBaby: null == perBaby ? _self.perBaby : perBaby // ignore: cast_nullable_to_non_nullable
as List<BabyGrowthItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyGrowthStatistics].
extension BabyGrowthStatisticsPatterns on BabyGrowthStatistics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyGrowthStatistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyGrowthStatistics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyGrowthStatistics value)  $default,){
final _that = this;
switch (_that) {
case _BabyGrowthStatistics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyGrowthStatistics value)?  $default,){
final _that = this;
switch (_that) {
case _BabyGrowthStatistics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BabyGrowthItem> perBaby)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyGrowthStatistics() when $default != null:
return $default(_that.perBaby);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BabyGrowthItem> perBaby)  $default,) {final _that = this;
switch (_that) {
case _BabyGrowthStatistics():
return $default(_that.perBaby);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BabyGrowthItem> perBaby)?  $default,) {final _that = this;
switch (_that) {
case _BabyGrowthStatistics() when $default != null:
return $default(_that.perBaby);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyGrowthStatistics implements BabyGrowthStatistics {
  const _BabyGrowthStatistics({ List<BabyGrowthItem> perBaby = const <BabyGrowthItem>[]}): _perBaby = perBaby;
  factory _BabyGrowthStatistics.fromJson(Map<String, dynamic> json) => _$BabyGrowthStatisticsFromJson(json);

 final  List<BabyGrowthItem> _perBaby;
@override@JsonKey() List<BabyGrowthItem> get perBaby {
  if (_perBaby is EqualUnmodifiableListView) return _perBaby;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_perBaby);
}


/// Create a copy of BabyGrowthStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyGrowthStatisticsCopyWith<_BabyGrowthStatistics> get copyWith => __$BabyGrowthStatisticsCopyWithImpl<_BabyGrowthStatistics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyGrowthStatisticsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyGrowthStatistics&&const DeepCollectionEquality().equals(other.perBaby, _perBaby));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_perBaby));
}

@override
String toString() {
    return 'BabyGrowthStatistics(perBaby: $perBaby)';
}


}

/// @nodoc
abstract mixin class _$BabyGrowthStatisticsCopyWith<$Res> implements $BabyGrowthStatisticsCopyWith<$Res> {
  factory _$BabyGrowthStatisticsCopyWith(_BabyGrowthStatistics value, $Res Function(_BabyGrowthStatistics) _then) = __$BabyGrowthStatisticsCopyWithImpl;
@override @useResult
$Res call({
 List<BabyGrowthItem> perBaby
});




}
/// @nodoc
class __$BabyGrowthStatisticsCopyWithImpl<$Res>
    implements _$BabyGrowthStatisticsCopyWith<$Res> {
  __$BabyGrowthStatisticsCopyWithImpl(this._self, this._then);

  final _BabyGrowthStatistics _self;
  final $Res Function(_BabyGrowthStatistics) _then;

/// Create a copy of BabyGrowthStatistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? perBaby = null,}) {
  return _then(_BabyGrowthStatistics(
perBaby: null == perBaby ? _self._perBaby : perBaby // ignore: cast_nullable_to_non_nullable
as List<BabyGrowthItem>,
  ));
}


}


/// @nodoc
mixin _$BabyGrowthItem {

 int get babyId; String get name; String get ageText; BabyGrowthLatest? get latest; BabyGrowthWindows get growth;
/// Create a copy of BabyGrowthItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyGrowthItemCopyWith<BabyGrowthItem> get copyWith => _$BabyGrowthItemCopyWithImpl<BabyGrowthItem>(this as BabyGrowthItem, _$identity);

  /// Serializes this BabyGrowthItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyGrowthItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyGrowthItem&&(identical(other.babyId, _this.babyId) || other.babyId == _this.babyId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.ageText, _this.ageText) || other.ageText == _this.ageText)&&(identical(other.latest, _this.latest) || other.latest == _this.latest)&&(identical(other.growth, _this.growth) || other.growth == _this.growth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyGrowthItem;
  return Object.hash(runtimeType,_this.babyId,_this.name,_this.ageText,_this.latest,_this.growth);
}

@override
String toString() {
  final _this = this as BabyGrowthItem;
  return 'BabyGrowthItem(babyId: ${_this.babyId}, name: ${_this.name}, ageText: ${_this.ageText}, latest: ${_this.latest}, growth: ${_this.growth})';
}


}

/// @nodoc
abstract mixin class $BabyGrowthItemCopyWith<$Res>  {
  factory $BabyGrowthItemCopyWith(BabyGrowthItem value, $Res Function(BabyGrowthItem) _then) = _$BabyGrowthItemCopyWithImpl;
@useResult
$Res call({
 int babyId, String name, String ageText, BabyGrowthLatest? latest, BabyGrowthWindows growth
});


$BabyGrowthLatestCopyWith<$Res>? get latest;$BabyGrowthWindowsCopyWith<$Res> get growth;

}
/// @nodoc
class _$BabyGrowthItemCopyWithImpl<$Res>
    implements $BabyGrowthItemCopyWith<$Res> {
  _$BabyGrowthItemCopyWithImpl(this._self, this._then);

  final BabyGrowthItem _self;
  final $Res Function(BabyGrowthItem) _then;

/// Create a copy of BabyGrowthItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? babyId = null,Object? name = null,Object? ageText = null,Object? latest = freezed,Object? growth = null,}) {
  return _then(BabyGrowthItem(
babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ageText: null == ageText ? _self.ageText : ageText // ignore: cast_nullable_to_non_nullable
as String,latest: freezed == latest ? _self.latest : latest // ignore: cast_nullable_to_non_nullable
as BabyGrowthLatest?,growth: null == growth ? _self.growth : growth // ignore: cast_nullable_to_non_nullable
as BabyGrowthWindows,
  ));
}
/// Create a copy of BabyGrowthItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthLatestCopyWith<$Res>? get latest {
    if (_self.latest == null) {
    return null;
  }

  return $BabyGrowthLatestCopyWith<$Res>(_self.latest!, (value) {
    return _then(_self.copyWith(latest: value));
  });
}/// Create a copy of BabyGrowthItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthWindowsCopyWith<$Res> get growth {
  
  return $BabyGrowthWindowsCopyWith<$Res>(_self.growth, (value) {
    return _then(_self.copyWith(growth: value));
  });
}
}


/// Adds pattern-matching-related methods to [BabyGrowthItem].
extension BabyGrowthItemPatterns on BabyGrowthItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyGrowthItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyGrowthItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyGrowthItem value)  $default,){
final _that = this;
switch (_that) {
case _BabyGrowthItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyGrowthItem value)?  $default,){
final _that = this;
switch (_that) {
case _BabyGrowthItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int babyId,  String name,  String ageText,  BabyGrowthLatest? latest,  BabyGrowthWindows growth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyGrowthItem() when $default != null:
return $default(_that.babyId,_that.name,_that.ageText,_that.latest,_that.growth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int babyId,  String name,  String ageText,  BabyGrowthLatest? latest,  BabyGrowthWindows growth)  $default,) {final _that = this;
switch (_that) {
case _BabyGrowthItem():
return $default(_that.babyId,_that.name,_that.ageText,_that.latest,_that.growth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int babyId,  String name,  String ageText,  BabyGrowthLatest? latest,  BabyGrowthWindows growth)?  $default,) {final _that = this;
switch (_that) {
case _BabyGrowthItem() when $default != null:
return $default(_that.babyId,_that.name,_that.ageText,_that.latest,_that.growth);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyGrowthItem implements BabyGrowthItem {
  const _BabyGrowthItem({required this.babyId, required this.name, required this.ageText, this.latest, required this.growth});
  factory _BabyGrowthItem.fromJson(Map<String, dynamic> json) => _$BabyGrowthItemFromJson(json);

@override final  int babyId;
@override final  String name;
@override final  String ageText;
@override final  BabyGrowthLatest? latest;
@override final  BabyGrowthWindows growth;

/// Create a copy of BabyGrowthItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyGrowthItemCopyWith<_BabyGrowthItem> get copyWith => __$BabyGrowthItemCopyWithImpl<_BabyGrowthItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyGrowthItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyGrowthItem&&(identical(other.babyId, babyId) || other.babyId == babyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.ageText, ageText) || other.ageText == ageText)&&(identical(other.latest, latest) || other.latest == latest)&&(identical(other.growth, growth) || other.growth == growth));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,babyId,name,ageText,latest,growth);
}

@override
String toString() {
    return 'BabyGrowthItem(babyId: $babyId, name: $name, ageText: $ageText, latest: $latest, growth: $growth)';
}


}

/// @nodoc
abstract mixin class _$BabyGrowthItemCopyWith<$Res> implements $BabyGrowthItemCopyWith<$Res> {
  factory _$BabyGrowthItemCopyWith(_BabyGrowthItem value, $Res Function(_BabyGrowthItem) _then) = __$BabyGrowthItemCopyWithImpl;
@override @useResult
$Res call({
 int babyId, String name, String ageText, BabyGrowthLatest? latest, BabyGrowthWindows growth
});


@override $BabyGrowthLatestCopyWith<$Res>? get latest;@override $BabyGrowthWindowsCopyWith<$Res> get growth;

}
/// @nodoc
class __$BabyGrowthItemCopyWithImpl<$Res>
    implements _$BabyGrowthItemCopyWith<$Res> {
  __$BabyGrowthItemCopyWithImpl(this._self, this._then);

  final _BabyGrowthItem _self;
  final $Res Function(_BabyGrowthItem) _then;

/// Create a copy of BabyGrowthItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? babyId = null,Object? name = null,Object? ageText = null,Object? latest = freezed,Object? growth = null,}) {
  return _then(_BabyGrowthItem(
babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ageText: null == ageText ? _self.ageText : ageText // ignore: cast_nullable_to_non_nullable
as String,latest: freezed == latest ? _self.latest : latest // ignore: cast_nullable_to_non_nullable
as BabyGrowthLatest?,growth: null == growth ? _self.growth : growth // ignore: cast_nullable_to_non_nullable
as BabyGrowthWindows,
  ));
}

/// Create a copy of BabyGrowthItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthLatestCopyWith<$Res>? get latest {
    if (_self.latest == null) {
    return null;
  }

  return $BabyGrowthLatestCopyWith<$Res>(_self.latest!, (value) {
    return _then(_self.copyWith(latest: value));
  });
}/// Create a copy of BabyGrowthItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthWindowsCopyWith<$Res> get growth {
  
  return $BabyGrowthWindowsCopyWith<$Res>(_self.growth, (value) {
    return _then(_self.copyWith(growth: value));
  });
}
}


/// @nodoc
mixin _$BabyGrowthLatest {

 DateTime get measureDate; String? get heightCm; String? get weightKg; String? get headCm; BabyPercentileBands get bands;
/// Create a copy of BabyGrowthLatest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyGrowthLatestCopyWith<BabyGrowthLatest> get copyWith => _$BabyGrowthLatestCopyWithImpl<BabyGrowthLatest>(this as BabyGrowthLatest, _$identity);

  /// Serializes this BabyGrowthLatest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyGrowthLatest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyGrowthLatest&&(identical(other.measureDate, _this.measureDate) || other.measureDate == _this.measureDate)&&(identical(other.heightCm, _this.heightCm) || other.heightCm == _this.heightCm)&&(identical(other.weightKg, _this.weightKg) || other.weightKg == _this.weightKg)&&(identical(other.headCm, _this.headCm) || other.headCm == _this.headCm)&&(identical(other.bands, _this.bands) || other.bands == _this.bands));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyGrowthLatest;
  return Object.hash(runtimeType,_this.measureDate,_this.heightCm,_this.weightKg,_this.headCm,_this.bands);
}

@override
String toString() {
  final _this = this as BabyGrowthLatest;
  return 'BabyGrowthLatest(measureDate: ${_this.measureDate}, heightCm: ${_this.heightCm}, weightKg: ${_this.weightKg}, headCm: ${_this.headCm}, bands: ${_this.bands})';
}


}

/// @nodoc
abstract mixin class $BabyGrowthLatestCopyWith<$Res>  {
  factory $BabyGrowthLatestCopyWith(BabyGrowthLatest value, $Res Function(BabyGrowthLatest) _then) = _$BabyGrowthLatestCopyWithImpl;
@useResult
$Res call({
 DateTime measureDate, String? heightCm, String? weightKg, String? headCm, BabyPercentileBands bands
});


$BabyPercentileBandsCopyWith<$Res> get bands;

}
/// @nodoc
class _$BabyGrowthLatestCopyWithImpl<$Res>
    implements $BabyGrowthLatestCopyWith<$Res> {
  _$BabyGrowthLatestCopyWithImpl(this._self, this._then);

  final BabyGrowthLatest _self;
  final $Res Function(BabyGrowthLatest) _then;

/// Create a copy of BabyGrowthLatest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? measureDate = null,Object? heightCm = freezed,Object? weightKg = freezed,Object? headCm = freezed,Object? bands = null,}) {
  return _then(BabyGrowthLatest(
measureDate: null == measureDate ? _self.measureDate : measureDate // ignore: cast_nullable_to_non_nullable
as DateTime,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as String?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as String?,headCm: freezed == headCm ? _self.headCm : headCm // ignore: cast_nullable_to_non_nullable
as String?,bands: null == bands ? _self.bands : bands // ignore: cast_nullable_to_non_nullable
as BabyPercentileBands,
  ));
}
/// Create a copy of BabyGrowthLatest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyPercentileBandsCopyWith<$Res> get bands {
  
  return $BabyPercentileBandsCopyWith<$Res>(_self.bands, (value) {
    return _then(_self.copyWith(bands: value));
  });
}
}


/// Adds pattern-matching-related methods to [BabyGrowthLatest].
extension BabyGrowthLatestPatterns on BabyGrowthLatest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyGrowthLatest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyGrowthLatest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyGrowthLatest value)  $default,){
final _that = this;
switch (_that) {
case _BabyGrowthLatest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyGrowthLatest value)?  $default,){
final _that = this;
switch (_that) {
case _BabyGrowthLatest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime measureDate,  String? heightCm,  String? weightKg,  String? headCm,  BabyPercentileBands bands)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyGrowthLatest() when $default != null:
return $default(_that.measureDate,_that.heightCm,_that.weightKg,_that.headCm,_that.bands);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime measureDate,  String? heightCm,  String? weightKg,  String? headCm,  BabyPercentileBands bands)  $default,) {final _that = this;
switch (_that) {
case _BabyGrowthLatest():
return $default(_that.measureDate,_that.heightCm,_that.weightKg,_that.headCm,_that.bands);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime measureDate,  String? heightCm,  String? weightKg,  String? headCm,  BabyPercentileBands bands)?  $default,) {final _that = this;
switch (_that) {
case _BabyGrowthLatest() when $default != null:
return $default(_that.measureDate,_that.heightCm,_that.weightKg,_that.headCm,_that.bands);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyGrowthLatest implements BabyGrowthLatest {
  const _BabyGrowthLatest({required this.measureDate, this.heightCm, this.weightKg, this.headCm, required this.bands});
  factory _BabyGrowthLatest.fromJson(Map<String, dynamic> json) => _$BabyGrowthLatestFromJson(json);

@override final  DateTime measureDate;
@override final  String? heightCm;
@override final  String? weightKg;
@override final  String? headCm;
@override final  BabyPercentileBands bands;

/// Create a copy of BabyGrowthLatest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyGrowthLatestCopyWith<_BabyGrowthLatest> get copyWith => __$BabyGrowthLatestCopyWithImpl<_BabyGrowthLatest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyGrowthLatestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyGrowthLatest&&(identical(other.measureDate, measureDate) || other.measureDate == measureDate)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.headCm, headCm) || other.headCm == headCm)&&(identical(other.bands, bands) || other.bands == bands));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,measureDate,heightCm,weightKg,headCm,bands);
}

@override
String toString() {
    return 'BabyGrowthLatest(measureDate: $measureDate, heightCm: $heightCm, weightKg: $weightKg, headCm: $headCm, bands: $bands)';
}


}

/// @nodoc
abstract mixin class _$BabyGrowthLatestCopyWith<$Res> implements $BabyGrowthLatestCopyWith<$Res> {
  factory _$BabyGrowthLatestCopyWith(_BabyGrowthLatest value, $Res Function(_BabyGrowthLatest) _then) = __$BabyGrowthLatestCopyWithImpl;
@override @useResult
$Res call({
 DateTime measureDate, String? heightCm, String? weightKg, String? headCm, BabyPercentileBands bands
});


@override $BabyPercentileBandsCopyWith<$Res> get bands;

}
/// @nodoc
class __$BabyGrowthLatestCopyWithImpl<$Res>
    implements _$BabyGrowthLatestCopyWith<$Res> {
  __$BabyGrowthLatestCopyWithImpl(this._self, this._then);

  final _BabyGrowthLatest _self;
  final $Res Function(_BabyGrowthLatest) _then;

/// Create a copy of BabyGrowthLatest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? measureDate = null,Object? heightCm = freezed,Object? weightKg = freezed,Object? headCm = freezed,Object? bands = null,}) {
  return _then(_BabyGrowthLatest(
measureDate: null == measureDate ? _self.measureDate : measureDate // ignore: cast_nullable_to_non_nullable
as DateTime,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as String?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as String?,headCm: freezed == headCm ? _self.headCm : headCm // ignore: cast_nullable_to_non_nullable
as String?,bands: null == bands ? _self.bands : bands // ignore: cast_nullable_to_non_nullable
as BabyPercentileBands,
  ));
}

/// Create a copy of BabyGrowthLatest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyPercentileBandsCopyWith<$Res> get bands {
  
  return $BabyPercentileBandsCopyWith<$Res>(_self.bands, (value) {
    return _then(_self.copyWith(bands: value));
  });
}
}


/// @nodoc
mixin _$BabyPercentileBands {

 String? get height; String? get weight; String? get weightHeight; String? get bmi; String? get headCircumference;
/// Create a copy of BabyPercentileBands
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyPercentileBandsCopyWith<BabyPercentileBands> get copyWith => _$BabyPercentileBandsCopyWithImpl<BabyPercentileBands>(this as BabyPercentileBands, _$identity);

  /// Serializes this BabyPercentileBands to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyPercentileBands;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyPercentileBands&&(identical(other.height, _this.height) || other.height == _this.height)&&(identical(other.weight, _this.weight) || other.weight == _this.weight)&&(identical(other.weightHeight, _this.weightHeight) || other.weightHeight == _this.weightHeight)&&(identical(other.bmi, _this.bmi) || other.bmi == _this.bmi)&&(identical(other.headCircumference, _this.headCircumference) || other.headCircumference == _this.headCircumference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyPercentileBands;
  return Object.hash(runtimeType,_this.height,_this.weight,_this.weightHeight,_this.bmi,_this.headCircumference);
}

@override
String toString() {
  final _this = this as BabyPercentileBands;
  return 'BabyPercentileBands(height: ${_this.height}, weight: ${_this.weight}, weightHeight: ${_this.weightHeight}, bmi: ${_this.bmi}, headCircumference: ${_this.headCircumference})';
}


}

/// @nodoc
abstract mixin class $BabyPercentileBandsCopyWith<$Res>  {
  factory $BabyPercentileBandsCopyWith(BabyPercentileBands value, $Res Function(BabyPercentileBands) _then) = _$BabyPercentileBandsCopyWithImpl;
@useResult
$Res call({
 String? height, String? weight, String? weightHeight, String? bmi, String? headCircumference
});




}
/// @nodoc
class _$BabyPercentileBandsCopyWithImpl<$Res>
    implements $BabyPercentileBandsCopyWith<$Res> {
  _$BabyPercentileBandsCopyWithImpl(this._self, this._then);

  final BabyPercentileBands _self;
  final $Res Function(BabyPercentileBands) _then;

/// Create a copy of BabyPercentileBands
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? height = freezed,Object? weight = freezed,Object? weightHeight = freezed,Object? bmi = freezed,Object? headCircumference = freezed,}) {
  return _then(BabyPercentileBands(
height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as String?,weightHeight: freezed == weightHeight ? _self.weightHeight : weightHeight // ignore: cast_nullable_to_non_nullable
as String?,bmi: freezed == bmi ? _self.bmi : bmi // ignore: cast_nullable_to_non_nullable
as String?,headCircumference: freezed == headCircumference ? _self.headCircumference : headCircumference // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyPercentileBands].
extension BabyPercentileBandsPatterns on BabyPercentileBands {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyPercentileBands value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyPercentileBands() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyPercentileBands value)  $default,){
final _that = this;
switch (_that) {
case _BabyPercentileBands():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyPercentileBands value)?  $default,){
final _that = this;
switch (_that) {
case _BabyPercentileBands() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? height,  String? weight,  String? weightHeight,  String? bmi,  String? headCircumference)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyPercentileBands() when $default != null:
return $default(_that.height,_that.weight,_that.weightHeight,_that.bmi,_that.headCircumference);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? height,  String? weight,  String? weightHeight,  String? bmi,  String? headCircumference)  $default,) {final _that = this;
switch (_that) {
case _BabyPercentileBands():
return $default(_that.height,_that.weight,_that.weightHeight,_that.bmi,_that.headCircumference);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? height,  String? weight,  String? weightHeight,  String? bmi,  String? headCircumference)?  $default,) {final _that = this;
switch (_that) {
case _BabyPercentileBands() when $default != null:
return $default(_that.height,_that.weight,_that.weightHeight,_that.bmi,_that.headCircumference);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyPercentileBands implements BabyPercentileBands {
  const _BabyPercentileBands({this.height, this.weight, this.weightHeight, this.bmi, this.headCircumference});
  factory _BabyPercentileBands.fromJson(Map<String, dynamic> json) => _$BabyPercentileBandsFromJson(json);

@override final  String? height;
@override final  String? weight;
@override final  String? weightHeight;
@override final  String? bmi;
@override final  String? headCircumference;

/// Create a copy of BabyPercentileBands
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyPercentileBandsCopyWith<_BabyPercentileBands> get copyWith => __$BabyPercentileBandsCopyWithImpl<_BabyPercentileBands>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyPercentileBandsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyPercentileBands&&(identical(other.height, height) || other.height == height)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.weightHeight, weightHeight) || other.weightHeight == weightHeight)&&(identical(other.bmi, bmi) || other.bmi == bmi)&&(identical(other.headCircumference, headCircumference) || other.headCircumference == headCircumference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,height,weight,weightHeight,bmi,headCircumference);
}

@override
String toString() {
    return 'BabyPercentileBands(height: $height, weight: $weight, weightHeight: $weightHeight, bmi: $bmi, headCircumference: $headCircumference)';
}


}

/// @nodoc
abstract mixin class _$BabyPercentileBandsCopyWith<$Res> implements $BabyPercentileBandsCopyWith<$Res> {
  factory _$BabyPercentileBandsCopyWith(_BabyPercentileBands value, $Res Function(_BabyPercentileBands) _then) = __$BabyPercentileBandsCopyWithImpl;
@override @useResult
$Res call({
 String? height, String? weight, String? weightHeight, String? bmi, String? headCircumference
});




}
/// @nodoc
class __$BabyPercentileBandsCopyWithImpl<$Res>
    implements _$BabyPercentileBandsCopyWith<$Res> {
  __$BabyPercentileBandsCopyWithImpl(this._self, this._then);

  final _BabyPercentileBands _self;
  final $Res Function(_BabyPercentileBands) _then;

/// Create a copy of BabyPercentileBands
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? height = freezed,Object? weight = freezed,Object? weightHeight = freezed,Object? bmi = freezed,Object? headCircumference = freezed,}) {
  return _then(_BabyPercentileBands(
height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as String?,weightHeight: freezed == weightHeight ? _self.weightHeight : weightHeight // ignore: cast_nullable_to_non_nullable
as String?,bmi: freezed == bmi ? _self.bmi : bmi // ignore: cast_nullable_to_non_nullable
as String?,headCircumference: freezed == headCircumference ? _self.headCircumference : headCircumference // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BabyGrowthWindows {

 BabyGrowthGain? get sinceLast; BabyGrowthGain? get last3Months; BabyGrowthGain? get last12Months;
/// Create a copy of BabyGrowthWindows
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyGrowthWindowsCopyWith<BabyGrowthWindows> get copyWith => _$BabyGrowthWindowsCopyWithImpl<BabyGrowthWindows>(this as BabyGrowthWindows, _$identity);

  /// Serializes this BabyGrowthWindows to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyGrowthWindows;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyGrowthWindows&&(identical(other.sinceLast, _this.sinceLast) || other.sinceLast == _this.sinceLast)&&(identical(other.last3Months, _this.last3Months) || other.last3Months == _this.last3Months)&&(identical(other.last12Months, _this.last12Months) || other.last12Months == _this.last12Months));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyGrowthWindows;
  return Object.hash(runtimeType,_this.sinceLast,_this.last3Months,_this.last12Months);
}

@override
String toString() {
  final _this = this as BabyGrowthWindows;
  return 'BabyGrowthWindows(sinceLast: ${_this.sinceLast}, last3Months: ${_this.last3Months}, last12Months: ${_this.last12Months})';
}


}

/// @nodoc
abstract mixin class $BabyGrowthWindowsCopyWith<$Res>  {
  factory $BabyGrowthWindowsCopyWith(BabyGrowthWindows value, $Res Function(BabyGrowthWindows) _then) = _$BabyGrowthWindowsCopyWithImpl;
@useResult
$Res call({
 BabyGrowthGain? sinceLast, BabyGrowthGain? last3Months, BabyGrowthGain? last12Months
});


$BabyGrowthGainCopyWith<$Res>? get sinceLast;$BabyGrowthGainCopyWith<$Res>? get last3Months;$BabyGrowthGainCopyWith<$Res>? get last12Months;

}
/// @nodoc
class _$BabyGrowthWindowsCopyWithImpl<$Res>
    implements $BabyGrowthWindowsCopyWith<$Res> {
  _$BabyGrowthWindowsCopyWithImpl(this._self, this._then);

  final BabyGrowthWindows _self;
  final $Res Function(BabyGrowthWindows) _then;

/// Create a copy of BabyGrowthWindows
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sinceLast = freezed,Object? last3Months = freezed,Object? last12Months = freezed,}) {
  return _then(BabyGrowthWindows(
sinceLast: freezed == sinceLast ? _self.sinceLast : sinceLast // ignore: cast_nullable_to_non_nullable
as BabyGrowthGain?,last3Months: freezed == last3Months ? _self.last3Months : last3Months // ignore: cast_nullable_to_non_nullable
as BabyGrowthGain?,last12Months: freezed == last12Months ? _self.last12Months : last12Months // ignore: cast_nullable_to_non_nullable
as BabyGrowthGain?,
  ));
}
/// Create a copy of BabyGrowthWindows
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthGainCopyWith<$Res>? get sinceLast {
    if (_self.sinceLast == null) {
    return null;
  }

  return $BabyGrowthGainCopyWith<$Res>(_self.sinceLast!, (value) {
    return _then(_self.copyWith(sinceLast: value));
  });
}/// Create a copy of BabyGrowthWindows
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthGainCopyWith<$Res>? get last3Months {
    if (_self.last3Months == null) {
    return null;
  }

  return $BabyGrowthGainCopyWith<$Res>(_self.last3Months!, (value) {
    return _then(_self.copyWith(last3Months: value));
  });
}/// Create a copy of BabyGrowthWindows
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthGainCopyWith<$Res>? get last12Months {
    if (_self.last12Months == null) {
    return null;
  }

  return $BabyGrowthGainCopyWith<$Res>(_self.last12Months!, (value) {
    return _then(_self.copyWith(last12Months: value));
  });
}
}


/// Adds pattern-matching-related methods to [BabyGrowthWindows].
extension BabyGrowthWindowsPatterns on BabyGrowthWindows {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyGrowthWindows value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyGrowthWindows() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyGrowthWindows value)  $default,){
final _that = this;
switch (_that) {
case _BabyGrowthWindows():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyGrowthWindows value)?  $default,){
final _that = this;
switch (_that) {
case _BabyGrowthWindows() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BabyGrowthGain? sinceLast,  BabyGrowthGain? last3Months,  BabyGrowthGain? last12Months)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyGrowthWindows() when $default != null:
return $default(_that.sinceLast,_that.last3Months,_that.last12Months);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BabyGrowthGain? sinceLast,  BabyGrowthGain? last3Months,  BabyGrowthGain? last12Months)  $default,) {final _that = this;
switch (_that) {
case _BabyGrowthWindows():
return $default(_that.sinceLast,_that.last3Months,_that.last12Months);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BabyGrowthGain? sinceLast,  BabyGrowthGain? last3Months,  BabyGrowthGain? last12Months)?  $default,) {final _that = this;
switch (_that) {
case _BabyGrowthWindows() when $default != null:
return $default(_that.sinceLast,_that.last3Months,_that.last12Months);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyGrowthWindows implements BabyGrowthWindows {
  const _BabyGrowthWindows({this.sinceLast, this.last3Months, this.last12Months});
  factory _BabyGrowthWindows.fromJson(Map<String, dynamic> json) => _$BabyGrowthWindowsFromJson(json);

@override final  BabyGrowthGain? sinceLast;
@override final  BabyGrowthGain? last3Months;
@override final  BabyGrowthGain? last12Months;

/// Create a copy of BabyGrowthWindows
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyGrowthWindowsCopyWith<_BabyGrowthWindows> get copyWith => __$BabyGrowthWindowsCopyWithImpl<_BabyGrowthWindows>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyGrowthWindowsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyGrowthWindows&&(identical(other.sinceLast, sinceLast) || other.sinceLast == sinceLast)&&(identical(other.last3Months, last3Months) || other.last3Months == last3Months)&&(identical(other.last12Months, last12Months) || other.last12Months == last12Months));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sinceLast,last3Months,last12Months);
}

@override
String toString() {
    return 'BabyGrowthWindows(sinceLast: $sinceLast, last3Months: $last3Months, last12Months: $last12Months)';
}


}

/// @nodoc
abstract mixin class _$BabyGrowthWindowsCopyWith<$Res> implements $BabyGrowthWindowsCopyWith<$Res> {
  factory _$BabyGrowthWindowsCopyWith(_BabyGrowthWindows value, $Res Function(_BabyGrowthWindows) _then) = __$BabyGrowthWindowsCopyWithImpl;
@override @useResult
$Res call({
 BabyGrowthGain? sinceLast, BabyGrowthGain? last3Months, BabyGrowthGain? last12Months
});


@override $BabyGrowthGainCopyWith<$Res>? get sinceLast;@override $BabyGrowthGainCopyWith<$Res>? get last3Months;@override $BabyGrowthGainCopyWith<$Res>? get last12Months;

}
/// @nodoc
class __$BabyGrowthWindowsCopyWithImpl<$Res>
    implements _$BabyGrowthWindowsCopyWith<$Res> {
  __$BabyGrowthWindowsCopyWithImpl(this._self, this._then);

  final _BabyGrowthWindows _self;
  final $Res Function(_BabyGrowthWindows) _then;

/// Create a copy of BabyGrowthWindows
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sinceLast = freezed,Object? last3Months = freezed,Object? last12Months = freezed,}) {
  return _then(_BabyGrowthWindows(
sinceLast: freezed == sinceLast ? _self.sinceLast : sinceLast // ignore: cast_nullable_to_non_nullable
as BabyGrowthGain?,last3Months: freezed == last3Months ? _self.last3Months : last3Months // ignore: cast_nullable_to_non_nullable
as BabyGrowthGain?,last12Months: freezed == last12Months ? _self.last12Months : last12Months // ignore: cast_nullable_to_non_nullable
as BabyGrowthGain?,
  ));
}

/// Create a copy of BabyGrowthWindows
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthGainCopyWith<$Res>? get sinceLast {
    if (_self.sinceLast == null) {
    return null;
  }

  return $BabyGrowthGainCopyWith<$Res>(_self.sinceLast!, (value) {
    return _then(_self.copyWith(sinceLast: value));
  });
}/// Create a copy of BabyGrowthWindows
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthGainCopyWith<$Res>? get last3Months {
    if (_self.last3Months == null) {
    return null;
  }

  return $BabyGrowthGainCopyWith<$Res>(_self.last3Months!, (value) {
    return _then(_self.copyWith(last3Months: value));
  });
}/// Create a copy of BabyGrowthWindows
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthGainCopyWith<$Res>? get last12Months {
    if (_self.last12Months == null) {
    return null;
  }

  return $BabyGrowthGainCopyWith<$Res>(_self.last12Months!, (value) {
    return _then(_self.copyWith(last12Months: value));
  });
}
}


/// @nodoc
mixin _$BabyGrowthGain {

 int get days; String? get heightCm; String? get weightKg; String? get headCm;
/// Create a copy of BabyGrowthGain
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyGrowthGainCopyWith<BabyGrowthGain> get copyWith => _$BabyGrowthGainCopyWithImpl<BabyGrowthGain>(this as BabyGrowthGain, _$identity);

  /// Serializes this BabyGrowthGain to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyGrowthGain;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyGrowthGain&&(identical(other.days, _this.days) || other.days == _this.days)&&(identical(other.heightCm, _this.heightCm) || other.heightCm == _this.heightCm)&&(identical(other.weightKg, _this.weightKg) || other.weightKg == _this.weightKg)&&(identical(other.headCm, _this.headCm) || other.headCm == _this.headCm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyGrowthGain;
  return Object.hash(runtimeType,_this.days,_this.heightCm,_this.weightKg,_this.headCm);
}

@override
String toString() {
  final _this = this as BabyGrowthGain;
  return 'BabyGrowthGain(days: ${_this.days}, heightCm: ${_this.heightCm}, weightKg: ${_this.weightKg}, headCm: ${_this.headCm})';
}


}

/// @nodoc
abstract mixin class $BabyGrowthGainCopyWith<$Res>  {
  factory $BabyGrowthGainCopyWith(BabyGrowthGain value, $Res Function(BabyGrowthGain) _then) = _$BabyGrowthGainCopyWithImpl;
@useResult
$Res call({
 int days, String? heightCm, String? weightKg, String? headCm
});




}
/// @nodoc
class _$BabyGrowthGainCopyWithImpl<$Res>
    implements $BabyGrowthGainCopyWith<$Res> {
  _$BabyGrowthGainCopyWithImpl(this._self, this._then);

  final BabyGrowthGain _self;
  final $Res Function(BabyGrowthGain) _then;

/// Create a copy of BabyGrowthGain
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? days = null,Object? heightCm = freezed,Object? weightKg = freezed,Object? headCm = freezed,}) {
  return _then(BabyGrowthGain(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as String?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as String?,headCm: freezed == headCm ? _self.headCm : headCm // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyGrowthGain].
extension BabyGrowthGainPatterns on BabyGrowthGain {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyGrowthGain value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyGrowthGain() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyGrowthGain value)  $default,){
final _that = this;
switch (_that) {
case _BabyGrowthGain():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyGrowthGain value)?  $default,){
final _that = this;
switch (_that) {
case _BabyGrowthGain() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int days,  String? heightCm,  String? weightKg,  String? headCm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyGrowthGain() when $default != null:
return $default(_that.days,_that.heightCm,_that.weightKg,_that.headCm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int days,  String? heightCm,  String? weightKg,  String? headCm)  $default,) {final _that = this;
switch (_that) {
case _BabyGrowthGain():
return $default(_that.days,_that.heightCm,_that.weightKg,_that.headCm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int days,  String? heightCm,  String? weightKg,  String? headCm)?  $default,) {final _that = this;
switch (_that) {
case _BabyGrowthGain() when $default != null:
return $default(_that.days,_that.heightCm,_that.weightKg,_that.headCm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyGrowthGain implements BabyGrowthGain {
  const _BabyGrowthGain({required this.days, this.heightCm, this.weightKg, this.headCm});
  factory _BabyGrowthGain.fromJson(Map<String, dynamic> json) => _$BabyGrowthGainFromJson(json);

@override final  int days;
@override final  String? heightCm;
@override final  String? weightKg;
@override final  String? headCm;

/// Create a copy of BabyGrowthGain
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyGrowthGainCopyWith<_BabyGrowthGain> get copyWith => __$BabyGrowthGainCopyWithImpl<_BabyGrowthGain>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyGrowthGainToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyGrowthGain&&(identical(other.days, days) || other.days == days)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.headCm, headCm) || other.headCm == headCm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,days,heightCm,weightKg,headCm);
}

@override
String toString() {
    return 'BabyGrowthGain(days: $days, heightCm: $heightCm, weightKg: $weightKg, headCm: $headCm)';
}


}

/// @nodoc
abstract mixin class _$BabyGrowthGainCopyWith<$Res> implements $BabyGrowthGainCopyWith<$Res> {
  factory _$BabyGrowthGainCopyWith(_BabyGrowthGain value, $Res Function(_BabyGrowthGain) _then) = __$BabyGrowthGainCopyWithImpl;
@override @useResult
$Res call({
 int days, String? heightCm, String? weightKg, String? headCm
});




}
/// @nodoc
class __$BabyGrowthGainCopyWithImpl<$Res>
    implements _$BabyGrowthGainCopyWith<$Res> {
  __$BabyGrowthGainCopyWithImpl(this._self, this._then);

  final _BabyGrowthGain _self;
  final $Res Function(_BabyGrowthGain) _then;

/// Create a copy of BabyGrowthGain
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? days = null,Object? heightCm = freezed,Object? weightKg = freezed,Object? headCm = freezed,}) {
  return _then(_BabyGrowthGain(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as String?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as String?,headCm: freezed == headCm ? _self.headCm : headCm // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BabyVaccineStatistics {

 List<BabyVaccineItem> get perBaby; List<BabyMilestoneItem> get milestoneTimeline;
/// Create a copy of BabyVaccineStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyVaccineStatisticsCopyWith<BabyVaccineStatistics> get copyWith => _$BabyVaccineStatisticsCopyWithImpl<BabyVaccineStatistics>(this as BabyVaccineStatistics, _$identity);

  /// Serializes this BabyVaccineStatistics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyVaccineStatistics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyVaccineStatistics&&const DeepCollectionEquality().equals(other.perBaby, _this.perBaby)&&const DeepCollectionEquality().equals(other.milestoneTimeline, _this.milestoneTimeline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyVaccineStatistics;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.perBaby),const DeepCollectionEquality().hash(_this.milestoneTimeline));
}

@override
String toString() {
  final _this = this as BabyVaccineStatistics;
  return 'BabyVaccineStatistics(perBaby: ${_this.perBaby}, milestoneTimeline: ${_this.milestoneTimeline})';
}


}

/// @nodoc
abstract mixin class $BabyVaccineStatisticsCopyWith<$Res>  {
  factory $BabyVaccineStatisticsCopyWith(BabyVaccineStatistics value, $Res Function(BabyVaccineStatistics) _then) = _$BabyVaccineStatisticsCopyWithImpl;
@useResult
$Res call({
 List<BabyVaccineItem> perBaby, List<BabyMilestoneItem> milestoneTimeline
});




}
/// @nodoc
class _$BabyVaccineStatisticsCopyWithImpl<$Res>
    implements $BabyVaccineStatisticsCopyWith<$Res> {
  _$BabyVaccineStatisticsCopyWithImpl(this._self, this._then);

  final BabyVaccineStatistics _self;
  final $Res Function(BabyVaccineStatistics) _then;

/// Create a copy of BabyVaccineStatistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? perBaby = null,Object? milestoneTimeline = null,}) {
  return _then(BabyVaccineStatistics(
perBaby: null == perBaby ? _self.perBaby : perBaby // ignore: cast_nullable_to_non_nullable
as List<BabyVaccineItem>,milestoneTimeline: null == milestoneTimeline ? _self.milestoneTimeline : milestoneTimeline // ignore: cast_nullable_to_non_nullable
as List<BabyMilestoneItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyVaccineStatistics].
extension BabyVaccineStatisticsPatterns on BabyVaccineStatistics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyVaccineStatistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyVaccineStatistics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyVaccineStatistics value)  $default,){
final _that = this;
switch (_that) {
case _BabyVaccineStatistics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyVaccineStatistics value)?  $default,){
final _that = this;
switch (_that) {
case _BabyVaccineStatistics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BabyVaccineItem> perBaby,  List<BabyMilestoneItem> milestoneTimeline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyVaccineStatistics() when $default != null:
return $default(_that.perBaby,_that.milestoneTimeline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BabyVaccineItem> perBaby,  List<BabyMilestoneItem> milestoneTimeline)  $default,) {final _that = this;
switch (_that) {
case _BabyVaccineStatistics():
return $default(_that.perBaby,_that.milestoneTimeline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BabyVaccineItem> perBaby,  List<BabyMilestoneItem> milestoneTimeline)?  $default,) {final _that = this;
switch (_that) {
case _BabyVaccineStatistics() when $default != null:
return $default(_that.perBaby,_that.milestoneTimeline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyVaccineStatistics implements BabyVaccineStatistics {
  const _BabyVaccineStatistics({ List<BabyVaccineItem> perBaby = const <BabyVaccineItem>[],  List<BabyMilestoneItem> milestoneTimeline = const <BabyMilestoneItem>[]}): _perBaby = perBaby,_milestoneTimeline = milestoneTimeline;
  factory _BabyVaccineStatistics.fromJson(Map<String, dynamic> json) => _$BabyVaccineStatisticsFromJson(json);

 final  List<BabyVaccineItem> _perBaby;
@override@JsonKey() List<BabyVaccineItem> get perBaby {
  if (_perBaby is EqualUnmodifiableListView) return _perBaby;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_perBaby);
}

 final  List<BabyMilestoneItem> _milestoneTimeline;
@override@JsonKey() List<BabyMilestoneItem> get milestoneTimeline {
  if (_milestoneTimeline is EqualUnmodifiableListView) return _milestoneTimeline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_milestoneTimeline);
}


/// Create a copy of BabyVaccineStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyVaccineStatisticsCopyWith<_BabyVaccineStatistics> get copyWith => __$BabyVaccineStatisticsCopyWithImpl<_BabyVaccineStatistics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyVaccineStatisticsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyVaccineStatistics&&const DeepCollectionEquality().equals(other.perBaby, _perBaby)&&const DeepCollectionEquality().equals(other.milestoneTimeline, _milestoneTimeline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_perBaby),const DeepCollectionEquality().hash(_milestoneTimeline));
}

@override
String toString() {
    return 'BabyVaccineStatistics(perBaby: $perBaby, milestoneTimeline: $milestoneTimeline)';
}


}

/// @nodoc
abstract mixin class _$BabyVaccineStatisticsCopyWith<$Res> implements $BabyVaccineStatisticsCopyWith<$Res> {
  factory _$BabyVaccineStatisticsCopyWith(_BabyVaccineStatistics value, $Res Function(_BabyVaccineStatistics) _then) = __$BabyVaccineStatisticsCopyWithImpl;
@override @useResult
$Res call({
 List<BabyVaccineItem> perBaby, List<BabyMilestoneItem> milestoneTimeline
});




}
/// @nodoc
class __$BabyVaccineStatisticsCopyWithImpl<$Res>
    implements _$BabyVaccineStatisticsCopyWith<$Res> {
  __$BabyVaccineStatisticsCopyWithImpl(this._self, this._then);

  final _BabyVaccineStatistics _self;
  final $Res Function(_BabyVaccineStatistics) _then;

/// Create a copy of BabyVaccineStatistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? perBaby = null,Object? milestoneTimeline = null,}) {
  return _then(_BabyVaccineStatistics(
perBaby: null == perBaby ? _self._perBaby : perBaby // ignore: cast_nullable_to_non_nullable
as List<BabyVaccineItem>,milestoneTimeline: null == milestoneTimeline ? _self._milestoneTimeline : milestoneTimeline // ignore: cast_nullable_to_non_nullable
as List<BabyMilestoneItem>,
  ));
}


}


/// @nodoc
mixin _$BabyVaccineItem {

 int get babyId; String get name; int get completionRate; BabyVaccineCounts get statusCounts; List<BabyVaccinePlanItem> get upcoming; List<BabyVaccinePlanItem> get overdueList; List<BabyVaccineRecordItem> get recordTimeline;
/// Create a copy of BabyVaccineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyVaccineItemCopyWith<BabyVaccineItem> get copyWith => _$BabyVaccineItemCopyWithImpl<BabyVaccineItem>(this as BabyVaccineItem, _$identity);

  /// Serializes this BabyVaccineItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyVaccineItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyVaccineItem&&(identical(other.babyId, _this.babyId) || other.babyId == _this.babyId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.completionRate, _this.completionRate) || other.completionRate == _this.completionRate)&&(identical(other.statusCounts, _this.statusCounts) || other.statusCounts == _this.statusCounts)&&const DeepCollectionEquality().equals(other.upcoming, _this.upcoming)&&const DeepCollectionEquality().equals(other.overdueList, _this.overdueList)&&const DeepCollectionEquality().equals(other.recordTimeline, _this.recordTimeline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyVaccineItem;
  return Object.hash(runtimeType,_this.babyId,_this.name,_this.completionRate,_this.statusCounts,const DeepCollectionEquality().hash(_this.upcoming),const DeepCollectionEquality().hash(_this.overdueList),const DeepCollectionEquality().hash(_this.recordTimeline));
}

@override
String toString() {
  final _this = this as BabyVaccineItem;
  return 'BabyVaccineItem(babyId: ${_this.babyId}, name: ${_this.name}, completionRate: ${_this.completionRate}, statusCounts: ${_this.statusCounts}, upcoming: ${_this.upcoming}, overdueList: ${_this.overdueList}, recordTimeline: ${_this.recordTimeline})';
}


}

/// @nodoc
abstract mixin class $BabyVaccineItemCopyWith<$Res>  {
  factory $BabyVaccineItemCopyWith(BabyVaccineItem value, $Res Function(BabyVaccineItem) _then) = _$BabyVaccineItemCopyWithImpl;
@useResult
$Res call({
 int babyId, String name, int completionRate, BabyVaccineCounts statusCounts, List<BabyVaccinePlanItem> upcoming, List<BabyVaccinePlanItem> overdueList, List<BabyVaccineRecordItem> recordTimeline
});


$BabyVaccineCountsCopyWith<$Res> get statusCounts;

}
/// @nodoc
class _$BabyVaccineItemCopyWithImpl<$Res>
    implements $BabyVaccineItemCopyWith<$Res> {
  _$BabyVaccineItemCopyWithImpl(this._self, this._then);

  final BabyVaccineItem _self;
  final $Res Function(BabyVaccineItem) _then;

/// Create a copy of BabyVaccineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? babyId = null,Object? name = null,Object? completionRate = null,Object? statusCounts = null,Object? upcoming = null,Object? overdueList = null,Object? recordTimeline = null,}) {
  return _then(BabyVaccineItem(
babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as int,statusCounts: null == statusCounts ? _self.statusCounts : statusCounts // ignore: cast_nullable_to_non_nullable
as BabyVaccineCounts,upcoming: null == upcoming ? _self.upcoming : upcoming // ignore: cast_nullable_to_non_nullable
as List<BabyVaccinePlanItem>,overdueList: null == overdueList ? _self.overdueList : overdueList // ignore: cast_nullable_to_non_nullable
as List<BabyVaccinePlanItem>,recordTimeline: null == recordTimeline ? _self.recordTimeline : recordTimeline // ignore: cast_nullable_to_non_nullable
as List<BabyVaccineRecordItem>,
  ));
}
/// Create a copy of BabyVaccineItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyVaccineCountsCopyWith<$Res> get statusCounts {
  
  return $BabyVaccineCountsCopyWith<$Res>(_self.statusCounts, (value) {
    return _then(_self.copyWith(statusCounts: value));
  });
}
}


/// Adds pattern-matching-related methods to [BabyVaccineItem].
extension BabyVaccineItemPatterns on BabyVaccineItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyVaccineItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyVaccineItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyVaccineItem value)  $default,){
final _that = this;
switch (_that) {
case _BabyVaccineItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyVaccineItem value)?  $default,){
final _that = this;
switch (_that) {
case _BabyVaccineItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int babyId,  String name,  int completionRate,  BabyVaccineCounts statusCounts,  List<BabyVaccinePlanItem> upcoming,  List<BabyVaccinePlanItem> overdueList,  List<BabyVaccineRecordItem> recordTimeline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyVaccineItem() when $default != null:
return $default(_that.babyId,_that.name,_that.completionRate,_that.statusCounts,_that.upcoming,_that.overdueList,_that.recordTimeline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int babyId,  String name,  int completionRate,  BabyVaccineCounts statusCounts,  List<BabyVaccinePlanItem> upcoming,  List<BabyVaccinePlanItem> overdueList,  List<BabyVaccineRecordItem> recordTimeline)  $default,) {final _that = this;
switch (_that) {
case _BabyVaccineItem():
return $default(_that.babyId,_that.name,_that.completionRate,_that.statusCounts,_that.upcoming,_that.overdueList,_that.recordTimeline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int babyId,  String name,  int completionRate,  BabyVaccineCounts statusCounts,  List<BabyVaccinePlanItem> upcoming,  List<BabyVaccinePlanItem> overdueList,  List<BabyVaccineRecordItem> recordTimeline)?  $default,) {final _that = this;
switch (_that) {
case _BabyVaccineItem() when $default != null:
return $default(_that.babyId,_that.name,_that.completionRate,_that.statusCounts,_that.upcoming,_that.overdueList,_that.recordTimeline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyVaccineItem implements BabyVaccineItem {
  const _BabyVaccineItem({required this.babyId, required this.name, required this.completionRate, required this.statusCounts,  List<BabyVaccinePlanItem> upcoming = const <BabyVaccinePlanItem>[],  List<BabyVaccinePlanItem> overdueList = const <BabyVaccinePlanItem>[],  List<BabyVaccineRecordItem> recordTimeline = const <BabyVaccineRecordItem>[]}): _upcoming = upcoming,_overdueList = overdueList,_recordTimeline = recordTimeline;
  factory _BabyVaccineItem.fromJson(Map<String, dynamic> json) => _$BabyVaccineItemFromJson(json);

@override final  int babyId;
@override final  String name;
@override final  int completionRate;
@override final  BabyVaccineCounts statusCounts;
 final  List<BabyVaccinePlanItem> _upcoming;
@override@JsonKey() List<BabyVaccinePlanItem> get upcoming {
  if (_upcoming is EqualUnmodifiableListView) return _upcoming;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_upcoming);
}

 final  List<BabyVaccinePlanItem> _overdueList;
@override@JsonKey() List<BabyVaccinePlanItem> get overdueList {
  if (_overdueList is EqualUnmodifiableListView) return _overdueList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_overdueList);
}

 final  List<BabyVaccineRecordItem> _recordTimeline;
@override@JsonKey() List<BabyVaccineRecordItem> get recordTimeline {
  if (_recordTimeline is EqualUnmodifiableListView) return _recordTimeline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recordTimeline);
}


/// Create a copy of BabyVaccineItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyVaccineItemCopyWith<_BabyVaccineItem> get copyWith => __$BabyVaccineItemCopyWithImpl<_BabyVaccineItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyVaccineItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyVaccineItem&&(identical(other.babyId, babyId) || other.babyId == babyId)&&(identical(other.name, name) || other.name == name)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.statusCounts, statusCounts) || other.statusCounts == statusCounts)&&const DeepCollectionEquality().equals(other.upcoming, _upcoming)&&const DeepCollectionEquality().equals(other.overdueList, _overdueList)&&const DeepCollectionEquality().equals(other.recordTimeline, _recordTimeline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,babyId,name,completionRate,statusCounts,const DeepCollectionEquality().hash(_upcoming),const DeepCollectionEquality().hash(_overdueList),const DeepCollectionEquality().hash(_recordTimeline));
}

@override
String toString() {
    return 'BabyVaccineItem(babyId: $babyId, name: $name, completionRate: $completionRate, statusCounts: $statusCounts, upcoming: $upcoming, overdueList: $overdueList, recordTimeline: $recordTimeline)';
}


}

/// @nodoc
abstract mixin class _$BabyVaccineItemCopyWith<$Res> implements $BabyVaccineItemCopyWith<$Res> {
  factory _$BabyVaccineItemCopyWith(_BabyVaccineItem value, $Res Function(_BabyVaccineItem) _then) = __$BabyVaccineItemCopyWithImpl;
@override @useResult
$Res call({
 int babyId, String name, int completionRate, BabyVaccineCounts statusCounts, List<BabyVaccinePlanItem> upcoming, List<BabyVaccinePlanItem> overdueList, List<BabyVaccineRecordItem> recordTimeline
});


@override $BabyVaccineCountsCopyWith<$Res> get statusCounts;

}
/// @nodoc
class __$BabyVaccineItemCopyWithImpl<$Res>
    implements _$BabyVaccineItemCopyWith<$Res> {
  __$BabyVaccineItemCopyWithImpl(this._self, this._then);

  final _BabyVaccineItem _self;
  final $Res Function(_BabyVaccineItem) _then;

/// Create a copy of BabyVaccineItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? babyId = null,Object? name = null,Object? completionRate = null,Object? statusCounts = null,Object? upcoming = null,Object? overdueList = null,Object? recordTimeline = null,}) {
  return _then(_BabyVaccineItem(
babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as int,statusCounts: null == statusCounts ? _self.statusCounts : statusCounts // ignore: cast_nullable_to_non_nullable
as BabyVaccineCounts,upcoming: null == upcoming ? _self._upcoming : upcoming // ignore: cast_nullable_to_non_nullable
as List<BabyVaccinePlanItem>,overdueList: null == overdueList ? _self._overdueList : overdueList // ignore: cast_nullable_to_non_nullable
as List<BabyVaccinePlanItem>,recordTimeline: null == recordTimeline ? _self._recordTimeline : recordTimeline // ignore: cast_nullable_to_non_nullable
as List<BabyVaccineRecordItem>,
  ));
}

/// Create a copy of BabyVaccineItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyVaccineCountsCopyWith<$Res> get statusCounts {
  
  return $BabyVaccineCountsCopyWith<$Res>(_self.statusCounts, (value) {
    return _then(_self.copyWith(statusCounts: value));
  });
}
}


/// @nodoc
mixin _$BabyVaccineCounts {

 int get vaccinated; int get upcoming; int get dueSoon; int get overdue;
/// Create a copy of BabyVaccineCounts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyVaccineCountsCopyWith<BabyVaccineCounts> get copyWith => _$BabyVaccineCountsCopyWithImpl<BabyVaccineCounts>(this as BabyVaccineCounts, _$identity);

  /// Serializes this BabyVaccineCounts to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyVaccineCounts;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyVaccineCounts&&(identical(other.vaccinated, _this.vaccinated) || other.vaccinated == _this.vaccinated)&&(identical(other.upcoming, _this.upcoming) || other.upcoming == _this.upcoming)&&(identical(other.dueSoon, _this.dueSoon) || other.dueSoon == _this.dueSoon)&&(identical(other.overdue, _this.overdue) || other.overdue == _this.overdue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyVaccineCounts;
  return Object.hash(runtimeType,_this.vaccinated,_this.upcoming,_this.dueSoon,_this.overdue);
}

@override
String toString() {
  final _this = this as BabyVaccineCounts;
  return 'BabyVaccineCounts(vaccinated: ${_this.vaccinated}, upcoming: ${_this.upcoming}, dueSoon: ${_this.dueSoon}, overdue: ${_this.overdue})';
}


}

/// @nodoc
abstract mixin class $BabyVaccineCountsCopyWith<$Res>  {
  factory $BabyVaccineCountsCopyWith(BabyVaccineCounts value, $Res Function(BabyVaccineCounts) _then) = _$BabyVaccineCountsCopyWithImpl;
@useResult
$Res call({
 int vaccinated, int upcoming, int dueSoon, int overdue
});




}
/// @nodoc
class _$BabyVaccineCountsCopyWithImpl<$Res>
    implements $BabyVaccineCountsCopyWith<$Res> {
  _$BabyVaccineCountsCopyWithImpl(this._self, this._then);

  final BabyVaccineCounts _self;
  final $Res Function(BabyVaccineCounts) _then;

/// Create a copy of BabyVaccineCounts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vaccinated = null,Object? upcoming = null,Object? dueSoon = null,Object? overdue = null,}) {
  return _then(BabyVaccineCounts(
vaccinated: null == vaccinated ? _self.vaccinated : vaccinated // ignore: cast_nullable_to_non_nullable
as int,upcoming: null == upcoming ? _self.upcoming : upcoming // ignore: cast_nullable_to_non_nullable
as int,dueSoon: null == dueSoon ? _self.dueSoon : dueSoon // ignore: cast_nullable_to_non_nullable
as int,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyVaccineCounts].
extension BabyVaccineCountsPatterns on BabyVaccineCounts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyVaccineCounts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyVaccineCounts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyVaccineCounts value)  $default,){
final _that = this;
switch (_that) {
case _BabyVaccineCounts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyVaccineCounts value)?  $default,){
final _that = this;
switch (_that) {
case _BabyVaccineCounts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int vaccinated,  int upcoming,  int dueSoon,  int overdue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyVaccineCounts() when $default != null:
return $default(_that.vaccinated,_that.upcoming,_that.dueSoon,_that.overdue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int vaccinated,  int upcoming,  int dueSoon,  int overdue)  $default,) {final _that = this;
switch (_that) {
case _BabyVaccineCounts():
return $default(_that.vaccinated,_that.upcoming,_that.dueSoon,_that.overdue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int vaccinated,  int upcoming,  int dueSoon,  int overdue)?  $default,) {final _that = this;
switch (_that) {
case _BabyVaccineCounts() when $default != null:
return $default(_that.vaccinated,_that.upcoming,_that.dueSoon,_that.overdue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyVaccineCounts implements BabyVaccineCounts {
  const _BabyVaccineCounts({required this.vaccinated, required this.upcoming, required this.dueSoon, required this.overdue});
  factory _BabyVaccineCounts.fromJson(Map<String, dynamic> json) => _$BabyVaccineCountsFromJson(json);

@override final  int vaccinated;
@override final  int upcoming;
@override final  int dueSoon;
@override final  int overdue;

/// Create a copy of BabyVaccineCounts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyVaccineCountsCopyWith<_BabyVaccineCounts> get copyWith => __$BabyVaccineCountsCopyWithImpl<_BabyVaccineCounts>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyVaccineCountsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyVaccineCounts&&(identical(other.vaccinated, vaccinated) || other.vaccinated == vaccinated)&&(identical(other.upcoming, upcoming) || other.upcoming == upcoming)&&(identical(other.dueSoon, dueSoon) || other.dueSoon == dueSoon)&&(identical(other.overdue, overdue) || other.overdue == overdue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,vaccinated,upcoming,dueSoon,overdue);
}

@override
String toString() {
    return 'BabyVaccineCounts(vaccinated: $vaccinated, upcoming: $upcoming, dueSoon: $dueSoon, overdue: $overdue)';
}


}

/// @nodoc
abstract mixin class _$BabyVaccineCountsCopyWith<$Res> implements $BabyVaccineCountsCopyWith<$Res> {
  factory _$BabyVaccineCountsCopyWith(_BabyVaccineCounts value, $Res Function(_BabyVaccineCounts) _then) = __$BabyVaccineCountsCopyWithImpl;
@override @useResult
$Res call({
 int vaccinated, int upcoming, int dueSoon, int overdue
});




}
/// @nodoc
class __$BabyVaccineCountsCopyWithImpl<$Res>
    implements _$BabyVaccineCountsCopyWith<$Res> {
  __$BabyVaccineCountsCopyWithImpl(this._self, this._then);

  final _BabyVaccineCounts _self;
  final $Res Function(_BabyVaccineCounts) _then;

/// Create a copy of BabyVaccineCounts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vaccinated = null,Object? upcoming = null,Object? dueSoon = null,Object? overdue = null,}) {
  return _then(_BabyVaccineCounts(
vaccinated: null == vaccinated ? _self.vaccinated : vaccinated // ignore: cast_nullable_to_non_nullable
as int,upcoming: null == upcoming ? _self.upcoming : upcoming // ignore: cast_nullable_to_non_nullable
as int,dueSoon: null == dueSoon ? _self.dueSoon : dueSoon // ignore: cast_nullable_to_non_nullable
as int,overdue: null == overdue ? _self.overdue : overdue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$BabyVaccinePlanItem {

 int get planId; String get vaccineName; String get doseNo; DateTime get dueDate; int? get daysToDue; int? get overdueDays;
/// Create a copy of BabyVaccinePlanItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyVaccinePlanItemCopyWith<BabyVaccinePlanItem> get copyWith => _$BabyVaccinePlanItemCopyWithImpl<BabyVaccinePlanItem>(this as BabyVaccinePlanItem, _$identity);

  /// Serializes this BabyVaccinePlanItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyVaccinePlanItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyVaccinePlanItem&&(identical(other.planId, _this.planId) || other.planId == _this.planId)&&(identical(other.vaccineName, _this.vaccineName) || other.vaccineName == _this.vaccineName)&&(identical(other.doseNo, _this.doseNo) || other.doseNo == _this.doseNo)&&(identical(other.dueDate, _this.dueDate) || other.dueDate == _this.dueDate)&&(identical(other.daysToDue, _this.daysToDue) || other.daysToDue == _this.daysToDue)&&(identical(other.overdueDays, _this.overdueDays) || other.overdueDays == _this.overdueDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyVaccinePlanItem;
  return Object.hash(runtimeType,_this.planId,_this.vaccineName,_this.doseNo,_this.dueDate,_this.daysToDue,_this.overdueDays);
}

@override
String toString() {
  final _this = this as BabyVaccinePlanItem;
  return 'BabyVaccinePlanItem(planId: ${_this.planId}, vaccineName: ${_this.vaccineName}, doseNo: ${_this.doseNo}, dueDate: ${_this.dueDate}, daysToDue: ${_this.daysToDue}, overdueDays: ${_this.overdueDays})';
}


}

/// @nodoc
abstract mixin class $BabyVaccinePlanItemCopyWith<$Res>  {
  factory $BabyVaccinePlanItemCopyWith(BabyVaccinePlanItem value, $Res Function(BabyVaccinePlanItem) _then) = _$BabyVaccinePlanItemCopyWithImpl;
@useResult
$Res call({
 int planId, String vaccineName, String doseNo, DateTime dueDate, int? daysToDue, int? overdueDays
});




}
/// @nodoc
class _$BabyVaccinePlanItemCopyWithImpl<$Res>
    implements $BabyVaccinePlanItemCopyWith<$Res> {
  _$BabyVaccinePlanItemCopyWithImpl(this._self, this._then);

  final BabyVaccinePlanItem _self;
  final $Res Function(BabyVaccinePlanItem) _then;

/// Create a copy of BabyVaccinePlanItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? planId = null,Object? vaccineName = null,Object? doseNo = null,Object? dueDate = null,Object? daysToDue = freezed,Object? overdueDays = freezed,}) {
  return _then(BabyVaccinePlanItem(
planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as int,vaccineName: null == vaccineName ? _self.vaccineName : vaccineName // ignore: cast_nullable_to_non_nullable
as String,doseNo: null == doseNo ? _self.doseNo : doseNo // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,daysToDue: freezed == daysToDue ? _self.daysToDue : daysToDue // ignore: cast_nullable_to_non_nullable
as int?,overdueDays: freezed == overdueDays ? _self.overdueDays : overdueDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyVaccinePlanItem].
extension BabyVaccinePlanItemPatterns on BabyVaccinePlanItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyVaccinePlanItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyVaccinePlanItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyVaccinePlanItem value)  $default,){
final _that = this;
switch (_that) {
case _BabyVaccinePlanItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyVaccinePlanItem value)?  $default,){
final _that = this;
switch (_that) {
case _BabyVaccinePlanItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int planId,  String vaccineName,  String doseNo,  DateTime dueDate,  int? daysToDue,  int? overdueDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyVaccinePlanItem() when $default != null:
return $default(_that.planId,_that.vaccineName,_that.doseNo,_that.dueDate,_that.daysToDue,_that.overdueDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int planId,  String vaccineName,  String doseNo,  DateTime dueDate,  int? daysToDue,  int? overdueDays)  $default,) {final _that = this;
switch (_that) {
case _BabyVaccinePlanItem():
return $default(_that.planId,_that.vaccineName,_that.doseNo,_that.dueDate,_that.daysToDue,_that.overdueDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int planId,  String vaccineName,  String doseNo,  DateTime dueDate,  int? daysToDue,  int? overdueDays)?  $default,) {final _that = this;
switch (_that) {
case _BabyVaccinePlanItem() when $default != null:
return $default(_that.planId,_that.vaccineName,_that.doseNo,_that.dueDate,_that.daysToDue,_that.overdueDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyVaccinePlanItem implements BabyVaccinePlanItem {
  const _BabyVaccinePlanItem({required this.planId, required this.vaccineName, required this.doseNo, required this.dueDate, this.daysToDue, this.overdueDays});
  factory _BabyVaccinePlanItem.fromJson(Map<String, dynamic> json) => _$BabyVaccinePlanItemFromJson(json);

@override final  int planId;
@override final  String vaccineName;
@override final  String doseNo;
@override final  DateTime dueDate;
@override final  int? daysToDue;
@override final  int? overdueDays;

/// Create a copy of BabyVaccinePlanItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyVaccinePlanItemCopyWith<_BabyVaccinePlanItem> get copyWith => __$BabyVaccinePlanItemCopyWithImpl<_BabyVaccinePlanItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyVaccinePlanItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyVaccinePlanItem&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.vaccineName, vaccineName) || other.vaccineName == vaccineName)&&(identical(other.doseNo, doseNo) || other.doseNo == doseNo)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.daysToDue, daysToDue) || other.daysToDue == daysToDue)&&(identical(other.overdueDays, overdueDays) || other.overdueDays == overdueDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,planId,vaccineName,doseNo,dueDate,daysToDue,overdueDays);
}

@override
String toString() {
    return 'BabyVaccinePlanItem(planId: $planId, vaccineName: $vaccineName, doseNo: $doseNo, dueDate: $dueDate, daysToDue: $daysToDue, overdueDays: $overdueDays)';
}


}

/// @nodoc
abstract mixin class _$BabyVaccinePlanItemCopyWith<$Res> implements $BabyVaccinePlanItemCopyWith<$Res> {
  factory _$BabyVaccinePlanItemCopyWith(_BabyVaccinePlanItem value, $Res Function(_BabyVaccinePlanItem) _then) = __$BabyVaccinePlanItemCopyWithImpl;
@override @useResult
$Res call({
 int planId, String vaccineName, String doseNo, DateTime dueDate, int? daysToDue, int? overdueDays
});




}
/// @nodoc
class __$BabyVaccinePlanItemCopyWithImpl<$Res>
    implements _$BabyVaccinePlanItemCopyWith<$Res> {
  __$BabyVaccinePlanItemCopyWithImpl(this._self, this._then);

  final _BabyVaccinePlanItem _self;
  final $Res Function(_BabyVaccinePlanItem) _then;

/// Create a copy of BabyVaccinePlanItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? planId = null,Object? vaccineName = null,Object? doseNo = null,Object? dueDate = null,Object? daysToDue = freezed,Object? overdueDays = freezed,}) {
  return _then(_BabyVaccinePlanItem(
planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as int,vaccineName: null == vaccineName ? _self.vaccineName : vaccineName // ignore: cast_nullable_to_non_nullable
as String,doseNo: null == doseNo ? _self.doseNo : doseNo // ignore: cast_nullable_to_non_nullable
as String,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,daysToDue: freezed == daysToDue ? _self.daysToDue : daysToDue // ignore: cast_nullable_to_non_nullable
as int?,overdueDays: freezed == overdueDays ? _self.overdueDays : overdueDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$BabyVaccineRecordItem {

 String get vaccineName; DateTime get givenDate; String? get clinic;
/// Create a copy of BabyVaccineRecordItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyVaccineRecordItemCopyWith<BabyVaccineRecordItem> get copyWith => _$BabyVaccineRecordItemCopyWithImpl<BabyVaccineRecordItem>(this as BabyVaccineRecordItem, _$identity);

  /// Serializes this BabyVaccineRecordItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyVaccineRecordItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyVaccineRecordItem&&(identical(other.vaccineName, _this.vaccineName) || other.vaccineName == _this.vaccineName)&&(identical(other.givenDate, _this.givenDate) || other.givenDate == _this.givenDate)&&(identical(other.clinic, _this.clinic) || other.clinic == _this.clinic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyVaccineRecordItem;
  return Object.hash(runtimeType,_this.vaccineName,_this.givenDate,_this.clinic);
}

@override
String toString() {
  final _this = this as BabyVaccineRecordItem;
  return 'BabyVaccineRecordItem(vaccineName: ${_this.vaccineName}, givenDate: ${_this.givenDate}, clinic: ${_this.clinic})';
}


}

/// @nodoc
abstract mixin class $BabyVaccineRecordItemCopyWith<$Res>  {
  factory $BabyVaccineRecordItemCopyWith(BabyVaccineRecordItem value, $Res Function(BabyVaccineRecordItem) _then) = _$BabyVaccineRecordItemCopyWithImpl;
@useResult
$Res call({
 String vaccineName, DateTime givenDate, String? clinic
});




}
/// @nodoc
class _$BabyVaccineRecordItemCopyWithImpl<$Res>
    implements $BabyVaccineRecordItemCopyWith<$Res> {
  _$BabyVaccineRecordItemCopyWithImpl(this._self, this._then);

  final BabyVaccineRecordItem _self;
  final $Res Function(BabyVaccineRecordItem) _then;

/// Create a copy of BabyVaccineRecordItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? vaccineName = null,Object? givenDate = null,Object? clinic = freezed,}) {
  return _then(BabyVaccineRecordItem(
vaccineName: null == vaccineName ? _self.vaccineName : vaccineName // ignore: cast_nullable_to_non_nullable
as String,givenDate: null == givenDate ? _self.givenDate : givenDate // ignore: cast_nullable_to_non_nullable
as DateTime,clinic: freezed == clinic ? _self.clinic : clinic // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyVaccineRecordItem].
extension BabyVaccineRecordItemPatterns on BabyVaccineRecordItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyVaccineRecordItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyVaccineRecordItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyVaccineRecordItem value)  $default,){
final _that = this;
switch (_that) {
case _BabyVaccineRecordItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyVaccineRecordItem value)?  $default,){
final _that = this;
switch (_that) {
case _BabyVaccineRecordItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String vaccineName,  DateTime givenDate,  String? clinic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyVaccineRecordItem() when $default != null:
return $default(_that.vaccineName,_that.givenDate,_that.clinic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String vaccineName,  DateTime givenDate,  String? clinic)  $default,) {final _that = this;
switch (_that) {
case _BabyVaccineRecordItem():
return $default(_that.vaccineName,_that.givenDate,_that.clinic);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String vaccineName,  DateTime givenDate,  String? clinic)?  $default,) {final _that = this;
switch (_that) {
case _BabyVaccineRecordItem() when $default != null:
return $default(_that.vaccineName,_that.givenDate,_that.clinic);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyVaccineRecordItem implements BabyVaccineRecordItem {
  const _BabyVaccineRecordItem({required this.vaccineName, required this.givenDate, this.clinic});
  factory _BabyVaccineRecordItem.fromJson(Map<String, dynamic> json) => _$BabyVaccineRecordItemFromJson(json);

@override final  String vaccineName;
@override final  DateTime givenDate;
@override final  String? clinic;

/// Create a copy of BabyVaccineRecordItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyVaccineRecordItemCopyWith<_BabyVaccineRecordItem> get copyWith => __$BabyVaccineRecordItemCopyWithImpl<_BabyVaccineRecordItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyVaccineRecordItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyVaccineRecordItem&&(identical(other.vaccineName, vaccineName) || other.vaccineName == vaccineName)&&(identical(other.givenDate, givenDate) || other.givenDate == givenDate)&&(identical(other.clinic, clinic) || other.clinic == clinic));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,vaccineName,givenDate,clinic);
}

@override
String toString() {
    return 'BabyVaccineRecordItem(vaccineName: $vaccineName, givenDate: $givenDate, clinic: $clinic)';
}


}

/// @nodoc
abstract mixin class _$BabyVaccineRecordItemCopyWith<$Res> implements $BabyVaccineRecordItemCopyWith<$Res> {
  factory _$BabyVaccineRecordItemCopyWith(_BabyVaccineRecordItem value, $Res Function(_BabyVaccineRecordItem) _then) = __$BabyVaccineRecordItemCopyWithImpl;
@override @useResult
$Res call({
 String vaccineName, DateTime givenDate, String? clinic
});




}
/// @nodoc
class __$BabyVaccineRecordItemCopyWithImpl<$Res>
    implements _$BabyVaccineRecordItemCopyWith<$Res> {
  __$BabyVaccineRecordItemCopyWithImpl(this._self, this._then);

  final _BabyVaccineRecordItem _self;
  final $Res Function(_BabyVaccineRecordItem) _then;

/// Create a copy of BabyVaccineRecordItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? vaccineName = null,Object? givenDate = null,Object? clinic = freezed,}) {
  return _then(_BabyVaccineRecordItem(
vaccineName: null == vaccineName ? _self.vaccineName : vaccineName // ignore: cast_nullable_to_non_nullable
as String,givenDate: null == givenDate ? _self.givenDate : givenDate // ignore: cast_nullable_to_non_nullable
as DateTime,clinic: freezed == clinic ? _self.clinic : clinic // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BabyMilestoneItem {

 int get babyId; String get babyName; DateTime get occurDate; String get title; String? get description;
/// Create a copy of BabyMilestoneItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyMilestoneItemCopyWith<BabyMilestoneItem> get copyWith => _$BabyMilestoneItemCopyWithImpl<BabyMilestoneItem>(this as BabyMilestoneItem, _$identity);

  /// Serializes this BabyMilestoneItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyMilestoneItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyMilestoneItem&&(identical(other.babyId, _this.babyId) || other.babyId == _this.babyId)&&(identical(other.babyName, _this.babyName) || other.babyName == _this.babyName)&&(identical(other.occurDate, _this.occurDate) || other.occurDate == _this.occurDate)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyMilestoneItem;
  return Object.hash(runtimeType,_this.babyId,_this.babyName,_this.occurDate,_this.title,_this.description);
}

@override
String toString() {
  final _this = this as BabyMilestoneItem;
  return 'BabyMilestoneItem(babyId: ${_this.babyId}, babyName: ${_this.babyName}, occurDate: ${_this.occurDate}, title: ${_this.title}, description: ${_this.description})';
}


}

/// @nodoc
abstract mixin class $BabyMilestoneItemCopyWith<$Res>  {
  factory $BabyMilestoneItemCopyWith(BabyMilestoneItem value, $Res Function(BabyMilestoneItem) _then) = _$BabyMilestoneItemCopyWithImpl;
@useResult
$Res call({
 int babyId, String babyName, DateTime occurDate, String title, String? description
});




}
/// @nodoc
class _$BabyMilestoneItemCopyWithImpl<$Res>
    implements $BabyMilestoneItemCopyWith<$Res> {
  _$BabyMilestoneItemCopyWithImpl(this._self, this._then);

  final BabyMilestoneItem _self;
  final $Res Function(BabyMilestoneItem) _then;

/// Create a copy of BabyMilestoneItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? babyId = null,Object? babyName = null,Object? occurDate = null,Object? title = null,Object? description = freezed,}) {
  return _then(BabyMilestoneItem(
babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,babyName: null == babyName ? _self.babyName : babyName // ignore: cast_nullable_to_non_nullable
as String,occurDate: null == occurDate ? _self.occurDate : occurDate // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyMilestoneItem].
extension BabyMilestoneItemPatterns on BabyMilestoneItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyMilestoneItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyMilestoneItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyMilestoneItem value)  $default,){
final _that = this;
switch (_that) {
case _BabyMilestoneItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyMilestoneItem value)?  $default,){
final _that = this;
switch (_that) {
case _BabyMilestoneItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int babyId,  String babyName,  DateTime occurDate,  String title,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyMilestoneItem() when $default != null:
return $default(_that.babyId,_that.babyName,_that.occurDate,_that.title,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int babyId,  String babyName,  DateTime occurDate,  String title,  String? description)  $default,) {final _that = this;
switch (_that) {
case _BabyMilestoneItem():
return $default(_that.babyId,_that.babyName,_that.occurDate,_that.title,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int babyId,  String babyName,  DateTime occurDate,  String title,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _BabyMilestoneItem() when $default != null:
return $default(_that.babyId,_that.babyName,_that.occurDate,_that.title,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyMilestoneItem implements BabyMilestoneItem {
  const _BabyMilestoneItem({required this.babyId, required this.babyName, required this.occurDate, required this.title, this.description});
  factory _BabyMilestoneItem.fromJson(Map<String, dynamic> json) => _$BabyMilestoneItemFromJson(json);

@override final  int babyId;
@override final  String babyName;
@override final  DateTime occurDate;
@override final  String title;
@override final  String? description;

/// Create a copy of BabyMilestoneItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyMilestoneItemCopyWith<_BabyMilestoneItem> get copyWith => __$BabyMilestoneItemCopyWithImpl<_BabyMilestoneItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyMilestoneItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyMilestoneItem&&(identical(other.babyId, babyId) || other.babyId == babyId)&&(identical(other.babyName, babyName) || other.babyName == babyName)&&(identical(other.occurDate, occurDate) || other.occurDate == occurDate)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,babyId,babyName,occurDate,title,description);
}

@override
String toString() {
    return 'BabyMilestoneItem(babyId: $babyId, babyName: $babyName, occurDate: $occurDate, title: $title, description: $description)';
}


}

/// @nodoc
abstract mixin class _$BabyMilestoneItemCopyWith<$Res> implements $BabyMilestoneItemCopyWith<$Res> {
  factory _$BabyMilestoneItemCopyWith(_BabyMilestoneItem value, $Res Function(_BabyMilestoneItem) _then) = __$BabyMilestoneItemCopyWithImpl;
@override @useResult
$Res call({
 int babyId, String babyName, DateTime occurDate, String title, String? description
});




}
/// @nodoc
class __$BabyMilestoneItemCopyWithImpl<$Res>
    implements _$BabyMilestoneItemCopyWith<$Res> {
  __$BabyMilestoneItemCopyWithImpl(this._self, this._then);

  final _BabyMilestoneItem _self;
  final $Res Function(_BabyMilestoneItem) _then;

/// Create a copy of BabyMilestoneItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? babyId = null,Object? babyName = null,Object? occurDate = null,Object? title = null,Object? description = freezed,}) {
  return _then(_BabyMilestoneItem(
babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,babyName: null == babyName ? _self.babyName : babyName // ignore: cast_nullable_to_non_nullable
as String,occurDate: null == occurDate ? _self.occurDate : occurDate // ignore: cast_nullable_to_non_nullable
as DateTime,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
