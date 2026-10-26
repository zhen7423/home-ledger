// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cat_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatFoodStatisticsQuery {

 String? get startDate; String? get endDate;
/// Create a copy of CatFoodStatisticsQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatFoodStatisticsQueryCopyWith<CatFoodStatisticsQuery> get copyWith => _$CatFoodStatisticsQueryCopyWithImpl<CatFoodStatisticsQuery>(this as CatFoodStatisticsQuery, _$identity);

  /// Serializes this CatFoodStatisticsQuery to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatFoodStatisticsQuery;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatFoodStatisticsQuery&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatFoodStatisticsQuery;
  return Object.hash(runtimeType,_this.startDate,_this.endDate);
}

@override
String toString() {
  final _this = this as CatFoodStatisticsQuery;
  return 'CatFoodStatisticsQuery(startDate: ${_this.startDate}, endDate: ${_this.endDate})';
}


}

/// @nodoc
abstract mixin class $CatFoodStatisticsQueryCopyWith<$Res>  {
  factory $CatFoodStatisticsQueryCopyWith(CatFoodStatisticsQuery value, $Res Function(CatFoodStatisticsQuery) _then) = _$CatFoodStatisticsQueryCopyWithImpl;
@useResult
$Res call({
 String? startDate, String? endDate
});




}
/// @nodoc
class _$CatFoodStatisticsQueryCopyWithImpl<$Res>
    implements $CatFoodStatisticsQueryCopyWith<$Res> {
  _$CatFoodStatisticsQueryCopyWithImpl(this._self, this._then);

  final CatFoodStatisticsQuery _self;
  final $Res Function(CatFoodStatisticsQuery) _then;

/// Create a copy of CatFoodStatisticsQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = freezed,Object? endDate = freezed,}) {
  return _then(CatFoodStatisticsQuery(
startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatFoodStatisticsQuery].
extension CatFoodStatisticsQueryPatterns on CatFoodStatisticsQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatFoodStatisticsQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatFoodStatisticsQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatFoodStatisticsQuery value)  $default,){
final _that = this;
switch (_that) {
case _CatFoodStatisticsQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatFoodStatisticsQuery value)?  $default,){
final _that = this;
switch (_that) {
case _CatFoodStatisticsQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? startDate,  String? endDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatFoodStatisticsQuery() when $default != null:
return $default(_that.startDate,_that.endDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? startDate,  String? endDate)  $default,) {final _that = this;
switch (_that) {
case _CatFoodStatisticsQuery():
return $default(_that.startDate,_that.endDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? startDate,  String? endDate)?  $default,) {final _that = this;
switch (_that) {
case _CatFoodStatisticsQuery() when $default != null:
return $default(_that.startDate,_that.endDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatFoodStatisticsQuery extends CatFoodStatisticsQuery {
  const _CatFoodStatisticsQuery({this.startDate, this.endDate}): super._();
  factory _CatFoodStatisticsQuery.fromJson(Map<String, dynamic> json) => _$CatFoodStatisticsQueryFromJson(json);

@override final  String? startDate;
@override final  String? endDate;

/// Create a copy of CatFoodStatisticsQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatFoodStatisticsQueryCopyWith<_CatFoodStatisticsQuery> get copyWith => __$CatFoodStatisticsQueryCopyWithImpl<_CatFoodStatisticsQuery>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatFoodStatisticsQueryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatFoodStatisticsQuery&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startDate,endDate);
}

@override
String toString() {
    return 'CatFoodStatisticsQuery(startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class _$CatFoodStatisticsQueryCopyWith<$Res> implements $CatFoodStatisticsQueryCopyWith<$Res> {
  factory _$CatFoodStatisticsQueryCopyWith(_CatFoodStatisticsQuery value, $Res Function(_CatFoodStatisticsQuery) _then) = __$CatFoodStatisticsQueryCopyWithImpl;
@override @useResult
$Res call({
 String? startDate, String? endDate
});




}
/// @nodoc
class __$CatFoodStatisticsQueryCopyWithImpl<$Res>
    implements _$CatFoodStatisticsQueryCopyWith<$Res> {
  __$CatFoodStatisticsQueryCopyWithImpl(this._self, this._then);

  final _CatFoodStatisticsQuery _self;
  final $Res Function(_CatFoodStatisticsQuery) _then;

/// Create a copy of CatFoodStatisticsQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = freezed,Object? endDate = freezed,}) {
  return _then(_CatFoodStatisticsQuery(
startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CatFoodConsumption {

 DateTime get startDate; DateTime get endDate; int get days; int get totalGrams; int get dailyAverage; int get finishedBags; List<CatBrandSlice> get brandBreakdown; List<CatMonthGrams> get monthlyTrend; List<CatFoodBag> get bagUsages;
/// Create a copy of CatFoodConsumption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatFoodConsumptionCopyWith<CatFoodConsumption> get copyWith => _$CatFoodConsumptionCopyWithImpl<CatFoodConsumption>(this as CatFoodConsumption, _$identity);

  /// Serializes this CatFoodConsumption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatFoodConsumption;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatFoodConsumption&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.days, _this.days) || other.days == _this.days)&&(identical(other.totalGrams, _this.totalGrams) || other.totalGrams == _this.totalGrams)&&(identical(other.dailyAverage, _this.dailyAverage) || other.dailyAverage == _this.dailyAverage)&&(identical(other.finishedBags, _this.finishedBags) || other.finishedBags == _this.finishedBags)&&const DeepCollectionEquality().equals(other.brandBreakdown, _this.brandBreakdown)&&const DeepCollectionEquality().equals(other.monthlyTrend, _this.monthlyTrend)&&const DeepCollectionEquality().equals(other.bagUsages, _this.bagUsages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatFoodConsumption;
  return Object.hash(runtimeType,_this.startDate,_this.endDate,_this.days,_this.totalGrams,_this.dailyAverage,_this.finishedBags,const DeepCollectionEquality().hash(_this.brandBreakdown),const DeepCollectionEquality().hash(_this.monthlyTrend),const DeepCollectionEquality().hash(_this.bagUsages));
}

@override
String toString() {
  final _this = this as CatFoodConsumption;
  return 'CatFoodConsumption(startDate: ${_this.startDate}, endDate: ${_this.endDate}, days: ${_this.days}, totalGrams: ${_this.totalGrams}, dailyAverage: ${_this.dailyAverage}, finishedBags: ${_this.finishedBags}, brandBreakdown: ${_this.brandBreakdown}, monthlyTrend: ${_this.monthlyTrend}, bagUsages: ${_this.bagUsages})';
}


}

/// @nodoc
abstract mixin class $CatFoodConsumptionCopyWith<$Res>  {
  factory $CatFoodConsumptionCopyWith(CatFoodConsumption value, $Res Function(CatFoodConsumption) _then) = _$CatFoodConsumptionCopyWithImpl;
@useResult
$Res call({
 DateTime startDate, DateTime endDate, int days, int totalGrams, int dailyAverage, int finishedBags, List<CatBrandSlice> brandBreakdown, List<CatMonthGrams> monthlyTrend, List<CatFoodBag> bagUsages
});




}
/// @nodoc
class _$CatFoodConsumptionCopyWithImpl<$Res>
    implements $CatFoodConsumptionCopyWith<$Res> {
  _$CatFoodConsumptionCopyWithImpl(this._self, this._then);

  final CatFoodConsumption _self;
  final $Res Function(CatFoodConsumption) _then;

/// Create a copy of CatFoodConsumption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = null,Object? endDate = null,Object? days = null,Object? totalGrams = null,Object? dailyAverage = null,Object? finishedBags = null,Object? brandBreakdown = null,Object? monthlyTrend = null,Object? bagUsages = null,}) {
  return _then(CatFoodConsumption(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,totalGrams: null == totalGrams ? _self.totalGrams : totalGrams // ignore: cast_nullable_to_non_nullable
as int,dailyAverage: null == dailyAverage ? _self.dailyAverage : dailyAverage // ignore: cast_nullable_to_non_nullable
as int,finishedBags: null == finishedBags ? _self.finishedBags : finishedBags // ignore: cast_nullable_to_non_nullable
as int,brandBreakdown: null == brandBreakdown ? _self.brandBreakdown : brandBreakdown // ignore: cast_nullable_to_non_nullable
as List<CatBrandSlice>,monthlyTrend: null == monthlyTrend ? _self.monthlyTrend : monthlyTrend // ignore: cast_nullable_to_non_nullable
as List<CatMonthGrams>,bagUsages: null == bagUsages ? _self.bagUsages : bagUsages // ignore: cast_nullable_to_non_nullable
as List<CatFoodBag>,
  ));
}

}


/// Adds pattern-matching-related methods to [CatFoodConsumption].
extension CatFoodConsumptionPatterns on CatFoodConsumption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatFoodConsumption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatFoodConsumption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatFoodConsumption value)  $default,){
final _that = this;
switch (_that) {
case _CatFoodConsumption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatFoodConsumption value)?  $default,){
final _that = this;
switch (_that) {
case _CatFoodConsumption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime startDate,  DateTime endDate,  int days,  int totalGrams,  int dailyAverage,  int finishedBags,  List<CatBrandSlice> brandBreakdown,  List<CatMonthGrams> monthlyTrend,  List<CatFoodBag> bagUsages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatFoodConsumption() when $default != null:
return $default(_that.startDate,_that.endDate,_that.days,_that.totalGrams,_that.dailyAverage,_that.finishedBags,_that.brandBreakdown,_that.monthlyTrend,_that.bagUsages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime startDate,  DateTime endDate,  int days,  int totalGrams,  int dailyAverage,  int finishedBags,  List<CatBrandSlice> brandBreakdown,  List<CatMonthGrams> monthlyTrend,  List<CatFoodBag> bagUsages)  $default,) {final _that = this;
switch (_that) {
case _CatFoodConsumption():
return $default(_that.startDate,_that.endDate,_that.days,_that.totalGrams,_that.dailyAverage,_that.finishedBags,_that.brandBreakdown,_that.monthlyTrend,_that.bagUsages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime startDate,  DateTime endDate,  int days,  int totalGrams,  int dailyAverage,  int finishedBags,  List<CatBrandSlice> brandBreakdown,  List<CatMonthGrams> monthlyTrend,  List<CatFoodBag> bagUsages)?  $default,) {final _that = this;
switch (_that) {
case _CatFoodConsumption() when $default != null:
return $default(_that.startDate,_that.endDate,_that.days,_that.totalGrams,_that.dailyAverage,_that.finishedBags,_that.brandBreakdown,_that.monthlyTrend,_that.bagUsages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatFoodConsumption implements CatFoodConsumption {
  const _CatFoodConsumption({required this.startDate, required this.endDate, required this.days, required this.totalGrams, required this.dailyAverage, required this.finishedBags,  List<CatBrandSlice> brandBreakdown = const <CatBrandSlice>[],  List<CatMonthGrams> monthlyTrend = const <CatMonthGrams>[],  List<CatFoodBag> bagUsages = const <CatFoodBag>[]}): _brandBreakdown = brandBreakdown,_monthlyTrend = monthlyTrend,_bagUsages = bagUsages;
  factory _CatFoodConsumption.fromJson(Map<String, dynamic> json) => _$CatFoodConsumptionFromJson(json);

@override final  DateTime startDate;
@override final  DateTime endDate;
@override final  int days;
@override final  int totalGrams;
@override final  int dailyAverage;
@override final  int finishedBags;
 final  List<CatBrandSlice> _brandBreakdown;
@override@JsonKey() List<CatBrandSlice> get brandBreakdown {
  if (_brandBreakdown is EqualUnmodifiableListView) return _brandBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_brandBreakdown);
}

 final  List<CatMonthGrams> _monthlyTrend;
@override@JsonKey() List<CatMonthGrams> get monthlyTrend {
  if (_monthlyTrend is EqualUnmodifiableListView) return _monthlyTrend;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_monthlyTrend);
}

 final  List<CatFoodBag> _bagUsages;
@override@JsonKey() List<CatFoodBag> get bagUsages {
  if (_bagUsages is EqualUnmodifiableListView) return _bagUsages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bagUsages);
}


/// Create a copy of CatFoodConsumption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatFoodConsumptionCopyWith<_CatFoodConsumption> get copyWith => __$CatFoodConsumptionCopyWithImpl<_CatFoodConsumption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatFoodConsumptionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatFoodConsumption&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.days, days) || other.days == days)&&(identical(other.totalGrams, totalGrams) || other.totalGrams == totalGrams)&&(identical(other.dailyAverage, dailyAverage) || other.dailyAverage == dailyAverage)&&(identical(other.finishedBags, finishedBags) || other.finishedBags == finishedBags)&&const DeepCollectionEquality().equals(other.brandBreakdown, _brandBreakdown)&&const DeepCollectionEquality().equals(other.monthlyTrend, _monthlyTrend)&&const DeepCollectionEquality().equals(other.bagUsages, _bagUsages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startDate,endDate,days,totalGrams,dailyAverage,finishedBags,const DeepCollectionEquality().hash(_brandBreakdown),const DeepCollectionEquality().hash(_monthlyTrend),const DeepCollectionEquality().hash(_bagUsages));
}

@override
String toString() {
    return 'CatFoodConsumption(startDate: $startDate, endDate: $endDate, days: $days, totalGrams: $totalGrams, dailyAverage: $dailyAverage, finishedBags: $finishedBags, brandBreakdown: $brandBreakdown, monthlyTrend: $monthlyTrend, bagUsages: $bagUsages)';
}


}

/// @nodoc
abstract mixin class _$CatFoodConsumptionCopyWith<$Res> implements $CatFoodConsumptionCopyWith<$Res> {
  factory _$CatFoodConsumptionCopyWith(_CatFoodConsumption value, $Res Function(_CatFoodConsumption) _then) = __$CatFoodConsumptionCopyWithImpl;
@override @useResult
$Res call({
 DateTime startDate, DateTime endDate, int days, int totalGrams, int dailyAverage, int finishedBags, List<CatBrandSlice> brandBreakdown, List<CatMonthGrams> monthlyTrend, List<CatFoodBag> bagUsages
});




}
/// @nodoc
class __$CatFoodConsumptionCopyWithImpl<$Res>
    implements _$CatFoodConsumptionCopyWith<$Res> {
  __$CatFoodConsumptionCopyWithImpl(this._self, this._then);

  final _CatFoodConsumption _self;
  final $Res Function(_CatFoodConsumption) _then;

/// Create a copy of CatFoodConsumption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = null,Object? endDate = null,Object? days = null,Object? totalGrams = null,Object? dailyAverage = null,Object? finishedBags = null,Object? brandBreakdown = null,Object? monthlyTrend = null,Object? bagUsages = null,}) {
  return _then(_CatFoodConsumption(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,totalGrams: null == totalGrams ? _self.totalGrams : totalGrams // ignore: cast_nullable_to_non_nullable
as int,dailyAverage: null == dailyAverage ? _self.dailyAverage : dailyAverage // ignore: cast_nullable_to_non_nullable
as int,finishedBags: null == finishedBags ? _self.finishedBags : finishedBags // ignore: cast_nullable_to_non_nullable
as int,brandBreakdown: null == brandBreakdown ? _self._brandBreakdown : brandBreakdown // ignore: cast_nullable_to_non_nullable
as List<CatBrandSlice>,monthlyTrend: null == monthlyTrend ? _self._monthlyTrend : monthlyTrend // ignore: cast_nullable_to_non_nullable
as List<CatMonthGrams>,bagUsages: null == bagUsages ? _self._bagUsages : bagUsages // ignore: cast_nullable_to_non_nullable
as List<CatFoodBag>,
  ));
}


}


/// @nodoc
mixin _$CatBrandSlice {

 String get brand; int get grams; int get percent;
/// Create a copy of CatBrandSlice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatBrandSliceCopyWith<CatBrandSlice> get copyWith => _$CatBrandSliceCopyWithImpl<CatBrandSlice>(this as CatBrandSlice, _$identity);

  /// Serializes this CatBrandSlice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatBrandSlice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatBrandSlice&&(identical(other.brand, _this.brand) || other.brand == _this.brand)&&(identical(other.grams, _this.grams) || other.grams == _this.grams)&&(identical(other.percent, _this.percent) || other.percent == _this.percent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatBrandSlice;
  return Object.hash(runtimeType,_this.brand,_this.grams,_this.percent);
}

@override
String toString() {
  final _this = this as CatBrandSlice;
  return 'CatBrandSlice(brand: ${_this.brand}, grams: ${_this.grams}, percent: ${_this.percent})';
}


}

/// @nodoc
abstract mixin class $CatBrandSliceCopyWith<$Res>  {
  factory $CatBrandSliceCopyWith(CatBrandSlice value, $Res Function(CatBrandSlice) _then) = _$CatBrandSliceCopyWithImpl;
@useResult
$Res call({
 String brand, int grams, int percent
});




}
/// @nodoc
class _$CatBrandSliceCopyWithImpl<$Res>
    implements $CatBrandSliceCopyWith<$Res> {
  _$CatBrandSliceCopyWithImpl(this._self, this._then);

  final CatBrandSlice _self;
  final $Res Function(CatBrandSlice) _then;

/// Create a copy of CatBrandSlice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? brand = null,Object? grams = null,Object? percent = null,}) {
  return _then(CatBrandSlice(
brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CatBrandSlice].
extension CatBrandSlicePatterns on CatBrandSlice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatBrandSlice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatBrandSlice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatBrandSlice value)  $default,){
final _that = this;
switch (_that) {
case _CatBrandSlice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatBrandSlice value)?  $default,){
final _that = this;
switch (_that) {
case _CatBrandSlice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String brand,  int grams,  int percent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatBrandSlice() when $default != null:
return $default(_that.brand,_that.grams,_that.percent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String brand,  int grams,  int percent)  $default,) {final _that = this;
switch (_that) {
case _CatBrandSlice():
return $default(_that.brand,_that.grams,_that.percent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String brand,  int grams,  int percent)?  $default,) {final _that = this;
switch (_that) {
case _CatBrandSlice() when $default != null:
return $default(_that.brand,_that.grams,_that.percent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatBrandSlice implements CatBrandSlice {
  const _CatBrandSlice({required this.brand, required this.grams, required this.percent});
  factory _CatBrandSlice.fromJson(Map<String, dynamic> json) => _$CatBrandSliceFromJson(json);

@override final  String brand;
@override final  int grams;
@override final  int percent;

/// Create a copy of CatBrandSlice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatBrandSliceCopyWith<_CatBrandSlice> get copyWith => __$CatBrandSliceCopyWithImpl<_CatBrandSlice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatBrandSliceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatBrandSlice&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.grams, grams) || other.grams == grams)&&(identical(other.percent, percent) || other.percent == percent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,brand,grams,percent);
}

@override
String toString() {
    return 'CatBrandSlice(brand: $brand, grams: $grams, percent: $percent)';
}


}

/// @nodoc
abstract mixin class _$CatBrandSliceCopyWith<$Res> implements $CatBrandSliceCopyWith<$Res> {
  factory _$CatBrandSliceCopyWith(_CatBrandSlice value, $Res Function(_CatBrandSlice) _then) = __$CatBrandSliceCopyWithImpl;
@override @useResult
$Res call({
 String brand, int grams, int percent
});




}
/// @nodoc
class __$CatBrandSliceCopyWithImpl<$Res>
    implements _$CatBrandSliceCopyWith<$Res> {
  __$CatBrandSliceCopyWithImpl(this._self, this._then);

  final _CatBrandSlice _self;
  final $Res Function(_CatBrandSlice) _then;

/// Create a copy of CatBrandSlice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? brand = null,Object? grams = null,Object? percent = null,}) {
  return _then(_CatBrandSlice(
brand: null == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CatMonthGrams {

 String get month; int get grams;
/// Create a copy of CatMonthGrams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatMonthGramsCopyWith<CatMonthGrams> get copyWith => _$CatMonthGramsCopyWithImpl<CatMonthGrams>(this as CatMonthGrams, _$identity);

  /// Serializes this CatMonthGrams to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatMonthGrams;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatMonthGrams&&(identical(other.month, _this.month) || other.month == _this.month)&&(identical(other.grams, _this.grams) || other.grams == _this.grams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatMonthGrams;
  return Object.hash(runtimeType,_this.month,_this.grams);
}

@override
String toString() {
  final _this = this as CatMonthGrams;
  return 'CatMonthGrams(month: ${_this.month}, grams: ${_this.grams})';
}


}

/// @nodoc
abstract mixin class $CatMonthGramsCopyWith<$Res>  {
  factory $CatMonthGramsCopyWith(CatMonthGrams value, $Res Function(CatMonthGrams) _then) = _$CatMonthGramsCopyWithImpl;
@useResult
$Res call({
 String month, int grams
});




}
/// @nodoc
class _$CatMonthGramsCopyWithImpl<$Res>
    implements $CatMonthGramsCopyWith<$Res> {
  _$CatMonthGramsCopyWithImpl(this._self, this._then);

  final CatMonthGrams _self;
  final $Res Function(CatMonthGrams) _then;

/// Create a copy of CatMonthGrams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? grams = null,}) {
  return _then(CatMonthGrams(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CatMonthGrams].
extension CatMonthGramsPatterns on CatMonthGrams {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatMonthGrams value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatMonthGrams() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatMonthGrams value)  $default,){
final _that = this;
switch (_that) {
case _CatMonthGrams():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatMonthGrams value)?  $default,){
final _that = this;
switch (_that) {
case _CatMonthGrams() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String month,  int grams)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatMonthGrams() when $default != null:
return $default(_that.month,_that.grams);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String month,  int grams)  $default,) {final _that = this;
switch (_that) {
case _CatMonthGrams():
return $default(_that.month,_that.grams);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String month,  int grams)?  $default,) {final _that = this;
switch (_that) {
case _CatMonthGrams() when $default != null:
return $default(_that.month,_that.grams);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatMonthGrams implements CatMonthGrams {
  const _CatMonthGrams({required this.month, required this.grams});
  factory _CatMonthGrams.fromJson(Map<String, dynamic> json) => _$CatMonthGramsFromJson(json);

@override final  String month;
@override final  int grams;

/// Create a copy of CatMonthGrams
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatMonthGramsCopyWith<_CatMonthGrams> get copyWith => __$CatMonthGramsCopyWithImpl<_CatMonthGrams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatMonthGramsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatMonthGrams&&(identical(other.month, month) || other.month == month)&&(identical(other.grams, grams) || other.grams == grams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,month,grams);
}

@override
String toString() {
    return 'CatMonthGrams(month: $month, grams: $grams)';
}


}

/// @nodoc
abstract mixin class _$CatMonthGramsCopyWith<$Res> implements $CatMonthGramsCopyWith<$Res> {
  factory _$CatMonthGramsCopyWith(_CatMonthGrams value, $Res Function(_CatMonthGrams) _then) = __$CatMonthGramsCopyWithImpl;
@override @useResult
$Res call({
 String month, int grams
});




}
/// @nodoc
class __$CatMonthGramsCopyWithImpl<$Res>
    implements _$CatMonthGramsCopyWith<$Res> {
  __$CatMonthGramsCopyWithImpl(this._self, this._then);

  final _CatMonthGrams _self;
  final $Res Function(_CatMonthGrams) _then;

/// Create a copy of CatMonthGrams
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? grams = null,}) {
  return _then(_CatMonthGrams(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CatDewormingStatistics {

 DateTime get windowStart; DateTime get windowEnd; List<CatDewormingCompletion> get completion; List<CatDewormingTimelineItem> get timeline; List<CatDueCountdownItem> get dueCountdown;
/// Create a copy of CatDewormingStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatDewormingStatisticsCopyWith<CatDewormingStatistics> get copyWith => _$CatDewormingStatisticsCopyWithImpl<CatDewormingStatistics>(this as CatDewormingStatistics, _$identity);

  /// Serializes this CatDewormingStatistics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatDewormingStatistics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatDewormingStatistics&&(identical(other.windowStart, _this.windowStart) || other.windowStart == _this.windowStart)&&(identical(other.windowEnd, _this.windowEnd) || other.windowEnd == _this.windowEnd)&&const DeepCollectionEquality().equals(other.completion, _this.completion)&&const DeepCollectionEquality().equals(other.timeline, _this.timeline)&&const DeepCollectionEquality().equals(other.dueCountdown, _this.dueCountdown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatDewormingStatistics;
  return Object.hash(runtimeType,_this.windowStart,_this.windowEnd,const DeepCollectionEquality().hash(_this.completion),const DeepCollectionEquality().hash(_this.timeline),const DeepCollectionEquality().hash(_this.dueCountdown));
}

@override
String toString() {
  final _this = this as CatDewormingStatistics;
  return 'CatDewormingStatistics(windowStart: ${_this.windowStart}, windowEnd: ${_this.windowEnd}, completion: ${_this.completion}, timeline: ${_this.timeline}, dueCountdown: ${_this.dueCountdown})';
}


}

/// @nodoc
abstract mixin class $CatDewormingStatisticsCopyWith<$Res>  {
  factory $CatDewormingStatisticsCopyWith(CatDewormingStatistics value, $Res Function(CatDewormingStatistics) _then) = _$CatDewormingStatisticsCopyWithImpl;
@useResult
$Res call({
 DateTime windowStart, DateTime windowEnd, List<CatDewormingCompletion> completion, List<CatDewormingTimelineItem> timeline, List<CatDueCountdownItem> dueCountdown
});




}
/// @nodoc
class _$CatDewormingStatisticsCopyWithImpl<$Res>
    implements $CatDewormingStatisticsCopyWith<$Res> {
  _$CatDewormingStatisticsCopyWithImpl(this._self, this._then);

  final CatDewormingStatistics _self;
  final $Res Function(CatDewormingStatistics) _then;

/// Create a copy of CatDewormingStatistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? windowStart = null,Object? windowEnd = null,Object? completion = null,Object? timeline = null,Object? dueCountdown = null,}) {
  return _then(CatDewormingStatistics(
windowStart: null == windowStart ? _self.windowStart : windowStart // ignore: cast_nullable_to_non_nullable
as DateTime,windowEnd: null == windowEnd ? _self.windowEnd : windowEnd // ignore: cast_nullable_to_non_nullable
as DateTime,completion: null == completion ? _self.completion : completion // ignore: cast_nullable_to_non_nullable
as List<CatDewormingCompletion>,timeline: null == timeline ? _self.timeline : timeline // ignore: cast_nullable_to_non_nullable
as List<CatDewormingTimelineItem>,dueCountdown: null == dueCountdown ? _self.dueCountdown : dueCountdown // ignore: cast_nullable_to_non_nullable
as List<CatDueCountdownItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [CatDewormingStatistics].
extension CatDewormingStatisticsPatterns on CatDewormingStatistics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatDewormingStatistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatDewormingStatistics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatDewormingStatistics value)  $default,){
final _that = this;
switch (_that) {
case _CatDewormingStatistics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatDewormingStatistics value)?  $default,){
final _that = this;
switch (_that) {
case _CatDewormingStatistics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime windowStart,  DateTime windowEnd,  List<CatDewormingCompletion> completion,  List<CatDewormingTimelineItem> timeline,  List<CatDueCountdownItem> dueCountdown)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatDewormingStatistics() when $default != null:
return $default(_that.windowStart,_that.windowEnd,_that.completion,_that.timeline,_that.dueCountdown);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime windowStart,  DateTime windowEnd,  List<CatDewormingCompletion> completion,  List<CatDewormingTimelineItem> timeline,  List<CatDueCountdownItem> dueCountdown)  $default,) {final _that = this;
switch (_that) {
case _CatDewormingStatistics():
return $default(_that.windowStart,_that.windowEnd,_that.completion,_that.timeline,_that.dueCountdown);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime windowStart,  DateTime windowEnd,  List<CatDewormingCompletion> completion,  List<CatDewormingTimelineItem> timeline,  List<CatDueCountdownItem> dueCountdown)?  $default,) {final _that = this;
switch (_that) {
case _CatDewormingStatistics() when $default != null:
return $default(_that.windowStart,_that.windowEnd,_that.completion,_that.timeline,_that.dueCountdown);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatDewormingStatistics implements CatDewormingStatistics {
  const _CatDewormingStatistics({required this.windowStart, required this.windowEnd,  List<CatDewormingCompletion> completion = const <CatDewormingCompletion>[],  List<CatDewormingTimelineItem> timeline = const <CatDewormingTimelineItem>[],  List<CatDueCountdownItem> dueCountdown = const <CatDueCountdownItem>[]}): _completion = completion,_timeline = timeline,_dueCountdown = dueCountdown;
  factory _CatDewormingStatistics.fromJson(Map<String, dynamic> json) => _$CatDewormingStatisticsFromJson(json);

@override final  DateTime windowStart;
@override final  DateTime windowEnd;
 final  List<CatDewormingCompletion> _completion;
@override@JsonKey() List<CatDewormingCompletion> get completion {
  if (_completion is EqualUnmodifiableListView) return _completion;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_completion);
}

 final  List<CatDewormingTimelineItem> _timeline;
@override@JsonKey() List<CatDewormingTimelineItem> get timeline {
  if (_timeline is EqualUnmodifiableListView) return _timeline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_timeline);
}

 final  List<CatDueCountdownItem> _dueCountdown;
@override@JsonKey() List<CatDueCountdownItem> get dueCountdown {
  if (_dueCountdown is EqualUnmodifiableListView) return _dueCountdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dueCountdown);
}


/// Create a copy of CatDewormingStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatDewormingStatisticsCopyWith<_CatDewormingStatistics> get copyWith => __$CatDewormingStatisticsCopyWithImpl<_CatDewormingStatistics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatDewormingStatisticsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatDewormingStatistics&&(identical(other.windowStart, windowStart) || other.windowStart == windowStart)&&(identical(other.windowEnd, windowEnd) || other.windowEnd == windowEnd)&&const DeepCollectionEquality().equals(other.completion, _completion)&&const DeepCollectionEquality().equals(other.timeline, _timeline)&&const DeepCollectionEquality().equals(other.dueCountdown, _dueCountdown));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,windowStart,windowEnd,const DeepCollectionEquality().hash(_completion),const DeepCollectionEquality().hash(_timeline),const DeepCollectionEquality().hash(_dueCountdown));
}

@override
String toString() {
    return 'CatDewormingStatistics(windowStart: $windowStart, windowEnd: $windowEnd, completion: $completion, timeline: $timeline, dueCountdown: $dueCountdown)';
}


}

/// @nodoc
abstract mixin class _$CatDewormingStatisticsCopyWith<$Res> implements $CatDewormingStatisticsCopyWith<$Res> {
  factory _$CatDewormingStatisticsCopyWith(_CatDewormingStatistics value, $Res Function(_CatDewormingStatistics) _then) = __$CatDewormingStatisticsCopyWithImpl;
@override @useResult
$Res call({
 DateTime windowStart, DateTime windowEnd, List<CatDewormingCompletion> completion, List<CatDewormingTimelineItem> timeline, List<CatDueCountdownItem> dueCountdown
});




}
/// @nodoc
class __$CatDewormingStatisticsCopyWithImpl<$Res>
    implements _$CatDewormingStatisticsCopyWith<$Res> {
  __$CatDewormingStatisticsCopyWithImpl(this._self, this._then);

  final _CatDewormingStatistics _self;
  final $Res Function(_CatDewormingStatistics) _then;

/// Create a copy of CatDewormingStatistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? windowStart = null,Object? windowEnd = null,Object? completion = null,Object? timeline = null,Object? dueCountdown = null,}) {
  return _then(_CatDewormingStatistics(
windowStart: null == windowStart ? _self.windowStart : windowStart // ignore: cast_nullable_to_non_nullable
as DateTime,windowEnd: null == windowEnd ? _self.windowEnd : windowEnd // ignore: cast_nullable_to_non_nullable
as DateTime,completion: null == completion ? _self._completion : completion // ignore: cast_nullable_to_non_nullable
as List<CatDewormingCompletion>,timeline: null == timeline ? _self._timeline : timeline // ignore: cast_nullable_to_non_nullable
as List<CatDewormingTimelineItem>,dueCountdown: null == dueCountdown ? _self._dueCountdown : dueCountdown // ignore: cast_nullable_to_non_nullable
as List<CatDueCountdownItem>,
  ));
}


}


/// @nodoc
mixin _$CatDewormingCompletion {

 int get catId; String get catName; String get type; int get due; int get done; int get rate; int? get overdueDays;
/// Create a copy of CatDewormingCompletion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatDewormingCompletionCopyWith<CatDewormingCompletion> get copyWith => _$CatDewormingCompletionCopyWithImpl<CatDewormingCompletion>(this as CatDewormingCompletion, _$identity);

  /// Serializes this CatDewormingCompletion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatDewormingCompletion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatDewormingCompletion&&(identical(other.catId, _this.catId) || other.catId == _this.catId)&&(identical(other.catName, _this.catName) || other.catName == _this.catName)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.due, _this.due) || other.due == _this.due)&&(identical(other.done, _this.done) || other.done == _this.done)&&(identical(other.rate, _this.rate) || other.rate == _this.rate)&&(identical(other.overdueDays, _this.overdueDays) || other.overdueDays == _this.overdueDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatDewormingCompletion;
  return Object.hash(runtimeType,_this.catId,_this.catName,_this.type,_this.due,_this.done,_this.rate,_this.overdueDays);
}

@override
String toString() {
  final _this = this as CatDewormingCompletion;
  return 'CatDewormingCompletion(catId: ${_this.catId}, catName: ${_this.catName}, type: ${_this.type}, due: ${_this.due}, done: ${_this.done}, rate: ${_this.rate}, overdueDays: ${_this.overdueDays})';
}


}

/// @nodoc
abstract mixin class $CatDewormingCompletionCopyWith<$Res>  {
  factory $CatDewormingCompletionCopyWith(CatDewormingCompletion value, $Res Function(CatDewormingCompletion) _then) = _$CatDewormingCompletionCopyWithImpl;
@useResult
$Res call({
 int catId, String catName, String type, int due, int done, int rate, int? overdueDays
});




}
/// @nodoc
class _$CatDewormingCompletionCopyWithImpl<$Res>
    implements $CatDewormingCompletionCopyWith<$Res> {
  _$CatDewormingCompletionCopyWithImpl(this._self, this._then);

  final CatDewormingCompletion _self;
  final $Res Function(CatDewormingCompletion) _then;

/// Create a copy of CatDewormingCompletion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catId = null,Object? catName = null,Object? type = null,Object? due = null,Object? done = null,Object? rate = null,Object? overdueDays = freezed,}) {
  return _then(CatDewormingCompletion(
catId: null == catId ? _self.catId : catId // ignore: cast_nullable_to_non_nullable
as int,catName: null == catName ? _self.catName : catName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,due: null == due ? _self.due : due // ignore: cast_nullable_to_non_nullable
as int,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as int,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as int,overdueDays: freezed == overdueDays ? _self.overdueDays : overdueDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatDewormingCompletion].
extension CatDewormingCompletionPatterns on CatDewormingCompletion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatDewormingCompletion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatDewormingCompletion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatDewormingCompletion value)  $default,){
final _that = this;
switch (_that) {
case _CatDewormingCompletion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatDewormingCompletion value)?  $default,){
final _that = this;
switch (_that) {
case _CatDewormingCompletion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int catId,  String catName,  String type,  int due,  int done,  int rate,  int? overdueDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatDewormingCompletion() when $default != null:
return $default(_that.catId,_that.catName,_that.type,_that.due,_that.done,_that.rate,_that.overdueDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int catId,  String catName,  String type,  int due,  int done,  int rate,  int? overdueDays)  $default,) {final _that = this;
switch (_that) {
case _CatDewormingCompletion():
return $default(_that.catId,_that.catName,_that.type,_that.due,_that.done,_that.rate,_that.overdueDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int catId,  String catName,  String type,  int due,  int done,  int rate,  int? overdueDays)?  $default,) {final _that = this;
switch (_that) {
case _CatDewormingCompletion() when $default != null:
return $default(_that.catId,_that.catName,_that.type,_that.due,_that.done,_that.rate,_that.overdueDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatDewormingCompletion implements CatDewormingCompletion {
  const _CatDewormingCompletion({required this.catId, required this.catName, required this.type, required this.due, required this.done, required this.rate, this.overdueDays});
  factory _CatDewormingCompletion.fromJson(Map<String, dynamic> json) => _$CatDewormingCompletionFromJson(json);

@override final  int catId;
@override final  String catName;
@override final  String type;
@override final  int due;
@override final  int done;
@override final  int rate;
@override final  int? overdueDays;

/// Create a copy of CatDewormingCompletion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatDewormingCompletionCopyWith<_CatDewormingCompletion> get copyWith => __$CatDewormingCompletionCopyWithImpl<_CatDewormingCompletion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatDewormingCompletionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatDewormingCompletion&&(identical(other.catId, catId) || other.catId == catId)&&(identical(other.catName, catName) || other.catName == catName)&&(identical(other.type, type) || other.type == type)&&(identical(other.due, due) || other.due == due)&&(identical(other.done, done) || other.done == done)&&(identical(other.rate, rate) || other.rate == rate)&&(identical(other.overdueDays, overdueDays) || other.overdueDays == overdueDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,catId,catName,type,due,done,rate,overdueDays);
}

@override
String toString() {
    return 'CatDewormingCompletion(catId: $catId, catName: $catName, type: $type, due: $due, done: $done, rate: $rate, overdueDays: $overdueDays)';
}


}

/// @nodoc
abstract mixin class _$CatDewormingCompletionCopyWith<$Res> implements $CatDewormingCompletionCopyWith<$Res> {
  factory _$CatDewormingCompletionCopyWith(_CatDewormingCompletion value, $Res Function(_CatDewormingCompletion) _then) = __$CatDewormingCompletionCopyWithImpl;
@override @useResult
$Res call({
 int catId, String catName, String type, int due, int done, int rate, int? overdueDays
});




}
/// @nodoc
class __$CatDewormingCompletionCopyWithImpl<$Res>
    implements _$CatDewormingCompletionCopyWith<$Res> {
  __$CatDewormingCompletionCopyWithImpl(this._self, this._then);

  final _CatDewormingCompletion _self;
  final $Res Function(_CatDewormingCompletion) _then;

/// Create a copy of CatDewormingCompletion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catId = null,Object? catName = null,Object? type = null,Object? due = null,Object? done = null,Object? rate = null,Object? overdueDays = freezed,}) {
  return _then(_CatDewormingCompletion(
catId: null == catId ? _self.catId : catId // ignore: cast_nullable_to_non_nullable
as int,catName: null == catName ? _self.catName : catName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,due: null == due ? _self.due : due // ignore: cast_nullable_to_non_nullable
as int,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as int,rate: null == rate ? _self.rate : rate // ignore: cast_nullable_to_non_nullable
as int,overdueDays: freezed == overdueDays ? _self.overdueDays : overdueDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$CatDewormingTimelineItem {

 int get catId; String get catName; String get type; DateTime get doneDate; String? get medicine;
/// Create a copy of CatDewormingTimelineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatDewormingTimelineItemCopyWith<CatDewormingTimelineItem> get copyWith => _$CatDewormingTimelineItemCopyWithImpl<CatDewormingTimelineItem>(this as CatDewormingTimelineItem, _$identity);

  /// Serializes this CatDewormingTimelineItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatDewormingTimelineItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatDewormingTimelineItem&&(identical(other.catId, _this.catId) || other.catId == _this.catId)&&(identical(other.catName, _this.catName) || other.catName == _this.catName)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.doneDate, _this.doneDate) || other.doneDate == _this.doneDate)&&(identical(other.medicine, _this.medicine) || other.medicine == _this.medicine));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatDewormingTimelineItem;
  return Object.hash(runtimeType,_this.catId,_this.catName,_this.type,_this.doneDate,_this.medicine);
}

@override
String toString() {
  final _this = this as CatDewormingTimelineItem;
  return 'CatDewormingTimelineItem(catId: ${_this.catId}, catName: ${_this.catName}, type: ${_this.type}, doneDate: ${_this.doneDate}, medicine: ${_this.medicine})';
}


}

/// @nodoc
abstract mixin class $CatDewormingTimelineItemCopyWith<$Res>  {
  factory $CatDewormingTimelineItemCopyWith(CatDewormingTimelineItem value, $Res Function(CatDewormingTimelineItem) _then) = _$CatDewormingTimelineItemCopyWithImpl;
@useResult
$Res call({
 int catId, String catName, String type, DateTime doneDate, String? medicine
});




}
/// @nodoc
class _$CatDewormingTimelineItemCopyWithImpl<$Res>
    implements $CatDewormingTimelineItemCopyWith<$Res> {
  _$CatDewormingTimelineItemCopyWithImpl(this._self, this._then);

  final CatDewormingTimelineItem _self;
  final $Res Function(CatDewormingTimelineItem) _then;

/// Create a copy of CatDewormingTimelineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catId = null,Object? catName = null,Object? type = null,Object? doneDate = null,Object? medicine = freezed,}) {
  return _then(CatDewormingTimelineItem(
catId: null == catId ? _self.catId : catId // ignore: cast_nullable_to_non_nullable
as int,catName: null == catName ? _self.catName : catName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,doneDate: null == doneDate ? _self.doneDate : doneDate // ignore: cast_nullable_to_non_nullable
as DateTime,medicine: freezed == medicine ? _self.medicine : medicine // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatDewormingTimelineItem].
extension CatDewormingTimelineItemPatterns on CatDewormingTimelineItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatDewormingTimelineItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatDewormingTimelineItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatDewormingTimelineItem value)  $default,){
final _that = this;
switch (_that) {
case _CatDewormingTimelineItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatDewormingTimelineItem value)?  $default,){
final _that = this;
switch (_that) {
case _CatDewormingTimelineItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int catId,  String catName,  String type,  DateTime doneDate,  String? medicine)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatDewormingTimelineItem() when $default != null:
return $default(_that.catId,_that.catName,_that.type,_that.doneDate,_that.medicine);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int catId,  String catName,  String type,  DateTime doneDate,  String? medicine)  $default,) {final _that = this;
switch (_that) {
case _CatDewormingTimelineItem():
return $default(_that.catId,_that.catName,_that.type,_that.doneDate,_that.medicine);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int catId,  String catName,  String type,  DateTime doneDate,  String? medicine)?  $default,) {final _that = this;
switch (_that) {
case _CatDewormingTimelineItem() when $default != null:
return $default(_that.catId,_that.catName,_that.type,_that.doneDate,_that.medicine);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatDewormingTimelineItem implements CatDewormingTimelineItem {
  const _CatDewormingTimelineItem({required this.catId, required this.catName, required this.type, required this.doneDate, this.medicine});
  factory _CatDewormingTimelineItem.fromJson(Map<String, dynamic> json) => _$CatDewormingTimelineItemFromJson(json);

@override final  int catId;
@override final  String catName;
@override final  String type;
@override final  DateTime doneDate;
@override final  String? medicine;

/// Create a copy of CatDewormingTimelineItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatDewormingTimelineItemCopyWith<_CatDewormingTimelineItem> get copyWith => __$CatDewormingTimelineItemCopyWithImpl<_CatDewormingTimelineItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatDewormingTimelineItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatDewormingTimelineItem&&(identical(other.catId, catId) || other.catId == catId)&&(identical(other.catName, catName) || other.catName == catName)&&(identical(other.type, type) || other.type == type)&&(identical(other.doneDate, doneDate) || other.doneDate == doneDate)&&(identical(other.medicine, medicine) || other.medicine == medicine));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,catId,catName,type,doneDate,medicine);
}

@override
String toString() {
    return 'CatDewormingTimelineItem(catId: $catId, catName: $catName, type: $type, doneDate: $doneDate, medicine: $medicine)';
}


}

/// @nodoc
abstract mixin class _$CatDewormingTimelineItemCopyWith<$Res> implements $CatDewormingTimelineItemCopyWith<$Res> {
  factory _$CatDewormingTimelineItemCopyWith(_CatDewormingTimelineItem value, $Res Function(_CatDewormingTimelineItem) _then) = __$CatDewormingTimelineItemCopyWithImpl;
@override @useResult
$Res call({
 int catId, String catName, String type, DateTime doneDate, String? medicine
});




}
/// @nodoc
class __$CatDewormingTimelineItemCopyWithImpl<$Res>
    implements _$CatDewormingTimelineItemCopyWith<$Res> {
  __$CatDewormingTimelineItemCopyWithImpl(this._self, this._then);

  final _CatDewormingTimelineItem _self;
  final $Res Function(_CatDewormingTimelineItem) _then;

/// Create a copy of CatDewormingTimelineItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catId = null,Object? catName = null,Object? type = null,Object? doneDate = null,Object? medicine = freezed,}) {
  return _then(_CatDewormingTimelineItem(
catId: null == catId ? _self.catId : catId // ignore: cast_nullable_to_non_nullable
as int,catName: null == catName ? _self.catName : catName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,doneDate: null == doneDate ? _self.doneDate : doneDate // ignore: cast_nullable_to_non_nullable
as DateTime,medicine: freezed == medicine ? _self.medicine : medicine // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CatDueCountdownItem {

 int get catId; String get catName; String get type; DateTime get nextDate; int? get daysToDue; int? get overdueDays;
/// Create a copy of CatDueCountdownItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatDueCountdownItemCopyWith<CatDueCountdownItem> get copyWith => _$CatDueCountdownItemCopyWithImpl<CatDueCountdownItem>(this as CatDueCountdownItem, _$identity);

  /// Serializes this CatDueCountdownItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CatDueCountdownItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatDueCountdownItem&&(identical(other.catId, _this.catId) || other.catId == _this.catId)&&(identical(other.catName, _this.catName) || other.catName == _this.catName)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.nextDate, _this.nextDate) || other.nextDate == _this.nextDate)&&(identical(other.daysToDue, _this.daysToDue) || other.daysToDue == _this.daysToDue)&&(identical(other.overdueDays, _this.overdueDays) || other.overdueDays == _this.overdueDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CatDueCountdownItem;
  return Object.hash(runtimeType,_this.catId,_this.catName,_this.type,_this.nextDate,_this.daysToDue,_this.overdueDays);
}

@override
String toString() {
  final _this = this as CatDueCountdownItem;
  return 'CatDueCountdownItem(catId: ${_this.catId}, catName: ${_this.catName}, type: ${_this.type}, nextDate: ${_this.nextDate}, daysToDue: ${_this.daysToDue}, overdueDays: ${_this.overdueDays})';
}


}

/// @nodoc
abstract mixin class $CatDueCountdownItemCopyWith<$Res>  {
  factory $CatDueCountdownItemCopyWith(CatDueCountdownItem value, $Res Function(CatDueCountdownItem) _then) = _$CatDueCountdownItemCopyWithImpl;
@useResult
$Res call({
 int catId, String catName, String type, DateTime nextDate, int? daysToDue, int? overdueDays
});




}
/// @nodoc
class _$CatDueCountdownItemCopyWithImpl<$Res>
    implements $CatDueCountdownItemCopyWith<$Res> {
  _$CatDueCountdownItemCopyWithImpl(this._self, this._then);

  final CatDueCountdownItem _self;
  final $Res Function(CatDueCountdownItem) _then;

/// Create a copy of CatDueCountdownItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catId = null,Object? catName = null,Object? type = null,Object? nextDate = null,Object? daysToDue = freezed,Object? overdueDays = freezed,}) {
  return _then(CatDueCountdownItem(
catId: null == catId ? _self.catId : catId // ignore: cast_nullable_to_non_nullable
as int,catName: null == catName ? _self.catName : catName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,nextDate: null == nextDate ? _self.nextDate : nextDate // ignore: cast_nullable_to_non_nullable
as DateTime,daysToDue: freezed == daysToDue ? _self.daysToDue : daysToDue // ignore: cast_nullable_to_non_nullable
as int?,overdueDays: freezed == overdueDays ? _self.overdueDays : overdueDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatDueCountdownItem].
extension CatDueCountdownItemPatterns on CatDueCountdownItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatDueCountdownItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatDueCountdownItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatDueCountdownItem value)  $default,){
final _that = this;
switch (_that) {
case _CatDueCountdownItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatDueCountdownItem value)?  $default,){
final _that = this;
switch (_that) {
case _CatDueCountdownItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int catId,  String catName,  String type,  DateTime nextDate,  int? daysToDue,  int? overdueDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatDueCountdownItem() when $default != null:
return $default(_that.catId,_that.catName,_that.type,_that.nextDate,_that.daysToDue,_that.overdueDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int catId,  String catName,  String type,  DateTime nextDate,  int? daysToDue,  int? overdueDays)  $default,) {final _that = this;
switch (_that) {
case _CatDueCountdownItem():
return $default(_that.catId,_that.catName,_that.type,_that.nextDate,_that.daysToDue,_that.overdueDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int catId,  String catName,  String type,  DateTime nextDate,  int? daysToDue,  int? overdueDays)?  $default,) {final _that = this;
switch (_that) {
case _CatDueCountdownItem() when $default != null:
return $default(_that.catId,_that.catName,_that.type,_that.nextDate,_that.daysToDue,_that.overdueDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatDueCountdownItem implements CatDueCountdownItem {
  const _CatDueCountdownItem({required this.catId, required this.catName, required this.type, required this.nextDate, this.daysToDue, this.overdueDays});
  factory _CatDueCountdownItem.fromJson(Map<String, dynamic> json) => _$CatDueCountdownItemFromJson(json);

@override final  int catId;
@override final  String catName;
@override final  String type;
@override final  DateTime nextDate;
@override final  int? daysToDue;
@override final  int? overdueDays;

/// Create a copy of CatDueCountdownItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatDueCountdownItemCopyWith<_CatDueCountdownItem> get copyWith => __$CatDueCountdownItemCopyWithImpl<_CatDueCountdownItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatDueCountdownItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatDueCountdownItem&&(identical(other.catId, catId) || other.catId == catId)&&(identical(other.catName, catName) || other.catName == catName)&&(identical(other.type, type) || other.type == type)&&(identical(other.nextDate, nextDate) || other.nextDate == nextDate)&&(identical(other.daysToDue, daysToDue) || other.daysToDue == daysToDue)&&(identical(other.overdueDays, overdueDays) || other.overdueDays == overdueDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,catId,catName,type,nextDate,daysToDue,overdueDays);
}

@override
String toString() {
    return 'CatDueCountdownItem(catId: $catId, catName: $catName, type: $type, nextDate: $nextDate, daysToDue: $daysToDue, overdueDays: $overdueDays)';
}


}

/// @nodoc
abstract mixin class _$CatDueCountdownItemCopyWith<$Res> implements $CatDueCountdownItemCopyWith<$Res> {
  factory _$CatDueCountdownItemCopyWith(_CatDueCountdownItem value, $Res Function(_CatDueCountdownItem) _then) = __$CatDueCountdownItemCopyWithImpl;
@override @useResult
$Res call({
 int catId, String catName, String type, DateTime nextDate, int? daysToDue, int? overdueDays
});




}
/// @nodoc
class __$CatDueCountdownItemCopyWithImpl<$Res>
    implements _$CatDueCountdownItemCopyWith<$Res> {
  __$CatDueCountdownItemCopyWithImpl(this._self, this._then);

  final _CatDueCountdownItem _self;
  final $Res Function(_CatDueCountdownItem) _then;

/// Create a copy of CatDueCountdownItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catId = null,Object? catName = null,Object? type = null,Object? nextDate = null,Object? daysToDue = freezed,Object? overdueDays = freezed,}) {
  return _then(_CatDueCountdownItem(
catId: null == catId ? _self.catId : catId // ignore: cast_nullable_to_non_nullable
as int,catName: null == catName ? _self.catName : catName // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,nextDate: null == nextDate ? _self.nextDate : nextDate // ignore: cast_nullable_to_non_nullable
as DateTime,daysToDue: freezed == daysToDue ? _self.daysToDue : daysToDue // ignore: cast_nullable_to_non_nullable
as int?,overdueDays: freezed == overdueDays ? _self.overdueDays : overdueDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
