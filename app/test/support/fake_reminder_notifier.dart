import 'package:homeledger/data/models/pending_reminder.dart';
import 'package:homeledger/data/services/reminder_notifier.dart';

/// `flutter_local_notifications` 在 `flutter test` 下没有平台通道，调真身就抛
/// MissingPluginException，所以凡是要跑 ViewModel 的测试都得把 reminderNotifierProvider 换成它。
class FakeReminderNotifier implements ReminderNotifier {
  FakeReminderNotifier({this.initResult = true, this.launchRoute});

  /// 用来演「用户拒了通知权限」那一半用例。
  final bool initResult;

  /// 演「App 是被点通知拉起来的」：`deliverLaunchRoute` 会把它交给 `onNavigate` 那一路的回调。
  final String? launchRoute;

  final List<PendingReminder> presented = [];

  /// 调用先后顺序。『先 cancelAll 再按最新一批重排』只有顺序对了才成立，数次数证不出来。
  final List<String> log = [];
  int cancelAllCount = 0;
  int initCount = 0;
  int openSettingsCount = 0;
  int deliverLaunchCount = 0;

  /// 重排之前「还排着」的那些通知 id。默认空集合表示没有待弹的定时，
  /// 用例要演「那条定时马上会被 cancelAll 取消掉」时把它设成对应 key 的 id。
  Set<int> scheduledIdsValue = const {};

  /// 插件通道故障注入：真身在测试里没有平台通道，任何一句都可能抛 `MissingPluginException`。
  /// 设了就抛，演「通知侧失败不许烧掉红点数据」那一半用例。
  /// `presentFailure` 可再用 `presentFailKeys` 收窄到指定的几条（null = 全部抛），
  /// 用来验「单条失败只跳过这一条，其余照常投递」。
  Object? scheduledIdsFailure;
  Object? presentFailure;
  Object? cancelAllFailure;
  Set<String>? presentFailKeys;

  /// 演「去系统设置」那一跳拉不起来：真身是平台通道调用，部分机型上会抛。
  Object? openSettingsFailure;

  /// 跳到过的落点。跳转由真实实现在 onNavigate 里做，替身只记下来。
  final List<String> navigated = [];

  @override
  Future<bool> init() async {
    initCount++;
    log.add('init');
    return initResult;
  }

  @override
  Future<bool> areGranted() async => initResult;

  @override
  Future<void> openSystemSettings() async {
    final failure = openSettingsFailure;
    if (failure != null) throw failure;
    openSettingsCount++;
  }

  @override
  Future<Set<int>> scheduledIds() async {
    final failure = scheduledIdsFailure;
    if (failure != null) throw failure;
    return scheduledIdsValue;
  }

  @override
  Future<String?> deliverLaunchRoute() async {
    deliverLaunchCount++;
    final route = launchRoute;
    // 真身跳一次就清掉了，替身照做：跳转是「用户点通知」那一次的事，不是每次刷新都来一遍
    if (route == null || _launchDelivered) {
      return null;
    }
    _launchDelivered = true;
    navigated.add(route);
    return route;
  }

  bool _launchDelivered = false;

  @override
  Future<void> present(PendingReminder reminder) async {
    final failure = presentFailure;
    if (failure != null &&
        (presentFailKeys == null || presentFailKeys!.contains(reminder.key))) {
      throw failure;
    }
    presented.add(reminder);
    log.add('present:${reminder.key}');
  }

  @override
  Future<void> cancelAll() async {
    final failure = cancelAllFailure;
    if (failure != null) throw failure;
    cancelAllCount++;
    log.add('cancelAll');
  }
}
