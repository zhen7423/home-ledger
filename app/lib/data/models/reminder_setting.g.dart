// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReminderSetting _$ReminderSettingFromJson(Map<String, dynamic> json) =>
    _ReminderSetting(
      type: json['type'] as String,
      label: json['label'] as String,
      enabled: json['enabled'] as bool,
      pushed: json['pushed'] as bool,
    );

Map<String, dynamic> _$ReminderSettingToJson(_ReminderSetting instance) =>
    <String, dynamic>{
      'type': instance.type,
      'label': instance.label,
      'enabled': instance.enabled,
      'pushed': instance.pushed,
    };
