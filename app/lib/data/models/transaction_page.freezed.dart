// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TransactionPage {

 List<Transaction> get records; int get total; int get page; int get size; int get pages; List<MonthSummary> get monthSummaries;
/// Create a copy of TransactionPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionPageCopyWith<TransactionPage> get copyWith => _$TransactionPageCopyWithImpl<TransactionPage>(this as TransactionPage, _$identity);

  /// Serializes this TransactionPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TransactionPage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionPage&&const DeepCollectionEquality().equals(other.records, _this.records)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.pages, _this.pages) || other.pages == _this.pages)&&const DeepCollectionEquality().equals(other.monthSummaries, _this.monthSummaries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TransactionPage;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.records),_this.total,_this.page,_this.size,_this.pages,const DeepCollectionEquality().hash(_this.monthSummaries));
}

@override
String toString() {
  final _this = this as TransactionPage;
  return 'TransactionPage(records: ${_this.records}, total: ${_this.total}, page: ${_this.page}, size: ${_this.size}, pages: ${_this.pages}, monthSummaries: ${_this.monthSummaries})';
}


}

/// @nodoc
abstract mixin class $TransactionPageCopyWith<$Res>  {
  factory $TransactionPageCopyWith(TransactionPage value, $Res Function(TransactionPage) _then) = _$TransactionPageCopyWithImpl;
@useResult
$Res call({
 List<Transaction> records, int total, int page, int size, int pages, List<MonthSummary> monthSummaries
});




}
/// @nodoc
class _$TransactionPageCopyWithImpl<$Res>
    implements $TransactionPageCopyWith<$Res> {
  _$TransactionPageCopyWithImpl(this._self, this._then);

  final TransactionPage _self;
  final $Res Function(TransactionPage) _then;

/// Create a copy of TransactionPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? records = null,Object? total = null,Object? page = null,Object? size = null,Object? pages = null,Object? monthSummaries = null,}) {
  return _then(TransactionPage(
records: null == records ? _self.records : records // ignore: cast_nullable_to_non_nullable
as List<Transaction>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,monthSummaries: null == monthSummaries ? _self.monthSummaries : monthSummaries // ignore: cast_nullable_to_non_nullable
as List<MonthSummary>,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionPage].
extension TransactionPagePatterns on TransactionPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionPage value)  $default,){
final _that = this;
switch (_that) {
case _TransactionPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionPage value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Transaction> records,  int total,  int page,  int size,  int pages,  List<MonthSummary> monthSummaries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionPage() when $default != null:
return $default(_that.records,_that.total,_that.page,_that.size,_that.pages,_that.monthSummaries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Transaction> records,  int total,  int page,  int size,  int pages,  List<MonthSummary> monthSummaries)  $default,) {final _that = this;
switch (_that) {
case _TransactionPage():
return $default(_that.records,_that.total,_that.page,_that.size,_that.pages,_that.monthSummaries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Transaction> records,  int total,  int page,  int size,  int pages,  List<MonthSummary> monthSummaries)?  $default,) {final _that = this;
switch (_that) {
case _TransactionPage() when $default != null:
return $default(_that.records,_that.total,_that.page,_that.size,_that.pages,_that.monthSummaries);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransactionPage implements TransactionPage {
  const _TransactionPage({required  List<Transaction> records, required this.total, required this.page, required this.size, required this.pages, required  List<MonthSummary> monthSummaries}): _records = records,_monthSummaries = monthSummaries;
  factory _TransactionPage.fromJson(Map<String, dynamic> json) => _$TransactionPageFromJson(json);

 final  List<Transaction> _records;
@override List<Transaction> get records {
  if (_records is EqualUnmodifiableListView) return _records;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_records);
}

@override final  int total;
@override final  int page;
@override final  int size;
@override final  int pages;
 final  List<MonthSummary> _monthSummaries;
@override List<MonthSummary> get monthSummaries {
  if (_monthSummaries is EqualUnmodifiableListView) return _monthSummaries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_monthSummaries);
}


/// Create a copy of TransactionPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionPageCopyWith<_TransactionPage> get copyWith => __$TransactionPageCopyWithImpl<_TransactionPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransactionPageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionPage&&const DeepCollectionEquality().equals(other.records, _records)&&(identical(other.total, total) || other.total == total)&&(identical(other.page, page) || other.page == page)&&(identical(other.size, size) || other.size == size)&&(identical(other.pages, pages) || other.pages == pages)&&const DeepCollectionEquality().equals(other.monthSummaries, _monthSummaries));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_records),total,page,size,pages,const DeepCollectionEquality().hash(_monthSummaries));
}

@override
String toString() {
    return 'TransactionPage(records: $records, total: $total, page: $page, size: $size, pages: $pages, monthSummaries: $monthSummaries)';
}


}

/// @nodoc
abstract mixin class _$TransactionPageCopyWith<$Res> implements $TransactionPageCopyWith<$Res> {
  factory _$TransactionPageCopyWith(_TransactionPage value, $Res Function(_TransactionPage) _then) = __$TransactionPageCopyWithImpl;
@override @useResult
$Res call({
 List<Transaction> records, int total, int page, int size, int pages, List<MonthSummary> monthSummaries
});




}
/// @nodoc
class __$TransactionPageCopyWithImpl<$Res>
    implements _$TransactionPageCopyWith<$Res> {
  __$TransactionPageCopyWithImpl(this._self, this._then);

  final _TransactionPage _self;
  final $Res Function(_TransactionPage) _then;

/// Create a copy of TransactionPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? records = null,Object? total = null,Object? page = null,Object? size = null,Object? pages = null,Object? monthSummaries = null,}) {
  return _then(_TransactionPage(
records: null == records ? _self._records : records // ignore: cast_nullable_to_non_nullable
as List<Transaction>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,monthSummaries: null == monthSummaries ? _self._monthSummaries : monthSummaries // ignore: cast_nullable_to_non_nullable
as List<MonthSummary>,
  ));
}


}

/// @nodoc
mixin _$TransactionPageQuery {

 String? get startDate; String? get endDate; String? get type; int? get categoryId; int? get subCategoryId; int? get accountId; int? get createdBy; String? get keyword; String? get amount; String? get source; int get page; int get size;
/// Create a copy of TransactionPageQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionPageQueryCopyWith<TransactionPageQuery> get copyWith => _$TransactionPageQueryCopyWithImpl<TransactionPageQuery>(this as TransactionPageQuery, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TransactionPageQuery;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransactionPageQuery&&(identical(other.startDate, _this.startDate) || other.startDate == _this.startDate)&&(identical(other.endDate, _this.endDate) || other.endDate == _this.endDate)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.subCategoryId, _this.subCategoryId) || other.subCategoryId == _this.subCategoryId)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.keyword, _this.keyword) || other.keyword == _this.keyword)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.size, _this.size) || other.size == _this.size));
}


@override
int get hashCode {
  final _this = this as TransactionPageQuery;
  return Object.hash(runtimeType,_this.startDate,_this.endDate,_this.type,_this.categoryId,_this.subCategoryId,_this.accountId,_this.createdBy,_this.keyword,_this.amount,_this.source,_this.page,_this.size);
}

@override
String toString() {
  final _this = this as TransactionPageQuery;
  return 'TransactionPageQuery(startDate: ${_this.startDate}, endDate: ${_this.endDate}, type: ${_this.type}, categoryId: ${_this.categoryId}, subCategoryId: ${_this.subCategoryId}, accountId: ${_this.accountId}, createdBy: ${_this.createdBy}, keyword: ${_this.keyword}, amount: ${_this.amount}, source: ${_this.source}, page: ${_this.page}, size: ${_this.size})';
}


}

/// @nodoc
abstract mixin class $TransactionPageQueryCopyWith<$Res>  {
  factory $TransactionPageQueryCopyWith(TransactionPageQuery value, $Res Function(TransactionPageQuery) _then) = _$TransactionPageQueryCopyWithImpl;
@useResult
$Res call({
 String? startDate, String? endDate, String? type, int? categoryId, int? subCategoryId, int? accountId, int? createdBy, String? keyword, String? amount, String? source, int page, int size
});




}
/// @nodoc
class _$TransactionPageQueryCopyWithImpl<$Res>
    implements $TransactionPageQueryCopyWith<$Res> {
  _$TransactionPageQueryCopyWithImpl(this._self, this._then);

  final TransactionPageQuery _self;
  final $Res Function(TransactionPageQuery) _then;

/// Create a copy of TransactionPageQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = freezed,Object? endDate = freezed,Object? type = freezed,Object? categoryId = freezed,Object? subCategoryId = freezed,Object? accountId = freezed,Object? createdBy = freezed,Object? keyword = freezed,Object? amount = freezed,Object? source = freezed,Object? page = null,Object? size = null,}) {
  return _then(TransactionPageQuery(
startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,subCategoryId: freezed == subCategoryId ? _self.subCategoryId : subCategoryId // ignore: cast_nullable_to_non_nullable
as int?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as int?,keyword: freezed == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TransactionPageQuery].
extension TransactionPageQueryPatterns on TransactionPageQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransactionPageQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransactionPageQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransactionPageQuery value)  $default,){
final _that = this;
switch (_that) {
case _TransactionPageQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransactionPageQuery value)?  $default,){
final _that = this;
switch (_that) {
case _TransactionPageQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? startDate,  String? endDate,  String? type,  int? categoryId,  int? subCategoryId,  int? accountId,  int? createdBy,  String? keyword,  String? amount,  String? source,  int page,  int size)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransactionPageQuery() when $default != null:
return $default(_that.startDate,_that.endDate,_that.type,_that.categoryId,_that.subCategoryId,_that.accountId,_that.createdBy,_that.keyword,_that.amount,_that.source,_that.page,_that.size);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? startDate,  String? endDate,  String? type,  int? categoryId,  int? subCategoryId,  int? accountId,  int? createdBy,  String? keyword,  String? amount,  String? source,  int page,  int size)  $default,) {final _that = this;
switch (_that) {
case _TransactionPageQuery():
return $default(_that.startDate,_that.endDate,_that.type,_that.categoryId,_that.subCategoryId,_that.accountId,_that.createdBy,_that.keyword,_that.amount,_that.source,_that.page,_that.size);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? startDate,  String? endDate,  String? type,  int? categoryId,  int? subCategoryId,  int? accountId,  int? createdBy,  String? keyword,  String? amount,  String? source,  int page,  int size)?  $default,) {final _that = this;
switch (_that) {
case _TransactionPageQuery() when $default != null:
return $default(_that.startDate,_that.endDate,_that.type,_that.categoryId,_that.subCategoryId,_that.accountId,_that.createdBy,_that.keyword,_that.amount,_that.source,_that.page,_that.size);case _:
  return null;

}
}

}

/// @nodoc


class _TransactionPageQuery extends TransactionPageQuery {
  const _TransactionPageQuery({this.startDate, this.endDate, this.type, this.categoryId, this.subCategoryId, this.accountId, this.createdBy, this.keyword, this.amount, this.source, this.page = 1, this.size = 30}): super._();
  

@override final  String? startDate;
@override final  String? endDate;
@override final  String? type;
@override final  int? categoryId;
@override final  int? subCategoryId;
@override final  int? accountId;
@override final  int? createdBy;
@override final  String? keyword;
@override final  String? amount;
@override final  String? source;
@override@JsonKey() final  int page;
@override@JsonKey() final  int size;

/// Create a copy of TransactionPageQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionPageQueryCopyWith<_TransactionPageQuery> get copyWith => __$TransactionPageQueryCopyWithImpl<_TransactionPageQuery>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransactionPageQuery&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.type, type) || other.type == type)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.subCategoryId, subCategoryId) || other.subCategoryId == subCategoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.source, source) || other.source == source)&&(identical(other.page, page) || other.page == page)&&(identical(other.size, size) || other.size == size));
}


@override
int get hashCode {
    return Object.hash(runtimeType,startDate,endDate,type,categoryId,subCategoryId,accountId,createdBy,keyword,amount,source,page,size);
}

@override
String toString() {
    return 'TransactionPageQuery(startDate: $startDate, endDate: $endDate, type: $type, categoryId: $categoryId, subCategoryId: $subCategoryId, accountId: $accountId, createdBy: $createdBy, keyword: $keyword, amount: $amount, source: $source, page: $page, size: $size)';
}


}

/// @nodoc
abstract mixin class _$TransactionPageQueryCopyWith<$Res> implements $TransactionPageQueryCopyWith<$Res> {
  factory _$TransactionPageQueryCopyWith(_TransactionPageQuery value, $Res Function(_TransactionPageQuery) _then) = __$TransactionPageQueryCopyWithImpl;
@override @useResult
$Res call({
 String? startDate, String? endDate, String? type, int? categoryId, int? subCategoryId, int? accountId, int? createdBy, String? keyword, String? amount, String? source, int page, int size
});




}
/// @nodoc
class __$TransactionPageQueryCopyWithImpl<$Res>
    implements _$TransactionPageQueryCopyWith<$Res> {
  __$TransactionPageQueryCopyWithImpl(this._self, this._then);

  final _TransactionPageQuery _self;
  final $Res Function(_TransactionPageQuery) _then;

/// Create a copy of TransactionPageQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = freezed,Object? endDate = freezed,Object? type = freezed,Object? categoryId = freezed,Object? subCategoryId = freezed,Object? accountId = freezed,Object? createdBy = freezed,Object? keyword = freezed,Object? amount = freezed,Object? source = freezed,Object? page = null,Object? size = null,}) {
  return _then(_TransactionPageQuery(
startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,subCategoryId: freezed == subCategoryId ? _self.subCategoryId : subCategoryId // ignore: cast_nullable_to_non_nullable
as int?,accountId: freezed == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int?,createdBy: freezed == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as int?,keyword: freezed == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
