// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReminderState _$ReminderStateFromJson(Map<String, dynamic> json) =>
    _ReminderState(
      notified:
          (json['notified'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      dismissed:
          (json['dismissed'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          const <String, String>{},
      batteryGuideShown: json['batteryGuideShown'] as bool? ?? false,
    );

Map<String, dynamic> _$ReminderStateToJson(_ReminderState instance) =>
    <String, dynamic>{
      'notified': instance.notified,
      'dismissed': instance.dismissed,
      'batteryGuideShown': instance.batteryGuideShown,
    };
