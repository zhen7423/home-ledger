// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'statistics_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StatisticsState {

 StatisticsRange get range; DateTime? get customStart; DateTime? get customEnd; int? get createdBy; TransactionSummary? get summary; FinanceStatistics? get overview;/// 数据来自统计快照而不是这次请求（§5.4）。为 true 时界面上要挂离线横幅。
 bool get fromCache; DateTime? get savedAt;
/// Create a copy of StatisticsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatisticsStateCopyWith<StatisticsState> get copyWith => _$StatisticsStateCopyWithImpl<StatisticsState>(this as StatisticsState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as StatisticsState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatisticsState&&(identical(other.range, _this.range) || other.range == _this.range)&&(identical(other.customStart, _this.customStart) || other.customStart == _this.customStart)&&(identical(other.customEnd, _this.customEnd) || other.customEnd == _this.customEnd)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&(identical(other.overview, _this.overview) || other.overview == _this.overview)&&(identical(other.fromCache, _this.fromCache) || other.fromCache == _this.fromCache)&&(identical(other.savedAt, _this.savedAt) || other.savedAt == _this.savedAt));
}


@override
int get hashCode {
  final _this = this as StatisticsState;
  return Object.hash(runtimeType,_this.range,_this.customStart,_this.customEnd,_this.createdBy,_this.summary,_this.overview,_this.fromCache,_this.savedAt);
}

@override
String toString() {
  final _this = this as StatisticsState;
  return 'StatisticsState(range: ${_this.range}, customStart: ${_this.customStart}, customEnd: ${_this.customEnd}, createdBy: ${_this.createdBy}, summary: ${_this.summary}, overview: ${_this.overview}, fromCache: ${_this.fromCache}, savedAt: ${_this.savedAt})';
}


}

/// @nodoc
abstract mixin class $StatisticsStateCopyWith<$Res>  {
  factory $StatisticsStateCopyWith(StatisticsState value, $Res Function(StatisticsState) _then) = _$StatisticsStateCopyWithImpl;
@useResult
$Res call({
 StatisticsRange range, DateTime? customStart, DateTime? customEnd, int? createdBy, TransactionSummary? summary, FinanceStatistics? overview, bool fromCache, DateTime? savedAt
});


$TransactionSummaryCopyWith<$Res>? get summary;$FinanceStatisticsCopyWith<$Res>? get overview;

}
/// @nodoc
class _$StatisticsStateCopyWithImpl<$Res>
    implements $StatisticsStateCopyWith<$Res> {
  _$StatisticsStateCopyWithImpl(this._self, this._then);

  final StatisticsState _self;
  final $Res Function(StatisticsState) _then;

/// Create a copy of StatisticsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? range = null,Object? customStart = freezed,Object? customEnd = freezed,Object? createdBy = freezed,Object? summary = freezed,Object? overview = freezed,Object? fromCache = null,Object? savedAt = freezed,}) {
  return _then(StatisticsState(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as StatisticsRange,customStart: freezed == customStart ? _self.customStart : customStart // ignore: cast_nullable_to_non_nullable
as DateTime?,customEnd: freezed == customEnd ? _self.customEnd : customEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as int?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as TransactionSummary?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as FinanceStatistics?,fromCache: null == fromCache ? _self.fromCache : fromCache // ignore: cast_nullable_to_non_nullable
as bool,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of StatisticsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionSummaryCopyWith<$Res>? get summary {
    if (_self.summary == null) {
    return null;
  }

  return $TransactionSummaryCopyWith<$Res>(_self.summary!, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of StatisticsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FinanceStatisticsCopyWith<$Res>? get overview {
    if (_self.overview == null) {
    return null;
  }

  return $FinanceStatisticsCopyWith<$Res>(_self.overview!, (value) {
    return _then(_self.copyWith(overview: value));
  });
}
}


/// Adds pattern-matching-related methods to [StatisticsState].
extension StatisticsStatePatterns on StatisticsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatisticsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatisticsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatisticsState value)  $default,){
final _that = this;
switch (_that) {
case _StatisticsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatisticsState value)?  $default,){
final _that = this;
switch (_that) {
case _StatisticsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StatisticsRange range,  DateTime? customStart,  DateTime? customEnd,  int? createdBy,  TransactionSummary? summary,  FinanceStatistics? overview,  bool fromCache,  DateTime? savedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatisticsState() when $default != null:
return $default(_that.range,_that.customStart,_that.customEnd,_that.createdBy,_that.summary,_that.overview,_that.fromCache,_that.savedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StatisticsRange range,  DateTime? customStart,  DateTime? customEnd,  int? createdBy,  TransactionSummary? summary,  FinanceStatistics? overview,  bool fromCache,  DateTime? savedAt)  $default,) {final _that = this;
switch (_that) {
case _StatisticsState():
return $default(_that.range,_that.customStart,_that.customEnd,_that.createdBy,_that.summary,_that.overview,_that.fromCache,_that.savedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StatisticsRange range,  DateTime? customStart,  DateTime? customEnd,  int? createdBy,  TransactionSummary? summary,  FinanceStatistics? overview,  bool fromCache,  DateTime? savedAt)?  $default,) {final _that = this;
switch (_that) {
case _StatisticsState() when $default != null:
return $default(_that.range,_that.customStart,_that.customEnd,_that.createdBy,_that.summary,_that.overview,_that.fromCache,_that.savedAt);case _:
  return null;

}
}

}

/// @nodoc


class _StatisticsState implements StatisticsState {
  const _StatisticsState({this.range = StatisticsRange.thisMonth, this.customStart, this.customEnd, this.createdBy, this.summary, this.overview, this.fromCache = false, this.savedAt});
  

@override@JsonKey() final  StatisticsRange range;
@override final  DateTime? customStart;
@override final  DateTime? customEnd;
@override final  int? createdBy;
@override final  TransactionSummary? summary;
@override final  FinanceStatistics? overview;
/// 数据来自统计快照而不是这次请求（§5.4）。为 true 时界面上要挂离线横幅。
@override@JsonKey() final  bool fromCache;
@override final  DateTime? savedAt;

/// Create a copy of StatisticsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatisticsStateCopyWith<_StatisticsState> get copyWith => __$StatisticsStateCopyWithImpl<_StatisticsState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatisticsState&&(identical(other.range, range) || other.range == range)&&(identical(other.customStart, customStart) || other.customStart == customStart)&&(identical(other.customEnd, customEnd) || other.customEnd == customEnd)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.fromCache, fromCache) || other.fromCache == fromCache)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,range,customStart,customEnd,createdBy,summary,overview,fromCache,savedAt);
}

@override
String toString() {
    return 'StatisticsState(range: $range, customStart: $customStart, customEnd: $customEnd, createdBy: $createdBy, summary: $summary, overview: $overview, fromCache: $fromCache, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class _$StatisticsStateCopyWith<$Res> implements $StatisticsStateCopyWith<$Res> {
  factory _$StatisticsStateCopyWith(_StatisticsState value, $Res Function(_StatisticsState) _then) = __$StatisticsStateCopyWithImpl;
@override @useResult
$Res call({
 StatisticsRange range, DateTime? customStart, DateTime? customEnd, int? createdBy, TransactionSummary? summary, FinanceStatistics? overview, bool fromCache, DateTime? savedAt
});


@override $TransactionSummaryCopyWith<$Res>? get summary;@override $FinanceStatisticsCopyWith<$Res>? get overview;

}
/// @nodoc
class __$StatisticsStateCopyWithImpl<$Res>
    implements _$StatisticsStateCopyWith<$Res> {
  __$StatisticsStateCopyWithImpl(this._self, this._then);

  final _StatisticsState _self;
  final $Res Function(_StatisticsState) _then;

/// Create a copy of StatisticsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? range = null,Object? customStart = freezed,Object? customEnd = freezed,Object? createdBy = freezed,Object? summary = freezed,Object? overview = freezed,Object? fromCache = null,Object? savedAt = freezed,}) {
  return _then(_StatisticsState(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as StatisticsRange,customStart: freezed == customStart ? _self.customStart : customStart // ignore: cast_nullable_to_non_nullable
as DateTime?,customEnd: freezed == customEnd ? _self.customEnd : customEnd // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as int?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as TransactionSummary?,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as FinanceStatistics?,fromCache: null == fromCache ? _self.fromCache : fromCache // ignore: cast_nullable_to_non_nullable
as bool,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of StatisticsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionSummaryCopyWith<$Res>? get summary {
    if (_self.summary == null) {
    return null;
  }

  return $TransactionSummaryCopyWith<$Res>(_self.summary!, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of StatisticsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FinanceStatisticsCopyWith<$Res>? get overview {
    if (_self.overview == null) {
    return null;
  }

  return $FinanceStatisticsCopyWith<$Res>(_self.overview!, (value) {
    return _then(_self.copyWith(overview: value));
  });
}
}

// dart format on
