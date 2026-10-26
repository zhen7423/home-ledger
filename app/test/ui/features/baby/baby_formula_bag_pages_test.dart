import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeledger/data/models/baby_formula_bag.dart';
import 'package:homeledger/data/repositories/baby_formula_bag_repository.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_formula_view_model.dart';
import 'package:homeledger/ui/features/baby/views/baby_formula_bag_edit_page.dart';
import 'package:homeledger/ui/features/baby/views/baby_formula_bag_list_page.dart';

/// §4.5.3 奶粉开罐的两屏页面（第 32 轮）：列表时间线 + 记一罐/改一罐表单。
void main() {
  late _StubFormulas formulas;

  Future<void> openList(WidgetTester tester, {List<BabyFormulaBag>? rows}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    formulas = _StubFormulas(rows ?? const []);
    final router = GoRouter(
      initialLocation: RoutePath.babyFormulas,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const _Placeholder('上一屏'),
          routes: [
            GoRoute(
              path: RoutePath.babyFormulas.substring(1),
              builder: (context, state) => const BabyFormulaBagListPage(),
            ),
            GoRoute(
              path: RoutePath.babyFormulaEdit.substring(1),
              builder: (context, state) =>
                  BabyFormulaBagEditPage(id: null),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
          babyFormulaViewModelProvider.overrideWith(() => formulas),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openEdit(WidgetTester tester) async {
    await openList(tester);
    await tester.tap(find.byTooltip('记一罐'));
    await tester.pumpAndSettle();
  }

  testWidgets('空态：没有奶粉记录，给一个「记一罐」入口', (tester) async {
    await openList(tester);

    expect(find.text('还没有奶粉记录'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '记一罐'), findsOneWidget);
  });

  testWidgets('列表一行一罐：品牌 + 规格 + 开着到哪天的推导句，当前罐带「在用」', (tester) async {
    await openList(
      tester,
      rows: [
        BabyFormulaBag(
          id: 1,
          brand: '皇家一段',
          packGrams: 800,
          startedDate: DateTime(2026, 8, 1),
          usageDays: 20,
          dailyAverage: 40,
          current: false,
        ),
        BabyFormulaBag(
          id: 2,
          brand: '合生元',
          packGrams: 800,
          startedDate: DateTime(2026, 9, 1),
          usageDays: null,
          dailyAverage: null,
          current: true,
        ),
      ],
    );

    expect(find.text('皇家一段'), findsOneWidget);
    expect(find.text('合生元'), findsOneWidget);
    expect(find.text('在用'), findsOneWidget);
    expect(find.textContaining('800 g 装 · 喝了 20 天 · 日均 40 g'), findsOneWidget);
    expect(find.textContaining('日均 —'), findsOneWidget);
  });

  testWidgets('删除先问一句，确认才走 VM.remove', (tester) async {
    await openList(
      tester,
      rows: [
        BabyFormulaBag(
          id: 9,
          brand: '皇家一段',
          packGrams: 800,
          startedDate: DateTime(2026, 8, 1),
          current: true,
        ),
      ],
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除').last);
    await tester.pumpAndSettle();
    expect(find.text('删除「皇家一段」这一罐？'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(formulas.removed, [9]);
  });

  testWidgets('记一罐：品牌从候选芯片选、规格与预计日均走校验，保存发完整的表单', (tester) async {
    await openEdit(tester);

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
    // 规格在 Form 里、品牌是芯片不进 Form，校验先拦规格
    expect(find.text('请填写包装规格'), findsOneWidget);
    expect(formulas.created, isEmpty);

    await tester.tap(find.widgetWithText(ActionChip, '其他品牌'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '皇家一段');
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, '包装规格（克）'), '800');
    await tester.enterText(
        find.widgetWithText(TextFormField, '预计每天克数（选填）'), '100');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(formulas.created, hasLength(1));
    final draft = formulas.created.single;
    expect(draft.brand, '皇家一段');
    expect(draft.packGrams, 800);
    expect(draft.estimatedDailyGrams, 100);
  });
}

class _StubFormulas extends BabyFormulaViewModel {
  _StubFormulas(this.rows);

  final List<BabyFormulaBag> rows;
  final List<int> removed = [];
  final List<BabyFormulaBagDraft> created = [];

  @override
  Future<List<BabyFormulaBag>> build() async => rows;

  @override
  Future<String?> create(BabyFormulaBagDraft draft) async {
    created.add(draft);
    return null;
  }

  @override
  Future<String?> remove(int id) async {
    removed.add(id);
    return null;
  }
}

class _AlwaysSignedIn extends AuthViewModel {
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