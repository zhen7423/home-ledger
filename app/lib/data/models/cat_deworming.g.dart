// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cat_deworming.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatDeworming _$CatDewormingFromJson(Map<String, dynamic> json) =>
    _CatDeworming(
      id: (json['id'] as num).toInt(),
      catId: (json['catId'] as num).toInt(),
      catName: json['catName'] as String,
      type: json['type'] as String,
      doneDate: DateTime.parse(json['doneDate'] as String),
      medicine: json['medicine'] as String,
      dosage: json['dosage'] as String?,
      nextDate: DateTime.parse(json['nextDate'] as String),
      daysToDue: (json['daysToDue'] as num?)?.toInt(),
      overdueDays: (json['overdueDays'] as num?)?.toInt(),
      remark: json['remark'] as String?,
    );

Map<String, dynamic> _$CatDewormingToJson(_CatDeworming instance) =>
    <String, dynamic>{
      'id': instance.id,
      'catId': instance.catId,
      'catName': instance.catName,
      'type': instance.type,
      'doneDate': instance.doneDate.toIso8601String(),
      'medicine': instance.medicine,
      'dosage': instance.dosage,
      'nextDate': instance.nextDate.toIso8601String(),
      'daysToDue': instance.daysToDue,
      'overdueDays': instance.overdueDays,
      'remark': instance.remark,
    };
