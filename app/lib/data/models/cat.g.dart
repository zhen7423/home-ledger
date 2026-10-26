// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Cat _$CatFromJson(Map<String, dynamic> json) => _Cat(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  gender: json['gender'] as String,
  birthday: json['birthday'] == null
      ? null
      : DateTime.parse(json['birthday'] as String),
  birthdayEstimated: json['birthdayEstimated'] as bool,
  breed: json['breed'] as String?,
  weightKg: json['weightKg'] as String?,
  neutered: json['neutered'] as String,
  remark: json['remark'] as String?,
  photoUrl: json['photoUrl'] as String?,
  archived: json['archived'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$CatToJson(_Cat instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'gender': instance.gender,
  'birthday': instance.birthday?.toIso8601String(),
  'birthdayEstimated': instance.birthdayEstimated,
  'breed': instance.breed,
  'weightKg': instance.weightKg,
  'neutered': instance.neutered,
  'remark': instance.remark,
  'photoUrl': instance.photoUrl,
  'archived': instance.archived,
  'createdAt': instance.createdAt.toIso8601String(),
};
