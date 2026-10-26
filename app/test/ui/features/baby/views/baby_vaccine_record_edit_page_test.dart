import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeledger/data/models/baby.dart';
import 'package:homeledger/data/models/baby_vaccine.dart';
import 'package:homeledger/data/repositories/baby_vaccine_record_repository.dart';
import 'package:homeledger/data/services/network_status.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_list_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_vaccine_record_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_vaccine_view_model.dart';
import 'package:homeledger/ui/features/baby/views/baby_vaccine_record_edit_page.dart';

import '../../../../support/s7_fixtures.dart';

/// §4.4.4 的接种记录录入。这一页最容易被写坏的是「下一针日期」那一格：`nextDate` 不在草稿里，
/// 服务端一律按该疫苗下一个未完成剂次推算，**渲染成一个填了不生效的输入框比不显示更糟**。
void main() {
  late _StubRecords records;
  late _StubPlans plans;

  Future<void> open(
    WidgetTester tester, {
    int? id,
    List<BabyVaccineRecord>? rows,
    List<BabyVaccinePlan>? planRows,
    List<Baby>? babies,
    NetworkStatus? network,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    records = _StubRecords(rows ?? [vaccineRecordFixture()]);
    plans = _StubPlans(planRows ?? const []);
    final router = _router(id);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
          babyListViewModelProvider.overrideWith(
            () => _StubBabies(babies ?? [babyFixture()]),
          ),
          babyVaccineRecordViewModelProvider.overrideWith(() => records),
          babyVaccineViewModelProvider.overrideWith(() => plans),
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

  Future<void> setText(WidgetTester tester, String label, String value) async {
    await tester.enterText(find.widgetWithText(TextFormField, label), value);
    await tester.pump();
  }

  String fieldText(WidgetTester tester, String label) => tester
      .widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextFormField, label),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;

  Future<void> save(WidgetTester tester) async {
    // 表单加长后保存按钮在视口外：ListView 懒构建，先把它拖进视口再点。
    await tester.dragUntilVisible(
      find.widgetWithText(FilledButton, '保存'),
      find.byType(ListView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
  }

  Future<void> pickBaby(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('小明').last);
    await tester.pumpAndSettle();
  }

  Future<void> pickGivenDate(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.event_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('疫苗名称、剂次、接种日期三格缺一个都不行，一次请求都不发', (tester) async {
    await open(tester);

    await save(tester);

    // 宝宝默认选中第一个（问题单 5），缺的只有名称、剂次与日期。
    expect(find.text('请选择宝宝'), findsNothing);
    expect(find.text('请填写疫苗名称'), findsOneWidget);
    expect(find.text('请填写剂次'), findsOneWidget);
    expect(find.text('请选择接种日期'), findsOneWidget);
    expect(records.creates, isEmpty);
  });

  testWidgets('从应种清单选一枚就填好名称剂次，提交带上 planId 指名回写', (tester) async {
    await open(
      tester,
      planRows: [
        planFixture(id: 201, vaccineName: '脊灰疫苗', doseNo: '2'),
        planFixture(id: 202, vaccineName: '百白破疫苗', doseNo: '3'),
      ],
    );

    await tester.tap(find.widgetWithText(ChoiceChip, '脊灰疫苗 第 2 剂'));
    await tester.pumpAndSettle();

    // 名称与剂次两格被自动填上，不需要手动录入（问题单 4）。
    expect(fieldText(tester, '疫苗名称'), '脊灰疫苗');
    expect(fieldText(tester, '剂次'), '2');

    await pickGivenDate(tester);
    await save(tester);

    final draft = records.creates.single;
    expect(draft.vaccineName, '脊灰疫苗');
    expect(draft.doseNo, '2');
    expect(draft.planId, 201, reason: '选中清单行后以 planId 指名回写');
  });

  testWidgets('手改名称后清掉整单里选的 planId，交回服务端按新键匹配', (tester) async {
    await open(
      tester,
      planRows: [planFixture(id: 201, vaccineName: '脊灰疫苗', doseNo: '2')],
    );

    await tester.tap(find.widgetWithText(ChoiceChip, '脊灰疫苗 第 2 剂'));
    await tester.pumpAndSettle();
    await setText(tester, '疫苗名称', '脊灰减毒活疫苗');

    await pickGivenDate(tester);
    await save(tester);

    expect(records.creates.single.planId, isNull);
    expect(records.creates.single.vaccineName, '脊灰减毒活疫苗');
  });

  testWidgets('「下一针日期」不是一个输入框，只有一行小字说明', (tester) async {
    await open(tester);

    expect(find.widgetWithText(TextFormField, '下一针日期'), findsNothing);
    expect(find.text('由服务端按该疫苗下一个未完成剂次推算，这里不能手填'), findsOneWidget);
  });

  testWidgets('编辑态回填这条记录，宝宝只读，并报出服务端上次算的下一针', (tester) async {
    await open(
      tester,
      id: 300,
      rows: [vaccineRecordFixture(nextDate: DateTime(2026, 3, 16))],
    );

    expect(find.text('编辑接种记录'), findsOneWidget);
    // 既有记录挂的宝宝可能已经归档，归档的宝宝不在选择器里。
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    expect(find.text('小明'), findsOneWidget);
    expect(find.text('由服务端推算，当前为 2026-03-16'), findsOneWidget);
    expect(find.text('改疫苗名称或剂次会重新匹配应种清单'), findsOneWidget);
  });

  testWidgets('新增态不提「重新匹配应种清单」那件事', (tester) async {
    await open(tester);

    expect(find.text('改疫苗名称或剂次会重新匹配应种清单'), findsNothing);
    expect(find.text('记一次接种'), findsOneWidget);
  });

  testWidgets('填齐了能存：草稿就是这几格，存完退回上一屏', (tester) async {
    await open(tester);
    await pickBaby(tester);
    await pickGivenDate(tester);
    await setText(tester, '疫苗名称', '乙肝疫苗');
    await setText(tester, '剂次', '2');
    await setText(tester, '接种机构（选填）', '社区卫生服务中心');

    await save(tester);

    final draft = records.creates.single;
    expect(draft.babyId, 1);
    expect(draft.vaccineName, '乙肝疫苗');
    expect(draft.doseNo, '2');
    expect(draft.clinic, '社区卫生服务中心');
    expect(draft.remark, isNull);
    expect(find.text('上一屏'), findsOneWidget);
  });

  testWidgets('编辑态改完存的是这条记录的 id', (tester) async {
    await open(tester, id: 300);
    await setText(tester, '剂次', '2');

    await save(tester);

    expect(records.saves.single.$1, 300);
    expect(records.saves.single.$2.doseNo, '2');
  });

  testWidgets('记录挂的宝宝已经不在了时说一声并退回', (tester) async {
    await open(tester, id: 999, rows: [vaccineRecordFixture()]);

    expect(find.text('没有找到这条接种记录，它可能已经被删除了'), findsOneWidget);
    expect(find.text('上一屏'), findsOneWidget);
  });

  testWidgets('家里一个在册宝宝都没有时整屏给建档入口', (tester) async {
    await open(tester, babies: [babyFixture(archived: true)]);

    expect(find.text('还没有在册的宝宝'), findsOneWidget);
    expect(find.text('接种记录要挂在宝宝名下，先建一个宝宝档案'), findsOneWidget);
    expect(find.text('宝宝建档'), findsOneWidget);
  });

  testWidgets('离线时保存按住，并把原因写在按钮下面', (tester) async {
    await open(tester, network: NetworkStatus.offline);

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '保存'))
          .onPressed,
      isNull,
    );
    expect(find.text('需联网后保存'), findsOneWidget);
  });
}

/// 录入页是 `/` 的一层子路由：保存成功要 `pop()` 回列表（清单那一段已经被回写成「已接种」）。
GoRouter _router(int? id) => GoRouter(
  initialLocation: RoutePath.babyVaccineRecordEdit,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _Placeholder('上一屏'),
      routes: [
        GoRoute(
          path: RoutePath.babyVaccineRecordEdit.substring(1),
          builder: (context, state) => BabyVaccineRecordEditPage(id: id),
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

class _StubRecords extends BabyVaccineRecordViewModel {
  _StubRecords(this.rows);

  final List<BabyVaccineRecord> rows;
  final List<VaccineRecordDraft> creates = [];
  final List<(int, VaccineRecordDraft)> saves = [];

  @override
  Future<List<BabyVaccineRecord>> build() async => rows;

  @override
  Future<String?> create(VaccineRecordDraft draft) async {
    creates.add(draft);
    return null;
  }

  @override
  Future<String?> save(int id, VaccineRecordDraft draft) async {
    saves.add((id, draft));
    return null;
  }
}

class _StubPlans extends BabyVaccineViewModel {
  _StubPlans(this.rows);

  final List<BabyVaccinePlan> rows;

  @override
  Future<List<BabyVaccinePlan>> build() async => rows;
}

class _FixedNetworkStatus extends NetworkStatusNotifier {
  _FixedNetworkStatus(this.status);

  final NetworkStatus status;

  @override
  NetworkStatus build() => status;
}
