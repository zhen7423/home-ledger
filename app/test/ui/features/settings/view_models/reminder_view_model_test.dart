import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/pending_reminder.dart';
import 'package:homeledger/data/models/reminder_setting.dart';
import 'package:homeledger/data/models/reminder_state.dart';
import 'package:homeledger/data/repositories/reminder_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/reminder_notifier.dart';
import 'package:homeledger/data/services/reminder_state_store.dart';
import 'package:homeledger/ui/core/date_format.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/settings/view_models/reminder_view_model.dart';

import '../../../../support/fake_reminder_notifier.dart';
import '../../../../support/s4_fixtures.dart';

const _overrunKey = 'BUDGET_OVERRUN:FAMILY';
const _warningKey = 'BUDGET_WARNING:FAMILY';

/// 两条待提醒都在，配上把「即将超支」开关打开的那份设置一起用：
/// 演示同一屏里一条发通知、一条只出红点。
final List<PendingReminder> _bothReminders = [
  reminder(key: _overrunKey),
  reminder(type: 'BUDGET_WARNING', key: _warningKey, title: '家庭总预算即将超支'),
];

/// 「即将超支」后端默认是关的，要让它出现在红点里得把这开关打开。
List<ReminderSetting> get _warningOn => reminderSettings(warningEnabled: true);

/// 提醒仓库替身。两份数据都能被用例改写，失败也在这里注入。
class _FakeReminderRepository implements ReminderRepository {
  _FakeReminderRepository({
    List<PendingReminder>? pending,
    List<ReminderSetting>? settings,
  }) : _pending = pending ?? const [],
       _settings = settings ?? reminderSettings();

  final List<PendingReminder> _pending;
  final List<ReminderSetting> _settings;

  final List<List<ReminderSettingItem>> saved = [];
  int pendingCalls = 0;
  int settingsCalls = 0;

  Object? settingsFailure;

  @override
  Future<List<ReminderSetting>> settings() async {
    settingsCalls++;
    _throwIfFailure();
    return _settings;
  }

  @override
  Future<void> saveSettings(List<ReminderSettingItem> items) async {
    _throwIfFailure();
    saved.add(items);
    // 后端是全量覆盖：交回来的那份就是新的服务端状态，替身也照这个改
    for (final item in items) {
      final index = _settings.indexWhere((row) => row.type == item.type);
      if (index >= 0) {
        _settings[index] = _settings[index].copyWith(enabled: item.enabled);
      }
    }
  }

  @override
  Future<List<PendingReminder>> pending() async {
    pendingCalls++;
    return _pending;
  }

  void _throwIfFailure() {
    final failure = settingsFailure;
    if (failure != null) throw failure;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

void main() {
  late Directory root;
  late ReminderStateStore store;
  late FakeReminderNotifier notifier;
  late _FakeReminderRepository repository;

  /// 换一套输入。用例在 `open()` 之前调它，容器建的时候读到的就是这一份。
  void reset({
    List<PendingReminder>? pending,
    List<ReminderSetting>? settings,
    bool granted = true,
    String? launchRoute,
  }) {
    notifier = FakeReminderNotifier(
      initResult: granted,
      launchRoute: launchRoute,
    );
    repository = _FakeReminderRepository(
      pending: pending ?? [reminder(key: _overrunKey)],
      settings: settings,
    );
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('reminder_view_model');
    store = ReminderStateStore(directoryResolver: () async => root);
    // 默认只有一条超支待提醒 + 后端那七个开关的默认值
    reset();
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  /// `flutter_local_notifications` 在测试里没有平台通道，通知那一侧一律换替身。
  /// 去重状态反过来用**真**的 `ReminderStateStore`，只把目录指到临时路径——
  /// 「今天已经提醒过」这套东西本身就是这里要验的东西，替身掉它等于没验。
  ProviderContainer open() {
    final container = ProviderContainer(
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
        reminderRepositoryProvider.overrideWithValue(repository),
        reminderNotifierProvider.overrideWith((_) => notifier),
        reminderStateStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<List<PendingReminder>> pendingRows() async =>
      await open().read(pendingReminderViewModelProvider.future);

  Future<void> seed(ReminderState state) => store.write(state);

  test('超支这一条发通知，并把当天记进已提醒状态', () async {
    final today = formatDate(DateTime.now());

    final rows = await pendingRows();

    expect(rows.map((r) => r.key), [_overrunKey]);
    expect(notifier.log, [
      'init',
      'cancelAll',
      'present:$_overrunKey',
    ], reason: '先清掉旧的定时，再按最新一批重排');
    expect((await store.read()).notified[_overrunKey], today);
  });

  test('同一事实当天已经提醒过，不再发第二条，但红点还在', () async {
    final today = formatDate(DateTime.now());
    await seed(ReminderState(notified: {_overrunKey: today}));

    final rows = await pendingRows();

    expect(rows.map((r) => r.key), [_overrunKey]);
    expect(notifier.presented, isEmpty);
  });

  test('昨天提醒过、今天还在超支，要再发一次', () async {
    await seed(const ReminderState(notified: {_overrunKey: '2026-09-13'}));

    await pendingRows();

    expect(notifier.presented.map((r) => r.key), [_overrunKey]);
  });

  test('即将超支只出红点，不进通知栏（§4.5 那张表的「推送」列）', () async {
    reset(pending: _bothReminders, settings: _warningOn);

    final rows = await pendingRows();

    expect(rows.map((r) => r.type), ['BUDGET_OVERRUN', 'BUDGET_WARNING']);
    expect(notifier.presented.map((r) => r.type), ['BUDGET_OVERRUN']);
  });

  test('红点数的是 App 内可见的条数，与发不发通知无关', () async {
    reset(pending: _bothReminders, settings: _warningOn);
    final container = open();

    await container.read(pendingReminderViewModelProvider.future);

    expect(container.read(pendingReminderCountProvider), 2);
    expect(notifier.presented, hasLength(1));
  });

  test('关掉某一类：它既不发通知也不进红点', () async {
    reset(
      settings: [
        for (final row in reminderSettings())
          if (row.type == 'BUDGET_OVERRUN')
            row.copyWith(enabled: false)
          else
            row,
      ],
    );

    final rows = await pendingRows();

    expect(rows, isEmpty);
    expect(notifier.presented, isEmpty);
  });

  test('划掉一条只消它自己，另一条照旧', () async {
    reset(pending: _bothReminders, settings: _warningOn);
    await seed(
      ReminderState(dismissed: {_overrunKey: formatDate(DateTime.now())}),
    );

    final rows = await pendingRows();

    expect(rows.map((r) => r.key), [_warningKey]);
    // 被划掉的正是那条会发通知的，剩下这条 pushed 为 false，于是一条都不发
    expect(notifier.presented, isEmpty);
  });

  test('用户拒了通知权限：红点照常，一条通知都不发', () async {
    reset(granted: false);

    final rows = await pendingRows();

    expect(rows.map((r) => r.key), [_overrunKey]);
    expect(notifier.log, ['init']);
    expect(notifier.cancelAllCount, 0);
  });

  test('划掉一条：当场少一条，并写下今天的日期', () async {
    reset(pending: _bothReminders, settings: _warningOn);
    final container = open();
    await container.read(pendingReminderViewModelProvider.future);

    await container
        .read(pendingReminderViewModelProvider.notifier)
        .dismiss(_overrunKey);

    expect(
      container
          .read(pendingReminderViewModelProvider)
          .requireValue
          .map((r) => r.key),
      [_warningKey],
    );
    expect(
      (await store.read()).dismissed[_overrunKey],
      formatDate(DateTime.now()),
    );
  });

  test('切开关交回的是整份七项，只有点的那一项变了', () async {
    final container = open();
    await container.read(reminderSettingViewModelProvider.future);

    final error = await container
        .read(reminderSettingViewModelProvider.notifier)
        .setEnabled('BUDGET_WARNING', true);

    expect(error, isNull);
    final items = repository.saved.single;
    expect(items.map((item) => item.type), hasLength(7));
    expect(
      items.firstWhere((item) => item.type == 'BUDGET_WARNING').enabled,
      isTrue,
    );
    expect(
      items
          .where((item) => item.type != 'BUDGET_WARNING')
          .every((item) => item.enabled),
      isTrue,
      reason: '其余六项后端默认就是开的，原样带回',
    );
    // 乐观更新：不重拉自己的清单，界面上那一格已经动了
    expect(
      container
          .read(reminderSettingViewModelProvider)
          .requireValue
          .firstWhere((row) => row.type == 'BUDGET_WARNING')
          .enabled,
      isTrue,
    );
    expect(repository.settingsCalls, 1);
  });

  test('切开关要重算待提醒：关掉的那类得从红点里消失', () async {
    reset(pending: _bothReminders, settings: _warningOn);
    final container = open();
    // 真实运行中红点一直挂着这个 provider。没人监听它算完就被回收，下面那次重算没有下游
    container.listen(pendingReminderViewModelProvider, (_, _) {});
    await container.read(pendingReminderViewModelProvider.future);
    expect(repository.pendingCalls, 1);

    await container
        .read(reminderSettingViewModelProvider.notifier)
        .setEnabled('BUDGET_WARNING', false);

    // 等这一轮真的算完：中途的状态是「loading 且仍带着上一轮的值」，那时读 value 拿到的是旧清单
    final rows = await container.read(pendingReminderViewModelProvider.future);

    expect(repository.pendingCalls, 2);
    expect(rows.map((r) => r.key), [_overrunKey]);
  });

  test('切开关失败就回滚到原样，也不重算待提醒', () async {
    final container = open();
    final before = await container.read(
      reminderSettingViewModelProvider.future,
    );
    repository.settingsFailure = const ApiException(
      code: 'VALIDATION_ERROR',
      message: '参数不合法',
    );

    final error = await container
        .read(reminderSettingViewModelProvider.notifier)
        .setEnabled('BUDGET_WARNING', true);

    expect(error, '参数不合法');
    expect(
      container.read(reminderSettingViewModelProvider).requireValue,
      before,
    );
    expect(repository.pendingCalls, 0);
  });

  test('排程类记的是它该响的那一天，不是今天', () async {
    const key = 'CAT_DEWORMING_EXTERNAL:CAT:1';
    final fireAt = DateTime.now().add(const Duration(days: 2));
    reset(
      pending: [
        reminder(
          type: 'CAT_DEWORMING_EXTERNAL',
          key: key,
          title: '猫咪体外驱虫到期',
          body: '咪咪的外驱还有 2 天',
          route: '/cat/dewormings',
          fireAt: fireAt,
        ),
      ],
    );

    final rows = await pendingRows();

    expect(rows, hasLength(1));
    expect(notifier.presented.single.fireAt, fireAt);
    expect(notifier.cancelAllCount, 1);
    expect(
      (await store.read()).notified[key],
      formatDate(fireAt),
      reason: '那天到了之后重算出来的立即提醒要靠这个日子认出「已经响过」',
    );
  });

  test('排程类每次都重排：定时已经被 cancelAll 取消掉，跳过就等于把今天这条丢了', () async {
    const key = 'CAT_DEWORMING_EXTERNAL:CAT:1';
    reset(
      pending: [
        reminder(
          type: 'CAT_DEWORMING_EXTERNAL',
          key: key,
          route: '/cat/dewormings',
          fireAt: DateTime.now().add(const Duration(days: 2)),
        ),
      ],
    );
    final container = open();
    container.listen(pendingReminderViewModelProvider, (_, _) {});
    await container.read(pendingReminderViewModelProvider.future);

    container.invalidate(pendingReminderViewModelProvider);
    await container.read(pendingReminderViewModelProvider.future);

    expect(notifier.presented, hasLength(2), reason: '同一天再进一次 App 要把它重新排上');
    expect(notifier.cancelAllCount, 2);
  });

  test('定时还排着时不能按「今天已提醒」跳过：那是刚被取消掉的，跳过就一条都收不到', () async {
    const key = 'CAT_DEWORMING_EXTERNAL:CAT:1';
    reset(
      pending: [
        reminder(
          type: 'CAT_DEWORMING_EXTERNAL',
          key: key,
          route: '/cat/dewormings',
        ),
      ],
    );
    notifier.scheduledIdsValue = {notificationIdOf(key)};
    await seed(ReminderState(notified: {key: formatDate(DateTime.now())}));

    await pendingRows();

    expect(notifier.presented.map((row) => row.key), [key]);
  });

  test('冷启动点通知的那一次跳转，等登录态就绪后交付', () async {
    reset(launchRoute: '/baby/vaccines');

    await pendingRows();

    expect(notifier.navigated, ['/baby/vaccines']);
  });

  test('冷启动点通知：那一屏的提醒一起记为今天看过了，红点当场就少', () async {
    reset(
      launchRoute: '/finance/budgets',
      pending: _bothReminders,
      settings: _warningOn,
    );

    final rows = await pendingRows();

    expect(rows, isEmpty, reason: '用户是被这两条里的某一条叫起来的，那一页已经看到了');
    expect(
      (await store.read()).dismissed.keys,
      containsAll([_overrunKey, _warningKey]),
    );
  });

  test('按落点消除：进了那一页，同一屏的提醒一起记为今天看过了', () async {
    reset(pending: _bothReminders, settings: _warningOn);
    final container = open();
    await container.read(pendingReminderViewModelProvider.future);

    await container
        .read(pendingReminderViewModelProvider.notifier)
        .dismissByRoute('/finance/budgets');

    expect(
      container.read(pendingReminderViewModelProvider).requireValue,
      isEmpty,
    );
    expect(
      (await store.read()).dismissed.keys,
      containsAll([_overrunKey, _warningKey]),
    );
  });

  test('电池优化引导：回写前读到未弹过，落盘之后才读得到', () async {
    final container = open();
    // 先把待提醒那一轮算完再动引导状态：那一轮在后台会往 reminder-state.json 写 `notified`，
    // 写到一半时 tearDown 正在删临时目录，Windows 上会以「目录不是空的」失败。
    // 这条用例验的是引导的读写时序，不该被另一条后台写入的时序牵连
    await container.read(pendingReminderViewModelProvider.future);
    final notifierOfPage = container.read(
      pendingReminderViewModelProvider.notifier,
    );

    expect(await notifierOfPage.isBatteryGuideShown(), isFalse);

    await notifierOfPage.markBatteryGuideShown();

    expect(await notifierOfPage.isBatteryGuideShown(), isTrue);
    expect((await store.read()).batteryGuideShown, isTrue);
  });

  test('scheduledIds 抛异常：按无排程降级，红点照常、当轮仍立即弹', () async {
    notifier.scheduledIdsFailure = Exception('MissingPluginException');

    // 红点数据不许被通知侧的异常烧掉：照常返回那一条
    final rows = await pendingRows();
    expect(rows.map((r) => r.key), [_overrunKey]);
    // 按「没有排程」降级后照常走投递
    expect(notifier.presented.map((r) => r.key), [_overrunKey]);
  });

  test('定时查询失败时「今天已提醒」照常跳过，不因降级重弹', () async {
    notifier.scheduledIdsFailure = Exception('MissingPluginException');
    notifier.scheduledIdsValue = {notificationIdOf(_overrunKey)};
    await seed(
      ReminderState(notified: {_overrunKey: formatDate(DateTime.now())}),
    );

    final rows = await pendingRows();

    expect(rows.map((r) => r.key), [_overrunKey]);
    expect(
      notifier.presented,
      isEmpty,
      reason: '降级成空集合后仍走「已弹过就跳过」；最坏是排程被取消的那次重排一次，可接受',
    );
  });

  test('cancelAll 抛异常也压不住重排：照常投递、红点不烧', () async {
    notifier.cancelAllFailure = Exception('MissingPluginException');

    final rows = await pendingRows();

    expect(rows.map((r) => r.key), [_overrunKey]);
    expect(notifier.presented.map((r) => r.key), [_overrunKey]);
  });

  test('单条投递失败只跳过这一条：其余照常投递、已记状态不污染', () async {
    const dewormKey = 'CAT_DEWORMING_EXTERNAL:CAT:1';
    // 两条都是 pushed=true 的：失败的那条被跳过后，排在它后面的仍要能投出去
    reset(
      pending: [
        reminder(key: _overrunKey),
        reminder(
          type: 'CAT_DEWORMING_EXTERNAL',
          key: dewormKey,
          title: '猫咪体外驱虫到期',
          route: '/cat/dewormings',
        ),
      ],
    );
    notifier.presentFailure = Exception('DeliveryBlocked');
    notifier.presentFailKeys = {_overrunKey};

    final rows = await pendingRows();

    expect(rows.map((r) => r.key), [
      _overrunKey,
      dewormKey,
    ], reason: '整屏红点不因一条投递失败而烧掉');
    expect(notifier.presented.map((r) => r.key), [
      dewormKey,
    ], reason: '失败的那条跳过，排在它后面的照常投递');
    final stored = await store.read();
    expect(
      stored.notified,
      isNot(contains(_overrunKey)),
      reason: '失败不写 touched，下次进 App 还会再试',
    );
    expect(stored.notified[dewormKey], formatDate(DateTime.now()));
  });
}
