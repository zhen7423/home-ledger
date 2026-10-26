// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'finance_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FinanceStatistics {

 DateTime get startDate; DateTime get endDate; List<CategorySlice> get categoryBreakdown; List<MonthSummary> get monthlyTrend; List<DailyPoint> get dailyTrend; List<AccountSlice> get accountBreakdown; List<MemberSlice> get memberComparison;
/// Create a copy of FinanceStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinanceStatisticsCopyWith<FinanceStatistics> get copyWith => _$FinanceStatisticsCopyWithImpl<FinanceStatistics>(this as FinanceStatistics, _$identity);

  /// Serializes this FinanceStatistics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FinanceStatistics;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinanceStatistics&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&const DeepCollectionEquality().equals(other.categoryBreakdown, _this.categoryBreakdown)&&const DeepCollectionEquality().equals(other.monthlyTrend, _this.monthlyTrend)&&const DeepCollectionEquality().equals(other.dailyTrend, _this.dailyTrend)&&const DeepCollectionEquality().equals(other.accountBreakdown, _this.accountBreakdown)&&const DeepCollectionEquality().equals(other.memberComparison, _this.memberComparison));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FinanceStatistics;
  return Object.hash(runtimeType,_this.startDate,_this.endDate,const DeepCollectionEquality().hash(_this.categoryBreakdown),const DeepCollectionEquality().hash(_this.monthlyTrend),const DeepCollectionEquality().hash(_this.dailyTrend),const DeepCollectionEquality().hash(_this.accountBreakdown),const DeepCollectionEquality().hash(_this.memberComparison));
}

@override
String toString() {
  final _this = this as FinanceStatistics;
  return 'FinanceStatistics(startDate: ${_this.startDate}, endDate: ${_this.endDate}, categoryBreakdown: ${_this.categoryBreakdown}, monthlyTrend: ${_this.monthlyTrend}, dailyTrend: ${_this.dailyTrend}, accountBreakdown: ${_this.accountBreakdown}, memberComparison: ${_this.memberComparison})';
}


}

/// @nodoc
abstract mixin class $FinanceStatisticsCopyWith<$Res>  {
  factory $FinanceStatisticsCopyWith(FinanceStatistics value, $Res Function(FinanceStatistics) _then) = _$FinanceStatisticsCopyWithImpl;
@useResult
$Res call({
 DateTime startDate, DateTime endDate, List<CategorySlice> categoryBreakdown, List<MonthSummary> monthlyTrend, List<DailyPoint> dailyTrend, List<AccountSlice> accountBreakdown, List<MemberSlice> memberComparison
});




}
/// @nodoc
class _$FinanceStatisticsCopyWithImpl<$Res>
    implements $FinanceStatisticsCopyWith<$Res> {
  _$FinanceStatisticsCopyWithImpl(this._self, this._then);

  final FinanceStatistics _self;
  final $Res Function(FinanceStatistics) _then;

/// Create a copy of FinanceStatistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = null,Object? endDate = null,Object? categoryBreakdown = null,Object? monthlyTrend = null,Object? dailyTrend = null,Object? accountBreakdown = null,Object? memberComparison = null,}) {
  return _then(FinanceStatistics(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,categoryBreakdown: null == categoryBreakdown ? _self.categoryBreakdown : categoryBreakdown // ignore: cast_nullable_to_non_nullable
as List<CategorySlice>,monthlyTrend: null == monthlyTrend ? _self.monthlyTrend : monthlyTrend // ignore: cast_nullable_to_non_nullable
as List<MonthSummary>,dailyTrend: null == dailyTrend ? _self.dailyTrend : dailyTrend // ignore: cast_nullable_to_non_nullable
as List<DailyPoint>,accountBreakdown: null == accountBreakdown ? _self.accountBreakdown : accountBreakdown // ignore: cast_nullable_to_non_nullable
as List<AccountSlice>,memberComparison: null == memberComparison ? _self.memberComparison : memberComparison // ignore: cast_nullable_to_non_nullable
as List<MemberSlice>,
  ));
}

}


/// Adds pattern-matching-related methods to [FinanceStatistics].
extension FinanceStatisticsPatterns on FinanceStatistics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinanceStatistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinanceStatistics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinanceStatistics value)  $default,){
final _that = this;
switch (_that) {
case _FinanceStatistics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinanceStatistics value)?  $default,){
final _that = this;
switch (_that) {
case _FinanceStatistics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime startDate,  DateTime endDate,  List<CategorySlice> categoryBreakdown,  List<MonthSummary> monthlyTrend,  List<DailyPoint> dailyTrend,  List<AccountSlice> accountBreakdown,  List<MemberSlice> memberComparison)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinanceStatistics() when $default != null:
return $default(_that.startDate,_that.endDate,_that.categoryBreakdown,_that.monthlyTrend,_that.dailyTrend,_that.accountBreakdown,_that.memberComparison);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime startDate,  DateTime endDate,  List<CategorySlice> categoryBreakdown,  List<MonthSummary> monthlyTrend,  List<DailyPoint> dailyTrend,  List<AccountSlice> accountBreakdown,  List<MemberSlice> memberComparison)  $default,) {final _that = this;
switch (_that) {
case _FinanceStatistics():
return $default(_that.startDate,_that.endDate,_that.categoryBreakdown,_that.monthlyTrend,_that.dailyTrend,_that.accountBreakdown,_that.memberComparison);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime startDate,  DateTime endDate,  List<CategorySlice> categoryBreakdown,  List<MonthSummary> monthlyTrend,  List<DailyPoint> dailyTrend,  List<AccountSlice> accountBreakdown,  List<MemberSlice> memberComparison)?  $default,) {final _that = this;
switch (_that) {
case _FinanceStatistics() when $default != null:
return $default(_that.startDate,_that.endDate,_that.categoryBreakdown,_that.monthlyTrend,_that.dailyTrend,_that.accountBreakdown,_that.memberComparison);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FinanceStatistics implements FinanceStatistics {
  const _FinanceStatistics({required this.startDate, required this.endDate, required  List<CategorySlice> categoryBreakdown, required  List<MonthSummary> monthlyTrend, required  List<DailyPoint> dailyTrend, required  List<AccountSlice> accountBreakdown, required  List<MemberSlice> memberComparison}): _categoryBreakdown = categoryBreakdown,_monthlyTrend = monthlyTrend,_dailyTrend = dailyTrend,_accountBreakdown = accountBreakdown,_memberComparison = memberComparison;
  factory _FinanceStatistics.fromJson(Map<String, dynamic> json) => _$FinanceStatisticsFromJson(json);

@override final  DateTime startDate;
@override final  DateTime endDate;
 final  List<CategorySlice> _categoryBreakdown;
@override List<CategorySlice> get categoryBreakdown {
  if (_categoryBreakdown is EqualUnmodifiableListView) return _categoryBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryBreakdown);
}

 final  List<MonthSummary> _monthlyTrend;
@override List<MonthSummary> get monthlyTrend {
  if (_monthlyTrend is EqualUnmodifiableListView) return _monthlyTrend;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_monthlyTrend);
}

 final  List<DailyPoint> _dailyTrend;
@override List<DailyPoint> get dailyTrend {
  if (_dailyTrend is EqualUnmodifiableListView) return _dailyTrend;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dailyTrend);
}

 final  List<AccountSlice> _accountBreakdown;
@override List<AccountSlice> get accountBreakdown {
  if (_accountBreakdown is EqualUnmodifiableListView) return _accountBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_accountBreakdown);
}

 final  List<MemberSlice> _memberComparison;
@override List<MemberSlice> get memberComparison {
  if (_memberComparison is EqualUnmodifiableListView) return _memberComparison;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberComparison);
}


/// Create a copy of FinanceStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinanceStatisticsCopyWith<_FinanceStatistics> get copyWith => __$FinanceStatisticsCopyWithImpl<_FinanceStatistics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FinanceStatisticsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinanceStatistics&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&const DeepCollectionEquality().equals(other.categoryBreakdown, _categoryBreakdown)&&const DeepCollectionEquality().equals(other.monthlyTrend, _monthlyTrend)&&const DeepCollectionEquality().equals(other.dailyTrend, _dailyTrend)&&const DeepCollectionEquality().equals(other.accountBreakdown, _accountBreakdown)&&const DeepCollectionEquality().equals(other.memberComparison, _memberComparison));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startDate,endDate,const DeepCollectionEquality().hash(_categoryBreakdown),const DeepCollectionEquality().hash(_monthlyTrend),const DeepCollectionEquality().hash(_dailyTrend),const DeepCollectionEquality().hash(_accountBreakdown),const DeepCollectionEquality().hash(_memberComparison));
}

@override
String toString() {
    return 'FinanceStatistics(startDate: $startDate, endDate: $endDate, categoryBreakdown: $categoryBreakdown, monthlyTrend: $monthlyTrend, dailyTrend: $dailyTrend, accountBreakdown: $accountBreakdown, memberComparison: $memberComparison)';
}


}

/// @nodoc
abstract mixin class _$FinanceStatisticsCopyWith<$Res> implements $FinanceStatisticsCopyWith<$Res> {
  factory _$FinanceStatisticsCopyWith(_FinanceStatistics value, $Res Function(_FinanceStatistics) _then) = __$FinanceStatisticsCopyWithImpl;
@override @useResult
$Res call({
 DateTime startDate, DateTime endDate, List<CategorySlice> categoryBreakdown, List<MonthSummary> monthlyTrend, List<DailyPoint> dailyTrend, List<AccountSlice> accountBreakdown, List<MemberSlice> memberComparison
});




}
/// @nodoc
class __$FinanceStatisticsCopyWithImpl<$Res>
    implements _$FinanceStatisticsCopyWith<$Res> {
  __$FinanceStatisticsCopyWithImpl(this._self, this._then);

  final _FinanceStatistics _self;
  final $Res Function(_FinanceStatistics) _then;

/// Create a copy of FinanceStatistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = null,Object? endDate = null,Object? categoryBreakdown = null,Object? monthlyTrend = null,Object? dailyTrend = null,Object? accountBreakdown = null,Object? memberComparison = null,}) {
  return _then(_FinanceStatistics(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,categoryBreakdown: null == categoryBreakdown ? _self._categoryBreakdown : categoryBreakdown // ignore: cast_nullable_to_non_nullable
as List<CategorySlice>,monthlyTrend: null == monthlyTrend ? _self._monthlyTrend : monthlyTrend // ignore: cast_nullable_to_non_nullable
as List<MonthSummary>,dailyTrend: null == dailyTrend ? _self._dailyTrend : dailyTrend // ignore: cast_nullable_to_non_nullable
as List<DailyPoint>,accountBreakdown: null == accountBreakdown ? _self._accountBreakdown : accountBreakdown // ignore: cast_nullable_to_non_nullable
as List<AccountSlice>,memberComparison: null == memberComparison ? _self._memberComparison : memberComparison // ignore: cast_nullable_to_non_nullable
as List<MemberSlice>,
  ));
}


}


/// @nodoc
mixin _$CategorySlice {

 int? get categoryId; String get name; String get amount; int get percent; List<CategorySlice> get subCategories;
/// Create a copy of CategorySlice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategorySliceCopyWith<CategorySlice> get copyWith => _$CategorySliceCopyWithImpl<CategorySlice>(this as CategorySlice, _$identity);

  /// Serializes this CategorySlice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CategorySlice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategorySlice&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.percent, _this.percent) || other.percent == _this.percent)&&const DeepCollectionEquality().equals(other.subCategories, _this.subCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CategorySlice;
  return Object.hash(runtimeType,_this.categoryId,_this.name,_this.amount,_this.percent,const DeepCollectionEquality().hash(_this.subCategories));
}

@override
String toString() {
  final _this = this as CategorySlice;
  return 'CategorySlice(categoryId: ${_this.categoryId}, name: ${_this.name}, amount: ${_this.amount}, percent: ${_this.percent}, subCategories: ${_this.subCategories})';
}


}

/// @nodoc
abstract mixin class $CategorySliceCopyWith<$Res>  {
  factory $CategorySliceCopyWith(CategorySlice value, $Res Function(CategorySlice) _then) = _$CategorySliceCopyWithImpl;
@useResult
$Res call({
 int? categoryId, String name, String amount, int percent, List<CategorySlice> subCategories
});




}
/// @nodoc
class _$CategorySliceCopyWithImpl<$Res>
    implements $CategorySliceCopyWith<$Res> {
  _$CategorySliceCopyWithImpl(this._self, this._then);

  final CategorySlice _self;
  final $Res Function(CategorySlice) _then;

/// Create a copy of CategorySlice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = freezed,Object? name = null,Object? amount = null,Object? percent = null,Object? subCategories = null,}) {
  return _then(CategorySlice(
categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,subCategories: null == subCategories ? _self.subCategories : subCategories // ignore: cast_nullable_to_non_nullable
as List<CategorySlice>,
  ));
}

}


/// Adds pattern-matching-related methods to [CategorySlice].
extension CategorySlicePatterns on CategorySlice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategorySlice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategorySlice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategorySlice value)  $default,){
final _that = this;
switch (_that) {
case _CategorySlice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategorySlice value)?  $default,){
final _that = this;
switch (_that) {
case _CategorySlice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? categoryId,  String name,  String amount,  int percent,  List<CategorySlice> subCategories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategorySlice() when $default != null:
return $default(_that.categoryId,_that.name,_that.amount,_that.percent,_that.subCategories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? categoryId,  String name,  String amount,  int percent,  List<CategorySlice> subCategories)  $default,) {final _that = this;
switch (_that) {
case _CategorySlice():
return $default(_that.categoryId,_that.name,_that.amount,_that.percent,_that.subCategories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? categoryId,  String name,  String amount,  int percent,  List<CategorySlice> subCategories)?  $default,) {final _that = this;
switch (_that) {
case _CategorySlice() when $default != null:
return $default(_that.categoryId,_that.name,_that.amount,_that.percent,_that.subCategories);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategorySlice implements CategorySlice {
  const _CategorySlice({this.categoryId, required this.name, required this.amount, required this.percent,  List<CategorySlice> subCategories = const <CategorySlice>[]}): _subCategories = subCategories;
  factory _CategorySlice.fromJson(Map<String, dynamic> json) => _$CategorySliceFromJson(json);

@override final  int? categoryId;
@override final  String name;
@override final  String amount;
@override final  int percent;
 final  List<CategorySlice> _subCategories;
@override@JsonKey() List<CategorySlice> get subCategories {
  if (_subCategories is EqualUnmodifiableListView) return _subCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subCategories);
}


/// Create a copy of CategorySlice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategorySliceCopyWith<_CategorySlice> get copyWith => __$CategorySliceCopyWithImpl<_CategorySlice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategorySliceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategorySlice&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.percent, percent) || other.percent == percent)&&const DeepCollectionEquality().equals(other.subCategories, _subCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,categoryId,name,amount,percent,const DeepCollectionEquality().hash(_subCategories));
}

@override
String toString() {
    return 'CategorySlice(categoryId: $categoryId, name: $name, amount: $amount, percent: $percent, subCategories: $subCategories)';
}


}

/// @nodoc
abstract mixin class _$CategorySliceCopyWith<$Res> implements $CategorySliceCopyWith<$Res> {
  factory _$CategorySliceCopyWith(_CategorySlice value, $Res Function(_CategorySlice) _then) = __$CategorySliceCopyWithImpl;
@override @useResult
$Res call({
 int? categoryId, String name, String amount, int percent, List<CategorySlice> subCategories
});




}
/// @nodoc
class __$CategorySliceCopyWithImpl<$Res>
    implements _$CategorySliceCopyWith<$Res> {
  __$CategorySliceCopyWithImpl(this._self, this._then);

  final _CategorySlice _self;
  final $Res Function(_CategorySlice) _then;

/// Create a copy of CategorySlice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = freezed,Object? name = null,Object? amount = null,Object? percent = null,Object? subCategories = null,}) {
  return _then(_CategorySlice(
categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,subCategories: null == subCategories ? _self._subCategories : subCategories // ignore: cast_nullable_to_non_nullable
as List<CategorySlice>,
  ));
}


}


/// @nodoc
mixin _$DailyPoint {

 DateTime get date; String get expense;
/// Create a copy of DailyPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyPointCopyWith<DailyPoint> get copyWith => _$DailyPointCopyWithImpl<DailyPoint>(this as DailyPoint, _$identity);

  /// Serializes this DailyPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DailyPoint;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyPoint&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.expense, _this.expense) || other.expense == _this.expense));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DailyPoint;
  return Object.hash(runtimeType,_this.date,_this.expense);
}

@override
String toString() {
  final _this = this as DailyPoint;
  return 'DailyPoint(date: ${_this.date}, expense: ${_this.expense})';
}


}

/// @nodoc
abstract mixin class $DailyPointCopyWith<$Res>  {
  factory $DailyPointCopyWith(DailyPoint value, $Res Function(DailyPoint) _then) = _$DailyPointCopyWithImpl;
@useResult
$Res call({
 DateTime date, String expense
});




}
/// @nodoc
class _$DailyPointCopyWithImpl<$Res>
    implements $DailyPointCopyWith<$Res> {
  _$DailyPointCopyWithImpl(this._self, this._then);

  final DailyPoint _self;
  final $Res Function(DailyPoint) _then;

/// Create a copy of DailyPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? expense = null,}) {
  return _then(DailyPoint(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,expense: null == expense ? _self.expense : expense // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyPoint].
extension DailyPointPatterns on DailyPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyPoint value)  $default,){
final _that = this;
switch (_that) {
case _DailyPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyPoint value)?  $default,){
final _that = this;
switch (_that) {
case _DailyPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  String expense)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyPoint() when $default != null:
return $default(_that.date,_that.expense);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  String expense)  $default,) {final _that = this;
switch (_that) {
case _DailyPoint():
return $default(_that.date,_that.expense);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  String expense)?  $default,) {final _that = this;
switch (_that) {
case _DailyPoint() when $default != null:
return $default(_that.date,_that.expense);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyPoint implements DailyPoint {
  const _DailyPoint({required this.date, required this.expense});
  factory _DailyPoint.fromJson(Map<String, dynamic> json) => _$DailyPointFromJson(json);

@override final  DateTime date;
@override final  String expense;

/// Create a copy of DailyPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyPointCopyWith<_DailyPoint> get copyWith => __$DailyPointCopyWithImpl<_DailyPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyPointToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyPoint&&(identical(other.date, date) || other.date == date)&&(identical(other.expense, expense) || other.expense == expense));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,date,expense);
}

@override
String toString() {
    return 'DailyPoint(date: $date, expense: $expense)';
}


}

/// @nodoc
abstract mixin class _$DailyPointCopyWith<$Res> implements $DailyPointCopyWith<$Res> {
  factory _$DailyPointCopyWith(_DailyPoint value, $Res Function(_DailyPoint) _then) = __$DailyPointCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, String expense
});




}
/// @nodoc
class __$DailyPointCopyWithImpl<$Res>
    implements _$DailyPointCopyWith<$Res> {
  __$DailyPointCopyWithImpl(this._self, this._then);

  final _DailyPoint _self;
  final $Res Function(_DailyPoint) _then;

/// Create a copy of DailyPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? expense = null,}) {
  return _then(_DailyPoint(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,expense: null == expense ? _self.expense : expense // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AccountSlice {

 int get accountId; String get name; String get amount; int get percent;
/// Create a copy of AccountSlice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountSliceCopyWith<AccountSlice> get copyWith => _$AccountSliceCopyWithImpl<AccountSlice>(this as AccountSlice, _$identity);

  /// Serializes this AccountSlice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AccountSlice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountSlice&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.percent, _this.percent) || other.percent == _this.percent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AccountSlice;
  return Object.hash(runtimeType,_this.accountId,_this.name,_this.amount,_this.percent);
}

@override
String toString() {
  final _this = this as AccountSlice;
  return 'AccountSlice(accountId: ${_this.accountId}, name: ${_this.name}, amount: ${_this.amount}, percent: ${_this.percent})';
}


}

/// @nodoc
abstract mixin class $AccountSliceCopyWith<$Res>  {
  factory $AccountSliceCopyWith(AccountSlice value, $Res Function(AccountSlice) _then) = _$AccountSliceCopyWithImpl;
@useResult
$Res call({
 int accountId, String name, String amount, int percent
});




}
/// @nodoc
class _$AccountSliceCopyWithImpl<$Res>
    implements $AccountSliceCopyWith<$Res> {
  _$AccountSliceCopyWithImpl(this._self, this._then);

  final AccountSlice _self;
  final $Res Function(AccountSlice) _then;

/// Create a copy of AccountSlice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = null,Object? name = null,Object? amount = null,Object? percent = null,}) {
  return _then(AccountSlice(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountSlice].
extension AccountSlicePatterns on AccountSlice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountSlice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountSlice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountSlice value)  $default,){
final _that = this;
switch (_that) {
case _AccountSlice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountSlice value)?  $default,){
final _that = this;
switch (_that) {
case _AccountSlice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int accountId,  String name,  String amount,  int percent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountSlice() when $default != null:
return $default(_that.accountId,_that.name,_that.amount,_that.percent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int accountId,  String name,  String amount,  int percent)  $default,) {final _that = this;
switch (_that) {
case _AccountSlice():
return $default(_that.accountId,_that.name,_that.amount,_that.percent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int accountId,  String name,  String amount,  int percent)?  $default,) {final _that = this;
switch (_that) {
case _AccountSlice() when $default != null:
return $default(_that.accountId,_that.name,_that.amount,_that.percent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccountSlice implements AccountSlice {
  const _AccountSlice({required this.accountId, required this.name, required this.amount, required this.percent});
  factory _AccountSlice.fromJson(Map<String, dynamic> json) => _$AccountSliceFromJson(json);

@override final  int accountId;
@override final  String name;
@override final  String amount;
@override final  int percent;

/// Create a copy of AccountSlice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountSliceCopyWith<_AccountSlice> get copyWith => __$AccountSliceCopyWithImpl<_AccountSlice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountSliceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountSlice&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.percent, percent) || other.percent == percent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,accountId,name,amount,percent);
}

@override
String toString() {
    return 'AccountSlice(accountId: $accountId, name: $name, amount: $amount, percent: $percent)';
}


}

/// @nodoc
abstract mixin class _$AccountSliceCopyWith<$Res> implements $AccountSliceCopyWith<$Res> {
  factory _$AccountSliceCopyWith(_AccountSlice value, $Res Function(_AccountSlice) _then) = __$AccountSliceCopyWithImpl;
@override @useResult
$Res call({
 int accountId, String name, String amount, int percent
});




}
/// @nodoc
class __$AccountSliceCopyWithImpl<$Res>
    implements _$AccountSliceCopyWith<$Res> {
  __$AccountSliceCopyWithImpl(this._self, this._then);

  final _AccountSlice _self;
  final $Res Function(_AccountSlice) _then;

/// Create a copy of AccountSlice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? name = null,Object? amount = null,Object? percent = null,}) {
  return _then(_AccountSlice(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$CategoryAmount {

 int? get categoryId; String get amount;
/// Create a copy of CategoryAmount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryAmountCopyWith<CategoryAmount> get copyWith => _$CategoryAmountCopyWithImpl<CategoryAmount>(this as CategoryAmount, _$identity);

  /// Serializes this CategoryAmount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CategoryAmount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryAmount&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.amount, _this.amount) || other.amount == _this.amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CategoryAmount;
  return Object.hash(runtimeType,_this.categoryId,_this.amount);
}

@override
String toString() {
  final _this = this as CategoryAmount;
  return 'CategoryAmount(categoryId: ${_this.categoryId}, amount: ${_this.amount})';
}


}

/// @nodoc
abstract mixin class $CategoryAmountCopyWith<$Res>  {
  factory $CategoryAmountCopyWith(CategoryAmount value, $Res Function(CategoryAmount) _then) = _$CategoryAmountCopyWithImpl;
@useResult
$Res call({
 int? categoryId, String amount
});




}
/// @nodoc
class _$CategoryAmountCopyWithImpl<$Res>
    implements $CategoryAmountCopyWith<$Res> {
  _$CategoryAmountCopyWithImpl(this._self, this._then);

  final CategoryAmount _self;
  final $Res Function(CategoryAmount) _then;

/// Create a copy of CategoryAmount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = freezed,Object? amount = null,}) {
  return _then(CategoryAmount(
categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryAmount].
extension CategoryAmountPatterns on CategoryAmount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryAmount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryAmount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryAmount value)  $default,){
final _that = this;
switch (_that) {
case _CategoryAmount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryAmount value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryAmount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? categoryId,  String amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryAmount() when $default != null:
return $default(_that.categoryId,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? categoryId,  String amount)  $default,) {final _that = this;
switch (_that) {
case _CategoryAmount():
return $default(_that.categoryId,_that.amount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? categoryId,  String amount)?  $default,) {final _that = this;
switch (_that) {
case _CategoryAmount() when $default != null:
return $default(_that.categoryId,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryAmount implements CategoryAmount {
  const _CategoryAmount({this.categoryId, required this.amount});
  factory _CategoryAmount.fromJson(Map<String, dynamic> json) => _$CategoryAmountFromJson(json);

@override final  int? categoryId;
@override final  String amount;

/// Create a copy of CategoryAmount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryAmountCopyWith<_CategoryAmount> get copyWith => __$CategoryAmountCopyWithImpl<_CategoryAmount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryAmountToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryAmount&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,categoryId,amount);
}

@override
String toString() {
    return 'CategoryAmount(categoryId: $categoryId, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$CategoryAmountCopyWith<$Res> implements $CategoryAmountCopyWith<$Res> {
  factory _$CategoryAmountCopyWith(_CategoryAmount value, $Res Function(_CategoryAmount) _then) = __$CategoryAmountCopyWithImpl;
@override @useResult
$Res call({
 int? categoryId, String amount
});




}
/// @nodoc
class __$CategoryAmountCopyWithImpl<$Res>
    implements _$CategoryAmountCopyWith<$Res> {
  __$CategoryAmountCopyWithImpl(this._self, this._then);

  final _CategoryAmount _self;
  final $Res Function(_CategoryAmount) _then;

/// Create a copy of CategoryAmount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = freezed,Object? amount = null,}) {
  return _then(_CategoryAmount(
categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MemberSlice {

 int get userId; String get nickname; String get total; List<CategoryAmount> get byCategory;
/// Create a copy of MemberSlice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberSliceCopyWith<MemberSlice> get copyWith => _$MemberSliceCopyWithImpl<MemberSlice>(this as MemberSlice, _$identity);

  /// Serializes this MemberSlice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MemberSlice;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberSlice&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.nickname, _this.nickname) || other.nickname == _this.nickname)&&(identical(other.total, _this.total) || other.total == _this.total)&&const DeepCollectionEquality().equals(other.byCategory, _this.byCategory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MemberSlice;
  return Object.hash(runtimeType,_this.userId,_this.nickname,_this.total,const DeepCollectionEquality().hash(_this.byCategory));
}

@override
String toString() {
  final _this = this as MemberSlice;
  return 'MemberSlice(userId: ${_this.userId}, nickname: ${_this.nickname}, total: ${_this.total}, byCategory: ${_this.byCategory})';
}


}

/// @nodoc
abstract mixin class $MemberSliceCopyWith<$Res>  {
  factory $MemberSliceCopyWith(MemberSlice value, $Res Function(MemberSlice) _then) = _$MemberSliceCopyWithImpl;
@useResult
$Res call({
 int userId, String nickname, String total, List<CategoryAmount> byCategory
});




}
/// @nodoc
class _$MemberSliceCopyWithImpl<$Res>
    implements $MemberSliceCopyWith<$Res> {
  _$MemberSliceCopyWithImpl(this._self, this._then);

  final MemberSlice _self;
  final $Res Function(MemberSlice) _then;

/// Create a copy of MemberSlice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? nickname = null,Object? total = null,Object? byCategory = null,}) {
  return _then(MemberSlice(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,byCategory: null == byCategory ? _self.byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as List<CategoryAmount>,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberSlice].
extension MemberSlicePatterns on MemberSlice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberSlice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberSlice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberSlice value)  $default,){
final _that = this;
switch (_that) {
case _MemberSlice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberSlice value)?  $default,){
final _that = this;
switch (_that) {
case _MemberSlice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int userId,  String nickname,  String total,  List<CategoryAmount> byCategory)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberSlice() when $default != null:
return $default(_that.userId,_that.nickname,_that.total,_that.byCategory);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int userId,  String nickname,  String total,  List<CategoryAmount> byCategory)  $default,) {final _that = this;
switch (_that) {
case _MemberSlice():
return $default(_that.userId,_that.nickname,_that.total,_that.byCategory);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int userId,  String nickname,  String total,  List<CategoryAmount> byCategory)?  $default,) {final _that = this;
switch (_that) {
case _MemberSlice() when $default != null:
return $default(_that.userId,_that.nickname,_that.total,_that.byCategory);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberSlice implements MemberSlice {
  const _MemberSlice({required this.userId, required this.nickname, required this.total, required  List<CategoryAmount> byCategory}): _byCategory = byCategory;
  factory _MemberSlice.fromJson(Map<String, dynamic> json) => _$MemberSliceFromJson(json);

@override final  int userId;
@override final  String nickname;
@override final  String total;
 final  List<CategoryAmount> _byCategory;
@override List<CategoryAmount> get byCategory {
  if (_byCategory is EqualUnmodifiableListView) return _byCategory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byCategory);
}


/// Create a copy of MemberSlice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberSliceCopyWith<_MemberSlice> get copyWith => __$MemberSliceCopyWithImpl<_MemberSlice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberSliceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberSlice&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.byCategory, _byCategory));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,userId,nickname,total,const DeepCollectionEquality().hash(_byCategory));
}

@override
String toString() {
    return 'MemberSlice(userId: $userId, nickname: $nickname, total: $total, byCategory: $byCategory)';
}


}

/// @nodoc
abstract mixin class _$MemberSliceCopyWith<$Res> implements $MemberSliceCopyWith<$Res> {
  factory _$MemberSliceCopyWith(_MemberSlice value, $Res Function(_MemberSlice) _then) = __$MemberSliceCopyWithImpl;
@override @useResult
$Res call({
 int userId, String nickname, String total, List<CategoryAmount> byCategory
});




}
/// @nodoc
class __$MemberSliceCopyWithImpl<$Res>
    implements _$MemberSliceCopyWith<$Res> {
  __$MemberSliceCopyWithImpl(this._self, this._then);

  final _MemberSlice _self;
  final $Res Function(_MemberSlice) _then;

/// Create a copy of MemberSlice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? nickname = null,Object? total = null,Object? byCategory = null,}) {
  return _then(_MemberSlice(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,byCategory: null == byCategory ? _self._byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as List<CategoryAmount>,
  ));
}


}


/// @nodoc
mixin _$StatisticsQuery {

 String? get startDate; String? get endDate; int? get createdBy;
/// Create a copy of StatisticsQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatisticsQueryCopyWith<StatisticsQuery> get copyWith => _$StatisticsQueryCopyWithImpl<StatisticsQuery>(this as StatisticsQuery, _$identity);

  /// Serializes this StatisticsQuery to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StatisticsQuery;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatisticsQuery&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StatisticsQuery;
  return Object.hash(runtimeType,_this.startDate,_this.endDate,_this.createdBy);
}

@override
String toString() {
  final _this = this as StatisticsQuery;
  return 'StatisticsQuery(startDate: ${_this.startDate}, endDate: ${_this.endDate}, createdBy: ${_this.createdBy})';
}


}

/// @nodoc
abstract mixin class $StatisticsQueryCopyWith<$Res>  {
  factory $StatisticsQueryCopyWith(StatisticsQuery value, $Res Function(StatisticsQuery) _then) = _$StatisticsQueryCopyWithImpl;
@useResult
$Res call({
 String? startDate, String? endDate, int? createdBy
});




}
/// @nodoc
class _$StatisticsQueryCopyWithImpl<$Res>
    implements $StatisticsQueryCopyWith<$Res> {
  _$StatisticsQueryCopyWithImpl(this._self, this._then);

  final StatisticsQuery _self;
  final $Res Function(StatisticsQuery) _then;

/// Create a copy of StatisticsQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = freezed,Object? endDate = freezed,Object? createdBy = freezed,}) {
  return _then(StatisticsQuery(
startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [StatisticsQuery].
extension StatisticsQueryPatterns on StatisticsQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatisticsQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatisticsQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatisticsQuery value)  $default,){
final _that = this;
switch (_that) {
case _StatisticsQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatisticsQuery value)?  $default,){
final _that = this;
switch (_that) {
case _StatisticsQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? startDate,  String? endDate,  int? createdBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatisticsQuery() when $default != null:
return $default(_that.startDate,_that.endDate,_that.createdBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? startDate,  String? endDate,  int? createdBy)  $default,) {final _that = this;
switch (_that) {
case _StatisticsQuery():
return $default(_that.startDate,_that.endDate,_that.createdBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? startDate,  String? endDate,  int? createdBy)?  $default,) {final _that = this;
switch (_that) {
case _StatisticsQuery() when $default != null:
return $default(_that.startDate,_that.endDate,_that.createdBy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatisticsQuery extends StatisticsQuery {
  const _StatisticsQuery({this.startDate, this.endDate, this.createdBy}): super._();
  factory _StatisticsQuery.fromJson(Map<String, dynamic> json) => _$StatisticsQueryFromJson(json);

@override final  String? startDate;
@override final  String? endDate;
@override final  int? createdBy;

/// Create a copy of StatisticsQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatisticsQueryCopyWith<_StatisticsQuery> get copyWith => __$StatisticsQueryCopyWithImpl<_StatisticsQuery>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatisticsQueryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatisticsQuery&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startDate,endDate,createdBy);
}

@override
String toString() {
    return 'StatisticsQuery(startDate: $startDate, endDate: $endDate, createdBy: $createdBy)';
}


}

/// @nodoc
abstract mixin class _$StatisticsQueryCopyWith<$Res> implements $StatisticsQueryCopyWith<$Res> {
  factory _$StatisticsQueryCopyWith(_StatisticsQuery value, $Res Function(_StatisticsQuery) _then) = __$StatisticsQueryCopyWithImpl;
@override @useResult
$Res call({
 String? startDate, String? endDate, int? createdBy
});




}
/// @nodoc
class __$StatisticsQueryCopyWithImpl<$Res>
    implements _$StatisticsQueryCopyWith<$Res> {
  __$StatisticsQueryCopyWithImpl(this._self, this._then);

  final _StatisticsQuery _self;
  final $Res Function(_StatisticsQuery) _then;

/// Create a copy of StatisticsQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = freezed,Object? endDate = freezed,Object? createdBy = freezed,}) {
  return _then(_StatisticsQuery(
startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
