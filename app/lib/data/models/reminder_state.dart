import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder_state.freezed.dart';
part 'reminder_state.g.dart';

/// 提醒的设备级状态，整份存进 `reminder-state.json`（读写见 `ReminderStateStore`）。
///
/// 三张表都是「后端的 key → 哪一天」，key 稳定且不带月份，所以日期放在值里而不是键里。
///
/// - `notified`：这个事实当天已经提醒过了，同日不再重复弹（§10 用例 13）。**排程类记的是
///   `fireDate` 而不是「今天」**——一条排到 3 天后的通知，在那一天到来之前就已经写下了它该响的日子，
///   这样那天再打开 App 时不会与已经弹过的那条重复。
/// - `dismissed`：用户把它划掉了（或点进去看过了），当天不再出红点，第二天重新出现。
/// - `batteryGuideShown`：电池优化引导弹过没有。它与上面两张表不同，是「一辈子一次」的开关而不是
///   按天过期的记录，但同属「这台设备上的提醒状态」，再开一个文件只为存一个布尔值不值当。
///
/// 不落服务端：这是「这台设备上的用户看过没有」，同家庭另一台手机该不该弹，跟这台机器的
/// 操作没有关系。
@freezed
abstract class ReminderState with _$ReminderState {
  const factory ReminderState({
    @Default(<String, String>{}) Map<String, String> notified,
    @Default(<String, String>{}) Map<String, String> dismissed,
    @Default(false) bool batteryGuideShown,
  }) = _ReminderState;

  factory ReminderState.fromJson(Map<String, dynamic> json) =>
      _$ReminderStateFromJson(json);
}
