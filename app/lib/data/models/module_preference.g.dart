// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'module_preference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ModulePreference _$ModulePreferenceFromJson(Map<String, dynamic> json) =>
    _ModulePreference(
      moduleKey: json['moduleKey'] as String,
      label: json['label'] as String,
      enabled: json['enabled'] as bool,
      sortNo: (json['sortNo'] as num).toInt(),
    );

Map<String, dynamic> _$ModulePreferenceToJson(_ModulePreference instance) =>
    <String, dynamic>{
      'moduleKey': instance.moduleKey,
      'label': instance.label,
      'enabled': instance.enabled,
      'sortNo': instance.sortNo,
    };
