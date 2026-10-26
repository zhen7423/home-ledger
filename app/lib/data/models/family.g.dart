// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Family _$FamilyFromJson(Map<String, dynamic> json) => _Family(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  ownerUserId: (json['ownerUserId'] as num).toInt(),
  inviteEnabled: json['inviteEnabled'] as bool,
  inviteCode: json['inviteCode'] as String?,
  inviteCodeExpireAt: json['inviteCodeExpireAt'] == null
      ? null
      : DateTime.parse(json['inviteCodeExpireAt'] as String),
  members: (json['members'] as List<dynamic>)
      .map((e) => Member.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FamilyToJson(_Family instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'ownerUserId': instance.ownerUserId,
  'inviteEnabled': instance.inviteEnabled,
  'inviteCode': instance.inviteCode,
  'inviteCodeExpireAt': instance.inviteCodeExpireAt?.toIso8601String(),
  'members': instance.members,
};
