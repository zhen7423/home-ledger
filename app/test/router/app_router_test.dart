import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/cat_deworming.dart';
import 'package:homeledger/data/models/cat_food_bag.dart';
import 'package:homeledger/data/models/family.dart';
import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/data/models/member.dart';
import 'package:homeledger/data/repositories/cat_deworming_repository.dart';
import 'package:homeledger/data/repositories/cat_food_bag_repository.dart';
import 'package:homeledger/data/repositories/export_repository.dart';
import 'package:homeledger/data/services/file_sharer.dart';
import 'package:homeledger/data/services/network_status.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/family/view_models/family_view_model.dart';

import '../support/fake_export_repository.dart';
import '../support/fake_file_sharer.dart';
import '../support/s5_fixtures.dart';

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

String? _redirect(
  SessionStatus status,
  AsyncValue<Family?> family,
  String location,
) => resolveRedirect(status: status, family: family, location: location);

void main() {
  group('登录态未知', () {
    test('停在启动页，别处一律拉回启动页', () {
      expect(
        _redirect(
          SessionStatus.unknown,
          const AsyncLoading<Family?>(),
          RoutePath.splash,
        ),
        isNull,
      );
      expect(
        _redirect(
          SessionStatus.unknown,
          const AsyncLoading<Family?>(),
          RoutePath.home,
        ),
        RoutePath.splash,
      );
      expect(
        _redirect(
          SessionStatus.unknown,
          const AsyncLoading<Family?>(),
          RoutePath.login,
        ),
        RoutePath.splash,
      );
    });
  });

  group('已退出登录', () {
    test('去登录页，但登录与注册页自己不动', () {
      const loading = AsyncLoading<Family?>();
      expect(
        _redirect(SessionStatus.signedOut, loading, RoutePath.home),
        RoutePath.login,
      );
      expect(
        _redirect(SessionStatus.signedOut, loading, RoutePath.settings),
        RoutePath.login,
      );
      expect(
        _redirect(SessionStatus.signedOut, loading, RoutePath.splash),
        RoutePath.login,
      );
      expect(
        _redirect(SessionStatus.signedOut, loading, RoutePath.login),
        isNull,
      );
      expect(
        _redirect(SessionStatus.signedOut, loading, RoutePath.register),
        isNull,
      );
    });

    test('记账那一摊路径也一样先回登录页', () {
      const loading = AsyncLoading<Family?>();
      for (final path in [
        RoutePath.finance,
        RoutePath.transactionNew,
        RoutePath.categories,
        RoutePath.paymentAccounts,
        RoutePath.transactionOf(7),
      ]) {
        expect(
          _redirect(SessionStatus.signedOut, loading, path),
          RoutePath.login,
          reason: path,
        );
      }
    });
  });

  group('已登录', () {
    test('家庭还在加载时先停在启动页，不闪跳', () {
      expect(
        _redirect(
          SessionStatus.signedIn,
          const AsyncLoading<Family?>(),
          RoutePath.login,
        ),
        RoutePath.splash,
      );
      expect(
        _redirect(
          SessionStatus.signedIn,
          const AsyncLoading<Family?>(),
          RoutePath.splash,
        ),
        isNull,
      );
    });

    test('已站在壳内业务页时家庭数据重载不弹回启动页（下拉刷新守卫）', () {
      const loading = AsyncLoading<Family?>();
      // 首页下拉刷新会 invalidate familyViewModelProvider 让其回到 loading，
      // 这时候不能把用户弹回 logo 页，要在原页面原地等数据回来。
      for (final path in [
        RoutePath.home,
        RoutePath.settings,
        RoutePath.family,
        RoutePath.account,
        RoutePath.finance,
        RoutePath.catHome,
        RoutePath.babyHome,
      ]) {
        expect(
          _redirect(SessionStatus.signedIn, loading, path),
          isNull,
          reason: path,
        );
      }
      // 未落地位置（登录/引导/启动页自身）仍保持原行为：拉到启动页等家庭数据。
      expect(
        _redirect(SessionStatus.signedIn, loading, RoutePath.login),
        RoutePath.splash,
      );
      expect(
        _redirect(SessionStatus.signedIn, loading, RoutePath.onboarding),
        RoutePath.splash,
      );
      expect(
        _redirect(SessionStatus.signedIn, loading, RoutePath.splash),
        isNull,
      );
    });

    test('没有家庭就去引导页，但账号页放行', () {
      final none = AsyncData<Family?>(null);
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.splash),
        RoutePath.onboarding,
      );
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.home),
        RoutePath.onboarding,
      );
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.settings),
        RoutePath.onboarding,
      );
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.family),
        RoutePath.onboarding,
      );
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.onboarding),
        isNull,
      );
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.account),
        isNull,
      );
    });

    test('没有家庭也进不了记账，一律先去引导页', () {
      final none = AsyncData<Family?>(null);
      for (final path in [
        RoutePath.finance,
        RoutePath.transactionNew,
        RoutePath.categories,
        RoutePath.editTransaction(7),
      ]) {
        expect(
          _redirect(SessionStatus.signedIn, none, path),
          RoutePath.onboarding,
          reason: path,
        );
      }
    });

    test('没有家庭也改得了通知开关，但碰不了预算与规则', () {
      final none = AsyncData<Family?>(null);
      // 那七个开关存在 `reminder_setting.user_id` 上，跟家庭无关
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.notifications),
        isNull,
      );
      for (final path in [
        RoutePath.budgets,
        RoutePath.recurringRules,
        RoutePath.recurringRuleNew,
        RoutePath.recurringRuleOf(7),
      ]) {
        expect(
          _redirect(SessionStatus.signedIn, none, path),
          RoutePath.onboarding,
          reason: path,
        );
      }
    });

    test('有家庭就进首页，并离开引导页与登录注册页', () {
      final has = AsyncData<Family?>(_family());
      expect(
        _redirect(SessionStatus.signedIn, has, RoutePath.splash),
        RoutePath.home,
      );
      expect(
        _redirect(SessionStatus.signedIn, has, RoutePath.onboarding),
        RoutePath.home,
      );
      expect(
        _redirect(SessionStatus.signedIn, has, RoutePath.login),
        RoutePath.home,
      );
      expect(
        _redirect(SessionStatus.signedIn, has, RoutePath.register),
        RoutePath.home,
      );
      expect(_redirect(SessionStatus.signedIn, has, RoutePath.home), isNull);
      expect(
        _redirect(SessionStatus.signedIn, has, RoutePath.settings),
        isNull,
      );
      expect(_redirect(SessionStatus.signedIn, has, RoutePath.family), isNull);
      expect(_redirect(SessionStatus.signedIn, has, RoutePath.account), isNull);
    });

    test('有家庭时记账相关路径都放行', () {
      final has = AsyncData<Family?>(_family());
      for (final path in [
        RoutePath.finance,
        RoutePath.transactionNew,
        RoutePath.categories,
        RoutePath.paymentAccounts,
        RoutePath.transactionOf(7),
        RoutePath.editTransaction(7),
        RoutePath.budgets,
        RoutePath.recurringRules,
        RoutePath.recurringRuleOf(7),
        RoutePath.notifications,
        RoutePath.statistics,
        RoutePath.export,
      ]) {
        expect(
          _redirect(SessionStatus.signedIn, has, path),
          isNull,
          reason: path,
        );
      }
    });
  });

  group('统计页与导出页', () {
    test('没有家庭时这两页都不给进，统计要按家庭聚合', () {
      final none = AsyncData<Family?>(null);
      for (final path in [RoutePath.statistics, RoutePath.export]) {
        expect(
          _redirect(SessionStatus.signedIn, none, path),
          RoutePath.onboarding,
          reason: path,
        );
      }
    });

    test('统计页带过去的条件是查询串，没带的那条压根不出现', () {
      expect(
        RoutePath.exportWith(
          const StatisticsQuery(
            startDate: '2026-09-01',
            endDate: '2026-09-14',
            createdBy: 10,
          ),
        ),
        '/finance/export?startDate=2026-09-01&endDate=2026-09-14&createdBy=10',
      );
      // 没带记录人时那一段整个不出现，而不是留一个空值 `createdBy=`
      expect(
        RoutePath.exportWith(
          const StatisticsQuery(startDate: '2026-09-01', endDate: '2026-09-14'),
        ),
        '/finance/export?startDate=2026-09-01&endDate=2026-09-14',
      );
      // 三个条件一个都没挑时：一个参数都不编进去，末尾也不留光秃秃的 `?`
      expect(RoutePath.exportWith(const StatisticsQuery()), '/finance/export');
    });

    testWidgets('记录人那段解不开时不白屏，只当没带这一条', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
          familyViewModelProvider.overrideWith(_StubFamily.new),
          exportRepositoryProvider.overrideWithValue(
            FakeExportRepository(summary: summary()),
          ),
          fileSharerProvider.overrideWithValue(FakeFileSharer()),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      // 挂载之前就把地址换过去：`initialLocation` 是启动页，挂上去之后它会先把首页那一摊
      // provider 拉起来，跟这一条要验的东西毫无关系
      router.go(
        '${RoutePath.export}?startDate=2026-09-01&endDate=2026-09-14&createdBy=abc',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('导出数据'), findsOneWidget);
      // 两个日期照常收下，只有解不开的记录人当成没带
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '全部成员'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '小明'))
            .selected,
        isFalse,
      );
    });
  });

  group('猫咪九条路由', () {
    // `allowed` 那个集合一个字都没改：九条 cat 路径都不在里面。这两条挡的是日后有人
    // 「顺手把 /cat 加进白名单，猫不也要家庭才能看吗」那次改动。
    test('没有家庭时九条都不给进，一律先去引导页', () {
      final none = AsyncData<Family?>(null);
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.catHome),
        RoutePath.onboarding,
      );
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.catCats),
        RoutePath.onboarding,
      );
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.catCatEdit),
        RoutePath.onboarding,
      );
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.catFoodBags),
        RoutePath.onboarding,
      );
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.catFoodBagEdit),
        RoutePath.onboarding,
      );
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.catDewormings),
        RoutePath.onboarding,
      );
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.catDewormingEdit),
        RoutePath.onboarding,
      );
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.catSettings),
        RoutePath.onboarding,
      );
      expect(
        _redirect(SessionStatus.signedIn, none, RoutePath.catStatistics),
        RoutePath.onboarding,
      );
    });

    test('有家庭时九条都放行', () {
      final has = AsyncData<Family?>(_family());
      expect(_redirect(SessionStatus.signedIn, has, RoutePath.catHome), isNull);
      expect(_redirect(SessionStatus.signedIn, has, RoutePath.catCats), isNull);
      expect(
        _redirect(SessionStatus.signedIn, has, RoutePath.catCatEdit),
        isNull,
      );
      expect(
        _redirect(SessionStatus.signedIn, has, RoutePath.catFoodBags),
        isNull,
      );
      expect(
        _redirect(SessionStatus.signedIn, has, RoutePath.catFoodBagEdit),
        isNull,
      );
      expect(
        _redirect(SessionStatus.signedIn, has, RoutePath.catDewormings),
        isNull,
      );
      expect(
        _redirect(SessionStatus.signedIn, has, RoutePath.catDewormingEdit),
        isNull,
      );
      expect(
        _redirect(SessionStatus.signedIn, has, RoutePath.catSettings),
        isNull,
      );
      expect(
        _redirect(SessionStatus.signedIn, has, RoutePath.catStatistics),
        isNull,
      );
    });
  });

  group('宝宝十条路由', () {
    // 与猫那九条同一件事：`allowed` 那个集合一个字都没改，十条 baby 路径都不在里面。
    // 这两条挡的是日后有人「顺手把 /baby 加进白名单」那次改动——宝宝档案与总览一样离不开家庭。
    test('没有家庭时十条都不给进，一律先去引导页', () {
      final none = AsyncData<Family?>(null);
      for (final path in _babyPaths) {
        expect(
          _redirect(SessionStatus.signedIn, none, path),
          RoutePath.onboarding,
          reason: path,
        );
      }
    });

    test('有家庭时十条都放行', () {
      final has = AsyncData<Family?>(_family());
      for (final path in _babyPaths) {
        expect(
          _redirect(SessionStatus.signedIn, has, path),
          isNull,
          reason: path,
        );
      }
    });
  });

  group('猫咪路由的参数', () {
    testWidgets('点新增进的是干净的新建页，不带 id 时不白屏', (tester) async {
      // `?id=` 解不出时回 null 而不是 0：0 会让这一页变成「按 id 回填失败」的编辑页，
      // 看上去正常，但保存时改的是不存在的那条。
      await _openCatPage(tester, RoutePath.catCatEdit);

      expect(tester.takeException(), isNull);
      expect(find.text('猫咪建档'), findsOneWidget);
      expect(find.text('编辑猫咪'), findsNothing);
    });

    testWidgets('驱虫列表带 catId 时只显示那一只', (tester) async {
      await _openCatPage(
        tester,
        RoutePath.catDewormingsOf(3),
        deworming: _FakeCatDewormingRepository([
          _deworming(id: 1, catId: 3, catName: '大橘'),
          _deworming(id: 2, catId: 3, catName: '大橘'),
          _deworming(id: 3, catId: 1, catName: '咪咪'),
        ]),
      );

      expect(find.text('大橘'), findsNWidgets(2));
      expect(find.text('咪咪'), findsNothing);
    });

    testWidgets('提醒里存的 route 字符串能落到真实页面', (tester) async {
      // 后端 `ReminderServiceImpl` 存的是这两个字面量，不走 `RoutePath`：
      // 前端路由表与那份字符串是不是同一套，只有在路由表这侧断才测得出来。
      await _openCatPage(
        tester,
        '/cat/dewormings',
        deworming: _FakeCatDewormingRepository(const []),
      );
      expect(find.text('驱虫记录'), findsOneWidget);

      await _openCatPage(
        tester,
        '/cat/food-bags',
        foodBags: _FakeCatFoodBagRepository(),
      );
      expect(find.text('猫粮袋'), findsOneWidget);
    });
  });
}

/// 十条 baby 路径，两条断言共用一份，免得两处各抄一遍还抄漏一条。
const List<String> _babyPaths = [
  RoutePath.babyHome,
  RoutePath.babyList,
  RoutePath.babyEdit,
  RoutePath.babyGrowths,
  RoutePath.babyGrowthEdit,
  RoutePath.babyGrowthCurve,
  RoutePath.babyVaccines,
  RoutePath.babyVaccineRecordEdit,
  RoutePath.babyRecords,
  RoutePath.babyStatistics,
];

/// 起真路由表，直接落在要验的那条路径上。挂载之前就 `go`：`initialLocation` 是启动页，
/// 挂上去之后重定向会把首页那一摊 provider 全拉起来，跟这一组要验的参数解析无关。
Future<void> _openCatPage(
  WidgetTester tester,
  String location, {
  CatDewormingRepository? deworming,
  CatFoodBagRepository? foodBags,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
      familyViewModelProvider.overrideWith(_StubFamily.new),
      networkStatusProvider.overrideWith(_AlwaysOnline.new),
      if (deworming != null)
        catDewormingRepositoryProvider.overrideWithValue(deworming),
      if (foodBags != null)
        catFoodBagRepositoryProvider.overrideWithValue(foodBags),
    ],
  );
  addTearDown(container.dispose);
  final router = container.read(routerProvider);
  router.go(location);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

CatDeworming _deworming({
  required int id,
  required int catId,
  required String catName,
}) => CatDeworming(
  id: id,
  catId: catId,
  catName: catName,
  type: 'EXTERNAL',
  doneDate: DateTime(2026, 9, 1),
  medicine: '测试药',
  nextDate: DateTime(2026, 10, 1),
  daysToDue: 15,
);

class _AlwaysOnline extends NetworkStatusNotifier {
  @override
  NetworkStatus build() => NetworkStatus.online;
}

class _FakeCatDewormingRepository implements CatDewormingRepository {
  _FakeCatDewormingRepository(this.rows);

  final List<CatDeworming> rows;

  @override
  Future<List<CatDeworming>> list({int? catId}) async => rows;

  @override
  Future<void> create(CatDewormingDraft draft) async {}

  @override
  Future<void> update(int id, CatDewormingDraft draft) async {}

  @override
  Future<void> remove(int id) async {}
}

class _FakeCatFoodBagRepository implements CatFoodBagRepository {
  @override
  Future<List<CatFoodBag>> list() async => const [];

  @override
  Future<CatFoodCurrent?> current() async => null;

  @override
  Future<void> create(CatFoodBagDraft draft) async {}

  @override
  Future<void> update(int id, CatFoodBagDraft draft) async {}

  @override
  Future<void> remove(int id) async {}
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

class _StubFamily extends FamilyViewModel {
  @override
  Future<Family?> build() async => _family();
}
