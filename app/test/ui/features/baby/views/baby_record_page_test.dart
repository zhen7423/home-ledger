import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/baby.dart';
import 'package:homeledger/data/models/baby_record.dart';
import 'package:homeledger/data/repositories/baby_record_repository.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_list_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_record_view_model.dart';
import 'package:homeledger/ui/features/baby/views/baby_record_page.dart';

import '../../../../support/s7_fixtures.dart';

/// §4.4.5 的里程碑与就诊。两套形状相同的 CRUD 合在一屏两段里，表单做成底部弹层——
/// 所以这一页要验的是：时间轴上那行带不带宝宝名、就诊那一行的费用不会被当成流水，
/// 以及「一个在册宝宝都没有」时新增被拦在门外而不是弹一张选不出宝宝的表单。
void main() {
  late _StubMilestones milestones;
  late _StubMedicals medicals;

  Future<void> open(
    WidgetTester tester, {
    int? babyId,
    List<BabyMilestone>? milestoneRows,
    List<BabyMedical>? medicalRows,
    List<Baby>? babies,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    milestones = _StubMilestones(milestoneRows ?? [milestoneFixture()]);
    medicals = _StubMedicals(medicalRows ?? [medicalFixture()]);

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
          babyListViewModelProvider.overrideWith(
            () => _StubBabies(
              babies ?? [babyFixture(), babyFixture(id: 2, name: '小红')],
            ),
          ),
          babyMilestoneViewModelProvider.overrideWith(() => milestones),
          babyMedicalViewModelProvider.overrideWith(() => medicals),
        ],
        child: MaterialApp(home: BabyRecordPage(babyId: babyId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester, String label) async {
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> openMedicalSegment(WidgetTester tester) async {
    await tester.tap(find.text('就诊'));
    await tester.pumpAndSettle();
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

  testWidgets('不给 babyId 时时间轴上每行都带宝宝名，日期在标题下面', (tester) async {
    await open(
      tester,
      milestoneRows: [
        milestoneFixture(),
        milestoneFixture(
          id: 401,
          babyId: 2,
          occurDate: DateTime(2026, 5, 20),
          title: '第一颗牙',
        ),
      ],
    );

    expect(find.text('里程碑与就诊'), findsOneWidget);
    expect(find.text('小明 · 第一次抬头'), findsOneWidget);
    expect(find.text('2026-01-08'), findsOneWidget);
    expect(find.text('小红 · 第一颗牙'), findsOneWidget);
  });

  testWidgets('给了 babyId 就只列那一个，行里不再重复宝宝名', (tester) async {
    await open(tester, babyId: 1);

    expect(find.text('小明 的里程碑与就诊'), findsOneWidget);
    expect(find.text('第一次抬头'), findsOneWidget);
    expect(find.textContaining('小明 ·'), findsNothing);
  });

  testWidgets('就诊那一行把医院、科室、诊断、用药、费用都写出来', (tester) async {
    await open(tester);
    await openMedicalSegment(tester);

    expect(find.text('小明 · 2026-08-03'), findsOneWidget);
    expect(find.text('市妇幼保健院 · 儿内科'), findsOneWidget);
    expect(find.text('诊断 上呼吸道感染'), findsOneWidget);
    expect(find.text('用药 小儿氨酚黄那敏颗粒'), findsOneWidget);
    expect(find.text('费用 ¥128.50'), findsOneWidget);
  });

  testWidgets('里程碑的内置常用项点一下就填进输入框', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('记一条里程碑'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('第一次翻身'));
    await tester.pumpAndSettle();

    // 内置项不是字典：写进库的就是这个 title，与手打的没有区别（§1.4 第 21 条）。
    expect(fieldText(tester, '标题'), '第一次翻身');
  });

  testWidgets('发生日期那一格没选就保存，当场拦下且不发请求', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('记一条里程碑'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '标题'), '第一次抬头');

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('请选择发生日期'), findsOneWidget);
    expect(milestones.creates, isEmpty);
  });

  testWidgets('记一条里程碑：填齐了保存，弹层关掉由页面发「已保存」', (tester) async {
    await open(tester, babyId: 1);
    await tester.tap(find.byTooltip('记一条里程碑'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '标题'), '第一次独坐');
    await tester.tap(find.byIcon(Icons.event_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    final draft = milestones.creates.single;
    expect(draft.babyId, 1);
    expect(draft.title, '第一次独坐');
    expect(draft.description, isNull);
    expect(find.text('记一条里程碑'), findsNothing);
    expect(find.text('已保存'), findsOneWidget);
  });

  testWidgets('一个在册宝宝都没有时新增被拦在门外，两段各说各的那一句', (tester) async {
    await open(tester, babies: [babyFixture(archived: true)]);

    await tester.tap(find.byTooltip('记一条里程碑'));
    await tester.pumpAndSettle();
    expect(find.text('还没有在册的宝宝，先建档再记录里程碑'), findsOneWidget);

    await openMedicalSegment(tester);
    await tester.tap(find.byTooltip('记一次就诊'));
    await tester.pumpAndSettle();
    expect(find.text('还没有在册的宝宝，先建档再记录就诊'), findsOneWidget);
  });

  testWidgets('删一条里程碑先问一句，那句话点明连到统计页', (tester) async {
    await open(tester);
    await openMenu(tester, '删除');

    expect(find.text('删除「第一次抬头」这条里程碑？'), findsOneWidget);
    expect(find.text('统计页的里程碑时间轴会跟着少一条。删除后无法恢复。'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(milestones.removed, [400]);
  });

  testWidgets('删一条就诊说的是不影响记账——它只是一条记录', (tester) async {
    await open(tester);
    await openMedicalSegment(tester);
    await openMenu(tester, '删除');

    expect(find.text('删除 2026-08-03 这条就诊记录？'), findsOneWidget);
    expect(find.text('它只是留档，删掉不影响记账。删除后无法恢复。'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(medicals.removed, [500]);
  });

  testWidgets('两段各有一句空态', (tester) async {
    await open(tester, milestoneRows: const [], medicalRows: const []);

    expect(find.text('还没有里程碑'), findsOneWidget);

    await openMedicalSegment(tester);
    expect(find.text('还没有就诊记录'), findsOneWidget);
    expect(find.text('记一次就诊留个档；费用只是一条记录，不会自动生成流水'), findsOneWidget);
  });
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

class _StubMilestones extends BabyMilestoneViewModel {
  _StubMilestones(this.rows);

  final List<BabyMilestone> rows;
  final List<MilestoneDraft> creates = [];
  final List<int> removed = [];

  @override
  Future<List<BabyMilestone>> build() async => rows;

  @override
  Future<String?> create(MilestoneDraft draft) async {
    creates.add(draft);
    return null;
  }

  @override
  Future<String?> remove(int id) async {
    removed.add(id);
    return null;
  }
}

class _StubMedicals extends BabyMedicalViewModel {
  _StubMedicals(this.rows);

  final List<BabyMedical> rows;
  final List<int> removed = [];

  @override
  Future<List<BabyMedical>> build() async => rows;

  @override
  Future<String?> remove(int id) async {
    removed.add(id);
    return null;
  }
}
