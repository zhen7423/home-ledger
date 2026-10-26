import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/pending_reminder.dart';
import '../../../../data/models/reminder_setting.dart';
import '../../../../data/services/reminder_notifier.dart';
import '../../../core/error_copy.dart';
import '../view_models/reminder_view_model.dart';

/// §4.5 的通知设置：七个开关 + 当前待处理的提醒。
///
/// 这一页要在没有家庭时也能进：开关是**用户级**的（`reminder_setting.user_id`），
/// 与家庭无关，而用户在加入家庭之前也可能先把某类提醒关掉。
class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  /// 用户点「去系统设置」后是切到 Settings 那个 App 里改开关，回来时 Flutter 侧只有一条
  /// 生命周期回调可用。不在按钮的 onPressed 里立刻重查：那一下系统设置页才刚打开，
  /// 查回来的还是改之前的值，提示照样挂着。
  late final AppLifecycleListener _lifecycle = AppLifecycleListener(
    onResume: () => ref.invalidate(notificationPermissionProvider),
  );

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(reminderSettingViewModelProvider);
    final pending = ref.watch(pendingReminderViewModelProvider);
    // 只在明确读到「没开」时提示：还在查的那一瞬间就喊权限没开，是冤枉用户
    final denied = ref.watch(notificationPermissionProvider).value == false;

    return Scaffold(
      appBar: AppBar(title: const Text('通知设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (denied) _PermissionNotice(onOpenSettings: _openSettings),
          _SectionTitle('哪些提醒会发通知'),
          settings.when(
            loading: () => const _CenterSpinner(),
            error: (error, _) => _SectionError(error: error),
            data: (rows) => Column(
              children: [
                for (final row in rows)
                  _SettingTile(
                    setting: row,
                    onChanged: (enabled) => _toggle(row.type, enabled),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            pending.value == null ? '待处理提醒' : '待处理提醒（${pending.value!.length}）',
          ),
          pending.when(
            loading: () => const _CenterSpinner(),
            error: (error, _) => _SectionError(error: error),
            data: (rows) => rows.isEmpty
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Text('一切正常，没有待处理的提醒。'),
                  )
                : Column(
                    children: [
                      for (final row in rows)
                        _ReminderTile(
                          reminder: row,
                          onTap: () => _open(row),
                          onDismiss: () => ref
                              .read(pendingReminderViewModelProvider.notifier)
                              .dismiss(row.key),
                        ),
                    ],
                  ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(
              '划掉的提醒只在今天不再显示，明天还会再来一次。'
              '「不再提醒」是关掉这一类，到上面那一段里关。',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 这一页是乐观更新：失败时那一格会被悄悄拨回原位，不吭一声只剩「点了又弹回来」。
  Future<void> _toggle(String type, bool enabled) async {
    final error = await ref
        .read(reminderSettingViewModelProvider.notifier)
        .setEnabled(type, enabled);
    if (error != null && mounted) showSnackBar(context, error);
  }

  /// §4.5.2「进入相应列表页后红点消除」：点进去看过了就不再挂着这条红点。
  /// 先记再看，跳转本身是同步的，顺序反了的话返回时那条还在列表上。
  Future<void> _open(PendingReminder reminder) async {
    await ref.read(pendingReminderViewModelProvider.notifier).dismiss(reminder.key);
    if (mounted) {
      await context.push(reminder.route);
    }
  }

  Future<void> _openSettings() async {
    // 这里不重查权限：系统设置页才刚打开，用户还没动手，查回来还是旧值。
    // 改完之后由 onResume 负责。
    await ref.read(reminderNotifierProvider).openSystemSettings();
  }
}

/// 权限被拒之后的一句兜底提示（§4.5.1）。红点与 App 内列表不受影响，
/// `PendingReminderViewModel` 里那条「granted 也照样返回可见列表」保证了这点。
class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '通知权限未开启，超支提醒只会出现在 App 里。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          TextButton(onPressed: onOpenSettings, child: const Text('去系统设置')),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.setting, required this.onChanged});

  final ReminderSetting setting;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(setting.label),
      // `pushed` 是后端枚举算出来的，改不了：它说明这一类会不会进系统通知栏，
      // 而开关 `enabled` 管的是「这一类提醒要不要出现在 App 里」。两者不是一个东西。
      subtitle: Text(setting.pushed ? '会发到系统通知栏' : '只在 App 内提示，不发通知'),
      trailing: Switch(value: setting.enabled, onChanged: onChanged),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.onTap,
    required this.onDismiss,
  });

  final PendingReminder reminder;

  final VoidCallback onTap;

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // 跳哪由后端在 `route` 里给：「预算超支该去哪页」写在前端的话，改一次要同时发后端与 App
      onTap: onTap,
      leading: const Icon(Icons.notifications_active_outlined),
      title: Text(reminder.title),
      subtitle: Text(reminder.body),
      trailing: IconButton(
        tooltip: '今天不再提醒',
        icon: const Icon(Icons.close),
        onPressed: onDismiss,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(errorCopy(error)),
    );
  }
}

class _CenterSpinner extends StatelessWidget {
  const _CenterSpinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
