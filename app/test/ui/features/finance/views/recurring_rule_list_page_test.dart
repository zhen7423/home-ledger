import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeledger/data/models/flow_type.dart';
import 'package:homeledger/data/models/recurring_rule.dart';
import 'package:homeledger/data/repositories/recurring_rule_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/finance/views/recurring_rule_list_page.dart';

import '../../../../support/s4_fixtures.dart';

class _FakeRuleRepository implements RecurringRuleRepository {
  _FakeRuleRepository(this.rows);

  List<RecurringRule> rows;

  final List<int> toggled = [];
  int listCalls = 0;
  Object? writeFailure;

  @override
  Future<List<RecurringRule>> list({String? type}) async {
    listCalls++;
    return rows;
  }

  @override
  Future<RecurringRule> toggle(int id) async {
    final failure = writeFailure;
    if (failure != null) throw failure;
    toggled.add(id);
    rows = [
      for (final row in rows)
        if (row.id == id) row.copyWith(enabled: !row.enabled) else row,
    ];
    return rows.firstWhere((row) => row.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

/// 列表页的两个动作都是推开二级页（新建、看详情），所以给它一条真的路由。
/// 二级页只放占位文本：这里要证的是「跳到了哪、带着哪个 id」，不是那一页的内容。
GoRouter _openRouter() => GoRouter(
  initialLocation: RoutePath.recurringRules,
  routes: [
    GoRoute(
      path: RoutePath.recurringRules,
      builder: (context, state) => const RecurringRuleListPage(),
    ),
    // 顺序照搬 app 里的那份：新建这条必须排在带 :id 的前面，否则 'new' 会被当成 id
    GoRoute(
      path: RoutePath.recurringRuleNew,
      builder: (context, state) => const _Placeholder('新建规则页'),
    ),
    GoRoute(
      path: RoutePath.recurringRuleDetail,
      builder: (context, state) =>
          _Placeholder('规则详情 ${state.pathParameters['id']}'),
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

Future<_FakeRuleRepository> _open(
  WidgetTester tester, {
  List<RecurringRule>? rows,
  Object? writeFailure,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final repo = _FakeRuleRepository(rows ?? [rule()])
    ..writeFailure = writeFailure;
  final router = _openRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
        recurringRuleRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _useSegment(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('一行规则摆出周期、类别与支付方式，金额带符号', (tester) async {
    await _open(tester);

    expect(find.text('房租'), findsOneWidget);
    expect(find.text('每月 1 日 · 居住 · 微信'), findsOneWidget);
    // 支出是负的：这一列要和记账页的收支两色对上，光看数字分不清是进还是出
    expect(find.text('-¥3,000.00'), findsOneWidget);
    expect(find.text('已停用'), findsNothing);
  });

  testWidgets('停用的规则挂着标签，开关也留在行上', (tester) async {
    await _open(tester, rows: [rule(enabled: false)]);

    expect(find.text('已停用'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('拨一下开关只改启停：列表重拉，规则本身不动', (tester) async {
    final repo = await _open(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(repo.toggled, [1]);
    expect(find.text('已停用'), findsOneWidget);
    expect(find.text('房租'), findsOneWidget);
  });

  testWidgets('后端拒了这次启停：整页落到错误态，文案用服务端那句', (tester) async {
    await _open(
      tester,
      writeFailure: const ApiException(
        code: 'RESOURCE_NOT_FOUND',
        message: '规则不存在或已删除',
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // 错误态那一块与 snackbar 各摆一份：写失败把整份清单打成 AsyncError 是 S3 字典页的同一形状
    expect(find.text('规则不存在或已删除'), findsNWidgets(2));
    expect(find.text('房租'), findsNothing);
  });

  testWidgets('切「支出」是在本地这份上筛，不再发一次请求', (tester) async {
    final repo = await _open(
      tester,
      rows: [
        rule(),
        rule(
          id: 2,
          name: '工资',
          type: FlowType.income,
          amount: '12000.00',
          categoryName: '工资',
          accountName: '银行卡',
        ),
      ],
    );
    final before = repo.listCalls;

    await _useSegment(tester, '支出');

    expect(find.text('房租'), findsOneWidget);
    expect(find.text('工资'), findsNothing);
    expect(repo.listCalls, before);

    await _useSegment(tester, '收入');
    expect(find.text('工资'), findsOneWidget);
    expect(find.text('+¥12,000.00'), findsOneWidget);
  });

  testWidgets('筛出来是空的，该给「看全部」而不是引导新建', (tester) async {
    await _open(tester);

    await _useSegment(tester, '收入');

    expect(find.text('这个类型下还没有规则'), findsOneWidget);
    expect(find.text('还没有周期记账规则'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, '看全部'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, '看全部'));
    await tester.pumpAndSettle();
    expect(find.text('房租'), findsOneWidget);
  });

  testWidgets('一条规则都没有时，空态引导去新建', (tester) async {
    await _open(tester, rows: const []);

    expect(find.text('还没有周期记账规则'), findsOneWidget);
    expect(find.text('这个类型下还没有规则'), findsNothing);
    expect(find.widgetWithText(FilledButton, '新建规则'), findsOneWidget);
  });

  testWidgets('点一行进那条规则的详情，带着它的 id', (tester) async {
    await _open(
      tester,
      rows: [
        rule(),
        rule(id: 7, name: '宽带费'),
      ],
    );

    await tester.tap(find.text('宽带费'));
    await tester.pumpAndSettle();

    // 占位页把路由参数原样打了出去：跳到哪条路由、带的是不是这一条的 id
    expect(find.text('规则详情 7'), findsOneWidget);
  });

  testWidgets('右上的加号去新建页，不会被 :id 那条路由吃掉', (tester) async {
    await _open(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('新建规则页'), findsOneWidget);
  });
}
