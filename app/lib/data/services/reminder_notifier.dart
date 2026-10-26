import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/pending_reminder.dart';

/// 通知能力的抽象。
///
/// 抽出来不是为了将来换实现（本期只有 Android 一条路），而是为了测试：
/// `flutter_local_notifications` 在 `flutter test` 下调任何真实方法都会抛 `MissingPluginException`
/// ——测试环境没有平台通道。没有这层抽象，ViewModel 的测试就没法跑。
abstract interface class ReminderNotifier {
  /// 首次调用时建通知渠道并请求权限。返回是否拿到了权限。
  ///
  /// App 是被通知点开的（进程已被系统杀掉）时，那一次点击的落点在这里记下来，
  /// 由调用方在登录态就绪之后喊一次 [deliverLaunchRoute]。
  Future<bool> init();

  /// `fireAt` 为空即立即弹出，非空则排到那个时刻。
  Future<void> present(PendingReminder reminder);

  /// 数据刷新后重排：先全清再按最新的一批排，否则改过的提醒会留下旧的定时。
  Future<void> cancelAll();

  /// 已经排上、还没有弹的那些通知 id。
  ///
  /// 重排之前先问一次，是为了分清「那条定时已经弹过了」与「它还被排着、只是马上要被 [cancelAll] 取消」：
  /// 两种情况下「今天这条已经记在 `notified` 里」，但前者不该再弹，后者不重弹就一条都收不到。
  Future<Set<int>> scheduledIds();

  /// 冷启动点通知的那一次跳转：跳过去，并把落点交回来（没被通知点开过、或已经跳过时回 `null`）。
  ///
  /// 回一个落点而不是只跳一下，是为了让调用方顺手把那条提醒记成「今天看过了」——
  /// 冷启动时待提醒列表还没到手上，只有落点可用，而这正是按 route 认领那几条的依据（§4.5.2）。
  Future<String?> deliverLaunchRoute();

  /// 通知权限此刻是否开着。**只查，不弹授权框**——框是 `init()` 弹的，通知设置页只是回头看
  /// 一眼结果，打开那一页不该再打扰用户一次（§4.5.1）。
  Future<bool> areGranted();

  /// 把用户送到系统的通知设置页。误拒之后只能由他自己开回来，App 里再点一次授权框也没用。
  Future<void> openSystemSettings();
}

/// 真实实现：Android 本地通知。
///
/// 没有服务端推送，也没有厂商通道（§1.2、§4.5.3）。App 被系统杀掉或电池优化限制时通知可能不触发，
/// 这是需求文档明示过的已知限制，红点是兜底。
class LocalReminderNotifier implements ReminderNotifier {
  /// onNavigate 收到的是通知的 payload，也就是后端给的 route。走回调而不是在这里 import
  /// GoRouter：service 层依赖 router 会让它在测试里没法单独实例化，跳转由 main.dart 里
  /// 那个 override 接（那是唯一同时看得见 routerProvider 与 ProviderScope 的位置）。
  LocalReminderNotifier({this._onNavigate})
    : _plugin = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'homeledger_reminders';
  static const String _channelName = '家庭日记提醒';
  // 七类提醒共用这一个渠道，描述就写全：只写「周期记账与预算」会让用户在系统设置里以为
  // 疫苗与驱虫的提醒来自别的 App
  static const String _channelDescription = '疫苗、驱虫、猫粮与预算提醒';

  final FlutterLocalNotificationsPlugin _plugin;

  final void Function(String route)? _onNavigate;

  /// 待提醒列表每次刷新都会调这里，而渠道与权限做一次就够（`initialize` 还会把回调重新注册一遍）。
  /// memo 住第一次的那个 Future，而不是记住「初始化过了」再返回 false，否则第二次刷新会以为权限被拒。
  Future<bool>? _initialized;

  /// 冷启动那一次点击的落点。只在进程被通知拉起时有值，跳过一次就清掉。
  String? _launchRoute;

  @override
  Future<bool> init() => _initialized ??= _initialize();

  Future<bool> _initialize() async {
    // 时区数据在 package:timezone/data/latest.dart 里，timezone.dart 只有 setLocalLocation /
    // getLocation / TZDateTime，不 import 前者会让 getLocation 直接抛异常
    tz_data.initializeTimeZones();
    // 固定 Asia/Shanghai，与后端 TimeConfig 的时区一致。不引 flutter_timezone 去问设备时区：
    // §5.5 定的是全项目一个时区，跟着设备走会让「设备在东京的用户」收到错位一小时的通知
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onTap,
    );
    // 渠道只在 init 建一次。重复调用是幂等的，但放在这里比放在每次 present 里清楚
    await _android()?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.defaultImportance,
      ),
    );
    // 进程被通知拉起时，`onDidReceiveNotificationResponse` 不会触发——那一次点击发生在插件注册回调之前。
    // 只能回头看一次启动详情，跳转由 deliverLaunchRoute 在登录态就绪后完成
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final route = launch?.notificationResponse?.payload;
      if (route != null && route.isNotEmpty) {
        _launchRoute = route;
      }
    }
    // Android 上这个叫 requestNotificationsPermission，Darwin 那套 requestPermissions 在这里不存在
    final granted = await _android()?.requestNotificationsPermission();
    return granted ?? false;
  }

  @override
  Future<String?> deliverLaunchRoute() async {
    final route = _launchRoute;
    if (route == null) {
      return null;
    }
    // 先清再跳：这个方法是每次刷新待提醒时都会被喊的，留着它就会反复把用户推回那一页
    _launchRoute = null;
    _onNavigate?.call(route);
    return route;
  }

  @override
  Future<Set<int>> scheduledIds() async {
    final requests = await _plugin.pendingNotificationRequests();
    return {for (final request in requests) request.id};
  }

  @override
  Future<bool> areGranted() async =>
      await _android()?.areNotificationsEnabled() ?? false;

  @override
  Future<void> openSystemSettings() async {
    // 返回值只说明「那个 activity 有没有拉起来」。不据此报错：拉不起来时用户看到的还是
    // 同一句提示，比多弹一个「打开失败」更诚实，而拉得起来时他要在那里面自己做完决定。
    await _android()?.openAppNotificationSettings();
  }

  AndroidFlutterLocalNotificationsPlugin? _android() => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> present(PendingReminder reminder) async {
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
      ),
    );
    final id = notificationIdOf(reminder.key);
    final fireAt = reminder.fireAt;
    if (fireAt == null) {
      await _plugin.show(
        id: id,
        title: reminder.title,
        body: reminder.body,
        notificationDetails: details,
        payload: reminder.route,
      );
      return;
    }
    await _plugin.zonedSchedule(
      id: id,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: _atShanghai(fireAt),
      notificationDetails: details,
      // 不用 exact：那要 SCHEDULE_EXACT_ALARM，用户在系统设置里一眼看到「这个记账 App 要定时唤醒」
      // 只会觉得可疑。提醒差几分钟没人会在意（§4.5.3 本来就允许被电池优化延后）
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: reminder.route,
    );
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  /// 后端回的 `fireAt` 是不带时区标记的 Asia/Shanghai 本地串。逐字段搬进 TZDateTime 而不是
  /// `TZDateTime.from`：后者会把这个 DateTime 当成「设备此刻的时刻」，设备在东京时墙钟就被挪走一小时了。
  static tz.TZDateTime _atShanghai(DateTime value) => tz.TZDateTime(
    tz.local,
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
    value.second,
  );

  void _onTap(NotificationResponse response) {
    final route = response.payload;
    if (route != null && route.isNotEmpty) {
      _onNavigate?.call(route);
    }
  }
}

/// key 哈希成 int 当通知 id：同一个事实两次 present 会覆盖而不是并排弹两条。
///
/// FNV-1a 而不是 `String.hashCode`：Dart VM 的字符串哈希带每进程随机种子，进程重启后同一 key
/// 的 id 必变。日常靠「cancelAll 全清再重排」兜住；一旦某次 cancelAll 失败（被吞掉后照常重排），
/// 旧 id 的通知无法逐条取消，只会越积越多。稳定哈希让 id 跨进程也对得上（扫描报告 2026-10-26 P3-3）。
/// 放在类外是因为**调用方也要用它**：`scheduledIds()` 回来的是 id，得拿同一个函数折算才能对上号，
/// 两处各写一遍就等于两份哈希定义，错一份时症状是「重排把还在排的那条当成已弹过的」。
int notificationIdOf(String key) {
  var hash = 0x811c9dc5;
  for (final byte in key.codeUnits) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  // 空串一轮循环都不走，初值 2166136261 超出 Android 通知 id 的有符号 32 位域；
  // 统一再掩一次，任何输入都落在 0..2^31-1（复扫 P3）
  return hash & 0x7fffffff;
}

/// 真实实现由 `PendingReminderViewModel` 在第一次 `present` 之前 `init()` 一次（建渠道 + 要权限）。
/// 测试里一律 `overrideWith((ref) => FakeReminderNotifier())` 换掉——插件在 `flutter test` 下没有平台通道。
///
/// 这一份不带 `onNavigate`：本文件不 import GoRouter（否则测试里连构造都做不了），
/// 而 `routerProvider` 与 `ProviderScope` 要同时可见才有得注入——所以带跳转的那一份在
/// `main.dart` 里 override 进来。
final reminderNotifierProvider = Provider<ReminderNotifier>(
  (ref) => LocalReminderNotifier(),
);
