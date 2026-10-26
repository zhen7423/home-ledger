// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransactionPage _$TransactionPageFromJson(Map<String, dynamic> json) =>
    _TransactionPage(
      records: (json['records'] as List<dynamic>)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      size: (json['size'] as num).toInt(),
      pages: (json['pages'] as num).toInt(),
      monthSummaries: (json['monthSummaries'] as List<dynamic>)
          .map((e) => MonthSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TransactionPageToJson(_TransactionPage instance) =>
    <String, dynamic>{
      'records': instance.records,
      'total': instance.total,
      'page': instance.page,
      'size': instance.size,
      'pages': instance.pages,
      'monthSummaries': instance.monthSummaries,
    };
