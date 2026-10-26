import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder_setting.freezed.dart';
part 'reminder_setting.g.dart';

/// 一类提醒的开关状态，对应后端的 ReminderSettingResponse。
///
/// `label` 由服务端给中文：前端硬编码七份文案的话，S6 / S7 加第八类就得跟着发一次 App。
/// `pushed` 取自 `ReminderType` 枚举、用户改不了，只用来显示「这类提醒会进通知栏」那句副标题；
/// 可改的只有 `enabled`，它关掉的是红点与 App 内展示，不等于 `pushed`。
@freezed
abstract class ReminderSetting with _$ReminderSetting {
  const factory ReminderSetting({
    required String type,
    required String label,
    required bool enabled,
    required bool pushed,
  }) = _ReminderSetting;

  factory ReminderSetting.fromJson(Map<String, dynamic> json) =>
      _$ReminderSettingFromJson(json);
}
