// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'baby_formula_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BabyFormulaStatistics {

 int get totalGrams; int get totalDays; int get dailyAverage; List<BabyFormulaMonthGrams> get monthlyTrend;
/// Create a copy of BabyFormulaStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyFormulaStatisticsCopyWith<BabyFormulaStatistics> get copyWith => _$BabyFormulaStatisticsCopyWithImpl<BabyFormulaStatistics>(this as BabyFormulaStatistics, _$identity);

  /// Serializes this BabyFormulaStatistics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyFormulaStatistics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyFormulaStatistics&&(identical(other.totalGrams, _this.totalGrams) || other.totalGrams == _this.totalGrams)&&(identical(other.totalDays, _this.totalDays) || other.totalDays == _this.totalDays)&&(identical(other.dailyAverage, _this.dailyAverage) || other.dailyAverage == _this.dailyAverage)&&const DeepCollectionEquality().equals(other.monthlyTrend, _this.monthlyTrend));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyFormulaStatistics;
  return Object.hash(runtimeType,_this.totalGrams,_this.totalDays,_this.dailyAverage,const DeepCollectionEquality().hash(_this.monthlyTrend));
}

@override
String toString() {
  final _this = this as BabyFormulaStatistics;
  return 'BabyFormulaStatistics(totalGrams: ${_this.totalGrams}, totalDays: ${_this.totalDays}, dailyAverage: ${_this.dailyAverage}, monthlyTrend: ${_this.monthlyTrend})';
}


}

/// @nodoc
abstract mixin class $BabyFormulaStatisticsCopyWith<$Res>  {
  factory $BabyFormulaStatisticsCopyWith(BabyFormulaStatistics value, $Res Function(BabyFormulaStatistics) _then) = _$BabyFormulaStatisticsCopyWithImpl;
@useResult
$Res call({
 int totalGrams, int totalDays, int dailyAverage, List<BabyFormulaMonthGrams> monthlyTrend
});




}
/// @nodoc
class _$BabyFormulaStatisticsCopyWithImpl<$Res>
    implements $BabyFormulaStatisticsCopyWith<$Res> {
  _$BabyFormulaStatisticsCopyWithImpl(this._self, this._then);

  final BabyFormulaStatistics _self;
  final $Res Function(BabyFormulaStatistics) _then;

/// Create a copy of BabyFormulaStatistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalGrams = null,Object? totalDays = null,Object? dailyAverage = null,Object? monthlyTrend = null,}) {
  return _then(BabyFormulaStatistics(
totalGrams: null == totalGrams ? _self.totalGrams : totalGrams // ignore: cast_nullable_to_non_nullable
as int,totalDays: null == totalDays ? _self.totalDays : totalDays // ignore: cast_nullable_to_non_nullable
as int,dailyAverage: null == dailyAverage ? _self.dailyAverage : dailyAverage // ignore: cast_nullable_to_non_nullable
as int,monthlyTrend: null == monthlyTrend ? _self.monthlyTrend : monthlyTrend // ignore: cast_nullable_to_non_nullable
as List<BabyFormulaMonthGrams>,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyFormulaStatistics].
extension BabyFormulaStatisticsPatterns on BabyFormulaStatistics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyFormulaStatistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyFormulaStatistics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyFormulaStatistics value)  $default,){
final _that = this;
switch (_that) {
case _BabyFormulaStatistics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyFormulaStatistics value)?  $default,){
final _that = this;
switch (_that) {
case _BabyFormulaStatistics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalGrams,  int totalDays,  int dailyAverage,  List<BabyFormulaMonthGrams> monthlyTrend)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BabyFormulaStatistics() when $default != null:
return $default(_that.totalGrams,_that.totalDays,_that.dailyAverage,_that.monthlyTrend);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalGrams,  int totalDays,  int dailyAverage,  List<BabyFormulaMonthGrams> monthlyTrend)  $default,) {final _that = this;
switch (_that) {
case _BabyFormulaStatistics():
return $default(_that.totalGrams,_that.totalDays,_that.dailyAverage,_that.monthlyTrend);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalGrams,  int totalDays,  int dailyAverage,  List<BabyFormulaMonthGrams> monthlyTrend)?  $default,) {final _that = this;
switch (_that) {
case _BabyFormulaStatistics() when $default != null:
return $default(_that.totalGrams,_that.totalDays,_that.dailyAverage,_that.monthlyTrend);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyFormulaStatistics implements BabyFormulaStatistics {
  const _BabyFormulaStatistics({required this.totalGrams, required this.totalDays, required this.dailyAverage,  List<BabyFormulaMonthGrams> monthlyTrend = const <BabyFormulaMonthGrams>[]}): _monthlyTrend = monthlyTrend;
  factory _BabyFormulaStatistics.fromJson(Map<String, dynamic> json) => _$BabyFormulaStatisticsFromJson(json);

@override final  int totalGrams;
@override final  int totalDays;
@override final  int dailyAverage;
 final  List<BabyFormulaMonthGrams> _monthlyTrend;
@override@JsonKey() List<BabyFormulaMonthGrams> get monthlyTrend {
  if (_monthlyTrend is EqualUnmodifiableListView) return _monthlyTrend;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_monthlyTrend);
}


/// Create a copy of BabyFormulaStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyFormulaStatisticsCopyWith<_BabyFormulaStatistics> get copyWith => __$BabyFormulaStatisticsCopyWithImpl<_BabyFormulaStatistics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyFormulaStatisticsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyFormulaStatistics&&(identical(other.totalGrams, totalGrams) || other.totalGrams == totalGrams)&&(identical(other.totalDays, totalDays) || other.totalDays == totalDays)&&(identical(other.dailyAverage, dailyAverage) || other.dailyAverage == dailyAverage)&&const DeepCollectionEquality().equals(other.monthlyTrend, _monthlyTrend));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,totalGrams,totalDays,dailyAverage,const DeepCollectionEquality().hash(_monthlyTrend));
}

@override
String toString() {
    return 'BabyFormulaStatistics(totalGrams: $totalGrams, totalDays: $totalDays, dailyAverage: $dailyAverage, monthlyTrend: $monthlyTrend)';
}


}

/// @nodoc
abstract mixin class _$BabyFormulaStatisticsCopyWith<$Res> implements $BabyFormulaStatisticsCopyWith<$Res> {
  factory _$BabyFormulaStatisticsCopyWith(_BabyFormulaStatistics value, $Res Function(_BabyFormulaStatistics) _then) = __$BabyFormulaStatisticsCopyWithImpl;
@override @useResult
$Res call({
 int totalGrams, int totalDays, int dailyAverage, List<BabyFormulaMonthGrams> monthlyTrend
});




}
/// @nodoc
class __$BabyFormulaStatisticsCopyWithImpl<$Res>
    implements _$BabyFormulaStatisticsCopyWith<$Res> {
  __$BabyFormulaStatisticsCopyWithImpl(this._self, this._then);

  final _BabyFormulaStatistics _self;
  final $Res Function(_BabyFormulaStatistics) _then;

/// Create a copy of BabyFormulaStatistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalGrams = null,Object? totalDays = null,Object? dailyAverage = null,Object? monthlyTrend = null,}) {
  return _then(_BabyFormulaStatistics(
totalGrams: null == totalGrams ? _self.totalGrams : totalGrams // ignore: cast_nullable_to_non_nullable
as int,totalDays: null == totalDays ? _self.totalDays : totalDays // ignore: cast_nullable_to_non_nullable
as int,dailyAverage: null == dailyAverage ? _self.dailyAverage : dailyAverage // ignore: cast_nullable_to_non_nullable
as int,monthlyTrend: null == monthlyTrend ? _self._monthlyTrend : monthlyTrend // ignore: cast_nullable_to_non_nullable
as List<BabyFormulaMonthGrams>,
  ));
}


}


/// @nodoc
mixin _$BabyFormulaMonthGrams {

 String get month; int get grams;
/// Create a copy of BabyFormulaMonthGrams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BabyFormulaMonthGramsCopyWith<BabyFormulaMonthGrams> get copyWith => _$BabyFormulaMonthGramsCopyWithImpl<BabyFormulaMonthGrams>(this as BabyFormulaMonthGrams, _$identity);

  /// Serializes this BabyFormulaMonthGrams to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BabyFormulaMonthGrams;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BabyFormulaMonthGrams&&(identical(other.month, _this.month) || other.month == _this.month)&&(identical(other.grams, _this.grams) || other.grams == _this.grams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BabyFormulaMonthGrams;
  return Object.hash(runtimeType,_this.month,_this.grams);
}

@override
String toString() {
  final _this = this as BabyFormulaMonthGrams;
  return 'BabyFormulaMonthGrams(month: ${_this.month}, grams: ${_this.grams})';
}


}

/// @nodoc
abstract mixin class $BabyFormulaMonthGramsCopyWith<$Res>  {
  factory $BabyFormulaMonthGramsCopyWith(BabyFormulaMonthGrams value, $Res Function(BabyFormulaMonthGrams) _then) = _$BabyFormulaMonthGramsCopyWithImpl;
@useResult
$Res call({
 String month, int grams
});




}
/// @nodoc
class _$BabyFormulaMonthGramsCopyWithImpl<$Res>
    implements $BabyFormulaMonthGramsCopyWith<$Res> {
  _$BabyFormulaMonthGramsCopyWithImpl(this._self, this._then);

  final BabyFormulaMonthGrams _self;
  final $Res Function(BabyFormulaMonthGrams) _then;

/// Create a copy of BabyFormulaMonthGrams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = null,Object? grams = null,}) {
  return _then(BabyFormulaMonthGrams(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BabyFormulaMonthGrams].
extension BabyFormulaMonthGramsPatterns on BabyFormulaMonthGrams {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BabyFormulaMonthGrams value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BabyFormulaMonthGrams() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BabyFormulaMonthGrams value)  $default,){
final _that = this;
switch (_that) {
case _BabyFormulaMonthGrams():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BabyFormulaMonthGrams value)?  $default,){
final _that = this;
switch (_that) {
case _BabyFormulaMonthGrams() when $default != null:
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
case _BabyFormulaMonthGrams() when $default != null:
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
case _BabyFormulaMonthGrams():
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
case _BabyFormulaMonthGrams() when $default != null:
return $default(_that.month,_that.grams);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BabyFormulaMonthGrams implements BabyFormulaMonthGrams {
  const _BabyFormulaMonthGrams({required this.month, required this.grams});
  factory _BabyFormulaMonthGrams.fromJson(Map<String, dynamic> json) => _$BabyFormulaMonthGramsFromJson(json);

@override final  String month;
@override final  int grams;

/// Create a copy of BabyFormulaMonthGrams
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BabyFormulaMonthGramsCopyWith<_BabyFormulaMonthGrams> get copyWith => __$BabyFormulaMonthGramsCopyWithImpl<_BabyFormulaMonthGrams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BabyFormulaMonthGramsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BabyFormulaMonthGrams&&(identical(other.month, month) || other.month == month)&&(identical(other.grams, grams) || other.grams == grams));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,month,grams);
}

@override
String toString() {
    return 'BabyFormulaMonthGrams(month: $month, grams: $grams)';
}


}

/// @nodoc
abstract mixin class _$BabyFormulaMonthGramsCopyWith<$Res> implements $BabyFormulaMonthGramsCopyWith<$Res> {
  factory _$BabyFormulaMonthGramsCopyWith(_BabyFormulaMonthGrams value, $Res Function(_BabyFormulaMonthGrams) _then) = __$BabyFormulaMonthGramsCopyWithImpl;
@override @useResult
$Res call({
 String month, int grams
});




}
/// @nodoc
class __$BabyFormulaMonthGramsCopyWithImpl<$Res>
    implements _$BabyFormulaMonthGramsCopyWith<$Res> {
  __$BabyFormulaMonthGramsCopyWithImpl(this._self, this._then);

  final _BabyFormulaMonthGrams _self;
  final $Res Function(_BabyFormulaMonthGrams) _then;

/// Create a copy of BabyFormulaMonthGrams
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = null,Object? grams = null,}) {
  return _then(_BabyFormulaMonthGrams(
month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,grams: null == grams ? _self.grams : grams // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
