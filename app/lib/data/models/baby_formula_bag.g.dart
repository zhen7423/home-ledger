// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baby_formula_bag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BabyFormulaBag _$BabyFormulaBagFromJson(Map<String, dynamic> json) =>
    _BabyFormulaBag(
      id: (json['id'] as num).toInt(),
      brand: json['brand'] as String,
      packGrams: (json['packGrams'] as num).toInt(),
      startedDate: DateTime.parse(json['startedDate'] as String),
      startedTime: json['startedTime'] as String?,
      estimatedDailyGrams: (json['estimatedDailyGrams'] as num?)?.toInt(),
      usageDays: (json['usageDays'] as num?)?.toInt(),
      dailyAverage: (json['dailyAverage'] as num?)?.toInt(),
      current: json['current'] as bool,
      remark: json['remark'] as String?,
    );

Map<String, dynamic> _$BabyFormulaBagToJson(_BabyFormulaBag instance) =>
    <String, dynamic>{
      'id': instance.id,
      'brand': instance.brand,
      'packGrams': instance.packGrams,
      'startedDate': instance.startedDate.toIso8601String(),
      'startedTime': instance.startedTime,
      'estimatedDailyGrams': instance.estimatedDailyGrams,
      'usageDays': instance.usageDays,
      'dailyAverage': instance.dailyAverage,
      'current': instance.current,
      'remark': instance.remark,
    };

_BabyFormulaCurrent _$BabyFormulaCurrentFromJson(Map<String, dynamic> json) =>
    _BabyFormulaCurrent(
      bag: json['bag'] == null
          ? null
          : BabyFormulaBag.fromJson(json['bag'] as Map<String, dynamic>),
      estimate: json['estimate'] == null
          ? null
          : BabyFormulaEstimate.fromJson(
              json['estimate'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$BabyFormulaCurrentToJson(_BabyFormulaCurrent instance) =>
    <String, dynamic>{'bag': instance.bag, 'estimate': instance.estimate};
