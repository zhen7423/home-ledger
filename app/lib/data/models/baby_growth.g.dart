// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baby_growth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BabyGrowth _$BabyGrowthFromJson(Map<String, dynamic> json) => _BabyGrowth(
  id: (json['id'] as num).toInt(),
  babyId: (json['babyId'] as num).toInt(),
  measureDate: DateTime.parse(json['measureDate'] as String),
  heightCm: json['heightCm'] as String?,
  weightKg: json['weightKg'] as String?,
  headCm: json['headCm'] as String?,
  remark: json['remark'] as String?,
  deltaFromPrevious: json['deltaFromPrevious'] == null
      ? null
      : BabyGrowthDelta.fromJson(
          json['deltaFromPrevious'] as Map<String, dynamic>,
        ),
  percentiles: json['percentiles'] == null
      ? null
      : BabyPercentiles.fromJson(json['percentiles'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BabyGrowthToJson(_BabyGrowth instance) =>
    <String, dynamic>{
      'id': instance.id,
      'babyId': instance.babyId,
      'measureDate': instance.measureDate.toIso8601String(),
      'heightCm': instance.heightCm,
      'weightKg': instance.weightKg,
      'headCm': instance.headCm,
      'remark': instance.remark,
      'deltaFromPrevious': instance.deltaFromPrevious,
      'percentiles': instance.percentiles,
    };

_BabyPercentiles _$BabyPercentilesFromJson(Map<String, dynamic> json) =>
    _BabyPercentiles(
      height: json['height'] as String?,
      weight: json['weight'] as String?,
      weightHeight: json['weightHeight'] as String?,
      bmi: json['bmi'] as String?,
      headCircumference: json['headCircumference'] as String?,
    );

Map<String, dynamic> _$BabyPercentilesToJson(_BabyPercentiles instance) =>
    <String, dynamic>{
      'height': instance.height,
      'weight': instance.weight,
      'weightHeight': instance.weightHeight,
      'bmi': instance.bmi,
      'headCircumference': instance.headCircumference,
    };

_BabyGrowthDelta _$BabyGrowthDeltaFromJson(Map<String, dynamic> json) =>
    _BabyGrowthDelta(
      days: (json['days'] as num?)?.toInt(),
      heightCm: json['heightCm'] as String?,
      weightKg: json['weightKg'] as String?,
      headCm: json['headCm'] as String?,
    );

Map<String, dynamic> _$BabyGrowthDeltaToJson(_BabyGrowthDelta instance) =>
    <String, dynamic>{
      'days': instance.days,
      'heightCm': instance.heightCm,
      'weightKg': instance.weightKg,
      'headCm': instance.headCm,
    };

_BabyCurve _$BabyCurveFromJson(Map<String, dynamic> json) => _BabyCurve(
  babyId: (json['babyId'] as num).toInt(),
  metric: json['metric'] as String,
  standardMetric: json['standardMetric'] as String,
  points:
      (json['points'] as List<dynamic>?)
          ?.map((e) => BabyCurvePoint.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BabyCurvePoint>[],
  standard:
      (json['standard'] as List<dynamic>?)
          ?.map((e) => GrowthStandardRow.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <GrowthStandardRow>[],
  disclaimer: json['disclaimer'] as String,
);

Map<String, dynamic> _$BabyCurveToJson(_BabyCurve instance) =>
    <String, dynamic>{
      'babyId': instance.babyId,
      'metric': instance.metric,
      'standardMetric': instance.standardMetric,
      'points': instance.points,
      'standard': instance.standard,
      'disclaimer': instance.disclaimer,
    };

_BabyCurvePoint _$BabyCurvePointFromJson(Map<String, dynamic> json) =>
    _BabyCurvePoint(
      measureDate: DateTime.parse(json['measureDate'] as String),
      ageMonths: (json['ageMonths'] as num).toInt(),
      xValue: (json['xValue'] as num).toDouble(),
      measured: (json['measured'] as num).toDouble(),
      percentileBand: json['percentileBand'] as String?,
    );

Map<String, dynamic> _$BabyCurvePointToJson(_BabyCurvePoint instance) =>
    <String, dynamic>{
      'measureDate': instance.measureDate.toIso8601String(),
      'ageMonths': instance.ageMonths,
      'xValue': instance.xValue,
      'measured': instance.measured,
      'percentileBand': instance.percentileBand,
    };

_GrowthStandardRow _$GrowthStandardRowFromJson(Map<String, dynamic> json) =>
    _GrowthStandardRow(
      xValue: (json['xValue'] as num).toDouble(),
      p3: (json['p3'] as num).toDouble(),
      p10: (json['p10'] as num).toDouble(),
      p25: (json['p25'] as num).toDouble(),
      p50: (json['p50'] as num).toDouble(),
      p75: (json['p75'] as num).toDouble(),
      p90: (json['p90'] as num).toDouble(),
      p97: (json['p97'] as num).toDouble(),
    );

Map<String, dynamic> _$GrowthStandardRowToJson(_GrowthStandardRow instance) =>
    <String, dynamic>{
      'xValue': instance.xValue,
      'p3': instance.p3,
      'p10': instance.p10,
      'p25': instance.p25,
      'p50': instance.p50,
      'p75': instance.p75,
      'p90': instance.p90,
      'p97': instance.p97,
    };
