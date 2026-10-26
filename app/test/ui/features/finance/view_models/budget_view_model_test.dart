import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/budget.dart';
import 'package:homeledger/data/models/budget_progress.dart';
import 'package:homeledger/data/repositories/budget_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/finance/view_models/budget_view_model.dart';

import '../../../../support/s4_fixtures.dart';

/// 预算仓库的替身。清单与进度各一份可变数据，外加「被调用了几次」的计数——
/// 这个 VM 要验的两件事（写后重拉、额度变了要连带刷进度）都只在次数上看得见。
class _FakeBudgetRepository implements BudgetRepository {
  _FakeBudgetRepository({List<Budget>? rows, List<BudgetProgress>? progresses})
    : rows = rows ?? [budget()],
      progresses = progresses ?? [budgetProgress()];

  List<Budget> rows;
  List<BudgetProgress> progresses;

  final List<List<BudgetDraftItem>?> saves = [];
  final List<String?> months = [];
  int listCalls = 0;
  int progressCalls = 0;

  Object? writeFailure;

  @override
  Future<List<Budget>> list() async {
    listCalls++;
    return rows;
  }

  @override
  Future<void> save(List<BudgetDraftItem>? items) async {
    final failure = writeFailure;
    if (failure != null) throw failure;
    saves.add(items);
    // 后端是整体替换：先删光再重插，id 也换一批
    rows = [
      for (final (index, item) in (items ?? const <BudgetDraftItem>[]).indexed)
        budget(
          id: index + 1,
          scope: item.scope,
          categoryId: item.categoryId,
          memberUserId: item.memberUserId,
          amount: item.amount,
        ),
    ];
  }

  @override
  Future<List<BudgetProgress>> progress({String? month}) async {
    progressCalls++;
    months.add(month);
    return progresses;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

ProviderContainer _container(_FakeBudgetRepository repo) {
  final container = ProviderContainer(
    overrides: [
      authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
      budgetRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  // 都挂上监听，失效之后才会立刻重拉，次数才可数
  container.listen(budgetViewModelProvider, (_, _) {});
  container.listen(budgetProgressViewModelProvider, (_, _) {});
  return container;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('保存之后额度与进度都重拉：分母变了，进度条不能留在旧的那份上', () async {
    final repo = _FakeBudgetRepository();
    final container = _container(repo);
    await container.read(budgetViewModelProvider.future);
    await container.read(budgetProgressViewModelProvider.future);
    expect(repo.listCalls, 1);
    expect(repo.progressCalls, 1);

    final error = await container.read(budgetViewModelProvider.notifier).save([
      const BudgetDraftItem(scope: 'FAMILY', amount: '6000.00'),
    ]);
    await _settle();

    expect(error, isNull);
    expect(repo.listCalls, 2);
    expect(repo.progressCalls, 2);
    expect(
      container.read(budgetViewModelProvider).requireValue.single.amount,
      '6000.00',
    );
  });

  test('同一维度重复提交被服务端拒了，两份数据都不动', () async {
    final repo = _FakeBudgetRepository();
    repo.writeFailure = const ApiException(
      code: 'BUDGET_DUPLICATED',
      message: '同一个维度只能设置一条预算',
    );
    final container = _container(repo);
    final before = await container.read(budgetViewModelProvider.future);
    await container.read(budgetProgressViewModelProvider.future);

    final error = await container
        .read(budgetViewModelProvider.notifier)
        .save(const [
          BudgetDraftItem(scope: 'FAMILY', amount: '6000.00'),
          BudgetDraftItem(scope: 'FAMILY', amount: '7000.00'),
        ]);
    await _settle();

    expect(error, '同一个维度只能设置一条预算');
    expect(repo.listCalls, 1);
    expect(repo.progressCalls, 1);
    expect(container.read(budgetViewModelProvider).requireValue, before);
  });

  test('把三行全删光再保存，交上去的是空清单而不是 null', () async {
    final repo = _FakeBudgetRepository();
    final container = _container(repo);
    await container.read(budgetViewModelProvider.future);

    await container.read(budgetViewModelProvider.notifier).save(const []);

    // null 是「没提交」，[] 是「提交了一份空的」，仓库测试里钉过这两者的区别
    expect(repo.saves.single, isEmpty);
    expect(container.read(budgetViewModelProvider).requireValue, isEmpty);
  });

  test('切月份是再发一次请求，不在本地那一份上接着算', () async {
    final repo = _FakeBudgetRepository();
    final container = _container(repo);
    await container.read(budgetProgressViewModelProvider.future);

    await container
        .read(budgetProgressViewModelProvider.notifier)
        .load(month: '2026-08');

    expect(repo.months.last, '2026-08');
    expect(repo.progressCalls, 2);
  });

  test('未登录时两份都是空的，一次请求都不发', () async {
    final repo = _FakeBudgetRepository();
    final container = ProviderContainer(
      overrides: [
        authViewModelProvider.overrideWith(_SignedOut.new),
        budgetRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(budgetViewModelProvider.future), isEmpty);
    expect(
      await container.read(budgetProgressViewModelProvider.future),
      isEmpty,
    );
    expect(repo.listCalls, 0);
    expect(repo.progressCalls, 0);
  });
}

class _SignedOut extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedOut);
}
