import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeledger/data/models/category.dart';
import 'package:homeledger/data/models/flow_type.dart';
import 'package:homeledger/data/models/payment_account.dart';
import 'package:homeledger/data/models/transaction.dart';
import 'package:homeledger/data/models/transaction_page.dart';
import 'package:homeledger/data/repositories/category_repository.dart';
import 'package:homeledger/data/repositories/payment_account_repository.dart';
import 'package:homeledger/data/repositories/transaction_repository.dart';
import 'package:homeledger/data/services/network_status.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/finance/views/transaction_edit_page.dart';

import '../../../support/finance_fixtures.dart';

/// 记一笔要用的两棵字典：一个带小类、一个不带，另有一个停用的大类。
const _categories = [
  Category(
    id: 1,
    type: FlowType.expense,
    name: '餐饮',
    iconKey: 'restaurant',
    colorIndex: 0,
    sortNo: 1,
    enabled: true,
    preset: true,
    children: [
      Category(
        id: 11,
        type: FlowType.expense,
        name: '早餐',
        sortNo: 1,
        enabled: true,
        preset: true,
      ),
      Category(
        id: 12,
        type: FlowType.expense,
        name: '正餐',
        sortNo: 2,
        enabled: true,
        preset: true,
      ),
    ],
  ),
  Category(
    id: 2,
    type: FlowType.expense,
    name: '交通',
    iconKey: 'bus',
    colorIndex: 1,
    sortNo: 2,
    enabled: true,
    preset: true,
  ),
  Category(
    id: 3,
    type: FlowType.expense,
    name: '娱乐',
    iconKey: 'sports_esports',
    colorIndex: 2,
    sortNo: 3,
    enabled: false,
    preset: true,
  ),
];

const _accounts = [
  PaymentAccount(id: 1, name: '微信', sortNo: 1, isDefault: true, enabled: true),
  PaymentAccount(id: 2, name: '现金', sortNo: 2, isDefault: false, enabled: true),
];

/// 记账页只用到字典读与流水写，其余方法一调就炸，免得测试假绿。
class _FakeCategoryRepository implements CategoryRepository {
  @override
  Future<CategoryTreeResult> tree() async =>
      const CategoryTreeResult(_categories, fromCache: false);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakePaymentAccountRepository implements PaymentAccountRepository {
  @override
  Future<PaymentAccountListResult> list() async =>
      const PaymentAccountListResult(_accounts, fromCache: false);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// 交给仓库的那一笔，字段与 `create` 的入参一一对应。
typedef _Draft = ({
  String amount,
  int categoryId,
  int? subCategoryId,
  int accountId,
  String bizDate,
  String? remark,
});

class _FakeTransactionRepository implements TransactionRepository {
  final List<_Draft> drafts = [];
  int pageCalls = 0;

  @override
  Future<TransactionPageResult> page(TransactionPageQuery query) async {
    pageCalls++;
    return pageResult(transactionPage(page: 1, pages: 1, records: const []));
  }

  @override
  Future<Transaction> create({
    required String amount,
    required int categoryId,
    int? subCategoryId,
    required int accountId,
    required String bizDate,
    String? remark,
  }) async {
    drafts.add((
      amount: amount,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      accountId: accountId,
      bizDate: bizDate,
      remark: remark,
    ));
    return tx(id: 99, bizDate: DateTime.parse(bizDate));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

/// 记一笔在真实 app 里是被 push 进来的、保存完要 pop 回去，测试也给它一条来路。
/// 用的是 GoRouter 而不是普通路由表：页面收尾调的是 go_router 的 `context.pop()`。
GoRouter _openRouter() => GoRouter(
  initialLocation: RoutePath.finance,
  routes: [
    GoRoute(
      path: RoutePath.finance,
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('来自列表页'))),
    ),
    GoRoute(
      path: RoutePath.transactionNew,
      builder: (context, state) => const TransactionEditPage(),
    ),
  ],
);

Future<_FakeTransactionRepository> _openEditPage(
  WidgetTester tester, {
  NetworkStatus? network,
}) async {
  // 默认 800x600 的测试窗口比手机矮，表单最底下的保存按钮会落在视口外，点不到
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final repo = _FakeTransactionRepository();
  final router = _openRouter();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
        categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepository()),
        paymentAccountRepositoryProvider.overrideWithValue(
          _FakePaymentAccountRepository(),
        ),
        transactionRepositoryProvider.overrideWithValue(repo),
        if (network != null)
          networkStatusProvider.overrideWith(
            () => _FixedNetworkStatus(network),
          ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  router.push(RoutePath.transactionNew);
  await tester.pumpAndSettle();
  return repo;
}

class _FixedNetworkStatus extends NetworkStatusNotifier {
  _FixedNetworkStatus(this.status);

  final NetworkStatus status;

  @override
  NetworkStatus build() => status;
}

/// 保存那颗在屏幕外时树上压根没有它，先滚出来再谈点不点。
Future<Finder> _revealSave(WidgetTester tester) async {
  final save = find.widgetWithText(FilledButton, '保存');
  // 页面上有两个 Scrollable，横向那条是支付方式，竖向这条才是主角。
  await tester.scrollUntilVisible(
    save,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  return save;
}

/// 保存要等写入、列表重拉、pop 三段异步都走完。
Future<void> _tapSave(WidgetTester tester) async {
  await tester.tap(await _revealSave(tester));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('表单摆出可选类别与默认支付方式（§4.2.1）', (tester) async {
    await _openEditPage(tester);

    expect(find.text('餐饮'), findsOneWidget);
    expect(find.text('交通'), findsOneWidget);
    // 停用大类不进记账选项，只在类别管理页里露脸
    expect(find.text('娱乐'), findsNothing);
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '微信')).selected,
      isTrue,
    );
  });

  testWidgets('填金额选类别后保存，仓库收到一笔支出', (tester) async {
    final repo = await _openEditPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, '金额'), '58.5');
    await tester.tap(find.text('餐饮'));
    await tester.pumpAndSettle();
    await _tapSave(tester);

    final draft = repo.drafts.single;
    expect(draft.amount, '58.5');
    expect(draft.categoryId, 1);
    expect(draft.subCategoryId, isNull);
    expect(draft.accountId, 1);
    // 后端的日期参数只认 yyyy-MM-dd，带时刻的 ISO 串解不开
    expect(draft.bizDate, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
  });

  testWidgets('选了小类就把小类一起交出去', (tester) async {
    final repo = await _openEditPage(tester);

    await tester.tap(find.text('餐饮'));
    await tester.pumpAndSettle();
    expect(find.text('小类（可不选）'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, '金额'), '12');
    await tester.tap(find.text('正餐'));
    await _tapSave(tester);

    expect(repo.drafts.single.subCategoryId, 12);
  });

  testWidgets('保存之后回到列表页并让它重拉', (tester) async {
    final repo = await _openEditPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, '金额'), '30');
    await tester.tap(find.text('交通'));
    await tester.pumpAndSettle();
    await _tapSave(tester);

    expect(find.text('来自列表页'), findsOneWidget);
    expect(repo.pageCalls, greaterThan(0));
  });

  testWidgets('金额留空时当场拦下，不发请求', (tester) async {
    final repo = await _openEditPage(tester);

    await _tapSave(tester);

    expect(find.text('请输入金额'), findsOneWidget);
    expect(repo.drafts, isEmpty);
  });

  testWidgets('没选类别时提示选类别，不发请求', (tester) async {
    final repo = await _openEditPage(tester);

    await tester.enterText(find.widgetWithText(TextFormField, '金额'), '20');
    await _tapSave(tester);

    expect(find.text('请选择类别'), findsOneWidget);
    expect(repo.drafts, isEmpty);
  });

  testWidgets('断网时保存按住，并把为什么点不动写在下面', (tester) async {
    final repo = await _openEditPage(tester, network: NetworkStatus.offline);

    await tester.enterText(find.widgetWithText(TextFormField, '金额'), '20');
    await tester.tap(find.text('交通'));
    await tester.pumpAndSettle();
    final save = await _revealSave(tester);

    // 表单已经填全，此刻按住它的只能是网络
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    expect(find.text('需联网后保存'), findsOneWidget);
    expect(repo.drafts, isEmpty);
  });

  testWidgets('网络状态还没查出来时不拦记账', (tester) async {
    // 冷启动那一下既不能说在线也不能说离线，按离线处理等于用户一打开 App 就记不了账
    final repo = await _openEditPage(tester, network: NetworkStatus.unknown);

    await tester.enterText(find.widgetWithText(TextFormField, '金额'), '20');
    await tester.tap(find.text('交通'));
    await tester.pumpAndSettle();
    await _tapSave(tester);

    expect(repo.drafts.single.amount, '20');
    expect(find.text('需联网后保存'), findsNothing);
  });
}
