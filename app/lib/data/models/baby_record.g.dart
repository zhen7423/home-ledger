// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baby_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BabyMilestone _$BabyMilestoneFromJson(Map<String, dynamic> json) =>
    _BabyMilestone(
      id: (json['id'] as num).toInt(),
      babyId: (json['babyId'] as num).toInt(),
      occurDate: DateTime.parse(json['occurDate'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$BabyMilestoneToJson(_BabyMilestone instance) =>
    <String, dynamic>{
      'id': instance.id,
      'babyId': instance.babyId,
      'occurDate': instance.occurDate.toIso8601String(),
      'title': instance.title,
      'description': instance.description,
    };

_BabyMedical _$BabyMedicalFromJson(Map<String, dynamic> json) => _BabyMedical(
  id: (json['id'] as num).toInt(),
  babyId: (json['babyId'] as num).toInt(),
  visitDate: DateTime.parse(json['visitDate'] as String),
  hospital: json['hospital'] as String?,
  department: json['department'] as String?,
  diagnosis: json['diagnosis'] as String?,
  medicine: json['medicine'] as String?,
  costAmount: json['costAmount'] as String?,
  remark: json['remark'] as String?,
);

Map<String, dynamic> _$BabyMedicalToJson(_BabyMedical instance) =>
    <String, dynamic>{
      'id': instance.id,
      'babyId': instance.babyId,
      'visitDate': instance.visitDate.toIso8601String(),
      'hospital': instance.hospital,
      'department': instance.department,
      'diagnosis': instance.diagnosis,
      'medicine': instance.medicine,
      'costAmount': instance.costAmount,
      'remark': instance.remark,
    };
