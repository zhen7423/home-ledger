// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_list_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TransactionFilter {

 DateTime? get startDate; DateTime? get endDate; String? get type; int? get categoryId; int? get subCategoryId; int? get accountId; int? get createdBy; String? get keyword; String? get amount;/// `'AUTO'` 只看周期规则自动生成的，`'MANUAL'` 只看手记的，null 不限。
/// 首页那块「今天已自动生成 N 笔」点进来带的就是它。
 String? get source;
/// Create a copy of TransactionFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionFilterCopyWith<TransactionFilter> get copyWith => _$TransactionFilterCopyWithImpl<TransactionFilter>(this as TransactionFilter, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TransactionFilter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionFilter&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.subCategoryId, _this.subCategoryId) || other.subCategoryId == _this.subCategoryId)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.keyword, _this.keyword) || other.keyword == _this.keyword)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.source, _this.source) || other.source == _this.source));
}


@override
int get hashCode {
  final _this = this as TransactionFilter;
  return Object.hash(runtimeType,_this.startDate,_this.endDate,_this.type,_this.categoryId,_this.subCategoryId,_this.accountId,_this.createdBy,_this.keyword,_this.amount,_this.source);
}

@override
String toString() {
  final _this = this as TransactionFilter;
  return 'TransactionFilter(startDate: ${_this.startDate}, endDate: ${_this.endDate}, type: ${_this.type}, categoryId: ${_this.categoryId}, subCategoryId: ${_this.subCategoryId}, accountId: ${_this.accountId}, createdBy: ${_this.createdBy}, keyword: ${_this.keyword}, amount: ${_this.amount}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $TransactionFilterCopyWith<$Res>  {
  factory $TransactionFilterCopyWith(TransactionFilter value, $Res Function(TransactionFilter) _then) = _$TransactionFilterCopyWithImpl;
@useResult
$Res call({
 DateTime? startDate, DateTime? endDate, String? type, int? categoryId, int? subCategoryId, int? accountId, int? createdBy, String? keyword, String? amount, String? source
});




}
/// @nodoc
class _$TransactionFilterCopyWithImpl<$Res>
    implements $TransactionFilterCopyWith<$Res> {
  _$TransactionFilterCopyWithImpl(this._self, this._then);

  final TransactionFilter _self;
  final $Res Function(TransactionFilter) _then;

/// Create a copy of TransactionFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = freezed,Object? endDate = freezed,Object? type = freezed,Object? categoryId = freezed,Object? subCategoryId = freezed,Object? accountId = freezed,Object? createdBy = freezed,Object? keyword = freezed,Object? amount = freezed,Object? source = freezed,}) {
  return _then(TransactionFilter(
startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,subCategoryId: freezed == subCategoryId ? _self.subCategoryId : subCategoryId // ignore: cast_nullable_to_non_nullable
as int?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as int?,keyword: freezed == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionFilter].
extension TransactionFilterPatterns on TransactionFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionFilter value)  $default,){
final _that = this;
switch (_that) {
case _TransactionFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionFilter value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime? startDate,  DateTime? endDate,  String? type,  int? categoryId,  int? subCategoryId,  int? accountId,  int? createdBy,  String? keyword,  String? amount,  String? source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionFilter() when $default != null:
return $default(_that.startDate,_that.endDate,_that.type,_that.categoryId,_that.subCategoryId,_that.accountId,_that.createdBy,_that.keyword,_that.amount,_that.source);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime? startDate,  DateTime? endDate,  String? type,  int? categoryId,  int? subCategoryId,  int? accountId,  int? createdBy,  String? keyword,  String? amount,  String? source)  $default,) {final _that = this;
switch (_that) {
case _TransactionFilter():
return $default(_that.startDate,_that.endDate,_that.type,_that.categoryId,_that.subCategoryId,_that.accountId,_that.createdBy,_that.keyword,_that.amount,_that.source);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime? startDate,  DateTime? endDate,  String? type,  int? categoryId,  int? subCategoryId,  int? accountId,  int? createdBy,  String? keyword,  String? amount,  String? source)?  $default,) {final _that = this;
switch (_that) {
case _TransactionFilter() when $default != null:
return $default(_that.startDate,_that.endDate,_that.type,_that.categoryId,_that.subCategoryId,_that.accountId,_that.createdBy,_that.keyword,_that.amount,_that.source);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionFilter implements TransactionFilter {
  const _TransactionFilter({this.startDate, this.endDate, this.type, this.categoryId, this.subCategoryId, this.accountId, this.createdBy, this.keyword, this.amount, this.source});
  

@override final  DateTime? startDate;
@override final  DateTime? endDate;
@override final  String? type;
@override final  int? categoryId;
@override final  int? subCategoryId;
@override final  int? accountId;
@override final  int? createdBy;
@override final  String? keyword;
@override final  String? amount;
/// `'AUTO'` 只看周期规则自动生成的，`'MANUAL'` 只看手记的，null 不限。
/// 首页那块「今天已自动生成 N 笔」点进来带的就是它。
@override final  String? source;

/// Create a copy of TransactionFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionFilterCopyWith<_TransactionFilter> get copyWith => __$TransactionFilterCopyWithImpl<_TransactionFilter>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionFilter&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.type, type) || other.type == type)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.subCategoryId, subCategoryId) || other.subCategoryId == subCategoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.source, source) || other.source == source));
}


@override
int get hashCode {
    return Object.hash(runtimeType,startDate,endDate,type,categoryId,subCategoryId,accountId,createdBy,keyword,amount,source);
}

@override
String toString() {
    return 'TransactionFilter(startDate: $startDate, endDate: $endDate, type: $type, categoryId: $categoryId, subCategoryId: $subCategoryId, accountId: $accountId, createdBy: $createdBy, keyword: $keyword, amount: $amount, source: $source)';
}


}

/// @nodoc
abstract mixin class _$TransactionFilterCopyWith<$Res> implements $TransactionFilterCopyWith<$Res> {
  factory _$TransactionFilterCopyWith(_TransactionFilter value, $Res Function(_TransactionFilter) _then) = __$TransactionFilterCopyWithImpl;
@override @useResult
$Res call({
 DateTime? startDate, DateTime? endDate, String? type, int? categoryId, int? subCategoryId, int? accountId, int? createdBy, String? keyword, String? amount, String? source
});




}
/// @nodoc
class __$TransactionFilterCopyWithImpl<$Res>
    implements _$TransactionFilterCopyWith<$Res> {
  __$TransactionFilterCopyWithImpl(this._self, this._then);

  final _TransactionFilter _self;
  final $Res Function(_TransactionFilter) _then;

/// Create a copy of TransactionFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = freezed,Object? endDate = freezed,Object? type = freezed,Object? categoryId = freezed,Object? subCategoryId = freezed,Object? accountId = freezed,Object? createdBy = freezed,Object? keyword = freezed,Object? amount = freezed,Object? source = freezed,}) {
  return _then(_TransactionFilter(
startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,subCategoryId: freezed == subCategoryId ? _self.subCategoryId : subCategoryId // ignore: cast_nullable_to_non_nullable
as int?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as int?,keyword: freezed == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$TransactionListState {

 List<TransactionGroup> get groups; int get page; int get pages; bool get hasMore; TransactionFilter get filter; bool get loadingMore;/// 这一屏的数据是本地缓存供的（§5.4）。为 true 时列表顶上挂「离线模式 · 数据截至 …」横幅。
 bool get fromCache;/// 缓存里**最早**那份月份文件的写入时刻。离线时读的是好几个月的文件，取最早的而不是
/// 最晚的，理由写在 `TransactionCacheStore.readRange` 的注释里：宁可悲观也不能谎报新鲜度。
 DateTime? get savedAt;
/// Create a copy of TransactionListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionListStateCopyWith<TransactionListState> get copyWith => _$TransactionListStateCopyWithImpl<TransactionListState>(this as TransactionListState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TransactionListState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionListState&&const DeepCollectionEquality().equals(other.groups, _this.groups)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.pages, _this.pages) || other.pages == _this.pages)&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore)&&(identical(other.filter, _this.filter) || other.filter == _this.filter)&&(identical(other.loadingMore, _this.loadingMore) || other.loadingMore == _this.loadingMore)&&(identical(other.fromCache, _this.fromCache) || other.fromCache == _this.fromCache)&&(identical(other.savedAt, _this.savedAt) || other.savedAt == _this.savedAt));
}


@override
int get hashCode {
  final _this = this as TransactionListState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.groups),_this.page,_this.pages,_this.hasMore,_this.filter,_this.loadingMore,_this.fromCache,_this.savedAt);
}

@override
String toString() {
  final _this = this as TransactionListState;
  return 'TransactionListState(groups: ${_this.groups}, page: ${_this.page}, pages: ${_this.pages}, hasMore: ${_this.hasMore}, filter: ${_this.filter}, loadingMore: ${_this.loadingMore}, fromCache: ${_this.fromCache}, savedAt: ${_this.savedAt})';
}


}

/// @nodoc
abstract mixin class $TransactionListStateCopyWith<$Res>  {
  factory $TransactionListStateCopyWith(TransactionListState value, $Res Function(TransactionListState) _then) = _$TransactionListStateCopyWithImpl;
@useResult
$Res call({
 List<TransactionGroup> groups, int page, int pages, bool hasMore, TransactionFilter filter, bool loadingMore, bool fromCache, DateTime? savedAt
});


$TransactionFilterCopyWith<$Res> get filter;

}
/// @nodoc
class _$TransactionListStateCopyWithImpl<$Res>
    implements $TransactionListStateCopyWith<$Res> {
  _$TransactionListStateCopyWithImpl(this._self, this._then);

  final TransactionListState _self;
  final $Res Function(TransactionListState) _then;

/// Create a copy of TransactionListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groups = null,Object? page = null,Object? pages = null,Object? hasMore = null,Object? filter = null,Object? loadingMore = null,Object? fromCache = null,Object? savedAt = freezed,}) {
  return _then(TransactionListState(
groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as List<TransactionGroup>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as TransactionFilter,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,fromCache: null == fromCache ? _self.fromCache : fromCache // ignore: cast_nullable_to_non_nullable
as bool,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of TransactionListState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionFilterCopyWith<$Res> get filter {
  
  return $TransactionFilterCopyWith<$Res>(_self.filter, (value) {
    return _then(_self.copyWith(filter: value));
  });
}
}


/// Adds pattern-matching-related methods to [TransactionListState].
extension TransactionListStatePatterns on TransactionListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionListState value)  $default,){
final _that = this;
switch (_that) {
case _TransactionListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionListState value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TransactionGroup> groups,  int page,  int pages,  bool hasMore,  TransactionFilter filter,  bool loadingMore,  bool fromCache,  DateTime? savedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionListState() when $default != null:
return $default(_that.groups,_that.page,_that.pages,_that.hasMore,_that.filter,_that.loadingMore,_that.fromCache,_that.savedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TransactionGroup> groups,  int page,  int pages,  bool hasMore,  TransactionFilter filter,  bool loadingMore,  bool fromCache,  DateTime? savedAt)  $default,) {final _that = this;
switch (_that) {
case _TransactionListState():
return $default(_that.groups,_that.page,_that.pages,_that.hasMore,_that.filter,_that.loadingMore,_that.fromCache,_that.savedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TransactionGroup> groups,  int page,  int pages,  bool hasMore,  TransactionFilter filter,  bool loadingMore,  bool fromCache,  DateTime? savedAt)?  $default,) {final _that = this;
switch (_that) {
case _TransactionListState() when $default != null:
return $default(_that.groups,_that.page,_that.pages,_that.hasMore,_that.filter,_that.loadingMore,_that.fromCache,_that.savedAt);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionListState implements TransactionListState {
  const _TransactionListState({ List<TransactionGroup> groups = const <TransactionGroup>[], this.page = 1, this.pages = 0, this.hasMore = false, this.filter = const TransactionFilter(), this.loadingMore = false, this.fromCache = false, this.savedAt}): _groups = groups;
  

 final  List<TransactionGroup> _groups;
@override@JsonKey() List<TransactionGroup> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}

@override@JsonKey() final  int page;
@override@JsonKey() final  int pages;
@override@JsonKey() final  bool hasMore;
@override@JsonKey() final  TransactionFilter filter;
@override@JsonKey() final  bool loadingMore;
/// 这一屏的数据是本地缓存供的（§5.4）。为 true 时列表顶上挂「离线模式 · 数据截至 …」横幅。
@override@JsonKey() final  bool fromCache;
/// 缓存里**最早**那份月份文件的写入时刻。离线时读的是好几个月的文件，取最早的而不是
/// 最晚的，理由写在 `TransactionCacheStore.readRange` 的注释里：宁可悲观也不能谎报新鲜度。
@override final  DateTime? savedAt;

/// Create a copy of TransactionListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionListStateCopyWith<_TransactionListState> get copyWith => __$TransactionListStateCopyWithImpl<_TransactionListState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionListState&&const DeepCollectionEquality().equals(other.groups, _groups)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.loadingMore, loadingMore) || other.loadingMore == loadingMore)&&(identical(other.fromCache, fromCache) || other.fromCache == fromCache)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_groups),page,pages,hasMore,filter,loadingMore,fromCache,savedAt);
}

@override
String toString() {
    return 'TransactionListState(groups: $groups, page: $page, pages: $pages, hasMore: $hasMore, filter: $filter, loadingMore: $loadingMore, fromCache: $fromCache, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class _$TransactionListStateCopyWith<$Res> implements $TransactionListStateCopyWith<$Res> {
  factory _$TransactionListStateCopyWith(_TransactionListState value, $Res Function(_TransactionListState) _then) = __$TransactionListStateCopyWithImpl;
@override @useResult
$Res call({
 List<TransactionGroup> groups, int page, int pages, bool hasMore, TransactionFilter filter, bool loadingMore, bool fromCache, DateTime? savedAt
});


@override $TransactionFilterCopyWith<$Res> get filter;

}
/// @nodoc
class __$TransactionListStateCopyWithImpl<$Res>
    implements _$TransactionListStateCopyWith<$Res> {
  __$TransactionListStateCopyWithImpl(this._self, this._then);

  final _TransactionListState _self;
  final $Res Function(_TransactionListState) _then;

/// Create a copy of TransactionListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groups = null,Object? page = null,Object? pages = null,Object? hasMore = null,Object? filter = null,Object? loadingMore = null,Object? fromCache = null,Object? savedAt = freezed,}) {
  return _then(_TransactionListState(
groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<TransactionGroup>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as TransactionFilter,loadingMore: null == loadingMore ? _self.loadingMore : loadingMore // ignore: cast_nullable_to_non_nullable
as bool,fromCache: null == fromCache ? _self.fromCache : fromCache // ignore: cast_nullable_to_non_nullable
as bool,savedAt: freezed == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of TransactionListState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransactionFilterCopyWith<$Res> get filter {
  
  return $TransactionFilterCopyWith<$Res>(_self.filter, (value) {
    return _then(_self.copyWith(filter: value));
  });
}
}

// dart format on
