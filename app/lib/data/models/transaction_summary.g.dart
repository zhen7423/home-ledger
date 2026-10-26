// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransactionSummary _$TransactionSummaryFromJson(Map<String, dynamic> json) =>
    _TransactionSummary(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      days: (json['days'] as num).toInt(),
      income: json['income'] as String,
      expense: json['expense'] as String,
      balance: json['balance'] as String,
      dailyAverageExpense: json['dailyAverageExpense'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$TransactionSummaryToJson(_TransactionSummary instance) =>
    <String, dynamic>{
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'days': instance.days,
      'income': instance.income,
      'expense': instance.expense,
      'balance': instance.balance,
      'dailyAverageExpense': instance.dailyAverageExpense,
      'count': instance.count,
    };
