import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_reminder.freezed.dart';
part 'pending_reminder.g.dart';

/// 一条待提醒事项，对应后端的 PendingReminderResponse。
///
/// `key` 是稳定的去重键（形如 `BUDGET_OVERRUN:C:123`，不带月份）：通知 id 与
/// 「今天已经提醒过」的本地状态都记在它上面，所以同一个事实两次查询必须得到同一个 key。
/// `route` 由服务端给——「预算超支该跳哪页」要是写在前端，改一次就得同时发后端与 App。
///
/// `module` 是这条属于哪个模块（`FINANCE` / `CAT` / `BABY`），底栏按它把角标挂到对应的 Tab 上。
/// 客户端因此不必认识七个具体类型——「哪个类型属于哪个模块」是服务端的事实。
///
/// `fireAt` 为空表示立即提醒（`show`），非空表示排到那个时刻（`zonedSchedule`）；
/// `fireDate` 是它的日期部分，只给「按天去重」用，两者要么都有要么都没有。
/// 后台返回的顺序即紧急度顺序（逾期 > 3 天内 > 14 天内），首页的卡片区直接铺它，不再自己排。
@freezed
abstract class PendingReminder with _$PendingReminder {
  const factory PendingReminder({
    required String type,
    required String module,
    required String key,
    required String title,
    required String body,
    required String route,
    DateTime? fireAt,
    DateTime? fireDate,
  }) = _PendingReminder;

  factory PendingReminder.fromJson(Map<String, dynamic> json) =>
      _$PendingReminderFromJson(json);
}
