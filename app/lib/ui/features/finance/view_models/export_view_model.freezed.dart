// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'export_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExportState {

 ExportFormat get format;/// 从统计页进来时带的是统计页当前那套条件（F6 的 `exportWith` 把它编进路由的
/// 查询参数），从设置页进来时是这个默认值，也就是「导出全部」。
 StatisticsQuery get query; TransactionSummary? get summary; bool get counting; bool get exporting; String? get error;
/// Create a copy of ExportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExportStateCopyWith<ExportState> get copyWith => _$ExportStateCopyWithImpl<ExportState>(this as ExportState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ExportState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportState&&(identical(other.format, _this.format) || other.format == _this.format)&&(identical(other.query, _this.query) || other.query == _this.query)&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&(identical(other.counting, _this.counting) || other.counting == _this.counting)&&(identical(other.exporting, _this.exporting) || other.exporting == _this.exporting)&&(identical(other.error, _this.error) || other.error == _this.error));
}


@override
int get hashCode {
  final _this = this as ExportState;
  return Object.hash(runtimeType,_this.format,_this.query,_this.summary,_this.counting,_this.exporting,_this.error);
}

@override
String toString() {
  final _this = this as ExportState;
  return 'ExportState(format: ${_this.format}, query: ${_this.query}, summary: ${_this.summary}, counting: ${_this.counting}, exporting: ${_this.exporting}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $ExportStateCopyWith<$Res>  {
  factory $ExportStateCopyWith(ExportState value, $Res Function(ExportState) _then) = _$ExportStateCopyWithImpl;
@useResult
$Res call({
 ExportFormat format, StatisticsQuery query, TransactionSummary? summary, bool counting, bool exporting, String? error
});


$StatisticsQueryCopyWith<$Res> get query;$TransactionSummaryCopyWith<$Res>? get summary;

}
/// @nodoc
class _$ExportStateCopyWithImpl<$Res>
    implements $ExportStateCopyWith<$Res> {
  _$ExportStateCopyWithImpl(this._self, this._then);

  final ExportState _self;
  final $Res Function(ExportState) _then;

/// Create a copy of ExportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? format = null,Object? query = null,Object? summary = freezed,Object? counting = null,Object? exporting = null,Object? error = freezed,}) {
  return _then(ExportState(
format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as ExportFormat,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as StatisticsQuery,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as TransactionSummary?,counting: null == counting ? _self.counting : counting // ignore: cast_nullable_to_non_nullable
as bool,exporting: null == exporting ? _self.exporting : exporting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ExportState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatisticsQueryCopyWith<$Res> get query {
  
  return $StatisticsQueryCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}/// Create a copy of ExportState
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
}
}


/// Adds pattern-matching-related methods to [ExportState].
extension ExportStatePatterns on ExportState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExportState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExportState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExportState value)  $default,){
final _that = this;
switch (_that) {
case _ExportState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExportState value)?  $default,){
final _that = this;
switch (_that) {
case _ExportState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ExportFormat format,  StatisticsQuery query,  TransactionSummary? summary,  bool counting,  bool exporting,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExportState() when $default != null:
return $default(_that.format,_that.query,_that.summary,_that.counting,_that.exporting,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ExportFormat format,  StatisticsQuery query,  TransactionSummary? summary,  bool counting,  bool exporting,  String? error)  $default,) {final _that = this;
switch (_that) {
case _ExportState():
return $default(_that.format,_that.query,_that.summary,_that.counting,_that.exporting,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ExportFormat format,  StatisticsQuery query,  TransactionSummary? summary,  bool counting,  bool exporting,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _ExportState() when $default != null:
return $default(_that.format,_that.query,_that.summary,_that.counting,_that.exporting,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ExportState implements ExportState {
  const _ExportState({this.format = ExportFormat.xlsx, this.query = const StatisticsQuery(), this.summary, this.counting = false, this.exporting = false, this.error});
  

@override@JsonKey() final  ExportFormat format;
/// 从统计页进来时带的是统计页当前那套条件（F6 的 `exportWith` 把它编进路由的
/// 查询参数），从设置页进来时是这个默认值，也就是「导出全部」。
@override@JsonKey() final  StatisticsQuery query;
@override final  TransactionSummary? summary;
@override@JsonKey() final  bool counting;
@override@JsonKey() final  bool exporting;
@override final  String? error;

/// Create a copy of ExportState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExportStateCopyWith<_ExportState> get copyWith => __$ExportStateCopyWithImpl<_ExportState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExportState&&(identical(other.format, format) || other.format == format)&&(identical(other.query, query) || other.query == query)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.counting, counting) || other.counting == counting)&&(identical(other.exporting, exporting) || other.exporting == exporting)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode {
    return Object.hash(runtimeType,format,query,summary,counting,exporting,error);
}

@override
String toString() {
    return 'ExportState(format: $format, query: $query, summary: $summary, counting: $counting, exporting: $exporting, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ExportStateCopyWith<$Res> implements $ExportStateCopyWith<$Res> {
  factory _$ExportStateCopyWith(_ExportState value, $Res Function(_ExportState) _then) = __$ExportStateCopyWithImpl;
@override @useResult
$Res call({
 ExportFormat format, StatisticsQuery query, TransactionSummary? summary, bool counting, bool exporting, String? error
});


@override $StatisticsQueryCopyWith<$Res> get query;@override $TransactionSummaryCopyWith<$Res>? get summary;

}
/// @nodoc
class __$ExportStateCopyWithImpl<$Res>
    implements _$ExportStateCopyWith<$Res> {
  __$ExportStateCopyWithImpl(this._self, this._then);

  final _ExportState _self;
  final $Res Function(_ExportState) _then;

/// Create a copy of ExportState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? format = null,Object? query = null,Object? summary = freezed,Object? counting = null,Object? exporting = null,Object? error = freezed,}) {
  return _then(_ExportState(
format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as ExportFormat,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as StatisticsQuery,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as TransactionSummary?,counting: null == counting ? _self.counting : counting // ignore: cast_nullable_to_non_nullable
as bool,exporting: null == exporting ? _self.exporting : exporting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ExportState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatisticsQueryCopyWith<$Res> get query {
  
  return $StatisticsQueryCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}/// Create a copy of ExportState
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
}
}

// dart format on
