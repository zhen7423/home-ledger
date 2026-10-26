// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cat_food_estimate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatFoodEstimate _$CatFoodEstimateFromJson(Map<String, dynamic> json) =>
    _CatFoodEstimate(
      usedDays: (json['usedDays'] as num).toInt(),
      dailyAverage: (json['dailyAverage'] as num).toInt(),
      consumedGrams: (json['consumedGrams'] as num).toInt(),
      remainingGrams: (json['remainingGrams'] as num).toInt(),
      remainingPercent: (json['remainingPercent'] as num).toInt(),
      daysLeft: (json['daysLeft'] as num).toInt(),
      depletionDate: DateTime.parse(json['depletionDate'] as String),
      fromHistory: json['fromHistory'] as bool,
      overEstimate: json['overEstimate'] as bool,
    );

Map<String, dynamic> _$CatFoodEstimateToJson(_CatFoodEstimate instance) =>
    <String, dynamic>{
      'usedDays': instance.usedDays,
      'dailyAverage': instance.dailyAverage,
      'consumedGrams': instance.consumedGrams,
      'remainingGrams': instance.remainingGrams,
      'remainingPercent': instance.remainingPercent,
      'daysLeft': instance.daysLeft,
      'depletionDate': instance.depletionDate.toIso8601String(),
      'fromHistory': instance.fromHistory,
      'overEstimate': instance.overEstimate,
    };
