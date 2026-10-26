// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cat_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatFoodStatisticsQuery _$CatFoodStatisticsQueryFromJson(
  Map<String, dynamic> json,
) => _CatFoodStatisticsQuery(
  startDate: json['startDate'] as String?,
  endDate: json['endDate'] as String?,
);

Map<String, dynamic> _$CatFoodStatisticsQueryToJson(
  _CatFoodStatisticsQuery instance,
) => <String, dynamic>{
  'startDate': instance.startDate,
  'endDate': instance.endDate,
};

_CatFoodConsumption _$CatFoodConsumptionFromJson(Map<String, dynamic> json) =>
    _CatFoodConsumption(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      days: (json['days'] as num).toInt(),
      totalGrams: (json['totalGrams'] as num).toInt(),
      dailyAverage: (json['dailyAverage'] as num).toInt(),
      finishedBags: (json['finishedBags'] as num).toInt(),
      brandBreakdown:
          (json['brandBreakdown'] as List<dynamic>?)
              ?.map((e) => CatBrandSlice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CatBrandSlice>[],
      monthlyTrend:
          (json['monthlyTrend'] as List<dynamic>?)
              ?.map((e) => CatMonthGrams.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CatMonthGrams>[],
      bagUsages:
          (json['bagUsages'] as List<dynamic>?)
              ?.map((e) => CatFoodBag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CatFoodBag>[],
    );

Map<String, dynamic> _$CatFoodConsumptionToJson(_CatFoodConsumption instance) =>
    <String, dynamic>{
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'days': instance.days,
      'totalGrams': instance.totalGrams,
      'dailyAverage': instance.dailyAverage,
      'finishedBags': instance.finishedBags,
      'brandBreakdown': instance.brandBreakdown,
      'monthlyTrend': instance.monthlyTrend,
      'bagUsages': instance.bagUsages,
    };

_CatBrandSlice _$CatBrandSliceFromJson(Map<String, dynamic> json) =>
    _CatBrandSlice(
      brand: json['brand'] as String,
      grams: (json['grams'] as num).toInt(),
      percent: (json['percent'] as num).toInt(),
    );

Map<String, dynamic> _$CatBrandSliceToJson(_CatBrandSlice instance) =>
    <String, dynamic>{
      'brand': instance.brand,
      'grams': instance.grams,
      'percent': instance.percent,
    };

_CatMonthGrams _$CatMonthGramsFromJson(Map<String, dynamic> json) =>
    _CatMonthGrams(
      month: json['month'] as String,
      grams: (json['grams'] as num).toInt(),
    );

Map<String, dynamic> _$CatMonthGramsToJson(_CatMonthGrams instance) =>
    <String, dynamic>{'month': instance.month, 'grams': instance.grams};

_CatDewormingStatistics _$CatDewormingStatisticsFromJson(
  Map<String, dynamic> json,
) => _CatDewormingStatistics(
  windowStart: DateTime.parse(json['windowStart'] as String),
  windowEnd: DateTime.parse(json['windowEnd'] as String),
  completion:
      (json['completion'] as List<dynamic>?)
          ?.map(
            (e) => CatDewormingCompletion.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <CatDewormingCompletion>[],
  timeline:
      (json['timeline'] as List<dynamic>?)
          ?.map(
            (e) => CatDewormingTimelineItem.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <CatDewormingTimelineItem>[],
  dueCountdown:
      (json['dueCountdown'] as List<dynamic>?)
          ?.map((e) => CatDueCountdownItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CatDueCountdownItem>[],
);

Map<String, dynamic> _$CatDewormingStatisticsToJson(
  _CatDewormingStatistics instance,
) => <String, dynamic>{
  'windowStart': instance.windowStart.toIso8601String(),
  'windowEnd': instance.windowEnd.toIso8601String(),
  'completion': instance.completion,
  'timeline': instance.timeline,
  'dueCountdown': instance.dueCountdown,
};

_CatDewormingCompletion _$CatDewormingCompletionFromJson(
  Map<String, dynamic> json,
) => _CatDewormingCompletion(
  catId: (json['catId'] as num).toInt(),
  catName: json['catName'] as String,
  type: json['type'] as String,
  due: (json['due'] as num).toInt(),
  done: (json['done'] as num).toInt(),
  rate: (json['rate'] as num).toInt(),
  overdueDays: (json['overdueDays'] as num?)?.toInt(),
);

Map<String, dynamic> _$CatDewormingCompletionToJson(
  _CatDewormingCompletion instance,
) => <String, dynamic>{
  'catId': instance.catId,
  'catName': instance.catName,
  'type': instance.type,
  'due': instance.due,
  'done': instance.done,
  'rate': instance.rate,
  'overdueDays': instance.overdueDays,
};

_CatDewormingTimelineItem _$CatDewormingTimelineItemFromJson(
  Map<String, dynamic> json,
) => _CatDewormingTimelineItem(
  catId: (json['catId'] as num).toInt(),
  catName: json['catName'] as String,
  type: json['type'] as String,
  doneDate: DateTime.parse(json['doneDate'] as String),
  medicine: json['medicine'] as String?,
);

Map<String, dynamic> _$CatDewormingTimelineItemToJson(
  _CatDewormingTimelineItem instance,
) => <String, dynamic>{
  'catId': instance.catId,
  'catName': instance.catName,
  'type': instance.type,
  'doneDate': instance.doneDate.toIso8601String(),
  'medicine': instance.medicine,
};

_CatDueCountdownItem _$CatDueCountdownItemFromJson(Map<String, dynamic> json) =>
    _CatDueCountdownItem(
      catId: (json['catId'] as num).toInt(),
      catName: json['catName'] as String,
      type: json['type'] as String,
      nextDate: DateTime.parse(json['nextDate'] as String),
      daysToDue: (json['daysToDue'] as num?)?.toInt(),
      overdueDays: (json['overdueDays'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CatDueCountdownItemToJson(
  _CatDueCountdownItem instance,
) => <String, dynamic>{
  'catId': instance.catId,
  'catName': instance.catName,
  'type': instance.type,
  'nextDate': instance.nextDate.toIso8601String(),
  'daysToDue': instance.daysToDue,
  'overdueDays': instance.overdueDays,
};
