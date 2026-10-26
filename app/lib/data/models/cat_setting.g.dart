// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cat_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatSetting _$CatSettingFromJson(Map<String, dynamic> json) => _CatSetting(
  internalMonths: (json['internalMonths'] as num?)?.toInt() ?? 3,
  externalMonths: (json['externalMonths'] as num?)?.toInt() ?? 1,
  estimatedDailyGrams: (json['estimatedDailyGrams'] as num?)?.toInt(),
  estimateTakenOverByHistory:
      json['estimateTakenOverByHistory'] as bool? ?? false,
);

Map<String, dynamic> _$CatSettingToJson(_CatSetting instance) =>
    <String, dynamic>{
      'internalMonths': instance.internalMonths,
      'externalMonths': instance.externalMonths,
      'estimatedDailyGrams': instance.estimatedDailyGrams,
      'estimateTakenOverByHistory': instance.estimateTakenOverByHistory,
    };
