import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/pending_reminder.dart';
import '../../../../data/models/reminder_setting.dart';
import '../../../../data/models/reminder_state.dart';
import '../../../../data/repositories/reminder_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../../data/services/reminder_notifier.dart';
import '../../../../data/services/reminder_state_store.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';

/// §4.5.1 的七个提醒开关。
class ReminderSettingViewModel extends AsyncNotifier<List<ReminderSetting>> {
  @override
  Future<List<ReminderSetting>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    return _repository.settings();
  }

  /// 单个开关切换后先乐观改本地状态再提交，失败回滚。
  ///
  /// 这里破例做乐观更新：开关类控件等一个来回再动，用户会以为没点上、连点几下，
  /// 而那几下都会变成请求。失败回滚比等待更少见，也更可接受。
  /// 交上去的是整份列表——后端的保存是全量覆盖，只传一项会把其他六项打回默认值。
  Future<String?> setEnabled(String type, bool enabled) async {
    final current = state.value ?? const <ReminderSetting>[];
    final next = [
      for (final row in current)
        if (row.type == type) row.copyWith(enabled: enabled) else row,
    ];
    state = AsyncData(next);
    try {
      await _repository.saveSettings([
        for (final row in next)
          ReminderSettingItem(type: row.type, enabled: row.enabled),
      ]);
    } on ApiException catch (e) {
      state = AsyncData(current);
      return errorCopy(e);
    }
    // 开关变了就重算一次待提醒：关掉的那类要从红点里消失，重新打开的要能发通知。
    // 不在这显式 invalidate `pendingReminderViewModelProvider`：它 build 里 watch 了这份设置，
    // 状态一改自己就重算，而从被 watch 的一方反过来 invalidate 会被 Riverpod 判成循环依赖。
    // 也不重拉自己的列表：乐观更新已经把这一项改对了，再 GET 一次是白跑一趟。
    return null;
  }

  ReminderRepository get _repository => ref.read(reminderRepositoryProvider);
}

final reminderSettingViewModelProvider =
    AsyncNotifierProvider<ReminderSettingViewModel, List<ReminderSetting>>(
      ReminderSettingViewModel.new,
    );

/// §4.5.2 的待提醒事项，同时是**通知与红点的唯一驱动源**。
///
/// 状态里装的是「滤掉已划掉的、滤掉关掉这一类提醒的」，也就是红点与通知设置页列表要看的那份。
/// 「今天已经发过通知」不减红点：超支了就该一整天都看得见，只是不再重复发第二条通知。
///
/// 它同时是 §4.5.2 那三条重排时机里两条的落点（启动、下拉刷新；从后台恢复由 `TabShell`
/// 在回前台时失效这个 provider 触发）。App 被杀后点通知冷启动的那一次跳转也在这里交付：
/// 那一刻登录态才刚就绪，路由跳转要有登录态兜着才不会被守卫弹回引导页。
class PendingReminderViewModel extends AsyncNotifier<List<PendingReminder>> {
  @override
  Future<List<PendingReminder>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    final notifier = ref.read(reminderNotifierProvider);
    final granted = await notifier.init();
    final launch = await notifier.deliverLaunchRoute();
    final rows = await _repository.pending();
    // watch 而不是 read：用户在设置页关掉某个开关，这一份要跟着重算
    final settings = {
      for (final row in await ref.watch(
        reminderSettingViewModelProvider.future,
      ))
        row.type: row,
    };
    var stored = await _store.read();
    final today = formatDate(DateTime.now());
    if (launch != null) {
      // 用户是被某条通知叫起来的，那一屏的提醒就算看过了。合并进本地 `dismissed` 而不是改 state：
      // 这里还在 build 里，而下面那句 visible 本来就要按更新后的这份算
      stored = await _store.update(
        (current) => current.copyWith(
          dismissed: {
            ...current.dismissed,
            for (final row in rows)
              if (row.route == launch) row.key: today,
          },
        ),
      );
    }
    // 排程之前先问一次「哪几条还排着」。cancelAll 之后这个信息就没了，而它是分清
    // 「已经弹过」与「马上要被取消」的唯一依据（见 _present）。
    // 问不到就按「没有排程」降级：最坏是今天多排一次，不会漏排。绝不能让它把 build 打进
    // AsyncError——那会把不依赖通知的红点一并清零，兑不了「通知没了红点还在」的承诺
    Set<int> scheduled = const <int>{};
    if (granted) {
      try {
        scheduled = await notifier.scheduledIds();
      } on Exception catch (e) {
        debugPrint('scheduledIds 失败，按无排程降级: $e');
      }
    }

    final visible = [
      for (final row in rows)
        if ((settings[row.type]?.enabled ?? true) &&
            stored.dismissed[row.key] != today)
          row,
    ];
    if (!granted) {
      // 权限被拒也照样返回这一份：§10 用例 34 要的就是「通知没了但红点还在」。
      // 只是这里必须原样交出去，不能顺手把 state 置空。
      return visible;
    }
    await _present(notifier, visible, settings, stored, scheduled, today);
    return visible;
  }

  /// 划掉一条：只记在设备上，不给后端发请求。「这台机器的用户看过了」是设备级状态，
  /// 换台设备重新看到是对的。第二天日期变了，它自己会重新出现。
  Future<void> dismiss(String key) async {
    final today = formatDate(DateTime.now());
    await _store.update(
      (current) =>
          current.copyWith(dismissed: {...current.dismissed, key: today}),
    );
    state = AsyncData([
      for (final row in state.value ?? const <PendingReminder>[])
        if (row.key != key) row,
    ]);
  }

  /// 从系统通知栏点进来的那一条：payload 里只有落点，没有 key，所以按 route 把同一屏的提醒
  /// 一起记为「今天已看」——用户确实进了那一页，而「疫苗逾期」这类提醒本来就共用一条落点。
  Future<void> dismissByRoute(String route) async {
    final rows = [
      for (final row in state.value ?? const <PendingReminder>[])
        if (row.route == route) row,
    ];
    for (final row in rows) {
      await dismiss(row.key);
    }
  }

  /// 电池优化引导是否已经弹过（§4.5.3 的缓解措施①）。只读不落盘。
  ///
  /// 「查一次、弹完再回写」曾经合并成一步的 claim（领到即落盘），但领位在弹窗之前：
  /// 首页在 claim 与弹窗之间被销毁时（冷启动切 Tab、深链直达），引导会被永久烧掉——
  /// 标志已落下，对话框却再也不会出现。拆成只读 + [markBatteryGuideShown] 两步，
  /// 同一次挂载内的重复由调用方的局部标志防住。
  Future<bool> isBatteryGuideShown() async =>
      (await _store.read()).batteryGuideShown;

  /// 对话框真正关闭之后回写「弹过了」。走 `update` 而不是整份覆盖：
  /// 它可能与待提醒重算写 `notified` 同时发生，串行队列 + 局部合并保证两边都不丢。
  Future<void> markBatteryGuideShown() async {
    await _store.update((current) => current.copyWith(batteryGuideShown: true));
  }

  Future<void> _present(
    ReminderNotifier notifier,
    List<PendingReminder> visible,
    Map<String, ReminderSetting> settings,
    ReminderState stored,
    Set<int> scheduled,
    String today,
  ) async {
    // 先全清再按这一批重排：不这么做的话，改过的提醒会留下旧的定时，同一次超支弹出两条内容不同的通知。
    // 清失败也压不住后面的重排与红点：与 scheduledIds 同一个理由，通知侧不许烧数据流
    try {
      await notifier.cancelAll();
    } on Exception catch (e) {
      debugPrint('cancelAll 失败，照常重排: $e');
    }
    // 只把这一轮动过的键并回去，不整份写：另外两处（划掉、首启引导）可能刚改过别的字段，
    // 整份覆盖会把它们无声地抹掉
    final touched = <String, String>{};
    for (final row in visible) {
      // 查不到开关时按「不发」处理：少发一条通知没人会投诉，多发一条扰民的有
      if (!(settings[row.type]?.pushed ?? false)) {
        continue;
      }
      // 排程类记的是它该响的那一天，立即类记今天——两者都表达「这一次已经处理过了」
      final stamp = row.fireDate == null ? today : formatDate(row.fireDate!);
      if (row.fireAt == null &&
          stored.notified[row.key] == stamp &&
          !scheduled.contains(notificationIdOf(row.key))) {
        // 已经弹过、且现在也没有排着的定时：再弹一次就是同一天两条一模一样的通知。
        // 那半句 `!scheduled.contains` 是必需的——定时还排着说明它只是刚被上面那句
        // cancelAll 取消了，这里跳过等于把今天这一条彻底丢掉（早上打开 App 就会踩到）
        continue;
      }
      // 单条投递失败只跳过这一条：不写 touched，下次进 App 还会再试。
      // 这里抛出去会击穿整个待提醒状态（见 build 里那段降级），通知是副作用，不许烧掉红点数据
      try {
        await notifier.present(row);
      } on Exception catch (e) {
        debugPrint('提醒 ${row.key} 投递失败，仅保留红点: $e');
        continue;
      }
      touched[row.key] = stamp;
    }
    if (touched.isNotEmpty) {
      await _store.update(
        (current) =>
            current.copyWith(notified: {...current.notified, ...touched}),
      );
    }
  }

  ReminderRepository get _repository => ref.read(reminderRepositoryProvider);

  ReminderStateStore get _store => ref.read(reminderStateStoreProvider);
}

final pendingReminderViewModelProvider =
    AsyncNotifierProvider<PendingReminderViewModel, List<PendingReminder>>(
      PendingReminderViewModel.new,
    );

/// 设置页「通知」那一行的角标、首页红点的数字。它只是状态长度的一个视图，
/// 单独一个 provider 是为了让读它的地方不必自己 `.value?.length`。
final pendingReminderCountProvider = Provider<int>(
  (ref) => ref.watch(pendingReminderViewModelProvider).value?.length ?? 0,
);

/// 系统通知权限此刻开没开，供通知设置页决定要不要给那句「去系统设置」的提示（§4.5.1）。
///
/// 单独一个 provider 而不塞进 `PendingReminderViewModel` 的状态：那份状态是「待提醒列表」，
/// 权限是另一件事，合在一起红点逻辑要多背一个返回值，而它自己一点也不用。
final notificationPermissionProvider = FutureProvider<bool>(
  (ref) => ref.watch(reminderNotifierProvider).areGranted(),
);
