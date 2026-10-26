// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingReminder _$PendingReminderFromJson(Map<String, dynamic> json) =>
    _PendingReminder(
      type: json['type'] as String,
      module: json['module'] as String,
      key: json['key'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      route: json['route'] as String,
      fireAt: json['fireAt'] == null
          ? null
          : DateTime.parse(json['fireAt'] as String),
      fireDate: json['fireDate'] == null
          ? null
          : DateTime.parse(json['fireDate'] as String),
    );

Map<String, dynamic> _$PendingReminderToJson(_PendingReminder instance) =>
    <String, dynamic>{
      'type': instance.type,
      'module': instance.module,
      'key': instance.key,
      'title': instance.title,
      'body': instance.body,
      'route': instance.route,
      'fireAt': instance.fireAt?.toIso8601String(),
      'fireDate': instance.fireDate?.toIso8601String(),
    };
