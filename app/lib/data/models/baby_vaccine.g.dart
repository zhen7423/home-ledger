// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'baby_vaccine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BabyVaccinePlan _$BabyVaccinePlanFromJson(Map<String, dynamic> json) =>
    _BabyVaccinePlan(
      id: (json['id'] as num).toInt(),
      babyId: (json['babyId'] as num).toInt(),
      vaccineName: json['vaccineName'] as String,
      doseNo: json['doseNo'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      plannedDate: json['plannedDate'] == null
          ? null
          : DateTime.parse(json['plannedDate'] as String),
      effectiveDate: DateTime.parse(json['effectiveDate'] as String),
      status: json['status'] as String,
      skipReason: json['skipReason'] as String?,
      recordId: (json['recordId'] as num?)?.toInt(),
      manual: json['manual'] as bool,
      displayStatus: json['displayStatus'] as String,
    );

Map<String, dynamic> _$BabyVaccinePlanToJson(_BabyVaccinePlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'babyId': instance.babyId,
      'vaccineName': instance.vaccineName,
      'doseNo': instance.doseNo,
      'dueDate': instance.dueDate.toIso8601String(),
      'plannedDate': instance.plannedDate?.toIso8601String(),
      'effectiveDate': instance.effectiveDate.toIso8601String(),
      'status': instance.status,
      'skipReason': instance.skipReason,
      'recordId': instance.recordId,
      'manual': instance.manual,
      'displayStatus': instance.displayStatus,
    };

_BabyVaccineRecord _$BabyVaccineRecordFromJson(Map<String, dynamic> json) =>
    _BabyVaccineRecord(
      id: (json['id'] as num).toInt(),
      babyId: (json['babyId'] as num).toInt(),
      planId: (json['planId'] as num?)?.toInt(),
      vaccineName: json['vaccineName'] as String,
      doseNo: json['doseNo'] as String,
      givenDate: DateTime.parse(json['givenDate'] as String),
      clinic: json['clinic'] as String?,
      batchNo: json['batchNo'] as String?,
      reaction: json['reaction'] as String?,
      nextDate: json['nextDate'] == null
          ? null
          : DateTime.parse(json['nextDate'] as String),
      remark: json['remark'] as String?,
    );

Map<String, dynamic> _$BabyVaccineRecordToJson(_BabyVaccineRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'babyId': instance.babyId,
      'planId': instance.planId,
      'vaccineName': instance.vaccineName,
      'doseNo': instance.doseNo,
      'givenDate': instance.givenDate.toIso8601String(),
      'clinic': instance.clinic,
      'batchNo': instance.batchNo,
      'reaction': instance.reaction,
      'nextDate': instance.nextDate?.toIso8601String(),
      'remark': instance.remark,
    };
