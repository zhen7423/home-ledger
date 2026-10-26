// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baby_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BabyGrowthStatistics _$BabyGrowthStatisticsFromJson(
  Map<String, dynamic> json,
) => _BabyGrowthStatistics(
  perBaby:
      (json['perBaby'] as List<dynamic>?)
          ?.map((e) => BabyGrowthItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BabyGrowthItem>[],
);

Map<String, dynamic> _$BabyGrowthStatisticsToJson(
  _BabyGrowthStatistics instance,
) => <String, dynamic>{'perBaby': instance.perBaby};

_BabyGrowthItem _$BabyGrowthItemFromJson(Map<String, dynamic> json) =>
    _BabyGrowthItem(
      babyId: (json['babyId'] as num).toInt(),
      name: json['name'] as String,
      ageText: json['ageText'] as String,
      latest: json['latest'] == null
          ? null
          : BabyGrowthLatest.fromJson(json['latest'] as Map<String, dynamic>),
      growth: BabyGrowthWindows.fromJson(
        json['growth'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$BabyGrowthItemToJson(_BabyGrowthItem instance) =>
    <String, dynamic>{
      'babyId': instance.babyId,
      'name': instance.name,
      'ageText': instance.ageText,
      'latest': instance.latest,
      'growth': instance.growth,
    };

_BabyGrowthLatest _$BabyGrowthLatestFromJson(Map<String, dynamic> json) =>
    _BabyGrowthLatest(
      measureDate: DateTime.parse(json['measureDate'] as String),
      heightCm: json['heightCm'] as String?,
      weightKg: json['weightKg'] as String?,
      headCm: json['headCm'] as String?,
      bands: BabyPercentileBands.fromJson(
        json['bands'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$BabyGrowthLatestToJson(_BabyGrowthLatest instance) =>
    <String, dynamic>{
      'measureDate': instance.measureDate.toIso8601String(),
      'heightCm': instance.heightCm,
      'weightKg': instance.weightKg,
      'headCm': instance.headCm,
      'bands': instance.bands,
    };

_BabyPercentileBands _$BabyPercentileBandsFromJson(Map<String, dynamic> json) =>
    _BabyPercentileBands(
      height: json['height'] as String?,
      weight: json['weight'] as String?,
      weightHeight: json['weightHeight'] as String?,
      bmi: json['bmi'] as String?,
      headCircumference: json['headCircumference'] as String?,
    );

Map<String, dynamic> _$BabyPercentileBandsToJson(
  _BabyPercentileBands instance,
) => <String, dynamic>{
  'height': instance.height,
  'weight': instance.weight,
  'weightHeight': instance.weightHeight,
  'bmi': instance.bmi,
  'headCircumference': instance.headCircumference,
};

_BabyGrowthWindows _$BabyGrowthWindowsFromJson(
  Map<String, dynamic> json,
) => _BabyGrowthWindows(
  sinceLast: json['sinceLast'] == null
      ? null
      : BabyGrowthGain.fromJson(json['sinceLast'] as Map<String, dynamic>),
  last3Months: json['last3Months'] == null
      ? null
      : BabyGrowthGain.fromJson(json['last3Months'] as Map<String, dynamic>),
  last12Months: json['last12Months'] == null
      ? null
      : BabyGrowthGain.fromJson(json['last12Months'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BabyGrowthWindowsToJson(_BabyGrowthWindows instance) =>
    <String, dynamic>{
      'sinceLast': instance.sinceLast,
      'last3Months': instance.last3Months,
      'last12Months': instance.last12Months,
    };

_BabyGrowthGain _$BabyGrowthGainFromJson(Map<String, dynamic> json) =>
    _BabyGrowthGain(
      days: (json['days'] as num).toInt(),
      heightCm: json['heightCm'] as String?,
      weightKg: json['weightKg'] as String?,
      headCm: json['headCm'] as String?,
    );

Map<String, dynamic> _$BabyGrowthGainToJson(_BabyGrowthGain instance) =>
    <String, dynamic>{
      'days': instance.days,
      'heightCm': instance.heightCm,
      'weightKg': instance.weightKg,
      'headCm': instance.headCm,
    };

_BabyVaccineStatistics _$BabyVaccineStatisticsFromJson(
  Map<String, dynamic> json,
) => _BabyVaccineStatistics(
  perBaby:
      (json['perBaby'] as List<dynamic>?)
          ?.map((e) => BabyVaccineItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BabyVaccineItem>[],
  milestoneTimeline:
      (json['milestoneTimeline'] as List<dynamic>?)
          ?.map((e) => BabyMilestoneItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BabyMilestoneItem>[],
);

Map<String, dynamic> _$BabyVaccineStatisticsToJson(
  _BabyVaccineStatistics instance,
) => <String, dynamic>{
  'perBaby': instance.perBaby,
  'milestoneTimeline': instance.milestoneTimeline,
};

_BabyVaccineItem _$BabyVaccineItemFromJson(
  Map<String, dynamic> json,
) => _BabyVaccineItem(
  babyId: (json['babyId'] as num).toInt(),
  name: json['name'] as String,
  completionRate: (json['completionRate'] as num).toInt(),
  statusCounts: BabyVaccineCounts.fromJson(
    json['statusCounts'] as Map<String, dynamic>,
  ),
  upcoming:
      (json['upcoming'] as List<dynamic>?)
          ?.map((e) => BabyVaccinePlanItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BabyVaccinePlanItem>[],
  overdueList:
      (json['overdueList'] as List<dynamic>?)
          ?.map((e) => BabyVaccinePlanItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BabyVaccinePlanItem>[],
  recordTimeline:
      (json['recordTimeline'] as List<dynamic>?)
          ?.map(
            (e) => BabyVaccineRecordItem.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <BabyVaccineRecordItem>[],
);

Map<String, dynamic> _$BabyVaccineItemToJson(_BabyVaccineItem instance) =>
    <String, dynamic>{
      'babyId': instance.babyId,
      'name': instance.name,
      'completionRate': instance.completionRate,
      'statusCounts': instance.statusCounts,
      'upcoming': instance.upcoming,
      'overdueList': instance.overdueList,
      'recordTimeline': instance.recordTimeline,
    };

_BabyVaccineCounts _$BabyVaccineCountsFromJson(Map<String, dynamic> json) =>
    _BabyVaccineCounts(
      vaccinated: (json['vaccinated'] as num).toInt(),
      upcoming: (json['upcoming'] as num).toInt(),
      dueSoon: (json['dueSoon'] as num).toInt(),
      overdue: (json['overdue'] as num).toInt(),
    );

Map<String, dynamic> _$BabyVaccineCountsToJson(_BabyVaccineCounts instance) =>
    <String, dynamic>{
      'vaccinated': instance.vaccinated,
      'upcoming': instance.upcoming,
      'dueSoon': instance.dueSoon,
      'overdue': instance.overdue,
    };

_BabyVaccinePlanItem _$BabyVaccinePlanItemFromJson(Map<String, dynamic> json) =>
    _BabyVaccinePlanItem(
      planId: (json['planId'] as num).toInt(),
      vaccineName: json['vaccineName'] as String,
      doseNo: json['doseNo'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      daysToDue: (json['daysToDue'] as num?)?.toInt(),
      overdueDays: (json['overdueDays'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BabyVaccinePlanItemToJson(
  _BabyVaccinePlanItem instance,
) => <String, dynamic>{
  'planId': instance.planId,
  'vaccineName': instance.vaccineName,
  'doseNo': instance.doseNo,
  'dueDate': instance.dueDate.toIso8601String(),
  'daysToDue': instance.daysToDue,
  'overdueDays': instance.overdueDays,
};

_BabyVaccineRecordItem _$BabyVaccineRecordItemFromJson(
  Map<String, dynamic> json,
) => _BabyVaccineRecordItem(
  vaccineName: json['vaccineName'] as String,
  givenDate: DateTime.parse(json['givenDate'] as String),
  clinic: json['clinic'] as String?,
);

Map<String, dynamic> _$BabyVaccineRecordItemToJson(
  _BabyVaccineRecordItem instance,
) => <String, dynamic>{
  'vaccineName': instance.vaccineName,
  'givenDate': instance.givenDate.toIso8601String(),
  'clinic': instance.clinic,
};

_BabyMilestoneItem _$BabyMilestoneItemFromJson(Map<String, dynamic> json) =>
    _BabyMilestoneItem(
      babyId: (json['babyId'] as num).toInt(),
      babyName: json['babyName'] as String,
      occurDate: DateTime.parse(json['occurDate'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$BabyMilestoneItemToJson(_BabyMilestoneItem instance) =>
    <String, dynamic>{
      'babyId': instance.babyId,
      'babyName': instance.babyName,
      'occurDate': instance.occurDate.toIso8601String(),
      'title': instance.title,
      'description': instance.description,
    };
