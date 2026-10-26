// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TokenResponse _$TokenResponseFromJson(Map<String, dynamic> json) =>
    _TokenResponse(
      tokenType: json['tokenType'] as String,
      accessToken: json['accessToken'] as String,
      accessExpiresInSeconds: (json['accessExpiresInSeconds'] as num).toInt(),
      refreshToken: json['refreshToken'] as String,
      refreshExpiresInSeconds: (json['refreshExpiresInSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$TokenResponseToJson(_TokenResponse instance) =>
    <String, dynamic>{
      'tokenType': instance.tokenType,
      'accessToken': instance.accessToken,
      'accessExpiresInSeconds': instance.accessExpiresInSeconds,
      'refreshToken': instance.refreshToken,
      'refreshExpiresInSeconds': instance.refreshExpiresInSeconds,
    };
