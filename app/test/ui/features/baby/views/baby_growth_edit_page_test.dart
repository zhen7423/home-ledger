import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeledger/data/models/baby.dart';
import 'package:homeledger/data/models/baby_growth.dart';
import 'package:homeledger/data/repositories/baby_growth_repository.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_growth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_list_view_model.dart';
import 'package:homeledger/ui/features/baby/views/baby_growth_edit_page.dart';

import '../../../../support/s7_fixtures.dart';

/// §4.4.2 的身高体重录入，同一页靠 `?id=` 有没有值区分。三处页面上独有的判断：
/// 「身高与体重至少填一项」把保存按住而不是等一次往返、宝宝那一栏编辑态只读、
/// 以及「上一次」那一块在新增与编辑两种形态下取的是不同的那一行。
void main() {
  late _StubGrowth growth;

  Future<void> open(
    WidgetTester tester, {
    int? id,
    List<BabyGrowth>? rows,
    List<Baby>? babies,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    growth = _StubGrowth(rows ?? [growthFixture()]);
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
          babyGrowthViewModelProvider.overrideWith(() => growth),
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
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
  }

  Future<void> pickBaby(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('小明').last);
    await tester.pumpAndSettle();
  }

  Future<void> pickMeasureDate(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.event_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('身高与体重一项都没填时保存按住，并写明为什么', (tester) async {
    await open(tester);

    expect(find.text('身高与体重至少填一项'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '保存'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('只填了度量还不够：测量日期缺着就拦下，一次请求都不发（宝宝已默认选中第一个，问题单 5）', (tester) async {
    await open(tester);
    await setText(tester, '身高（cm，选填）', '62.5');

    await save(tester);

    expect(find.text('请选择宝宝'), findsNothing);
    expect(find.text('请选择测量日期'), findsOneWidget);
    expect(growth.creates, isEmpty);
  });

  testWidgets('身高多一位小数就拦下，不留给 MySQL 悄悄四舍五入', (tester) async {
    await open(tester);
    await setText(tester, '身高（cm，选填）', '62.55');

    await save(tester);

    expect(find.text('身高最多一位小数'), findsOneWidget);
    expect(growth.creates, isEmpty);
  });

  testWidgets('填齐了能存：草稿就是这几格，存完退回上一屏', (tester) async {
    await open(tester);
    await pickBaby(tester);
    await pickMeasureDate(tester);
    await setText(tester, '身高（cm，选填）', '76.5');
    await setText(tester, '体重（kg，选填）', '9.80');

    await save(tester);

    final draft = growth.creates.single;
    expect(draft.babyId, 1);
    expect(draft.heightCm, '76.5');
    expect(draft.weightKg, '9.80');
    // 头围与备注一格没填就交 null，而不是空串——空串会在服务端撞形态校验。
    expect(draft.headCm, isNull);
    expect(draft.remark, isNull);
    expect(find.text('上一屏'), findsOneWidget);
  });

  testWidgets('多个在册宝宝时新增表单默认选中第一个（问题单 5），不用先手选', (tester) async {
    await open(
      tester,
      babies: [babyFixture(), babyFixture(id: 2, name: '小红')],
    );
    await pickMeasureDate(tester);
    await setText(tester, '身高（cm，选填）', '76.5');

    await save(tester);

    expect(growth.creates.single.babyId, 1, reason: '默认落在第一个宝宝上');
  });

  testWidgets('编辑态回填这条记录，宝宝只读，并给出它的「上一次」', (tester) async {
    await open(
      tester,
      id: 100,
      rows: [
        growthFixture(),
        growthFixture(
          id: 99,
          measureDate: DateTime(2026, 8, 10),
          heightCm: '75.0',
          weightKg: '9.40',
          headCm: '45.5',
          delta: null,
        ),
      ],
    );

    expect(find.text('编辑身高体重'), findsOneWidget);
    expect(fieldText(tester, '身高（cm，选填）'), '76.5');
    // 只读的理由：既有记录挂的宝宝可能已经归档，归档的宝宝不在上面的选择器里。
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    expect(find.text('小明'), findsOneWidget);
    expect(find.text('上一次 · 2026-08-10'), findsOneWidget);
    expect(find.text('身高 75.0 cm · 体重 9.40 kg · 头围 45.5 cm'), findsOneWidget);
    // 差值由服务端派生，前端只读不重算（§4.4.2）。
    expect(
      find.text('较上次 身高 +1.5 cm · 体重 +0.40 kg · 头围 +0.5 cm · 30 天'),
      findsOneWidget,
    );
  });

  testWidgets('新增态的「上一次」是该宝宝最近一次，手头没新值就没有差值那一行', (tester) async {
    await open(tester);
    await pickBaby(tester);

    expect(find.text('该宝宝最近一次 · 2026-09-10'), findsOneWidget);
    expect(find.textContaining('较上次'), findsNothing);
  });

  testWidgets('编辑态改完存的是这条记录的 id', (tester) async {
    await open(tester, id: 100);
    await setText(tester, '体重（kg，选填）', '9.90');

    await save(tester);

    expect(growth.saves.single.$1, 100);
    expect(growth.saves.single.$2.weightKg, '9.90');
    expect(find.text('上一屏'), findsOneWidget);
  });

  testWidgets('家里一个在册宝宝都没有时整屏给建档入口，不摆一张选不出宝宝的表单', (tester) async {
    await open(tester, babies: [babyFixture(archived: true)]);

    expect(find.text('还没有在册的宝宝'), findsOneWidget);
    expect(find.text('身高体重记录要挂在宝宝名下，先建一个宝宝档案'), findsOneWidget);
    expect(find.text('宝宝建档'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
}

/// 录入页是 `/` 的一层子路由：保存成功要 `pop()` 回上一屏，测试里就得有上一屏。
GoRouter _router(int? id) => GoRouter(
  initialLocation: RoutePath.babyGrowthEdit,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _Placeholder('上一屏'),
      routes: [
        GoRoute(
          path: RoutePath.babyGrowthEdit.substring(1),
          builder: (context, state) => BabyGrowthEditPage(id: id),
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

class _StubGrowth extends BabyGrowthViewModel {
  _StubGrowth(this.rows);

  final List<BabyGrowth> rows;
  final List<BabyGrowthDraft> creates = [];
  final List<(int, BabyGrowthDraft)> saves = [];

  @override
  Future<List<BabyGrowth>> build() async => rows;

  @override
  Future<String?> create(BabyGrowthDraft draft) async {
    creates.add(draft);
    return null;
  }

  @override
  Future<String?> save(int id, BabyGrowthDraft draft) async {
    saves.add((id, draft));
    return null;
  }
}
