// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'baby_growth.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BabyGrowth {

 int get id; int get babyId; DateTime get measureDate; String? get heightCm; String? get weightKg; String? get headCm; String? get remark; BabyGrowthDelta? get deltaFromPrevious; BabyPercentiles? get percentiles;
/// Create a copy of BabyGrowth
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyGrowthCopyWith<BabyGrowth> get copyWith => _$BabyGrowthCopyWithImpl<BabyGrowth>(this as BabyGrowth, _$identity);

  /// Serializes this BabyGrowth to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyGrowth;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyGrowth&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.babyId, _this.babyId) || other.babyId == _this.babyId)&&(identical(other.measureDate, _this.measureDate) || other.measureDate == _this.measureDate)&&(identical(other.heightCm, _this.heightCm) || other.heightCm == _this.heightCm)&&(identical(other.weightKg, _this.weightKg) || other.weightKg == _this.weightKg)&&(identical(other.headCm, _this.headCm) || other.headCm == _this.headCm)&&(identical(other.remark, _this.remark) || other.remark == _this.remark)&&(identical(other.deltaFromPrevious, _this.deltaFromPrevious) || other.deltaFromPrevious == _this.deltaFromPrevious)&&(identical(other.percentiles, _this.percentiles) || other.percentiles == _this.percentiles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyGrowth;
  return Object.hash(runtimeType,_this.id,_this.babyId,_this.measureDate,_this.heightCm,_this.weightKg,_this.headCm,_this.remark,_this.deltaFromPrevious,_this.percentiles);
}

@override
String toString() {
  final _this = this as BabyGrowth;
  return 'BabyGrowth(id: ${_this.id}, babyId: ${_this.babyId}, measureDate: ${_this.measureDate}, heightCm: ${_this.heightCm}, weightKg: ${_this.weightKg}, headCm: ${_this.headCm}, remark: ${_this.remark}, deltaFromPrevious: ${_this.deltaFromPrevious}, percentiles: ${_this.percentiles})';
}


}

/// @nodoc
abstract mixin class $BabyGrowthCopyWith<$Res>  {
  factory $BabyGrowthCopyWith(BabyGrowth value, $Res Function(BabyGrowth) _then) = _$BabyGrowthCopyWithImpl;
@useResult
$Res call({
 int id, int babyId, DateTime measureDate, String? heightCm, String? weightKg, String? headCm, String? remark, BabyGrowthDelta? deltaFromPrevious, BabyPercentiles? percentiles
});


$BabyGrowthDeltaCopyWith<$Res>? get deltaFromPrevious;$BabyPercentilesCopyWith<$Res>? get percentiles;

}
/// @nodoc
class _$BabyGrowthCopyWithImpl<$Res>
    implements $BabyGrowthCopyWith<$Res> {
  _$BabyGrowthCopyWithImpl(this._self, this._then);

  final BabyGrowth _self;
  final $Res Function(BabyGrowth) _then;

/// Create a copy of BabyGrowth
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? babyId = null,Object? measureDate = null,Object? heightCm = freezed,Object? weightKg = freezed,Object? headCm = freezed,Object? remark = freezed,Object? deltaFromPrevious = freezed,Object? percentiles = freezed,}) {
  return _then(BabyGrowth(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,measureDate: null == measureDate ? _self.measureDate : measureDate // ignore: cast_nullable_to_non_nullable
as DateTime,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as String?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as String?,headCm: freezed == headCm ? _self.headCm : headCm // ignore: cast_nullable_to_non_nullable
as String?,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,deltaFromPrevious: freezed == deltaFromPrevious ? _self.deltaFromPrevious : deltaFromPrevious // ignore: cast_nullable_to_non_nullable
as BabyGrowthDelta?,percentiles: freezed == percentiles ? _self.percentiles : percentiles // ignore: cast_nullable_to_non_nullable
as BabyPercentiles?,
  ));
}
/// Create a copy of BabyGrowth
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthDeltaCopyWith<$Res>? get deltaFromPrevious {
    if (_self.deltaFromPrevious == null) {
    return null;
  }

  return $BabyGrowthDeltaCopyWith<$Res>(_self.deltaFromPrevious!, (value) {
    return _then(_self.copyWith(deltaFromPrevious: value));
  });
}/// Create a copy of BabyGrowth
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyPercentilesCopyWith<$Res>? get percentiles {
    if (_self.percentiles == null) {
    return null;
  }

  return $BabyPercentilesCopyWith<$Res>(_self.percentiles!, (value) {
    return _then(_self.copyWith(percentiles: value));
  });
}
}


/// Adds pattern-matching-related methods to [BabyGrowth].
extension BabyGrowthPatterns on BabyGrowth {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyGrowth value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyGrowth() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyGrowth value)  $default,){
final _that = this;
switch (_that) {
case _BabyGrowth():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyGrowth value)?  $default,){
final _that = this;
switch (_that) {
case _BabyGrowth() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int babyId,  DateTime measureDate,  String? heightCm,  String? weightKg,  String? headCm,  String? remark,  BabyGrowthDelta? deltaFromPrevious,  BabyPercentiles? percentiles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyGrowth() when $default != null:
return $default(_that.id,_that.babyId,_that.measureDate,_that.heightCm,_that.weightKg,_that.headCm,_that.remark,_that.deltaFromPrevious,_that.percentiles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int babyId,  DateTime measureDate,  String? heightCm,  String? weightKg,  String? headCm,  String? remark,  BabyGrowthDelta? deltaFromPrevious,  BabyPercentiles? percentiles)  $default,) {final _that = this;
switch (_that) {
case _BabyGrowth():
return $default(_that.id,_that.babyId,_that.measureDate,_that.heightCm,_that.weightKg,_that.headCm,_that.remark,_that.deltaFromPrevious,_that.percentiles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int babyId,  DateTime measureDate,  String? heightCm,  String? weightKg,  String? headCm,  String? remark,  BabyGrowthDelta? deltaFromPrevious,  BabyPercentiles? percentiles)?  $default,) {final _that = this;
switch (_that) {
case _BabyGrowth() when $default != null:
return $default(_that.id,_that.babyId,_that.measureDate,_that.heightCm,_that.weightKg,_that.headCm,_that.remark,_that.deltaFromPrevious,_that.percentiles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyGrowth implements BabyGrowth {
  const _BabyGrowth({required this.id, required this.babyId, required this.measureDate, this.heightCm, this.weightKg, this.headCm, this.remark, this.deltaFromPrevious, this.percentiles});
  factory _BabyGrowth.fromJson(Map<String, dynamic> json) => _$BabyGrowthFromJson(json);

@override final  int id;
@override final  int babyId;
@override final  DateTime measureDate;
@override final  String? heightCm;
@override final  String? weightKg;
@override final  String? headCm;
@override final  String? remark;
@override final  BabyGrowthDelta? deltaFromPrevious;
@override final  BabyPercentiles? percentiles;

/// Create a copy of BabyGrowth
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyGrowthCopyWith<_BabyGrowth> get copyWith => __$BabyGrowthCopyWithImpl<_BabyGrowth>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyGrowthToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyGrowth&&(identical(other.id, id) || other.id == id)&&(identical(other.babyId, babyId) || other.babyId == babyId)&&(identical(other.measureDate, measureDate) || other.measureDate == measureDate)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.headCm, headCm) || other.headCm == headCm)&&(identical(other.remark, remark) || other.remark == remark)&&(identical(other.deltaFromPrevious, deltaFromPrevious) || other.deltaFromPrevious == deltaFromPrevious)&&(identical(other.percentiles, percentiles) || other.percentiles == percentiles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,babyId,measureDate,heightCm,weightKg,headCm,remark,deltaFromPrevious,percentiles);
}

@override
String toString() {
    return 'BabyGrowth(id: $id, babyId: $babyId, measureDate: $measureDate, heightCm: $heightCm, weightKg: $weightKg, headCm: $headCm, remark: $remark, deltaFromPrevious: $deltaFromPrevious, percentiles: $percentiles)';
}


}

/// @nodoc
abstract mixin class _$BabyGrowthCopyWith<$Res> implements $BabyGrowthCopyWith<$Res> {
  factory _$BabyGrowthCopyWith(_BabyGrowth value, $Res Function(_BabyGrowth) _then) = __$BabyGrowthCopyWithImpl;
@override @useResult
$Res call({
 int id, int babyId, DateTime measureDate, String? heightCm, String? weightKg, String? headCm, String? remark, BabyGrowthDelta? deltaFromPrevious, BabyPercentiles? percentiles
});


@override $BabyGrowthDeltaCopyWith<$Res>? get deltaFromPrevious;@override $BabyPercentilesCopyWith<$Res>? get percentiles;

}
/// @nodoc
class __$BabyGrowthCopyWithImpl<$Res>
    implements _$BabyGrowthCopyWith<$Res> {
  __$BabyGrowthCopyWithImpl(this._self, this._then);

  final _BabyGrowth _self;
  final $Res Function(_BabyGrowth) _then;

/// Create a copy of BabyGrowth
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? babyId = null,Object? measureDate = null,Object? heightCm = freezed,Object? weightKg = freezed,Object? headCm = freezed,Object? remark = freezed,Object? deltaFromPrevious = freezed,Object? percentiles = freezed,}) {
  return _then(_BabyGrowth(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,measureDate: null == measureDate ? _self.measureDate : measureDate // ignore: cast_nullable_to_non_nullable
as DateTime,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as String?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as String?,headCm: freezed == headCm ? _self.headCm : headCm // ignore: cast_nullable_to_non_nullable
as String?,remark: freezed == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String?,deltaFromPrevious: freezed == deltaFromPrevious ? _self.deltaFromPrevious : deltaFromPrevious // ignore: cast_nullable_to_non_nullable
as BabyGrowthDelta?,percentiles: freezed == percentiles ? _self.percentiles : percentiles // ignore: cast_nullable_to_non_nullable
as BabyPercentiles?,
  ));
}

/// Create a copy of BabyGrowth
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyGrowthDeltaCopyWith<$Res>? get deltaFromPrevious {
    if (_self.deltaFromPrevious == null) {
    return null;
  }

  return $BabyGrowthDeltaCopyWith<$Res>(_self.deltaFromPrevious!, (value) {
    return _then(_self.copyWith(deltaFromPrevious: value));
  });
}/// Create a copy of BabyGrowth
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BabyPercentilesCopyWith<$Res>? get percentiles {
    if (_self.percentiles == null) {
    return null;
  }

  return $BabyPercentilesCopyWith<$Res>(_self.percentiles!, (value) {
    return _then(_self.copyWith(percentiles: value));
  });
}
}


/// @nodoc
mixin _$BabyPercentiles {

 String? get height; String? get weight; String? get weightHeight; String? get bmi; String? get headCircumference;
/// Create a copy of BabyPercentiles
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyPercentilesCopyWith<BabyPercentiles> get copyWith => _$BabyPercentilesCopyWithImpl<BabyPercentiles>(this as BabyPercentiles, _$identity);

  /// Serializes this BabyPercentiles to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyPercentiles;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyPercentiles&&(identical(other.height, _this.height) || other.height == _this.height)&&(identical(other.weight, _this.weight) || other.weight == _this.weight)&&(identical(other.weightHeight, _this.weightHeight) || other.weightHeight == _this.weightHeight)&&(identical(other.bmi, _this.bmi) || other.bmi == _this.bmi)&&(identical(other.headCircumference, _this.headCircumference) || other.headCircumference == _this.headCircumference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyPercentiles;
  return Object.hash(runtimeType,_this.height,_this.weight,_this.weightHeight,_this.bmi,_this.headCircumference);
}

@override
String toString() {
  final _this = this as BabyPercentiles;
  return 'BabyPercentiles(height: ${_this.height}, weight: ${_this.weight}, weightHeight: ${_this.weightHeight}, bmi: ${_this.bmi}, headCircumference: ${_this.headCircumference})';
}


}

/// @nodoc
abstract mixin class $BabyPercentilesCopyWith<$Res>  {
  factory $BabyPercentilesCopyWith(BabyPercentiles value, $Res Function(BabyPercentiles) _then) = _$BabyPercentilesCopyWithImpl;
@useResult
$Res call({
 String? height, String? weight, String? weightHeight, String? bmi, String? headCircumference
});




}
/// @nodoc
class _$BabyPercentilesCopyWithImpl<$Res>
    implements $BabyPercentilesCopyWith<$Res> {
  _$BabyPercentilesCopyWithImpl(this._self, this._then);

  final BabyPercentiles _self;
  final $Res Function(BabyPercentiles) _then;

/// Create a copy of BabyPercentiles
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? height = freezed,Object? weight = freezed,Object? weightHeight = freezed,Object? bmi = freezed,Object? headCircumference = freezed,}) {
  return _then(BabyPercentiles(
height: freezed == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as String?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as String?,weightHeight: freezed == weightHeight ? _self.weightHeight : weightHeight // ignore: cast_nullable_to_non_nullable
as String?,bmi: freezed == bmi ? _self.bmi : bmi // ignore: cast_nullable_to_non_nullable
as String?,headCircumference: freezed == headCircumference ? _self.headCircumference : headCircumference // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyPercentiles].
extension BabyPercentilesPatterns on BabyPercentiles {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyPercentiles value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyPercentiles() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyPercentiles value)  $default,){
final _that = this;
switch (_that) {
case _BabyPercentiles():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyPercentiles value)?  $default,){
final _that = this;
switch (_that) {
case _BabyPercentiles() when $default != null:
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
case _BabyPercentiles() when $default != null:
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
case _BabyPercentiles():
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
case _BabyPercentiles() when $default != null:
return $default(_that.height,_that.weight,_that.weightHeight,_that.bmi,_that.headCircumference);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyPercentiles implements BabyPercentiles {
  const _BabyPercentiles({this.height, this.weight, this.weightHeight, this.bmi, this.headCircumference});
  factory _BabyPercentiles.fromJson(Map<String, dynamic> json) => _$BabyPercentilesFromJson(json);

@override final  String? height;
@override final  String? weight;
@override final  String? weightHeight;
@override final  String? bmi;
@override final  String? headCircumference;

/// Create a copy of BabyPercentiles
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyPercentilesCopyWith<_BabyPercentiles> get copyWith => __$BabyPercentilesCopyWithImpl<_BabyPercentiles>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyPercentilesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyPercentiles&&(identical(other.height, height) || other.height == height)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.weightHeight, weightHeight) || other.weightHeight == weightHeight)&&(identical(other.bmi, bmi) || other.bmi == bmi)&&(identical(other.headCircumference, headCircumference) || other.headCircumference == headCircumference));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,height,weight,weightHeight,bmi,headCircumference);
}

@override
String toString() {
    return 'BabyPercentiles(height: $height, weight: $weight, weightHeight: $weightHeight, bmi: $bmi, headCircumference: $headCircumference)';
}


}

/// @nodoc
abstract mixin class _$BabyPercentilesCopyWith<$Res> implements $BabyPercentilesCopyWith<$Res> {
  factory _$BabyPercentilesCopyWith(_BabyPercentiles value, $Res Function(_BabyPercentiles) _then) = __$BabyPercentilesCopyWithImpl;
@override @useResult
$Res call({
 String? height, String? weight, String? weightHeight, String? bmi, String? headCircumference
});




}
/// @nodoc
class __$BabyPercentilesCopyWithImpl<$Res>
    implements _$BabyPercentilesCopyWith<$Res> {
  __$BabyPercentilesCopyWithImpl(this._self, this._then);

  final _BabyPercentiles _self;
  final $Res Function(_BabyPercentiles) _then;

/// Create a copy of BabyPercentiles
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? height = freezed,Object? weight = freezed,Object? weightHeight = freezed,Object? bmi = freezed,Object? headCircumference = freezed,}) {
  return _then(_BabyPercentiles(
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
mixin _$BabyGrowthDelta {

 int? get days; String? get heightCm; String? get weightKg; String? get headCm;
/// Create a copy of BabyGrowthDelta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyGrowthDeltaCopyWith<BabyGrowthDelta> get copyWith => _$BabyGrowthDeltaCopyWithImpl<BabyGrowthDelta>(this as BabyGrowthDelta, _$identity);

  /// Serializes this BabyGrowthDelta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyGrowthDelta;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyGrowthDelta&&(identical(other.days, _this.days) || other.days == _this.days)&&(identical(other.heightCm, _this.heightCm) || other.heightCm == _this.heightCm)&&(identical(other.weightKg, _this.weightKg) || other.weightKg == _this.weightKg)&&(identical(other.headCm, _this.headCm) || other.headCm == _this.headCm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyGrowthDelta;
  return Object.hash(runtimeType,_this.days,_this.heightCm,_this.weightKg,_this.headCm);
}

@override
String toString() {
  final _this = this as BabyGrowthDelta;
  return 'BabyGrowthDelta(days: ${_this.days}, heightCm: ${_this.heightCm}, weightKg: ${_this.weightKg}, headCm: ${_this.headCm})';
}


}

/// @nodoc
abstract mixin class $BabyGrowthDeltaCopyWith<$Res>  {
  factory $BabyGrowthDeltaCopyWith(BabyGrowthDelta value, $Res Function(BabyGrowthDelta) _then) = _$BabyGrowthDeltaCopyWithImpl;
@useResult
$Res call({
 int? days, String? heightCm, String? weightKg, String? headCm
});




}
/// @nodoc
class _$BabyGrowthDeltaCopyWithImpl<$Res>
    implements $BabyGrowthDeltaCopyWith<$Res> {
  _$BabyGrowthDeltaCopyWithImpl(this._self, this._then);

  final BabyGrowthDelta _self;
  final $Res Function(BabyGrowthDelta) _then;

/// Create a copy of BabyGrowthDelta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? days = freezed,Object? heightCm = freezed,Object? weightKg = freezed,Object? headCm = freezed,}) {
  return _then(BabyGrowthDelta(
days: freezed == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as String?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as String?,headCm: freezed == headCm ? _self.headCm : headCm // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyGrowthDelta].
extension BabyGrowthDeltaPatterns on BabyGrowthDelta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyGrowthDelta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyGrowthDelta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyGrowthDelta value)  $default,){
final _that = this;
switch (_that) {
case _BabyGrowthDelta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyGrowthDelta value)?  $default,){
final _that = this;
switch (_that) {
case _BabyGrowthDelta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? days,  String? heightCm,  String? weightKg,  String? headCm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyGrowthDelta() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? days,  String? heightCm,  String? weightKg,  String? headCm)  $default,) {final _that = this;
switch (_that) {
case _BabyGrowthDelta():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? days,  String? heightCm,  String? weightKg,  String? headCm)?  $default,) {final _that = this;
switch (_that) {
case _BabyGrowthDelta() when $default != null:
return $default(_that.days,_that.heightCm,_that.weightKg,_that.headCm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyGrowthDelta implements BabyGrowthDelta {
  const _BabyGrowthDelta({this.days, this.heightCm, this.weightKg, this.headCm});
  factory _BabyGrowthDelta.fromJson(Map<String, dynamic> json) => _$BabyGrowthDeltaFromJson(json);

@override final  int? days;
@override final  String? heightCm;
@override final  String? weightKg;
@override final  String? headCm;

/// Create a copy of BabyGrowthDelta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyGrowthDeltaCopyWith<_BabyGrowthDelta> get copyWith => __$BabyGrowthDeltaCopyWithImpl<_BabyGrowthDelta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyGrowthDeltaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyGrowthDelta&&(identical(other.days, days) || other.days == days)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.headCm, headCm) || other.headCm == headCm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,days,heightCm,weightKg,headCm);
}

@override
String toString() {
    return 'BabyGrowthDelta(days: $days, heightCm: $heightCm, weightKg: $weightKg, headCm: $headCm)';
}


}

/// @nodoc
abstract mixin class _$BabyGrowthDeltaCopyWith<$Res> implements $BabyGrowthDeltaCopyWith<$Res> {
  factory _$BabyGrowthDeltaCopyWith(_BabyGrowthDelta value, $Res Function(_BabyGrowthDelta) _then) = __$BabyGrowthDeltaCopyWithImpl;
@override @useResult
$Res call({
 int? days, String? heightCm, String? weightKg, String? headCm
});




}
/// @nodoc
class __$BabyGrowthDeltaCopyWithImpl<$Res>
    implements _$BabyGrowthDeltaCopyWith<$Res> {
  __$BabyGrowthDeltaCopyWithImpl(this._self, this._then);

  final _BabyGrowthDelta _self;
  final $Res Function(_BabyGrowthDelta) _then;

/// Create a copy of BabyGrowthDelta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? days = freezed,Object? heightCm = freezed,Object? weightKg = freezed,Object? headCm = freezed,}) {
  return _then(_BabyGrowthDelta(
days: freezed == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as String?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as String?,headCm: freezed == headCm ? _self.headCm : headCm // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BabyCurve {

 int get babyId; String get metric; String get standardMetric; List<BabyCurvePoint> get points; List<GrowthStandardRow> get standard; String get disclaimer;
/// Create a copy of BabyCurve
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyCurveCopyWith<BabyCurve> get copyWith => _$BabyCurveCopyWithImpl<BabyCurve>(this as BabyCurve, _$identity);

  /// Serializes this BabyCurve to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyCurve;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyCurve&&(identical(other.babyId, _this.babyId) || other.babyId == _this.babyId)&&(identical(other.metric, _this.metric) || other.metric == _this.metric)&&(identical(other.standardMetric, _this.standardMetric) || other.standardMetric == _this.standardMetric)&&const DeepCollectionEquality().equals(other.points, _this.points)&&const DeepCollectionEquality().equals(other.standard, _this.standard)&&(identical(other.disclaimer, _this.disclaimer) || other.disclaimer == _this.disclaimer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyCurve;
  return Object.hash(runtimeType,_this.babyId,_this.metric,_this.standardMetric,const DeepCollectionEquality().hash(_this.points),const DeepCollectionEquality().hash(_this.standard),_this.disclaimer);
}

@override
String toString() {
  final _this = this as BabyCurve;
  return 'BabyCurve(babyId: ${_this.babyId}, metric: ${_this.metric}, standardMetric: ${_this.standardMetric}, points: ${_this.points}, standard: ${_this.standard}, disclaimer: ${_this.disclaimer})';
}


}

/// @nodoc
abstract mixin class $BabyCurveCopyWith<$Res>  {
  factory $BabyCurveCopyWith(BabyCurve value, $Res Function(BabyCurve) _then) = _$BabyCurveCopyWithImpl;
@useResult
$Res call({
 int babyId, String metric, String standardMetric, List<BabyCurvePoint> points, List<GrowthStandardRow> standard, String disclaimer
});




}
/// @nodoc
class _$BabyCurveCopyWithImpl<$Res>
    implements $BabyCurveCopyWith<$Res> {
  _$BabyCurveCopyWithImpl(this._self, this._then);

  final BabyCurve _self;
  final $Res Function(BabyCurve) _then;

/// Create a copy of BabyCurve
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? babyId = null,Object? metric = null,Object? standardMetric = null,Object? points = null,Object? standard = null,Object? disclaimer = null,}) {
  return _then(BabyCurve(
babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as String,standardMetric: null == standardMetric ? _self.standardMetric : standardMetric // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<BabyCurvePoint>,standard: null == standard ? _self.standard : standard // ignore: cast_nullable_to_non_nullable
as List<GrowthStandardRow>,disclaimer: null == disclaimer ? _self.disclaimer : disclaimer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyCurve].
extension BabyCurvePatterns on BabyCurve {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyCurve value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyCurve() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyCurve value)  $default,){
final _that = this;
switch (_that) {
case _BabyCurve():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyCurve value)?  $default,){
final _that = this;
switch (_that) {
case _BabyCurve() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int babyId,  String metric,  String standardMetric,  List<BabyCurvePoint> points,  List<GrowthStandardRow> standard,  String disclaimer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyCurve() when $default != null:
return $default(_that.babyId,_that.metric,_that.standardMetric,_that.points,_that.standard,_that.disclaimer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int babyId,  String metric,  String standardMetric,  List<BabyCurvePoint> points,  List<GrowthStandardRow> standard,  String disclaimer)  $default,) {final _that = this;
switch (_that) {
case _BabyCurve():
return $default(_that.babyId,_that.metric,_that.standardMetric,_that.points,_that.standard,_that.disclaimer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int babyId,  String metric,  String standardMetric,  List<BabyCurvePoint> points,  List<GrowthStandardRow> standard,  String disclaimer)?  $default,) {final _that = this;
switch (_that) {
case _BabyCurve() when $default != null:
return $default(_that.babyId,_that.metric,_that.standardMetric,_that.points,_that.standard,_that.disclaimer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyCurve implements BabyCurve {
  const _BabyCurve({required this.babyId, required this.metric, required this.standardMetric,  List<BabyCurvePoint> points = const <BabyCurvePoint>[],  List<GrowthStandardRow> standard = const <GrowthStandardRow>[], required this.disclaimer}): _points = points,_standard = standard;
  factory _BabyCurve.fromJson(Map<String, dynamic> json) => _$BabyCurveFromJson(json);

@override final  int babyId;
@override final  String metric;
@override final  String standardMetric;
 final  List<BabyCurvePoint> _points;
@override@JsonKey() List<BabyCurvePoint> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}

 final  List<GrowthStandardRow> _standard;
@override@JsonKey() List<GrowthStandardRow> get standard {
  if (_standard is EqualUnmodifiableListView) return _standard;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_standard);
}

@override final  String disclaimer;

/// Create a copy of BabyCurve
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyCurveCopyWith<_BabyCurve> get copyWith => __$BabyCurveCopyWithImpl<_BabyCurve>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyCurveToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyCurve&&(identical(other.babyId, babyId) || other.babyId == babyId)&&(identical(other.metric, metric) || other.metric == metric)&&(identical(other.standardMetric, standardMetric) || other.standardMetric == standardMetric)&&const DeepCollectionEquality().equals(other.points, _points)&&const DeepCollectionEquality().equals(other.standard, _standard)&&(identical(other.disclaimer, disclaimer) || other.disclaimer == disclaimer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,babyId,metric,standardMetric,const DeepCollectionEquality().hash(_points),const DeepCollectionEquality().hash(_standard),disclaimer);
}

@override
String toString() {
    return 'BabyCurve(babyId: $babyId, metric: $metric, standardMetric: $standardMetric, points: $points, standard: $standard, disclaimer: $disclaimer)';
}


}

/// @nodoc
abstract mixin class _$BabyCurveCopyWith<$Res> implements $BabyCurveCopyWith<$Res> {
  factory _$BabyCurveCopyWith(_BabyCurve value, $Res Function(_BabyCurve) _then) = __$BabyCurveCopyWithImpl;
@override @useResult
$Res call({
 int babyId, String metric, String standardMetric, List<BabyCurvePoint> points, List<GrowthStandardRow> standard, String disclaimer
});




}
/// @nodoc
class __$BabyCurveCopyWithImpl<$Res>
    implements _$BabyCurveCopyWith<$Res> {
  __$BabyCurveCopyWithImpl(this._self, this._then);

  final _BabyCurve _self;
  final $Res Function(_BabyCurve) _then;

/// Create a copy of BabyCurve
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? babyId = null,Object? metric = null,Object? standardMetric = null,Object? points = null,Object? standard = null,Object? disclaimer = null,}) {
  return _then(_BabyCurve(
babyId: null == babyId ? _self.babyId : babyId // ignore: cast_nullable_to_non_nullable
as int,metric: null == metric ? _self.metric : metric // ignore: cast_nullable_to_non_nullable
as String,standardMetric: null == standardMetric ? _self.standardMetric : standardMetric // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<BabyCurvePoint>,standard: null == standard ? _self._standard : standard // ignore: cast_nullable_to_non_nullable
as List<GrowthStandardRow>,disclaimer: null == disclaimer ? _self.disclaimer : disclaimer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BabyCurvePoint {

 DateTime get measureDate; int get ageMonths; double get xValue; double get measured; String? get percentileBand;
/// Create a copy of BabyCurvePoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyCurvePointCopyWith<BabyCurvePoint> get copyWith => _$BabyCurvePointCopyWithImpl<BabyCurvePoint>(this as BabyCurvePoint, _$identity);

  /// Serializes this BabyCurvePoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyCurvePoint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyCurvePoint&&(identical(other.measureDate, _this.measureDate) || other.measureDate == _this.measureDate)&&(identical(other.ageMonths, _this.ageMonths) || other.ageMonths == _this.ageMonths)&&(identical(other.xValue, _this.xValue) || other.xValue == _this.xValue)&&(identical(other.measured, _this.measured) || other.measured == _this.measured)&&(identical(other.percentileBand, _this.percentileBand) || other.percentileBand == _this.percentileBand));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyCurvePoint;
  return Object.hash(runtimeType,_this.measureDate,_this.ageMonths,_this.xValue,_this.measured,_this.percentileBand);
}

@override
String toString() {
  final _this = this as BabyCurvePoint;
  return 'BabyCurvePoint(measureDate: ${_this.measureDate}, ageMonths: ${_this.ageMonths}, xValue: ${_this.xValue}, measured: ${_this.measured}, percentileBand: ${_this.percentileBand})';
}


}

/// @nodoc
abstract mixin class $BabyCurvePointCopyWith<$Res>  {
  factory $BabyCurvePointCopyWith(BabyCurvePoint value, $Res Function(BabyCurvePoint) _then) = _$BabyCurvePointCopyWithImpl;
@useResult
$Res call({
 DateTime measureDate, int ageMonths, double xValue, double measured, String? percentileBand
});




}
/// @nodoc
class _$BabyCurvePointCopyWithImpl<$Res>
    implements $BabyCurvePointCopyWith<$Res> {
  _$BabyCurvePointCopyWithImpl(this._self, this._then);

  final BabyCurvePoint _self;
  final $Res Function(BabyCurvePoint) _then;

/// Create a copy of BabyCurvePoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? measureDate = null,Object? ageMonths = null,Object? xValue = null,Object? measured = null,Object? percentileBand = freezed,}) {
  return _then(BabyCurvePoint(
measureDate: null == measureDate ? _self.measureDate : measureDate // ignore: cast_nullable_to_non_nullable
as DateTime,ageMonths: null == ageMonths ? _self.ageMonths : ageMonths // ignore: cast_nullable_to_non_nullable
as int,xValue: null == xValue ? _self.xValue : xValue // ignore: cast_nullable_to_non_nullable
as double,measured: null == measured ? _self.measured : measured // ignore: cast_nullable_to_non_nullable
as double,percentileBand: freezed == percentileBand ? _self.percentileBand : percentileBand // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyCurvePoint].
extension BabyCurvePointPatterns on BabyCurvePoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyCurvePoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyCurvePoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyCurvePoint value)  $default,){
final _that = this;
switch (_that) {
case _BabyCurvePoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyCurvePoint value)?  $default,){
final _that = this;
switch (_that) {
case _BabyCurvePoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime measureDate,  int ageMonths,  double xValue,  double measured,  String? percentileBand)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyCurvePoint() when $default != null:
return $default(_that.measureDate,_that.ageMonths,_that.xValue,_that.measured,_that.percentileBand);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime measureDate,  int ageMonths,  double xValue,  double measured,  String? percentileBand)  $default,) {final _that = this;
switch (_that) {
case _BabyCurvePoint():
return $default(_that.measureDate,_that.ageMonths,_that.xValue,_that.measured,_that.percentileBand);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime measureDate,  int ageMonths,  double xValue,  double measured,  String? percentileBand)?  $default,) {final _that = this;
switch (_that) {
case _BabyCurvePoint() when $default != null:
return $default(_that.measureDate,_that.ageMonths,_that.xValue,_that.measured,_that.percentileBand);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyCurvePoint implements BabyCurvePoint {
  const _BabyCurvePoint({required this.measureDate, required this.ageMonths, required this.xValue, required this.measured, this.percentileBand});
  factory _BabyCurvePoint.fromJson(Map<String, dynamic> json) => _$BabyCurvePointFromJson(json);

@override final  DateTime measureDate;
@override final  int ageMonths;
@override final  double xValue;
@override final  double measured;
@override final  String? percentileBand;

/// Create a copy of BabyCurvePoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyCurvePointCopyWith<_BabyCurvePoint> get copyWith => __$BabyCurvePointCopyWithImpl<_BabyCurvePoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyCurvePointToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyCurvePoint&&(identical(other.measureDate, measureDate) || other.measureDate == measureDate)&&(identical(other.ageMonths, ageMonths) || other.ageMonths == ageMonths)&&(identical(other.xValue, xValue) || other.xValue == xValue)&&(identical(other.measured, measured) || other.measured == measured)&&(identical(other.percentileBand, percentileBand) || other.percentileBand == percentileBand));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,measureDate,ageMonths,xValue,measured,percentileBand);
}

@override
String toString() {
    return 'BabyCurvePoint(measureDate: $measureDate, ageMonths: $ageMonths, xValue: $xValue, measured: $measured, percentileBand: $percentileBand)';
}


}

/// @nodoc
abstract mixin class _$BabyCurvePointCopyWith<$Res> implements $BabyCurvePointCopyWith<$Res> {
  factory _$BabyCurvePointCopyWith(_BabyCurvePoint value, $Res Function(_BabyCurvePoint) _then) = __$BabyCurvePointCopyWithImpl;
@override @useResult
$Res call({
 DateTime measureDate, int ageMonths, double xValue, double measured, String? percentileBand
});




}
/// @nodoc
class __$BabyCurvePointCopyWithImpl<$Res>
    implements _$BabyCurvePointCopyWith<$Res> {
  __$BabyCurvePointCopyWithImpl(this._self, this._then);

  final _BabyCurvePoint _self;
  final $Res Function(_BabyCurvePoint) _then;

/// Create a copy of BabyCurvePoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? measureDate = null,Object? ageMonths = null,Object? xValue = null,Object? measured = null,Object? percentileBand = freezed,}) {
  return _then(_BabyCurvePoint(
measureDate: null == measureDate ? _self.measureDate : measureDate // ignore: cast_nullable_to_non_nullable
as DateTime,ageMonths: null == ageMonths ? _self.ageMonths : ageMonths // ignore: cast_nullable_to_non_nullable
as int,xValue: null == xValue ? _self.xValue : xValue // ignore: cast_nullable_to_non_nullable
as double,measured: null == measured ? _self.measured : measured // ignore: cast_nullable_to_non_nullable
as double,percentileBand: freezed == percentileBand ? _self.percentileBand : percentileBand // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$GrowthStandardRow {

 double get xValue; double get p3; double get p10; double get p25; double get p50; double get p75; double get p90; double get p97;
/// Create a copy of GrowthStandardRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrowthStandardRowCopyWith<GrowthStandardRow> get copyWith => _$GrowthStandardRowCopyWithImpl<GrowthStandardRow>(this as GrowthStandardRow, _$identity);

  /// Serializes this GrowthStandardRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GrowthStandardRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrowthStandardRow&&(identical(other.xValue, _this.xValue) || other.xValue == _this.xValue)&&(identical(other.p3, _this.p3) || other.p3 == _this.p3)&&(identical(other.p10, _this.p10) || other.p10 == _this.p10)&&(identical(other.p25, _this.p25) || other.p25 == _this.p25)&&(identical(other.p50, _this.p50) || other.p50 == _this.p50)&&(identical(other.p75, _this.p75) || other.p75 == _this.p75)&&(identical(other.p90, _this.p90) || other.p90 == _this.p90)&&(identical(other.p97, _this.p97) || other.p97 == _this.p97));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GrowthStandardRow;
  return Object.hash(runtimeType,_this.xValue,_this.p3,_this.p10,_this.p25,_this.p50,_this.p75,_this.p90,_this.p97);
}

@override
String toString() {
  final _this = this as GrowthStandardRow;
  return 'GrowthStandardRow(xValue: ${_this.xValue}, p3: ${_this.p3}, p10: ${_this.p10}, p25: ${_this.p25}, p50: ${_this.p50}, p75: ${_this.p75}, p90: ${_this.p90}, p97: ${_this.p97})';
}


}

/// @nodoc
abstract mixin class $GrowthStandardRowCopyWith<$Res>  {
  factory $GrowthStandardRowCopyWith(GrowthStandardRow value, $Res Function(GrowthStandardRow) _then) = _$GrowthStandardRowCopyWithImpl;
@useResult
$Res call({
 double xValue, double p3, double p10, double p25, double p50, double p75, double p90, double p97
});




}
/// @nodoc
class _$GrowthStandardRowCopyWithImpl<$Res>
    implements $GrowthStandardRowCopyWith<$Res> {
  _$GrowthStandardRowCopyWithImpl(this._self, this._then);

  final GrowthStandardRow _self;
  final $Res Function(GrowthStandardRow) _then;

/// Create a copy of GrowthStandardRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? xValue = null,Object? p3 = null,Object? p10 = null,Object? p25 = null,Object? p50 = null,Object? p75 = null,Object? p90 = null,Object? p97 = null,}) {
  return _then(GrowthStandardRow(
xValue: null == xValue ? _self.xValue : xValue // ignore: cast_nullable_to_non_nullable
as double,p3: null == p3 ? _self.p3 : p3 // ignore: cast_nullable_to_non_nullable
as double,p10: null == p10 ? _self.p10 : p10 // ignore: cast_nullable_to_non_nullable
as double,p25: null == p25 ? _self.p25 : p25 // ignore: cast_nullable_to_non_nullable
as double,p50: null == p50 ? _self.p50 : p50 // ignore: cast_nullable_to_non_nullable
as double,p75: null == p75 ? _self.p75 : p75 // ignore: cast_nullable_to_non_nullable
as double,p90: null == p90 ? _self.p90 : p90 // ignore: cast_nullable_to_non_nullable
as double,p97: null == p97 ? _self.p97 : p97 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [GrowthStandardRow].
extension GrowthStandardRowPatterns on GrowthStandardRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GrowthStandardRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GrowthStandardRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GrowthStandardRow value)  $default,){
final _that = this;
switch (_that) {
case _GrowthStandardRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GrowthStandardRow value)?  $default,){
final _that = this;
switch (_that) {
case _GrowthStandardRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double xValue,  double p3,  double p10,  double p25,  double p50,  double p75,  double p90,  double p97)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GrowthStandardRow() when $default != null:
return $default(_that.xValue,_that.p3,_that.p10,_that.p25,_that.p50,_that.p75,_that.p90,_that.p97);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double xValue,  double p3,  double p10,  double p25,  double p50,  double p75,  double p90,  double p97)  $default,) {final _that = this;
switch (_that) {
case _GrowthStandardRow():
return $default(_that.xValue,_that.p3,_that.p10,_that.p25,_that.p50,_that.p75,_that.p90,_that.p97);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double xValue,  double p3,  double p10,  double p25,  double p50,  double p75,  double p90,  double p97)?  $default,) {final _that = this;
switch (_that) {
case _GrowthStandardRow() when $default != null:
return $default(_that.xValue,_that.p3,_that.p10,_that.p25,_that.p50,_that.p75,_that.p90,_that.p97);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GrowthStandardRow implements GrowthStandardRow {
  const _GrowthStandardRow({required this.xValue, required this.p3, required this.p10, required this.p25, required this.p50, required this.p75, required this.p90, required this.p97});
  factory _GrowthStandardRow.fromJson(Map<String, dynamic> json) => _$GrowthStandardRowFromJson(json);

@override final  double xValue;
@override final  double p3;
@override final  double p10;
@override final  double p25;
@override final  double p50;
@override final  double p75;
@override final  double p90;
@override final  double p97;

/// Create a copy of GrowthStandardRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GrowthStandardRowCopyWith<_GrowthStandardRow> get copyWith => __$GrowthStandardRowCopyWithImpl<_GrowthStandardRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GrowthStandardRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GrowthStandardRow&&(identical(other.xValue, xValue) || other.xValue == xValue)&&(identical(other.p3, p3) || other.p3 == p3)&&(identical(other.p10, p10) || other.p10 == p10)&&(identical(other.p25, p25) || other.p25 == p25)&&(identical(other.p50, p50) || other.p50 == p50)&&(identical(other.p75, p75) || other.p75 == p75)&&(identical(other.p90, p90) || other.p90 == p90)&&(identical(other.p97, p97) || other.p97 == p97));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,xValue,p3,p10,p25,p50,p75,p90,p97);
}

@override
String toString() {
    return 'GrowthStandardRow(xValue: $xValue, p3: $p3, p10: $p10, p25: $p25, p50: $p50, p75: $p75, p90: $p90, p97: $p97)';
}


}

/// @nodoc
abstract mixin class _$GrowthStandardRowCopyWith<$Res> implements $GrowthStandardRowCopyWith<$Res> {
  factory _$GrowthStandardRowCopyWith(_GrowthStandardRow value, $Res Function(_GrowthStandardRow) _then) = __$GrowthStandardRowCopyWithImpl;
@override @useResult
$Res call({
 double xValue, double p3, double p10, double p25, double p50, double p75, double p90, double p97
});




}
/// @nodoc
class __$GrowthStandardRowCopyWithImpl<$Res>
    implements _$GrowthStandardRowCopyWith<$Res> {
  __$GrowthStandardRowCopyWithImpl(this._self, this._then);

  final _GrowthStandardRow _self;
  final $Res Function(_GrowthStandardRow) _then;

/// Create a copy of GrowthStandardRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? xValue = null,Object? p3 = null,Object? p10 = null,Object? p25 = null,Object? p50 = null,Object? p75 = null,Object? p90 = null,Object? p97 = null,}) {
  return _then(_GrowthStandardRow(
xValue: null == xValue ? _self.xValue : xValue // ignore: cast_nullable_to_non_nullable
as double,p3: null == p3 ? _self.p3 : p3 // ignore: cast_nullable_to_non_nullable
as double,p10: null == p10 ? _self.p10 : p10 // ignore: cast_nullable_to_non_nullable
as double,p25: null == p25 ? _self.p25 : p25 // ignore: cast_nullable_to_non_nullable
as double,p50: null == p50 ? _self.p50 : p50 // ignore: cast_nullable_to_non_nullable
as double,p75: null == p75 ? _self.p75 : p75 // ignore: cast_nullable_to_non_nullable
as double,p90: null == p90 ? _self.p90 : p90 // ignore: cast_nullable_to_non_nullable
as double,p97: null == p97 ? _self.p97 : p97 // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
