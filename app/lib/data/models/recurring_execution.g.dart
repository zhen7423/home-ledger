// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_execution.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecurringExecution _$RecurringExecutionFromJson(Map<String, dynamic> json) =>
    _RecurringExecution(
      id: (json['id'] as num).toInt(),
      bizDate: DateTime.parse(json['bizDate'] as String),
      transactionId: (json['transactionId'] as num).toInt(),
      executedDate: DateTime.parse(json['executedDate'] as String),
      backfilled: json['backfilled'] as bool,
    );

Map<String, dynamic> _$RecurringExecutionToJson(_RecurringExecution instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bizDate': instance.bizDate.toIso8601String(),
      'transactionId': instance.transactionId,
      'executedDate': instance.executedDate.toIso8601String(),
      'backfilled': instance.backfilled,
    };
