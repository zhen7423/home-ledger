import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeledger/data/models/baby.dart';
import 'package:homeledger/data/models/baby_vaccine.dart';
import 'package:homeledger/data/repositories/baby_vaccine_plan_repository.dart';
import 'package:homeledger/data/repositories/baby_vaccine_record_repository.dart';
import 'package:homeledger/data/services/network_status.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/core/offline_banner.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_list_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_vaccine_record_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_vaccine_view_model.dart';
import 'package:homeledger/ui/features/baby/views/baby_vaccine_page.dart';

import '../../../../support/s7_fixtures.dart';

/// §4.4.4 的疫苗页。两个分段各读一组 provider，而动作是这一页最容易改坏的地方：
/// `DONE` 行一个动作都不给（它只由接种记录回写）、手动行才有删除、
/// 标过之后菜单换成撤销且离线时是灰的——灰掉的菜单项说不清为什么点不动。
void main() {
  late _StubPlans plans;
  late _StubRecords records;

  Future<void> open(
    WidgetTester tester, {
    int? babyId,
    List<BabyVaccinePlan>? planRows,
    List<BabyVaccineRecord>? recordRows,
    List<Baby>? babies,
    NetworkStatus? network,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    plans = _StubPlans(planRows ?? [planFixture()]);
    records = _StubRecords(recordRows ?? [vaccineRecordFixture()]);
    final router = _router(babyId);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
          babyListViewModelProvider.overrideWith(
            () => _StubBabies(babies ?? [babyFixture()]),
          ),
          babyVaccineViewModelProvider.overrideWith(() => plans),
          babyVaccineRecordViewModelProvider.overrideWith(() => records),
          if (network != null)
            networkStatusProvider.overrideWith(
              () => _FixedNetworkStatus(network),
            ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickMenu(WidgetTester tester, String label) async {
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
  }

  testWidgets('五态各一枚徽章，跳过那条靠删除线把自己与待接种分开', (tester) async {
    await open(
      tester,
      planRows: [
        planFixture(
          id: 201,
          vaccineName: '卡介苗',
          status: 'DONE',
          displayStatus: 'VACCINATED',
          recordId: 300,
        ),
        planFixture(
          id: 202,
          status: 'SKIPPED',
          displayStatus: 'MARKED',
          skipReason: '医生建议延后',
        ),
        planFixture(
          id: 203,
          vaccineName: '脊灰疫苗',
          dueDate: DateTime(2026, 9, 1),
          displayStatus: 'OVERDUE',
        ),
        planFixture(id: 204, vaccineName: '百白破疫苗', displayStatus: 'DUE_SOON'),
        planFixture(id: 205, vaccineName: '麻腮风疫苗', displayStatus: 'UPCOMING'),
      ],
    );

    expect(find.text('已接种'), findsOneWidget);
    expect(find.text('已跳过 / 不适用'), findsOneWidget);
    expect(find.text('逾期'), findsOneWidget);
    expect(find.text('即将接种'), findsOneWidget);
    expect(find.text('待接种'), findsOneWidget);
    // 两块同是灰的，删除线是这两行唯一的分别（§4.4.4）。
    expect(
      tester.widget<Text>(find.text('已跳过 / 不适用')).style?.decoration,
      TextDecoration.lineThrough,
    );
    // 不划那一支传的是 `decoration: null`，而 `labelSmall` 自带 `TextDecoration.none`，
    // `copyWith` 传 null 又是保留原值，所以只能断言「不是删除线」。
    expect(
      tester.widget<Text>(find.text('待接种')).style?.decoration,
      isNot(TextDecoration.lineThrough),
    );

    // 已接种那一行补上那条记录的实际接种日期，原因挂在跳过那一行下面。
    expect(find.text('接种 2025-09-16'), findsOneWidget);
    expect(find.text('原因：医生建议延后'), findsOneWidget);
  });

  testWidgets('已接种那一行一个动作都不给', (tester) async {
    await open(
      tester,
      planRows: [
        planFixture(status: 'DONE', displayStatus: 'VACCINATED', recordId: 300),
      ],
    );

    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });

  testWidgets('字典生成的行不能删：标记已接种 / 跳过 / 不适用三个方向', (tester) async {
    await open(tester);
    await openMenu(tester);

    expect(find.text('标记已接种'), findsOneWidget);
    expect(find.text('标记跳过'), findsOneWidget);
    expect(find.text('标记不适用'), findsOneWidget);
    // 字典生成的行删了，下次改生日重算又会补回来（§4.4.4）。
    expect(find.text('删除'), findsNothing);
  });

  testWidgets('标记已接种：日期空着当场拦下，一次请求都不发', (tester) async {
    await open(tester);
    await pickMenu(tester, '标记已接种');

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('请选择接种日期'), findsOneWidget);
    expect(records.creates, isEmpty);
  });

  testWidgets('标记已接种：选了日期就落一条带 planId 的记录，回写那一行（问题单 3）', (tester) async {
    await open(tester);
    await pickMenu(tester, '标记已接种');

    await tester.tap(find.byIcon(Icons.event_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    final draft = records.creates.single;
    expect(draft.babyId, 1);
    expect(draft.vaccineName, '乙肝疫苗');
    expect(draft.doseNo, '1');
    expect(draft.planId, 200, reason: '指名回写默认那份的第 200 号应种项');
    expect(draft.givenDate, isNotNull);
  });

  testWidgets('手动加的自费项多一个删除', (tester) async {
    await open(tester, planRows: [planFixture(manual: true)]);
    await openMenu(tester);

    expect(find.text('删除'), findsOneWidget);
  });

  testWidgets('标过的行菜单换成撤销，不再给标记', (tester) async {
    await open(
      tester,
      planRows: [
        planFixture(
          status: 'SKIPPED',
          displayStatus: 'MARKED',
          skipReason: '医生建议延后',
        ),
      ],
    );
    await openMenu(tester);

    expect(find.text('撤销标记'), findsOneWidget);
    expect(find.text('标记跳过'), findsNothing);
  });

  testWidgets('离线时撤销那一条是灰的，原因写在文案里', (tester) async {
    await open(
      tester,
      planRows: [
        planFixture(
          status: 'SKIPPED',
          displayStatus: 'MARKED',
          skipReason: 'x',
        ),
      ],
      network: NetworkStatus.offline,
    );
    await openMenu(tester);

    expect(find.byType(OfflineBanner), findsOneWidget);
    final item = tester.widget<PopupMenuItem<String>>(
      find.widgetWithText(PopupMenuItem<String>, '撤销标记（需联网后保存）'),
    );
    expect(item.enabled, isFalse);
  });

  testWidgets('撤销只发状态，不带原因', (tester) async {
    await open(
      tester,
      planRows: [
        planFixture(
          status: 'SKIPPED',
          displayStatus: 'MARKED',
          skipReason: 'x',
        ),
      ],
    );
    await pickMenu(tester, '撤销标记');

    expect(plans.marked.single, (200, 'PENDING', null));
  });

  testWidgets('标记时原因空着就当场拦下，一次请求都不发', (tester) async {
    await open(tester);
    await pickMenu(tester, '标记跳过');

    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();

    expect(find.text('请填写原因'), findsOneWidget);
    expect(plans.marked, isEmpty);
  });

  testWidgets('填了原因才真的发出去，原因是那一格里的原文', (tester) async {
    await open(tester);
    await pickMenu(tester, '标记跳过');

    await tester.enterText(
      find.widgetWithText(TextFormField, '原因（最多 50 个字）'),
      '医生建议延后',
    );
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();

    expect(plans.marked.single, (200, 'SKIPPED', '医生建议延后'));
  });

  testWidgets('删手动那一行要二次确认，那句话点明它是手动的', (tester) async {
    await open(tester, planRows: [planFixture(manual: true)]);
    await pickMenu(tester, '删除');

    expect(find.text('删除「乙肝疫苗 第 1 剂」？'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(plans.removed, [200]);
  });

  testWidgets('两个分段各列各自那份，接种记录带上下一针日期', (tester) async {
    await open(
      tester,
      recordRows: [vaccineRecordFixture(nextDate: DateTime(2026, 3, 16))],
    );

    await tester.tap(find.text('接种记录'));
    await tester.pumpAndSettle();

    expect(find.text('乙肝疫苗 · 第 1 剂'), findsOneWidget);
    // 不带 babyId 就是「全部宝宝」那一份，记录行的首行由日期变成「宝宝名 · 日期」。
    expect(find.text('小明 · 2025-09-16'), findsOneWidget);
    expect(find.text('社区卫生服务中心'), findsOneWidget);
    expect(find.text('下一针 2026-03-16'), findsOneWidget);
  });

  testWidgets('分段上的「+」不是同一件事', (tester) async {
    await open(tester, planRows: const []);
    expect(find.byTooltip('添加自费疫苗'), findsOneWidget);

    await tester.tap(find.text('接种记录'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('记一次接种'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('接种记录录入'), findsOneWidget);
  });

  testWidgets('两段各有一句空态', (tester) async {
    await open(tester, planRows: const [], recordRows: const []);

    expect(find.text('没有应种项'), findsOneWidget);

    await tester.tap(find.text('接种记录'));
    await tester.pumpAndSettle();

    expect(find.text('还没有接种记录'), findsOneWidget);
  });

  testWidgets('不给 babyId 时每行带宝宝名，给了就只列那一个', (tester) async {
    await open(tester);
    expect(find.text('疫苗'), findsOneWidget);
    expect(find.text('小明 · 乙肝疫苗'), findsOneWidget);

    await open(tester, babyId: 1);
    expect(find.text('小明 的疫苗'), findsOneWidget);
    expect(find.text('乙肝疫苗'), findsOneWidget);
  });

  group('自费预置弹层（第 30 轮）', () {
    Future<void> openDialog(
      WidgetTester tester, {
      List<BabyVaccinePlan>? planRows,
    }) async {
      // 带 babyId = 1 进页：弹层默认选中这个宝宝，宝宝选择器省一步，「已在清单」的判定
      // 只发生在「有宝宝可选」之后（§4.4.4 的应种项都挂在具体宝宝名下）。
      await open(tester, babyId: 1, planRows: planRows ?? const []);
      await tester.tap(find.byTooltip('添加自费疫苗'));
      await tester.pumpAndSettle();
    }

    testWidgets('默认选中五联：四剂 + 按出生日期算好的日期一次列全，说明块在', (tester) async {
      await openDialog(tester);

      // 五个预置 + 自定义，共六枚
      expect(find.byType(ChoiceChip), findsNWidgets(6));
      expect(
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '五联疫苗')).selected,
        isTrue,
      );
      // babyFixture 出生 2025-09-16 → 2/3/4/18 月龄
      expect(find.text('第 1 剂 · 2025-11-16'), findsOneWidget);
      expect(find.text('第 2 剂 · 2025-12-16'), findsOneWidget);
      expect(find.text('第 3 剂 · 2026-01-16'), findsOneWidget);
      expect(find.text('第 4 剂 · 2027-03-16'), findsOneWidget);
      expect(find.textContaining('可替代同月龄的脊灰与百白破'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pumpAndSettle();

      expect(plans.createdSeries, hasLength(1));
      final drafts = plans.createdSeries.single;
      expect(drafts.map((d) => d.vaccineName).toSet(), {'五联疫苗'});
      expect(drafts.map((d) => d.doseNo), ['1', '2', '3', '4']);
      expect(drafts.map((d) => d.dueDate), [
        DateTime(2025, 11, 16),
        DateTime(2025, 12, 16),
        DateTime(2026, 1, 16),
        DateTime(2027, 3, 16),
      ]);
    });

    testWidgets('已有一剂的预置：那一行标已在清单，保存只发缺的那三剂', (tester) async {
      await openDialog(
        tester,
        planRows: [planFixture(vaccineName: '五联疫苗', doseNo: '1')],
      );
      expect(find.text('已在清单'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pumpAndSettle();

      expect(plans.createdSeries, hasLength(1));
      expect(plans.createdSeries.single.map((d) => d.doseNo), ['2', '3', '4']);
    });

    testWidgets('四剂都已加过：一剂都不发，就地提示', (tester) async {
      await openDialog(
        tester,
        planRows: [
          for (final dose in ['1', '2', '3', '4'])
            planFixture(vaccineName: '五联疫苗', doseNo: dose),
        ],
      );

      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pumpAndSettle();

      expect(plans.createdSeries, isEmpty);
      expect(find.text('这个宝宝的五联疫苗剂次都已在应种清单里'), findsOneWidget);
    });

    testWidgets('切到自定义：回到原来的手工表单，预置剂次行退场', (tester) async {
      await openDialog(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, '自定义'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, '疫苗名称'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '剂次'), findsOneWidget);
      expect(find.text('应种日期'), findsOneWidget);
      expect(find.text('第 1 剂 · 2025-11-16'), findsNothing);
    });
  });
}

/// 疫苗页是 `/` 的一层子路由，接种记录录入那页挂在同一个父上（分段上的「+」往那儿走）。
GoRouter _router(int? babyId) => GoRouter(
  initialLocation: RoutePath.babyVaccines,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _Placeholder('上一屏'),
      routes: [
        GoRoute(
          path: RoutePath.babyVaccineRecordEdit.substring(1),
          builder: (context, state) => const _Placeholder('接种记录录入'),
        ),
        GoRoute(
          path: RoutePath.babyVaccines.substring(1),
          builder: (context, state) => BabyVaccinePage(babyId: babyId),
        ),
      ],
    ),
  ],
);

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(text)));
}

class _AlwaysSignedIn extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

class _StubBabies extends BabyListViewModel {
  _StubBabies(this.rows);

  final List<Baby> rows;

  @override
  Future<List<Baby>> build() async => rows;
}

class _StubPlans extends BabyVaccineViewModel {
  _StubPlans(this.rows);

  final List<BabyVaccinePlan> rows;
  final List<(int, String, String?)> marked = [];
  final List<int> removed = [];

  /// 预置整串建的剂次（第 30 轮）：一次保存四剂要能断出「发了四条、每条的疫苗名与应种日期」。
  final List<List<ManualPlanDraft>> createdSeries = [];

  @override
  Future<List<BabyVaccinePlan>> build() async => rows;

  @override
  Future<String?> mark(int id, String status, String? reason) async {
    marked.add((id, status, reason));
    return null;
  }

  @override
  Future<String?> remove(int id) async {
    removed.add(id);
    return null;
  }

  @override
  Future<String?> createManualSeries(List<ManualPlanDraft> drafts) async {
    createdSeries.add(drafts);
    return null;
  }
}

class _StubRecords extends BabyVaccineRecordViewModel {
  _StubRecords(this.rows);

  final List<BabyVaccineRecord> rows;
  final List<VaccineRecordDraft> creates = [];

  @override
  Future<List<BabyVaccineRecord>> build() async => rows;

  @override
  Future<String?> create(VaccineRecordDraft draft) async {
    creates.add(draft);
    return null;
  }
}

class _FixedNetworkStatus extends NetworkStatusNotifier {
  _FixedNetworkStatus(this.status);

  final NetworkStatus status;

  @override
  NetworkStatus build() => status;
}
