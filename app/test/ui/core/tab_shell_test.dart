import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:homeledger/data/services/reminder_notifier.dart';
import 'package:homeledger/data/services/reminder_state_store.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/family/view_models/family_view_model.dart';

import '../../support/fake_reminder_notifier.dart';
import '../../support/fake_reminder_state_store.dart';
import '../../support/s4_fixtures.dart';
import '../../support/s9_fixtures.dart';

/// §3.2 的动态 Tab：起真路由表、真外壳，只看底栏画了几格。
///
/// 不测 `TabShell` 内部函数，走一遍真实挂载——「哪几个 Tab、什么顺序、点哪一格进哪一页」
/// 是这一层唯一的产出，绕开外壳去测映射表等于把要验的东西换成它的影子。
Family _family() => Family(
  id: 1,
  name: '小明的家',
  ownerUserId: 10,
  inviteEnabled: true,
  inviteCode: '228286',
  inviteCodeExpireAt: DateTime(2026, 9, 17),
  members: [
    Member(
      userId: 10,
      nickname: '小明',
      role: MemberRole.owner,
      joinedAt: DateTime(2026, 9, 10),
    ),
  ],
);

class _FakeFamilyRepository implements FamilyRepository {
  @override
  Future<Family?> current() async => _family();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeModuleRepository implements ModulePreferenceRepository {
  _FakeModuleRepository(this.rows);

  final List<ModulePreference> rows;

  @override
  Future<List<ModulePreference>> modules() async => rows;

  @override
  Future<void> saveModules(List<ModulePreferenceItem> items) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeHomeRepository implements HomeRepository {
  @override
  Future<HomeOverview> overview() async => homeOverview();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeReminderRepository implements ReminderRepository {
  _FakeReminderRepository(this.rows);

  final List<PendingReminder> rows;

  @override
  Future<List<ReminderSetting>> settings() async => reminderSettings();

  @override
  Future<List<PendingReminder>> pending() async => rows;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

class _StubFamily extends FamilyViewModel {
  @override
  Future<Family?> build() async => _family();
}

Future<void> _open(
  WidgetTester tester, {
  List<ModulePreference>? modules,
  List<PendingReminder>? pending,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
      familyViewModelProvider.overrideWith(_StubFamily.new),
      familyRepositoryProvider.overrideWithValue(_FakeFamilyRepository()),
      homeRepositoryProvider.overrideWithValue(_FakeHomeRepository()),
      modulePreferenceRepositoryProvider.overrideWithValue(
        _FakeModuleRepository(modules ?? modulePreferences()),
      ),
      reminderRepositoryProvider.overrideWithValue(
        _FakeReminderRepository(pending ?? const []),
      ),
      reminderNotifierProvider.overrideWith((_) => FakeReminderNotifier()),
      // 电池优化引导默认算「弹过了」：它是首启一次的事，不这么设的话每条用例都先面对一个对话框，
      // 而点底栏的动作会被那张对话框的遮罩吃掉
      reminderStateStoreProvider.overrideWithValue(
        FakeReminderStateStore(const ReminderState(batteryGuideShown: true)),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: container.read(routerProvider)),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _tabLabels(WidgetTester tester) => tester
    .widgetList<NavigationDestination>(find.byType(NavigationDestination))
    .map((row) => row.label)
    .toList();

void main() {
  testWidgets('三项全开时底栏是五个：首页 + 记账 + 宝宝 + 猫咪 + 设置（问题单 8）', (tester) async {
    await _open(tester);

    expect(_tabLabels(tester), ['首页', '记账', '宝宝', '猫咪', '设置']);
  });

  testWidgets('关掉猫咪，底栏少一格', (tester) async {
    await _open(tester, modules: modulePreferences(catEnabled: false));

    expect(_tabLabels(tester), ['首页', '记账', '宝宝', '设置']);
  });

  testWidgets('验收用例 32：三个模块全关，底栏只剩首页与设置，FAB 也收起来', (tester) async {
    await _open(
      tester,
      modules: modulePreferences(
        financeEnabled: false,
        catEnabled: false,
        babyEnabled: false,
      ),
    );

    expect(_tabLabels(tester), ['首页', '设置']);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('记账关掉但猫咪开着：FAB 收起，猫咪那一格还在', (tester) async {
    await _open(tester, modules: modulePreferences(financeEnabled: false));

    expect(_tabLabels(tester), ['首页', '宝宝', '猫咪', '设置']);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('首页不挂全局 FAB：浮起入口只在有记账动作的 Tab 上（问题单 1）', (tester) async {
    await _open(tester);

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('记账 Tab 的 FAB 是加号图标 + 记一笔 tooltip，不是带动文字按钮', (tester) async {
    await _open(tester);

    await tester.tap(find.text('记账'));
    // 记账页在测试里是真实 provider 的加载态（转圈动画不停），不能用 pumpAndSettle，
    // 切 Tab 的帧数有限，定长 pump 足够把 FAB 摆出来。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.tooltip, '记一笔');
    expect(fab.child, isA<Icon>());
    expect(find.text('记一笔'), findsNothing, reason: '入口只画图标，文字在 tooltip 里');
  });

  testWidgets('猫咪 Tab 的 FAB 入口是记猫粮，宝宝 Tab 的是记身高体重（问题单 1）', (tester) async {
    await _open(tester);

    await tester.tap(find.text('猫咪'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .tooltip,
      '记猫粮',
    );

    await tester.tap(find.text('宝宝'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<FloatingActionButton>(find.byType(FloatingActionButton))
          .tooltip,
      '记身高体重',
    );
  });

  testWidgets('设置页没有浮起入口', (tester) async {
    await _open(tester);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('Tabs 顺序跟着偏好走，不是写死的记账→猫咪→宝宝', (tester) async {
    await _open(
      tester,
      modules: [
        ModulePreference(
          moduleKey: 'BABY',
          label: '宝宝',
          enabled: true,
          sortNo: 0,
        ),
        ModulePreference(
          moduleKey: 'CAT',
          label: '猫咪',
          enabled: true,
          sortNo: 1,
        ),
        ModulePreference(
          moduleKey: 'FINANCE',
          label: '记账',
          enabled: true,
          sortNo: 2,
        ),
      ],
    );

    expect(_tabLabels(tester), ['首页', '宝宝', '猫咪', '记账', '设置']);
  });

  testWidgets('角标按模块分：首页数全部，各模块数自己那一份（§4.5.2）', (tester) async {
    await _open(
      tester,
      pending: [
        reminder(key: 'BUDGET_OVERRUN:FAMILY'),
        reminder(
          type: 'CAT_DEWORMING_EXTERNAL',
          module: 'CAT',
          key: 'CAT_DEWORMING_EXTERNAL:CAT:1',
          title: '猫咪体外驱虫到期',
          body: '咪咪的外驱已逾期 2 天',
          route: '/cat/dewormings',
        ),
      ],
    );

    final bar = find.byType(NavigationBar);
    expect(
      find.descendant(of: bar, matching: find.text('2')),
      findsOneWidget,
      reason: '首页那一格数的是全部待处理',
    );
    expect(
      find.descendant(of: bar, matching: find.text('1')),
      findsNWidgets(2),
      reason: '记账与猫咪各一条',
    );
  });

  testWidgets('一条待提醒都没有时一个角标都不画', (tester) async {
    await _open(tester);

    final bar = find.byType(NavigationBar);
    expect(find.descendant(of: bar, matching: find.text('1')), findsNothing);
  });

  testWidgets('点「设置」那一格切到设置分支，底栏那格随之高亮', (tester) async {
    await _open(tester);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 4, reason: '首页 0、记账 1、猫咪 2、宝宝 3、设置 4');
    // 设置页的内容出来了，说明那一格指的是设置这条分支
    expect(find.text('模块与 Tab'), findsOneWidget);
  });
}
