// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BudgetProgress _$BudgetProgressFromJson(Map<String, dynamic> json) =>
    _BudgetProgress(
      month: json['month'] as String,
      scope: json['scope'] as String,
      categoryId: (json['categoryId'] as num?)?.toInt(),
      categoryName: json['categoryName'] as String?,
      memberUserId: (json['memberUserId'] as num?)?.toInt(),
      memberName: json['memberName'] as String?,
      amount: json['amount'] as String,
      used: json['used'] as String,
      remaining: json['remaining'] as String,
      usedPercent: (json['usedPercent'] as num).toInt(),
      level: json['level'] as String,
      remainingDays: (json['remainingDays'] as num).toInt(),
    );

Map<String, dynamic> _$BudgetProgressToJson(_BudgetProgress instance) =>
    <String, dynamic>{
      'month': instance.month,
      'scope': instance.scope,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'memberUserId': instance.memberUserId,
      'memberName': instance.memberName,
      'amount': instance.amount,
      'used': instance.used,
      'remaining': instance.remaining,
      'usedPercent': instance.usedPercent,
      'level': instance.level,
      'remainingDays': instance.remainingDays,
    };
