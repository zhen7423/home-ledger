// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'month_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MonthSummary _$MonthSummaryFromJson(Map<String, dynamic> json) =>
    _MonthSummary(
      month: json['month'] as String,
      income: json['income'] as String,
      expense: json['expense'] as String,
      balance: json['balance'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$MonthSummaryToJson(_MonthSummary instance) =>
    <String, dynamic>{
      'month': instance.month,
      'income': instance.income,
      'expense': instance.expense,
      'balance': instance.balance,
      'count': instance.count,
    };
