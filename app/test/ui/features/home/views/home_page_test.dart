import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeledger/data/models/family.dart';
import 'package:homeledger/data/models/home_overview.dart';
import 'package:homeledger/data/models/member.dart';
import 'package:homeledger/data/models/module_preference.dart';
import 'package:homeledger/data/models/pending_reminder.dart';
import 'package:homeledger/data/models/reminder_setting.dart';
import 'package:homeledger/data/models/reminder_state.dart';
import 'package:homeledger/data/repositories/family_repository.dart';
import 'package:homeledger/data/repositories/home_repository.dart';
import 'package:homeledger/data/repositories/module_preference_repository.dart';
import 'package:homeledger/data/repositories/reminder_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/reminder_notifier.dart';
import 'package:homeledger/data/services/reminder_state_store.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/home/views/home_page.dart';

import '../../../../support/fake_reminder_notifier.dart';
import '../../../../support/fake_reminder_state_store.dart';
import '../../../../support/s4_fixtures.dart';
import '../../../../support/s9_fixtures.dart';

/// 家庭那一份，两个成员，创建者是「小明」。
Family _family({int? id}) => Family(
  id: id ?? 1,
  name: '小明的家',
  ownerUserId: 1,
  inviteEnabled: true,
  inviteCode: 'AB12CD',
  inviteCodeExpireAt: DateTime(2026, 9, 20),
  members: [
    Member(
      userId: 1,
      nickname: '小明',
      role: MemberRole.owner,
      joinedAt: DateTime(2026, 9, 1),
    ),
    Member(
      userId: 2,
      nickname: '阿珍',
      role: MemberRole.member,
      joinedAt: DateTime(2026, 9, 2),
    ),
  ],
);

class _FakeFamilyRepository implements FamilyRepository {
  _FakeFamilyRepository(this.family);

  Family? family;

  int currentCalls = 0;

  Object? failure;

  @override
  Future<Family?> current() async {
    currentCalls++;
    final error = failure;
    if (error != null) throw error;
    return family;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeHomeRepository implements HomeRepository {
  _FakeHomeRepository(this.rows);

  HomeOverview rows;

  int overviewCalls = 0;

  @override
  Future<HomeOverview> overview() async {
    overviewCalls++;
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeReminderRepository implements ReminderRepository {
  _FakeReminderRepository({List<PendingReminder>? pending})
    : _pending = pending ?? [reminder()];

  final List<PendingReminder> _pending;

  int pendingCalls = 0;

  @override
  Future<List<ReminderSetting>> settings() async => reminderSettings();

  @override
  Future<List<PendingReminder>> pending() async {
    pendingCalls++;
    return _pending;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeModuleRepository implements ModulePreferenceRepository {
  _FakeModuleRepository(this.rows);

  List<ModulePreference> rows;

  @override
  Future<List<ModulePreference>> modules() async => rows;

  @override
  Future<void> saveModules(List<ModulePreferenceItem> items) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

/// 打开首页要摸的五份数据：家庭、聚合、待提醒、模块偏好、设备级的提醒状态。
class _Opened {
  _Opened(
    this.family,
    this.home,
    this.reminders,
    this.modules,
    this.notifier,
    this.store,
  );

  final _FakeFamilyRepository family;
  final _FakeHomeRepository home;
  final _FakeReminderRepository reminders;
  final _FakeModuleRepository modules;
  final FakeReminderNotifier notifier;
  final FakeReminderStateStore store;
}

Future<_Opened> _open(
  WidgetTester tester, {
  Family? family,
  HomeOverview? overview,
  List<PendingReminder>? pending,
  List<ModulePreference>? modules,
  Object? familyFailure,
  bool batteryGuideShown = true,
  Object? openSettingsFailure,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final familyRepo = _FakeFamilyRepository(family ?? _family())
    ..failure = familyFailure;
  final homeRepo = _FakeHomeRepository(overview ?? homeOverview());
  final reminderRepo = _FakeReminderRepository(pending: pending);
  final moduleRepo = _FakeModuleRepository(modules ?? modulePreferences());
  final notifier = FakeReminderNotifier()
    ..openSettingsFailure = openSettingsFailure;
  // 电池优化引导默认算「弹过了」：它是首启一次的事，不这么设的话每条用例都要先关掉一个对话框
  final store = FakeReminderStateStore(
    ReminderState(batteryGuideShown: batteryGuideShown),
  );

  final router = GoRouter(
    initialLocation: RoutePath.home,
    routes: [
      GoRoute(
        path: RoutePath.home,
        builder: (context, state) => const HomePage(),
      ),
      // 直接把 URI 当页名显示出来：跳带没带查询串，一眼就看得到。
      GoRoute(
        path: RoutePath.finance,
        builder: (context, state) =>
            Scaffold(body: Center(child: Text(state.uri.toString()))),
      ),
      for (final path in const [
        RoutePath.statistics,
        RoutePath.budgets,
        RoutePath.notifications,
        RoutePath.transactionNew,
        RoutePath.catFoodBagEdit,
        RoutePath.babyGrowthEdit,
      ])
        GoRoute(
          path: path,
          builder: (context, state) =>
              Scaffold(body: Center(child: Text(path))),
        ),
      GoRoute(
        path: '/finance/transaction/:id',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('流水详情页'))),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      // Riverpod 3 对失败的异步 provider 默认按指数退避重试 10 次，首屏失败那条用例配上
      // pumpAndSettle 会把这 10 次全走完，请求数就成了 11。测试只验自己的接线，重试是容器的事。
      retry: (_, _) => null,
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
        familyRepositoryProvider.overrideWithValue(familyRepo),
        homeRepositoryProvider.overrideWithValue(homeRepo),
        reminderRepositoryProvider.overrideWithValue(reminderRepo),
        modulePreferenceRepositoryProvider.overrideWithValue(moduleRepo),
        reminderNotifierProvider.overrideWith((_) => notifier),
        reminderStateStoreProvider.overrideWithValue(store),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return _Opened(
    familyRepo,
    homeRepo,
    reminderRepo,
    moduleRepo,
    notifier,
    store,
  );
}

void main() {
  testWidgets('概要卡摆出本月支出收入结余，点进去是统计页', (tester) async {
    await _open(
      tester,
      overview: homeOverview(
        summary: homeSummary(
          monthIncome: '5000.00',
          monthExpense: '120.00',
          monthBalance: '4880.00',
          recordedDays: 3,
        ),
      ),
    );

    expect(find.text('本月'), findsOneWidget);
    expect(find.text('¥120.00'), findsOneWidget);
    expect(find.text('¥5,000.00'), findsOneWidget);
    expect(find.text('¥4,880.00'), findsOneWidget);
    // 家庭信息条把「当月已记录天数」写在成员数旁边
    expect(find.text('成员 2 人 · 本月已记录 3 天'), findsOneWidget);

    await tester.tap(find.text('看统计'));
    await tester.pumpAndSettle();

    expect(find.text(RoutePath.statistics), findsOneWidget);
  });

  testWidgets('家庭设了总预算就摆那一条进度，任一维度超支整卡变红', (tester) async {
    await _open(
      tester,
      overview: homeOverview(
        budgets: [
          budgetProgress(amount: '5000.00'),
          budgetProgress(
            scope: 'CATEGORY',
            categoryName: '餐饮',
            amount: '800.00',
            used: '900.00',
            remaining: '-100.00',
            usedPercent: 112,
            level: 'EXCEEDED',
          ),
        ],
      ),
    );

    expect(find.text('本月支出与预算'), findsOneWidget);
    expect(find.text('已用 ¥1,000.00 / ¥5,000.00　20%'), findsOneWidget);

    final card = tester.widget<Card>(
      find.ancestor(of: find.text('本月支出与预算'), matching: find.byType(Card)),
    );
    final theme = Theme.of(tester.element(find.text('本月支出与预算')));
    expect(
      card.color,
      theme.colorScheme.errorContainer,
      reason: '这一条是家庭维度、档位正常，但它下面有个类别超了，整卡要变红',
    );
  });

  testWidgets('没设家庭总预算时那一块整个不出现', (tester) async {
    await _open(
      tester,
      overview: homeOverview(
        budgets: [budgetProgress(scope: 'CATEGORY', categoryName: '餐饮')],
      ),
    );

    expect(find.text('本月支出与预算'), findsNothing);
    expect(find.text('成员 2 人 · 本月已记录 0 天'), findsOneWidget);
  });

  testWidgets('今天自动记了账就摆那一块，点进去带 source=AUTO 切到记账 Tab', (tester) async {
    await _open(
      tester,
      overview: homeOverview(summary: homeSummary(autoGeneratedToday: 2)),
    );

    expect(find.text('今天已自动生成 2 笔周期记账'), findsOneWidget);

    await tester.tap(find.text('今天已自动生成 2 笔周期记账'));
    await tester.pumpAndSettle();

    expect(find.text('/finance?source=AUTO'), findsOneWidget);
  });

  testWidgets('今天一笔都没自动记，那一块不占位置', (tester) async {
    await _open(tester);

    expect(find.textContaining('今天已自动生成'), findsNothing);
  });

  testWidgets('有未处理的提醒就横向摆出卡片，点进后端给的那条路径', (tester) async {
    await _open(tester);

    expect(find.text('待处理'), findsOneWidget);
    expect(find.text('家庭总预算已超支'), findsOneWidget);

    await tester.tap(find.text('家庭总预算已超支'));
    await tester.pumpAndSettle();

    expect(find.text(RoutePath.budgets), findsOneWidget);
  });

  testWidgets('待处理卡片高度一致（第 34 轮）：正文长短不改变卡片高度', (tester) async {
    // 两条正文长度悬殊：一条一句话，一条三行。高度一致后短正文那条不应被压低。
    await _open(
      tester,
      pending: [
        reminder(
          title: '短条',
          body: '一句',
          key: 'X:SHORT',
        ),
        reminder(
          title: '长条',
          body: '第一行很长很长很长很长很长很长很长很长很长很长很长很长'
              '第二行很长很长很长很长很长很长很长很长很长很长很长很长'
              '第三行很长很长很长很长很长很长很长很长很长很长很长很长',
          key: 'X:LONG',
        ),
      ],
    );

    final short = tester.getRect(find.text('短条'));
    final long = tester.getRect(find.text('长条'));
    expect(short.height, long.height);
  });

  testWidgets('一条提醒都没有时整个卡片区不出现', (tester) async {
    await _open(tester, pending: const []);

    expect(find.text('待处理'), findsNothing);
  });

  testWidgets('快捷区按已启用模块给三个入口', (tester) async {
    await _open(tester);

    expect(find.text('记一笔'), findsOneWidget);
    expect(find.text('换猫粮'), findsOneWidget);
    expect(find.text('记身高体重'), findsOneWidget);
  });

  testWidgets('关掉猫咪：快捷区少一个换猫粮入口', (tester) async {
    await _open(tester, modules: modulePreferences(catEnabled: false));

    expect(find.text('记一笔'), findsOneWidget);
    expect(find.text('换猫粮'), findsNothing);
    expect(find.text('记身高体重'), findsOneWidget);
  });

  testWidgets('记账模块关掉：概要、预算、自动记账与快捷入口都不出现', (tester) async {
    await _open(
      tester,
      modules: modulePreferences(financeEnabled: false),
      overview: homeOverview(
        summary: homeSummary(autoGeneratedToday: 3),
        budgets: [budgetProgress()],
      ),
    );

    expect(find.text('本月'), findsNothing);
    expect(find.text('本月支出与预算'), findsNothing);
    expect(find.textContaining('今天已自动生成'), findsNothing);
    expect(find.text('记一笔'), findsNothing);
    // 家庭信息条与最近动态照旧
    expect(find.textContaining('成员 2 人'), findsOneWidget);
  });

  testWidgets('最近动态摆出标题、摘要、记录人与相对时间', (tester) async {
    await _open(
      tester,
      overview: homeOverview(
        recentActivities: [
          recentActivity(
            title: '给咪咪做了外驱',
            summary: '2026-09-17 · 测试用药',
            actorName: '阿珍',
            module: 'CAT',
            occurredAt: DateTime.now().subtract(const Duration(minutes: 12)),
            route: '/cat/dewormings',
          ),
        ],
      ),
    );

    expect(find.text('最近动态'), findsOneWidget);
    expect(find.text('给咪咪做了外驱'), findsOneWidget);
    expect(find.text('2026-09-17 · 测试用药 · 阿珍'), findsOneWidget);
    expect(find.text('12 分钟前'), findsOneWidget);
  });

  testWidgets('记录人已退出家庭时那句写「已退出的成员」而不是空白', (tester) async {
    await _open(
      tester,
      overview: homeOverview(
        recentActivities: [recentActivity(actorName: null)],
      ),
    );

    expect(find.textContaining('已退出的成员'), findsOneWidget);
  });

  testWidgets('一条动态都没有时最近动态整块不出现', (tester) async {
    await _open(tester);

    expect(find.text('最近动态'), findsNothing);
  });

  testWidgets('下拉刷新把家庭与聚合并待提醒都重拉一遍', (tester) async {
    final opened = await _open(tester);

    // touchSlopY 归零：默认那 12 像素的下限会吃掉小距离拖动，刷新指示器根本不出现
    //
    // 从列表顶部往下拖而不是从列表视口中心起手：默认夹具的内容很短，视口中心恰好
    // 压在「记一笔」快捷按钮上，从按钮上起手在测试环境里不会触发刷新——而真实页面的
    // 内容要长得多，下拉也从顶部起手更符合直觉。测试的还是同一件事：下拉把三份数据重拉一遍。
    await tester.dragFrom(
      const Offset(180, 100),
      const Offset(0, 300),
      touchSlopY: 0,
    );
    await tester.pumpAndSettle();

    expect(opened.family.currentCalls, 2);
    expect(opened.home.overviewCalls, 2);
    expect(opened.reminders.pendingCalls, 2);
  });

  testWidgets('打开首页就把该发的通知排出去了', (tester) async {
    final opened = await _open(tester);

    // 排期的驱动源在首页与外壳的 watch 上。少了那些 watch，这条一条都不发
    expect(opened.notifier.presented.map((row) => row.key), [
      'BUDGET_OVERRUN:FAMILY',
    ]);
  });

  testWidgets('首次进首页弹一次电池优化引导，关掉之后才回写', (tester) async {
    final opened = await _open(tester, batteryGuideShown: false);

    expect(find.text('让提醒准时响'), findsOneWidget);
    expect(
      opened.store.state.batteryGuideShown,
      isFalse,
      reason: '弹窗还没关就先落标志，首页在这中间被销毁就再也看不到引导了',
    );

    await tester.tap(find.widgetWithText(FilledButton, '知道了'));
    await tester.pumpAndSettle();

    expect(find.text('让提醒准时响'), findsNothing);
    expect(opened.store.state.batteryGuideShown, isTrue);
  });

  testWidgets('已经弹过的设备进首页不再打扰', (tester) async {
    await _open(tester);

    expect(find.text('让提醒准时响'), findsNothing);
  });

  testWidgets('「去系统设置」拉不起来也不许把异常漏到外面', (tester) async {
    final opened = await _open(
      tester,
      batteryGuideShown: false,
      openSettingsFailure: Exception('MissingPluginException'),
    );

    await tester.tap(find.widgetWithText(TextButton, '去系统设置'));
    await tester.pumpAndSettle();

    // 抛出会被 tester 记成失败；这里能走到断言就说明调用方已接住。
    // 对话框当场关闭、落盘标志照常回写：引导不能因为跳转失败而反复骚扰。
    expect(find.text('让提醒准时响'), findsNothing);
    expect(opened.store.state.batteryGuideShown, isTrue);
  });

  testWidgets('家庭信息拉失败，给一句人话和一个重试', (tester) async {
    final opened = await _open(
      tester,
      familyFailure: const ApiException(
        code: 'SYSTEM_ERROR',
        message: '系统繁忙，请稍后再试',
      ),
    );

    expect(find.text('系统繁忙，请稍后再试'), findsOneWidget);
    expect(find.textContaining('成员 2 人'), findsNothing);

    // 重试只是重新发一次请求，服务端得先恢复，不然点了还是错
    opened.family.failure = null;
    await tester.tap(find.widgetWithText(FilledButton, '重试'));
    await tester.pumpAndSettle();

    expect(find.textContaining('成员 2 人'), findsOneWidget);
    expect(opened.family.currentCalls, 2);
  });
}
