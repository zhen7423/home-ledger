// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baby.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Baby _$BabyFromJson(Map<String, dynamic> json) => _Baby(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  gender: json['gender'] as String,
  birthDate: DateTime.parse(json['birthDate'] as String),
  birthHeight: json['birthHeight'] as String?,
  birthWeight: json['birthWeight'] as String?,
  remark: json['remark'] as String?,
  photoUrl: json['photoUrl'] as String?,
  archived: json['archived'] as bool,
  ageText: json['ageText'] as String,
);

Map<String, dynamic> _$BabyToJson(_Baby instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'gender': instance.gender,
  'birthDate': instance.birthDate.toIso8601String(),
  'birthHeight': instance.birthHeight,
  'birthWeight': instance.birthWeight,
  'remark': instance.remark,
  'photoUrl': instance.photoUrl,
  'archived': instance.archived,
  'ageText': instance.ageText,
};

_BabyOverview _$BabyOverviewFromJson(Map<String, dynamic> json) =>
    _BabyOverview(
      savedAt: DateTime.parse(json['savedAt'] as String),
      babies: (json['babies'] as List<dynamic>)
          .map((e) => Baby.fromJson(e as Map<String, dynamic>))
          .toList(),
      latestGrowth: json['latestGrowth'] == null
          ? null
          : BabyGrowthStatistics.fromJson(
              json['latestGrowth'] as Map<String, dynamic>,
            ),
      vaccineTodo: json['vaccineTodo'] == null
          ? null
          : BabyVaccineStatistics.fromJson(
              json['vaccineTodo'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$BabyOverviewToJson(_BabyOverview instance) =>
    <String, dynamic>{
      'savedAt': instance.savedAt.toIso8601String(),
      'babies': instance.babies,
      'latestGrowth': instance.latestGrowth,
      'vaccineTodo': instance.vaccineTodo,
    };
