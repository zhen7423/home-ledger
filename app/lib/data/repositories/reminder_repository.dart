import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pending_reminder.dart';
import '../models/reminder_setting.dart';
import '../services/api_client.dart';

/// §4.5 的提醒：开关清单与待提醒列表。
///
/// 提醒的**计算全在后端**，客户端只把 `pending` 回来的东西排成本地通知、顺手点亮红点，
/// 不做任何日期推算（§4.5.2）。这里也不做缓存：一份过期的「待提醒」会让人以为没事了。
class ReminderRepository {
  ReminderRepository({required this._api});

  final ApiClient _api;

  /// 七项全量，顺序与后端枚举一致，前端不再自己排。中文标签也来自服务端。
  Future<List<ReminderSetting>> settings() async {
    final rows = await _api.getList('/reminders/settings');
    return rows.map(ReminderSetting.fromJson).toList();
  }

  /// 后端 `items` 是必填的，所以这里不收 null：传 null 只会换来一个 400，
  /// 而调用方（设置页）永远是拿整份列表改一项再整体交回。
  Future<void> saveSettings(List<ReminderSettingItem> items) => _api.put(
    '/reminders/settings',
    body: {'items': items.map((item) => item.toJson()).toList()},
  );

  /// 当前待提醒的事项，含预算两档。空数组是「一切正常」，不是错误。
  Future<List<PendingReminder>> pending() async {
    final rows = await _api.getList('/reminders/pending');
    return rows.map(PendingReminder.fromJson).toList();
  }
}

/// 一个开关的提交形状。只带 type 与 enabled，label / pushed 是服务端算出来的，发回去没有意义。
class ReminderSettingItem {
  const ReminderSettingItem({required this.type, required this.enabled});

  final String type;

  final bool enabled;

  Map<String, Object?> toJson() => {'type': type, 'enabled': enabled};
}

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => ReminderRepository(api: ref.watch(apiClientProvider)),
);
