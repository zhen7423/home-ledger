// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_overview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomeOverview {

 HomeSummary get summary; List<BudgetProgress> get budgets; List<RecentActivity> get recentActivities;
/// Create a copy of HomeOverview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeOverviewCopyWith<HomeOverview> get copyWith => _$HomeOverviewCopyWithImpl<HomeOverview>(this as HomeOverview, _$identity);

  /// Serializes this HomeOverview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HomeOverview;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeOverview&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&const DeepCollectionEquality().equals(other.budgets, _this.budgets)&&const DeepCollectionEquality().equals(other.recentActivities, _this.recentActivities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HomeOverview;
  return Object.hash(runtimeType,_this.summary,const DeepCollectionEquality().hash(_this.budgets),const DeepCollectionEquality().hash(_this.recentActivities));
}

@override
String toString() {
  final _this = this as HomeOverview;
  return 'HomeOverview(summary: ${_this.summary}, budgets: ${_this.budgets}, recentActivities: ${_this.recentActivities})';
}


}

/// @nodoc
abstract mixin class $HomeOverviewCopyWith<$Res>  {
  factory $HomeOverviewCopyWith(HomeOverview value, $Res Function(HomeOverview) _then) = _$HomeOverviewCopyWithImpl;
@useResult
$Res call({
 HomeSummary summary, List<BudgetProgress> budgets, List<RecentActivity> recentActivities
});


$HomeSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$HomeOverviewCopyWithImpl<$Res>
    implements $HomeOverviewCopyWith<$Res> {
  _$HomeOverviewCopyWithImpl(this._self, this._then);

  final HomeOverview _self;
  final $Res Function(HomeOverview) _then;

/// Create a copy of HomeOverview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? budgets = null,Object? recentActivities = null,}) {
  return _then(HomeOverview(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as HomeSummary,budgets: null == budgets ? _self.budgets : budgets // ignore: cast_nullable_to_non_nullable
as List<BudgetProgress>,recentActivities: null == recentActivities ? _self.recentActivities : recentActivities // ignore: cast_nullable_to_non_nullable
as List<RecentActivity>,
  ));
}
/// Create a copy of HomeOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HomeSummaryCopyWith<$Res> get summary {
  
  return $HomeSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// Adds pattern-matching-related methods to [HomeOverview].
extension HomeOverviewPatterns on HomeOverview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeOverview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeOverview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeOverview value)  $default,){
final _that = this;
switch (_that) {
case _HomeOverview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeOverview value)?  $default,){
final _that = this;
switch (_that) {
case _HomeOverview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HomeSummary summary,  List<BudgetProgress> budgets,  List<RecentActivity> recentActivities)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeOverview() when $default != null:
return $default(_that.summary,_that.budgets,_that.recentActivities);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HomeSummary summary,  List<BudgetProgress> budgets,  List<RecentActivity> recentActivities)  $default,) {final _that = this;
switch (_that) {
case _HomeOverview():
return $default(_that.summary,_that.budgets,_that.recentActivities);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HomeSummary summary,  List<BudgetProgress> budgets,  List<RecentActivity> recentActivities)?  $default,) {final _that = this;
switch (_that) {
case _HomeOverview() when $default != null:
return $default(_that.summary,_that.budgets,_that.recentActivities);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomeOverview implements HomeOverview {
  const _HomeOverview({required this.summary, required  List<BudgetProgress> budgets, required  List<RecentActivity> recentActivities}): _budgets = budgets,_recentActivities = recentActivities;
  factory _HomeOverview.fromJson(Map<String, dynamic> json) => _$HomeOverviewFromJson(json);

@override final  HomeSummary summary;
 final  List<BudgetProgress> _budgets;
@override List<BudgetProgress> get budgets {
  if (_budgets is EqualUnmodifiableListView) return _budgets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_budgets);
}

 final  List<RecentActivity> _recentActivities;
@override List<RecentActivity> get recentActivities {
  if (_recentActivities is EqualUnmodifiableListView) return _recentActivities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentActivities);
}


/// Create a copy of HomeOverview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeOverviewCopyWith<_HomeOverview> get copyWith => __$HomeOverviewCopyWithImpl<_HomeOverview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomeOverviewToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeOverview&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.budgets, _budgets)&&const DeepCollectionEquality().equals(other.recentActivities, _recentActivities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(_budgets),const DeepCollectionEquality().hash(_recentActivities));
}

@override
String toString() {
    return 'HomeOverview(summary: $summary, budgets: $budgets, recentActivities: $recentActivities)';
}


}

/// @nodoc
abstract mixin class _$HomeOverviewCopyWith<$Res> implements $HomeOverviewCopyWith<$Res> {
  factory _$HomeOverviewCopyWith(_HomeOverview value, $Res Function(_HomeOverview) _then) = __$HomeOverviewCopyWithImpl;
@override @useResult
$Res call({
 HomeSummary summary, List<BudgetProgress> budgets, List<RecentActivity> recentActivities
});


@override $HomeSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class __$HomeOverviewCopyWithImpl<$Res>
    implements _$HomeOverviewCopyWith<$Res> {
  __$HomeOverviewCopyWithImpl(this._self, this._then);

  final _HomeOverview _self;
  final $Res Function(_HomeOverview) _then;

/// Create a copy of HomeOverview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? budgets = null,Object? recentActivities = null,}) {
  return _then(_HomeOverview(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as HomeSummary,budgets: null == budgets ? _self._budgets : budgets // ignore: cast_nullable_to_non_nullable
as List<BudgetProgress>,recentActivities: null == recentActivities ? _self._recentActivities : recentActivities // ignore: cast_nullable_to_non_nullable
as List<RecentActivity>,
  ));
}

/// Create a copy of HomeOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HomeSummaryCopyWith<$Res> get summary {
  
  return $HomeSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// @nodoc
mixin _$HomeSummary {

 String get monthIncome; String get monthExpense; String get monthBalance; int get recordedDays; int get autoGeneratedToday;
/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeSummaryCopyWith<HomeSummary> get copyWith => _$HomeSummaryCopyWithImpl<HomeSummary>(this as HomeSummary, _$identity);

  /// Serializes this HomeSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HomeSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeSummary&&(identical(other.monthIncome, _this.monthIncome) || other.monthIncome == _this.monthIncome)&&(identical(other.monthExpense, _this.monthExpense) || other.monthExpense == _this.monthExpense)&&(identical(other.monthBalance, _this.monthBalance) || other.monthBalance == _this.monthBalance)&&(identical(other.recordedDays, _this.recordedDays) || other.recordedDays == _this.recordedDays)&&(identical(other.autoGeneratedToday, _this.autoGeneratedToday) || other.autoGeneratedToday == _this.autoGeneratedToday));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HomeSummary;
  return Object.hash(runtimeType,_this.monthIncome,_this.monthExpense,_this.monthBalance,_this.recordedDays,_this.autoGeneratedToday);
}

@override
String toString() {
  final _this = this as HomeSummary;
  return 'HomeSummary(monthIncome: ${_this.monthIncome}, monthExpense: ${_this.monthExpense}, monthBalance: ${_this.monthBalance}, recordedDays: ${_this.recordedDays}, autoGeneratedToday: ${_this.autoGeneratedToday})';
}


}

/// @nodoc
abstract mixin class $HomeSummaryCopyWith<$Res>  {
  factory $HomeSummaryCopyWith(HomeSummary value, $Res Function(HomeSummary) _then) = _$HomeSummaryCopyWithImpl;
@useResult
$Res call({
 String monthIncome, String monthExpense, String monthBalance, int recordedDays, int autoGeneratedToday
});




}
/// @nodoc
class _$HomeSummaryCopyWithImpl<$Res>
    implements $HomeSummaryCopyWith<$Res> {
  _$HomeSummaryCopyWithImpl(this._self, this._then);

  final HomeSummary _self;
  final $Res Function(HomeSummary) _then;

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? monthIncome = null,Object? monthExpense = null,Object? monthBalance = null,Object? recordedDays = null,Object? autoGeneratedToday = null,}) {
  return _then(HomeSummary(
monthIncome: null == monthIncome ? _self.monthIncome : monthIncome // ignore: cast_nullable_to_non_nullable
as String,monthExpense: null == monthExpense ? _self.monthExpense : monthExpense // ignore: cast_nullable_to_non_nullable
as String,monthBalance: null == monthBalance ? _self.monthBalance : monthBalance // ignore: cast_nullable_to_non_nullable
as String,recordedDays: null == recordedDays ? _self.recordedDays : recordedDays // ignore: cast_nullable_to_non_nullable
as int,autoGeneratedToday: null == autoGeneratedToday ? _self.autoGeneratedToday : autoGeneratedToday // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeSummary].
extension HomeSummaryPatterns on HomeSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeSummary value)  $default,){
final _that = this;
switch (_that) {
case _HomeSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeSummary value)?  $default,){
final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String monthIncome,  String monthExpense,  String monthBalance,  int recordedDays,  int autoGeneratedToday)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
return $default(_that.monthIncome,_that.monthExpense,_that.monthBalance,_that.recordedDays,_that.autoGeneratedToday);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String monthIncome,  String monthExpense,  String monthBalance,  int recordedDays,  int autoGeneratedToday)  $default,) {final _that = this;
switch (_that) {
case _HomeSummary():
return $default(_that.monthIncome,_that.monthExpense,_that.monthBalance,_that.recordedDays,_that.autoGeneratedToday);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String monthIncome,  String monthExpense,  String monthBalance,  int recordedDays,  int autoGeneratedToday)?  $default,) {final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
return $default(_that.monthIncome,_that.monthExpense,_that.monthBalance,_that.recordedDays,_that.autoGeneratedToday);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomeSummary implements HomeSummary {
  const _HomeSummary({required this.monthIncome, required this.monthExpense, required this.monthBalance, required this.recordedDays, required this.autoGeneratedToday});
  factory _HomeSummary.fromJson(Map<String, dynamic> json) => _$HomeSummaryFromJson(json);

@override final  String monthIncome;
@override final  String monthExpense;
@override final  String monthBalance;
@override final  int recordedDays;
@override final  int autoGeneratedToday;

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeSummaryCopyWith<_HomeSummary> get copyWith => __$HomeSummaryCopyWithImpl<_HomeSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomeSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeSummary&&(identical(other.monthIncome, monthIncome) || other.monthIncome == monthIncome)&&(identical(other.monthExpense, monthExpense) || other.monthExpense == monthExpense)&&(identical(other.monthBalance, monthBalance) || other.monthBalance == monthBalance)&&(identical(other.recordedDays, recordedDays) || other.recordedDays == recordedDays)&&(identical(other.autoGeneratedToday, autoGeneratedToday) || other.autoGeneratedToday == autoGeneratedToday));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,monthIncome,monthExpense,monthBalance,recordedDays,autoGeneratedToday);
}

@override
String toString() {
    return 'HomeSummary(monthIncome: $monthIncome, monthExpense: $monthExpense, monthBalance: $monthBalance, recordedDays: $recordedDays, autoGeneratedToday: $autoGeneratedToday)';
}


}

/// @nodoc
abstract mixin class _$HomeSummaryCopyWith<$Res> implements $HomeSummaryCopyWith<$Res> {
  factory _$HomeSummaryCopyWith(_HomeSummary value, $Res Function(_HomeSummary) _then) = __$HomeSummaryCopyWithImpl;
@override @useResult
$Res call({
 String monthIncome, String monthExpense, String monthBalance, int recordedDays, int autoGeneratedToday
});




}
/// @nodoc
class __$HomeSummaryCopyWithImpl<$Res>
    implements _$HomeSummaryCopyWith<$Res> {
  __$HomeSummaryCopyWithImpl(this._self, this._then);

  final _HomeSummary _self;
  final $Res Function(_HomeSummary) _then;

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? monthIncome = null,Object? monthExpense = null,Object? monthBalance = null,Object? recordedDays = null,Object? autoGeneratedToday = null,}) {
  return _then(_HomeSummary(
monthIncome: null == monthIncome ? _self.monthIncome : monthIncome // ignore: cast_nullable_to_non_nullable
as String,monthExpense: null == monthExpense ? _self.monthExpense : monthExpense // ignore: cast_nullable_to_non_nullable
as String,monthBalance: null == monthBalance ? _self.monthBalance : monthBalance // ignore: cast_nullable_to_non_nullable
as String,recordedDays: null == recordedDays ? _self.recordedDays : recordedDays // ignore: cast_nullable_to_non_nullable
as int,autoGeneratedToday: null == autoGeneratedToday ? _self.autoGeneratedToday : autoGeneratedToday // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$RecentActivity {

 String get module; String get type; String get title; String get summary; String? get actorName; DateTime get occurredAt; String get route;
/// Create a copy of RecentActivity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentActivityCopyWith<RecentActivity> get copyWith => _$RecentActivityCopyWithImpl<RecentActivity>(this as RecentActivity, _$identity);

  /// Serializes this RecentActivity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RecentActivity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentActivity&&(identical(other.module, _this.module) || other.module == _this.module)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&(identical(other.actorName, _this.actorName) || other.actorName == _this.actorName)&&(identical(other.occurredAt, _this.occurredAt) || other.occurredAt == _this.occurredAt)&&(identical(other.route, _this.route) || other.route == _this.route));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RecentActivity;
  return Object.hash(runtimeType,_this.module,_this.type,_this.title,_this.summary,_this.actorName,_this.occurredAt,_this.route);
}

@override
String toString() {
  final _this = this as RecentActivity;
  return 'RecentActivity(module: ${_this.module}, type: ${_this.type}, title: ${_this.title}, summary: ${_this.summary}, actorName: ${_this.actorName}, occurredAt: ${_this.occurredAt}, route: ${_this.route})';
}


}

/// @nodoc
abstract mixin class $RecentActivityCopyWith<$Res>  {
  factory $RecentActivityCopyWith(RecentActivity value, $Res Function(RecentActivity) _then) = _$RecentActivityCopyWithImpl;
@useResult
$Res call({
 String module, String type, String title, String summary, String? actorName, DateTime occurredAt, String route
});




}
/// @nodoc
class _$RecentActivityCopyWithImpl<$Res>
    implements $RecentActivityCopyWith<$Res> {
  _$RecentActivityCopyWithImpl(this._self, this._then);

  final RecentActivity _self;
  final $Res Function(RecentActivity) _then;

/// Create a copy of RecentActivity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? module = null,Object? type = null,Object? title = null,Object? summary = null,Object? actorName = freezed,Object? occurredAt = null,Object? route = null,}) {
  return _then(RecentActivity(
module: null == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,actorName: freezed == actorName ? _self.actorName : actorName // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RecentActivity].
extension RecentActivityPatterns on RecentActivity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecentActivity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecentActivity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecentActivity value)  $default,){
final _that = this;
switch (_that) {
case _RecentActivity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecentActivity value)?  $default,){
final _that = this;
switch (_that) {
case _RecentActivity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String module,  String type,  String title,  String summary,  String? actorName,  DateTime occurredAt,  String route)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecentActivity() when $default != null:
return $default(_that.module,_that.type,_that.title,_that.summary,_that.actorName,_that.occurredAt,_that.route);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String module,  String type,  String title,  String summary,  String? actorName,  DateTime occurredAt,  String route)  $default,) {final _that = this;
switch (_that) {
case _RecentActivity():
return $default(_that.module,_that.type,_that.title,_that.summary,_that.actorName,_that.occurredAt,_that.route);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String module,  String type,  String title,  String summary,  String? actorName,  DateTime occurredAt,  String route)?  $default,) {final _that = this;
switch (_that) {
case _RecentActivity() when $default != null:
return $default(_that.module,_that.type,_that.title,_that.summary,_that.actorName,_that.occurredAt,_that.route);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecentActivity implements RecentActivity {
  const _RecentActivity({required this.module, required this.type, required this.title, required this.summary, this.actorName, required this.occurredAt, required this.route});
  factory _RecentActivity.fromJson(Map<String, dynamic> json) => _$RecentActivityFromJson(json);

@override final  String module;
@override final  String type;
@override final  String title;
@override final  String summary;
@override final  String? actorName;
@override final  DateTime occurredAt;
@override final  String route;

/// Create a copy of RecentActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecentActivityCopyWith<_RecentActivity> get copyWith => __$RecentActivityCopyWithImpl<_RecentActivity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecentActivityToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecentActivity&&(identical(other.module, module) || other.module == module)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.actorName, actorName) || other.actorName == actorName)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.route, route) || other.route == route));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,module,type,title,summary,actorName,occurredAt,route);
}

@override
String toString() {
    return 'RecentActivity(module: $module, type: $type, title: $title, summary: $summary, actorName: $actorName, occurredAt: $occurredAt, route: $route)';
}


}

/// @nodoc
abstract mixin class _$RecentActivityCopyWith<$Res> implements $RecentActivityCopyWith<$Res> {
  factory _$RecentActivityCopyWith(_RecentActivity value, $Res Function(_RecentActivity) _then) = __$RecentActivityCopyWithImpl;
@override @useResult
$Res call({
 String module, String type, String title, String summary, String? actorName, DateTime occurredAt, String route
});




}
/// @nodoc
class __$RecentActivityCopyWithImpl<$Res>
    implements _$RecentActivityCopyWith<$Res> {
  __$RecentActivityCopyWithImpl(this._self, this._then);

  final _RecentActivity _self;
  final $Res Function(_RecentActivity) _then;

/// Create a copy of RecentActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? module = null,Object? type = null,Object? title = null,Object? summary = null,Object? actorName = freezed,Object? occurredAt = null,Object? route = null,}) {
  return _then(_RecentActivity(
module: null == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,actorName: freezed == actorName ? _self.actorName : actorName // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
