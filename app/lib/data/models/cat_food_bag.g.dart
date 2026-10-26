// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cat_food_bag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatFoodBag _$CatFoodBagFromJson(Map<String, dynamic> json) => _CatFoodBag(
  id: (json['id'] as num).toInt(),
  brand: json['brand'] as String,
  packGrams: (json['packGrams'] as num).toInt(),
  startedDate: DateTime.parse(json['startedDate'] as String),
  usageDays: (json['usageDays'] as num?)?.toInt(),
  dailyAverage: (json['dailyAverage'] as num?)?.toInt(),
  current: json['current'] as bool,
  remark: json['remark'] as String?,
);

Map<String, dynamic> _$CatFoodBagToJson(_CatFoodBag instance) =>
    <String, dynamic>{
      'id': instance.id,
      'brand': instance.brand,
      'packGrams': instance.packGrams,
      'startedDate': instance.startedDate.toIso8601String(),
      'usageDays': instance.usageDays,
      'dailyAverage': instance.dailyAverage,
      'current': instance.current,
      'remark': instance.remark,
    };

_CatFoodCurrent _$CatFoodCurrentFromJson(Map<String, dynamic> json) =>
    _CatFoodCurrent(
      bag: json['bag'] == null
          ? null
          : CatFoodBag.fromJson(json['bag'] as Map<String, dynamic>),
      estimate: json['estimate'] == null
          ? null
          : CatFoodEstimate.fromJson(json['estimate'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CatFoodCurrentToJson(_CatFoodCurrent instance) =>
    <String, dynamic>{'bag': instance.bag, 'estimate': instance.estimate};
