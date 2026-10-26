// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Member _$MemberFromJson(Map<String, dynamic> json) => _Member(
  userId: (json['userId'] as num).toInt(),
  nickname: json['nickname'] as String,
  role: json['role'] as String,
  joinedAt: DateTime.parse(json['joinedAt'] as String),
);

Map<String, dynamic> _$MemberToJson(_Member instance) => <String, dynamic>{
  'userId': instance.userId,
  'nickname': instance.nickname,
  'role': instance.role,
  'joinedAt': instance.joinedAt.toIso8601String(),
};
