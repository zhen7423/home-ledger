// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baby_formula_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BabyFormulaStatistics _$BabyFormulaStatisticsFromJson(
  Map<String, dynamic> json,
) => _BabyFormulaStatistics(
  totalGrams: (json['totalGrams'] as num).toInt(),
  totalDays: (json['totalDays'] as num).toInt(),
  dailyAverage: (json['dailyAverage'] as num).toInt(),
  monthlyTrend:
      (json['monthlyTrend'] as List<dynamic>?)
          ?.map(
            (e) => BabyFormulaMonthGrams.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <BabyFormulaMonthGrams>[],
);

Map<String, dynamic> _$BabyFormulaStatisticsToJson(
  _BabyFormulaStatistics instance,
) => <String, dynamic>{
  'totalGrams': instance.totalGrams,
  'totalDays': instance.totalDays,
  'dailyAverage': instance.dailyAverage,
  'monthlyTrend': instance.monthlyTrend,
};

_BabyFormulaMonthGrams _$BabyFormulaMonthGramsFromJson(
  Map<String, dynamic> json,
) => _BabyFormulaMonthGrams(
  month: json['month'] as String,
  grams: (json['grams'] as num).toInt(),
);

Map<String, dynamic> _$BabyFormulaMonthGramsToJson(
  _BabyFormulaMonthGrams instance,
) => <String, dynamic>{'month': instance.month, 'grams': instance.grams};
