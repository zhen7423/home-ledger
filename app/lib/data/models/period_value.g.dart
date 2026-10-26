// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PeriodValue _$PeriodValueFromJson(Map<String, dynamic> json) => _PeriodValue(
  intervalDays: (json['intervalDays'] as num?)?.toInt(),
  weekdays: (json['weekdays'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  daysOfMonth: (json['daysOfMonth'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  month: (json['month'] as num?)?.toInt(),
);

Map<String, dynamic> _$PeriodValueToJson(_PeriodValue instance) =>
    <String, dynamic>{
      'intervalDays': instance.intervalDays,
      'weekdays': instance.weekdays,
      'daysOfMonth': instance.daysOfMonth,
      'month': instance.month,
    };
