import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/flow_type.dart';
import 'package:homeledger/data/models/home_overview.dart';
import 'package:homeledger/data/models/period_value.dart';
import 'package:homeledger/data/models/recurring_rule.dart';
import 'package:homeledger/data/models/transaction_page.dart';
import 'package:homeledger/data/repositories/home_repository.dart';
import 'package:homeledger/data/repositories/recurring_rule_repository.dart';
import 'package:homeledger/data/repositories/transaction_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/finance/view_models/recurring_rule_view_model.dart';
import 'package:homeledger/ui/features/finance/view_models/transaction_list_view_model.dart';
import 'package:homeledger/ui/features/home/view_models/home_view_model.dart';

import '../../../../support/finance_fixtures.dart';
import '../../../../support/s4_fixtures.dart';
import '../../../../support/s9_fixtures.dart';

/// 规则仓库的替身：一份可变的清单，写操作直接改它，于是「写完之后重拉到了什么」
/// 在断言里就是清单内容本身。
class _FakeRuleRepository implements RecurringRuleRepository {
  _FakeRuleRepository(this.rows);

  List<RecurringRule> rows;
  final List<RecurringRuleDraft> created = [];
  final List<String?> listedTypes = [];

  /// 非空时下一次写就抛这个异常，用来演服务端拒绝创建的那一半。
  Object? writeFailure;

  @override
  Future<List<RecurringRule>> list({String? type}) async {
    listedTypes.add(type);
    return [
      for (final row in rows)
        if (type == null || row.type == type) row,
    ];
  }

  @override
  Future<RecurringRule> create(RecurringRuleDraft draft) async {
    final failure = writeFailure;
    if (failure != null) throw failure;
    created.add(draft);
    rows = [...rows, rule(id: 9, name: draft.name, amount: draft.amount)];
    return rows.last;
  }

  @override
  Future<RecurringRule> update(int id, RecurringRuleDraft draft) async {
    final failure = writeFailure;
    if (failure != null) throw failure;
    rows = [
      for (final row in rows)
        if (row.id == id)
          row.copyWith(name: draft.name, amount: draft.amount)
        else
          row,
    ];
    return rows.firstWhere((row) => row.id == id);
  }

  @override
  Future<RecurringRule> toggle(int id) async {
    rows = [
      for (final row in rows)
        if (row.id == id) row.copyWith(enabled: !row.enabled) else row,
    ];
    return rows.firstWhere((row) => row.id == id);
  }

  @override
  Future<void> remove(int id) async {
    rows = [
      for (final row in rows)
        if (row.id != id) row,
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// 只为验证「写完要重拉」而存在：记下流水列表发了几次请求。
class _FakeTransactionRepository implements TransactionRepository {
  final List<TransactionPageQuery> queries = [];

  int get manualCalls => queries.where((q) => q.source == null).length;

  int get autoCalls => queries.where((q) => q.source == 'AUTO').length;

  @override
  Future<TransactionPageResult> page(TransactionPageQuery query) async {
    queries.add(query);
    return pageResult(transactionPage(page: 1, pages: 1, records: const []));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// 首页那块「今日自动生成 N 笔」自 S9 起长在聚合响应里，所以这里数的是聚合发了几次请求。
class _FakeHomeRepository implements HomeRepository {
  int overviewCalls = 0;

  @override
  Future<HomeOverview> overview() async {
    overviewCalls++;
    return homeOverview();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

class _SignedOutAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedOut);
}

/// 让两个读它的地方都保持被监听状态：失效之后它们才会立刻重拉，请求数才是可数的。
ProviderContainer _container({
  required _FakeRuleRepository rules,
  _FakeTransactionRepository? flows,
  _FakeHomeRepository? home,
}) {
  final container = ProviderContainer(
    overrides: [
      authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
      recurringRuleRepositoryProvider.overrideWithValue(rules),
      if (flows != null) transactionRepositoryProvider.overrideWithValue(flows),
      if (home != null) homeRepositoryProvider.overrideWithValue(home),
    ],
  );
  addTearDown(container.dispose);
  if (flows != null) {
    container.listen(transactionListViewModelProvider, (_, _) {});
    container.listen(homeOverviewProvider, (_, _) {});
  }
  return container;
}

/// 失效之后的重拉排在下一个事件循环里，等一次空转再数请求。
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('未登录时清单是空的，一个请求都不发', () async {
    final rules = _FakeRuleRepository([rule()]);
    final container = ProviderContainer(
      overrides: [
        authViewModelProvider.overrideWith(_SignedOutAuthViewModel.new),
        recurringRuleRepositoryProvider.overrideWithValue(rules),
      ],
    );
    addTearDown(container.dispose);

    final rows = await container.read(recurringRuleViewModelProvider.future);

    expect(rows, isEmpty);
    expect(rules.listedTypes, isEmpty);
  });

  test('建规则成功后，流水列表与首页聚合都重拉一次', () async {
    final flows = _FakeTransactionRepository();
    final home = _FakeHomeRepository();
    final rules = _FakeRuleRepository([rule()]);
    final container = _container(rules: rules, flows: flows, home: home);
    await container.read(transactionListViewModelProvider.future);
    await container.read(homeOverviewProvider.future);
    expect(flows.manualCalls, 1);
    expect(home.overviewCalls, 1);

    final error = await container
        .read(recurringRuleViewModelProvider.notifier)
        .create(_draftWith(name: '宽带'));
    await _settle();

    expect(error, isNull);
    // 后端在同一次请求里补当期流水（A4），这两处不重拉就是「建完了却看不见」
    expect(flows.manualCalls, 2);
    expect(home.overviewCalls, 2);
    expect(
      container.read(recurringRuleViewModelProvider).requireValue.last.name,
      '宽带',
    );
  });

  test('建规则被服务端拒了，不重拉流水、清单也不变', () async {
    final flows = _FakeTransactionRepository();
    final home = _FakeHomeRepository();
    final rules = _FakeRuleRepository([rule()]);
    rules.writeFailure = const ApiException(
      code: 'PERIOD_RANGE_INVALID',
      message: '间隔天数要在 1 到 365 之间',
    );
    final container = _container(rules: rules, flows: flows, home: home);
    final before = await container.read(recurringRuleViewModelProvider.future);
    await container.read(homeOverviewProvider.future);

    final error = await container
        .read(recurringRuleViewModelProvider.notifier)
        .create(_draftWith(name: '宽带'));
    await _settle();

    // 文案直接用后端给的：它带了是哪一项越界
    expect(error, '间隔天数要在 1 到 365 之间');
    expect(flows.manualCalls, 1);
    expect(home.overviewCalls, 1);
    expect(container.read(recurringRuleViewModelProvider).requireValue, before);
  });

  test('编辑既有规则走整份覆盖，之后同样重拉流水', () async {
    final flows = _FakeTransactionRepository();
    final rules = _FakeRuleRepository([rule(id: 1, name: '房租')]);
    final container = _container(rules: rules, flows: flows);
    await container.read(transactionListViewModelProvider.future);

    final error = await container
        .read(recurringRuleViewModelProvider.notifier)
        .save(1, _draftWith(name: '房租（含物业费）'));
    await _settle();

    expect(error, isNull);
    expect(
      container.read(recurringRuleViewModelProvider).requireValue.single.name,
      '房租（含物业费）',
    );
    expect(flows.manualCalls, 2);
  });

  test('启停只刷规则清单，不去重拉流水', () async {
    final flows = _FakeTransactionRepository();
    final rules = _FakeRuleRepository([rule(id: 1)]);
    final container = _container(rules: rules, flows: flows);
    await container.read(transactionListViewModelProvider.future);

    final error = await container
        .read(recurringRuleViewModelProvider.notifier)
        .toggle(1);
    await _settle();

    expect(error, isNull);
    expect(
      container
          .read(recurringRuleViewModelProvider)
          .requireValue
          .single
          .enabled,
      isFalse,
    );
    // 停的是「以后还生不生成」，已经记上的那几笔一行没动，流水列表没必要重来
    expect(flows.manualCalls, 1);
  });

  test('按类型筛是从服务端重拉的，不是在本地那份上过滤', () async {
    final rules = _FakeRuleRepository([
      rule(id: 1),
      rule(id: 2, type: FlowType.income, name: '工资'),
    ]);
    final container = _container(rules: rules);

    await container
        .read(recurringRuleViewModelProvider.notifier)
        .load(type: FlowType.income);

    expect(rules.listedTypes.last, FlowType.income);
    expect(
      container
          .read(recurringRuleViewModelProvider)
          .requireValue
          .map((r) => r.id),
      [2],
    );
  });

  test('删除一条之后清单少一行', () async {
    final rules = _FakeRuleRepository([rule(id: 1), rule(id: 2, name: '订阅')]);
    final container = _container(rules: rules);
    await container.read(recurringRuleViewModelProvider.future);

    await container.read(recurringRuleViewModelProvider.notifier).remove(2);

    expect(
      container
          .read(recurringRuleViewModelProvider)
          .requireValue
          .map((r) => r.id),
      [1],
    );
  });
}

/// 提交用的草稿。字段形状在 F3 的仓库测试里已经逐键钉过，这里要的是「有没有交上去」。
RecurringRuleDraft _draftWith({required String name}) => RecurringRuleDraft(
  name: name,
  amount: '99.00',
  categoryId: 3,
  accountId: 1,
  periodType: 'MONTHLY',
  periodValue: const PeriodValue(daysOfMonth: [1]),
  startDate: DateTime(2026, 10, 1),
);
