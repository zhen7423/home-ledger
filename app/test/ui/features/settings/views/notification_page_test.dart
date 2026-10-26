import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeledger/data/models/pending_reminder.dart';
import 'package:homeledger/data/models/reminder_setting.dart';
import 'package:homeledger/data/repositories/reminder_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/reminder_notifier.dart';
import 'package:homeledger/data/services/reminder_state_store.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/core/date_format.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/settings/views/notification_page.dart';

import '../../../../support/fake_reminder_notifier.dart';
import '../../../../support/fake_reminder_state_store.dart';
import '../../../../support/s4_fixtures.dart';

const _overrunKey = 'BUDGET_OVERRUN:FAMILY';
const _warningKey = 'BUDGET_WARNING:FAMILY';

final List<PendingReminder> _twoReminders = [
  reminder(key: _overrunKey),
  reminder(
    type: 'BUDGET_WARNING',
    key: _warningKey,
    title: '家庭总预算即将超支',
    body: '本月已支出 4100 元，达到预算的 82%',
  ),
];

class _FakeReminderRepository implements ReminderRepository {
  _FakeReminderRepository({
    List<PendingReminder>? pending,
    List<ReminderSetting>? settings,
  }) : _pending = pending ?? _twoReminders,
       _settings = settings ?? reminderSettings();

  final List<PendingReminder> _pending;
  final List<ReminderSetting> _settings;

  final List<List<ReminderSettingItem>> saved = [];
  Object? settingsFailure;

  @override
  Future<List<ReminderSetting>> settings() async {
    final failure = settingsFailure;
    if (failure != null) throw failure;
    return _settings;
  }

  @override
  Future<void> saveSettings(List<ReminderSettingItem> items) async {
    final failure = settingsFailure;
    if (failure != null) throw failure;
    saved.add(items);
    for (final item in items) {
      final index = _settings.indexWhere((row) => row.type == item.type);
      if (index >= 0) {
        _settings[index] = _settings[index].copyWith(enabled: item.enabled);
      }
    }
  }

  @override
  Future<List<PendingReminder>> pending() async => _pending;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(text)));
}

/// 打开通知设置页要摸的三样东西：交上去的设置、发出去的通知、写下的去重状态。
class _Opened {
  _Opened(this.repository, this.notifier, this.store);

  final _FakeReminderRepository repository;
  final FakeReminderNotifier notifier;
  final FakeReminderStateStore store;
}

Future<_Opened> _open(
  WidgetTester tester, {
  List<PendingReminder>? pending,
  List<ReminderSetting>? settings,
  bool granted = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final repository = _FakeReminderRepository(
    pending: pending,
    settings: settings,
  );
  final notifier = FakeReminderNotifier(initResult: granted);
  final store = FakeReminderStateStore();
  final router = GoRouter(
    initialLocation: RoutePath.notifications,
    routes: [
      GoRoute(
        path: RoutePath.notifications,
        builder: (context, state) => const NotificationPage(),
      ),
      GoRoute(
        path: RoutePath.budgets,
        builder: (context, state) => const _Placeholder('预算管理页'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
        reminderRepositoryProvider.overrideWithValue(repository),
        reminderNotifierProvider.overrideWith((_) => notifier),
        reminderStateStoreProvider.overrideWithValue(store),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return _Opened(repository, notifier, store);
}

/// 某一类开关本身。七行长得很像，只能顺着标签找。
Finder _switchOf(String label) => find.descendant(
  of: find.widgetWithText(ListTile, label),
  matching: find.byType(Switch),
);

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    120,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  testWidgets('七个开关各一行，会不会发通知写在副标题上', (tester) async {
    await _open(tester);

    expect(find.byType(Switch), findsNWidgets(7));
    // pushed 由后端枚举定，界面只是说明它：五类进通知栏，两类只在 App 里
    expect(find.text('会发到系统通知栏'), findsNWidgets(5));
    expect(find.text('只在 App 内提示，不发通知'), findsNWidgets(2));
  });

  testWidgets('拨一下开关当场就动，交上去的是整份七项', (tester) async {
    // 「预算即将超支」后端默认是关的，七行里只有它是 off
    final opened = await _open(tester);
    await _scrollTo(tester, _switchOf('预算即将超支'));

    await tester.tap(_switchOf('预算即将超支'));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(_switchOf('预算即将超支')).value, isTrue);
    final items = opened.repository.saved.single;
    expect(items, hasLength(7));
    expect(
      items.firstWhere((item) => item.type == 'BUDGET_WARNING').enabled,
      isTrue,
    );
  });

  testWidgets('保存失败就退回原样，并说出服务端那句', (tester) async {
    final opened = await _open(tester);
    // 得等列表已经摆好了再装失败：首屏就报错的话这一段压根不渲染，没开关可拨
    opened.repository.settingsFailure = const ApiException(
      code: 'VALIDATION_ERROR',
      message: '参数不合法',
    );
    await _scrollTo(tester, _switchOf('预算即将超支'));

    await tester.tap(_switchOf('预算即将超支'));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(_switchOf('预算即将超支')).value, isFalse);
    expect(find.text('参数不合法'), findsOneWidget);
  });

  testWidgets('待处理提醒摆出标题与正文，条数写在分组标题上', (tester) async {
    await _open(tester, settings: reminderSettings(warningEnabled: true));

    expect(find.text('待处理提醒（2）'), findsOneWidget);
    expect(find.text('家庭总预算已超支'), findsOneWidget);
    expect(find.text('本月已支出 4100 元，达到预算的 82%'), findsOneWidget);
  });

  testWidgets('关掉的那一类不出现在待处理列表里', (tester) async {
    await _open(tester);

    // 两份数据都在，但「即将超支」的开关默认是关的
    expect(find.text('家庭总预算已超支'), findsOneWidget);
    expect(find.text('家庭总预算即将超支'), findsNothing);
    expect(find.text('待处理提醒（1）'), findsOneWidget);
  });

  testWidgets('点一条提醒跳到后端给的那条路径，并把它记为今天看过了', (tester) async {
    final opened = await _open(tester);

    await tester.tap(find.text('家庭总预算已超支'));
    await tester.pumpAndSettle();

    expect(find.text('预算管理页'), findsOneWidget);
    expect(
      opened.store.state.dismissed[_overrunKey],
      formatDate(DateTime.now()),
      reason: '§4.5.2：进入相应列表页后红点消除，而消除状态本地持久化',
    );
  });

  testWidgets('划掉一条只消它自己，并写下今天的日期', (tester) async {
    final opened = await _open(
      tester,
      settings: reminderSettings(warningEnabled: true),
    );
    await _scrollTo(tester, find.byIcon(Icons.close).first);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.text('家庭总预算已超支'), findsNothing);
    expect(find.text('家庭总预算即将超支'), findsOneWidget);
    expect(find.text('待处理提醒（1）'), findsOneWidget);
    expect(
      opened.store.state.dismissed[_overrunKey],
      formatDate(DateTime.now()),
    );
  });

  testWidgets('没有待处理提醒时给一句准话，不留一块空白', (tester) async {
    await _open(tester, pending: const []);

    expect(find.text('待处理提醒（0）'), findsOneWidget);
    expect(find.text('一切正常，没有待处理的提醒。'), findsOneWidget);
  });

  testWidgets('权限没开：顶部挂着那句提示，旁边给一个跳转入口', (tester) async {
    await _open(tester, granted: false);

    expect(find.text('通知权限未开启，超支提醒只会出现在 App 里。'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '去系统设置'), findsOneWidget);
  });

  testWidgets('权限是开的，就不该多出那句吓人的话', (tester) async {
    await _open(tester);

    expect(find.text('通知权限未开启，超支提醒只会出现在 App 里。'), findsNothing);
    expect(find.widgetWithText(TextButton, '去系统设置'), findsNothing);
  });

  testWidgets('点「去系统设置」只是把人送过去，不当场重查权限', (tester) async {
    final opened = await _open(tester, granted: false);

    await tester.tap(find.widgetWithText(TextButton, '去系统设置'));
    await tester.pumpAndSettle();

    expect(opened.notifier.openSettingsCount, 1);
    // 系统设置页才刚打开，用户还没动手，此刻查回来的必然还是旧值，提示不该闪
    expect(find.text('通知权限未开启，超支提醒只会出现在 App 里。'), findsOneWidget);
  });

  testWidgets('超支那条排了一条通知，预警那条一条都不排', (tester) async {
    final opened = await _open(
      tester,
      settings: reminderSettings(warningEnabled: true),
    );

    expect(opened.notifier.presented.map((row) => row.key), [_overrunKey]);
  });
}
