import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/flow_type.dart';
import 'package:homeledger/data/models/transaction_page.dart';
import 'package:homeledger/data/repositories/transaction_repository.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/finance/view_models/transaction_list_view_model.dart';

import '../../../support/finance_fixtures.dart';

/// 只喂分页数据，不走网络。列表 VM 要验的分组、翻页、筛选全在 `page()` 的进出口上。
class _FakeTransactionRepository implements TransactionRepository {
  _FakeTransactionRepository(this._pages);

  final Map<int, TransactionPage> _pages;
  final List<TransactionPageQuery> queries = [];

  @override
  Future<TransactionPageResult> page(TransactionPageQuery query) async {
    final result = _pages[query.page];
    if (result == null) {
      throw StateError('测试没有准备第 ${query.page} 页');
    }
    queries.add(query);
    return pageResult(result);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// 列表 VM 只认登录态这一个信号，令牌存储与 ApiClient 那套地基不必拉进来。
class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

ProviderContainer _container(_FakeTransactionRepository repo) {
  final container = ProviderContainer(
    overrides: [
      authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
      transactionRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('首屏按记账月份分组，新月份在前，该月小计跟着对上', () async {
    final repo = _FakeTransactionRepository({
      1: transactionPage(
        page: 1,
        pages: 2,
        records: [
          tx(id: 3, bizDate: DateTime(2026, 9, 20)),
          tx(id: 2, bizDate: DateTime(2026, 9, 11)),
          tx(id: 1, bizDate: DateTime(2026, 8, 30)),
        ],
        summaries: [
          monthSummary('2026-09', count: 2),
          monthSummary('2026-08', count: 1),
        ],
      ),
    });

    final state = await _container(
      repo,
    ).read(transactionListViewModelProvider.future);

    expect(state.groups.map((g) => g.month), ['2026-09', '2026-08']);
    expect(state.groups.first.items.map((t) => t.id), [3, 2]);
    expect(state.groups.first.summary?.count, 2);
    expect(state.groups.last.summary?.count, 1);
    expect(state.page, 1);
    expect(state.hasMore, isTrue);
  });

  test('上拉加载把下一页并进已有月份，不另起一组', () async {
    final repo = _FakeTransactionRepository({
      1: transactionPage(
        page: 1,
        pages: 2,
        records: [
          tx(id: 2, bizDate: DateTime(2026, 9, 20)),
          tx(id: 1, bizDate: DateTime(2026, 8, 30)),
        ],
      ),
      2: transactionPage(
        page: 2,
        pages: 2,
        records: [
          tx(id: 3, bizDate: DateTime(2026, 9, 5)),
          tx(id: 4, bizDate: DateTime(2026, 7, 1)),
        ],
        summaries: [monthSummary('2026-09', count: 3)],
      ),
    });
    final container = _container(repo);
    await container.read(transactionListViewModelProvider.future);

    await container.read(transactionListViewModelProvider.notifier).loadMore();

    final state = container.read(transactionListViewModelProvider).requireValue;
    expect(state.groups.map((g) => g.month), ['2026-09', '2026-08', '2026-07']);
    expect(state.groups.first.items.map((t) => t.id), [2, 3]);
    expect(state.groups.first.summary?.count, 3);
    expect(state.page, 2);
    expect(repo.queries.map((q) => q.page), [1, 2]);
  });

  test('改筛选条件回到第 1 页重来，不追加到旧结果的尾巴上', () async {
    final repo = _FakeTransactionRepository({
      1: transactionPage(
        page: 1,
        pages: 2,
        records: [tx(id: 1, bizDate: DateTime(2026, 9, 20))],
      ),
      2: transactionPage(
        page: 2,
        pages: 2,
        records: [tx(id: 2, bizDate: DateTime(2026, 9, 1))],
      ),
    });
    final container = _container(repo);
    await container.read(transactionListViewModelProvider.future);
    final notifier = container.read(transactionListViewModelProvider.notifier);
    await notifier.loadMore();

    await notifier.apply(const TransactionFilter(type: FlowType.income));

    final state = container.read(transactionListViewModelProvider).requireValue;
    expect(repo.queries.map((q) => q.page), [1, 2, 1]);
    expect(state.groups.expand((g) => g.items).map((t) => t.id), [1]);
    expect(state.hasMore, isTrue);
  });

  test('筛选里的日期以 yyyy-MM-dd 发出，不是带时刻的 ISO 串', () async {
    final repo = _FakeTransactionRepository({
      1: transactionPage(page: 1, pages: 1, records: const []),
    });
    final container = _container(repo);

    await container
        .read(transactionListViewModelProvider.notifier)
        .apply(
          TransactionFilter(
            startDate: DateTime(2026, 9, 1),
            endDate: DateTime(2026, 9, 30),
          ),
        );

    final query = repo.queries.last;
    expect(query.startDate, '2026-09-01');
    expect(query.endDate, '2026-09-30');
    expect(query.type, isNull);
  });

  test('只有一页时上拉不再发请求', () async {
    final repo = _FakeTransactionRepository({
      1: transactionPage(
        page: 1,
        pages: 1,
        records: [tx(id: 1, bizDate: DateTime(2026, 9, 20))],
      ),
    });
    final container = _container(repo);

    final state = await container.read(transactionListViewModelProvider.future);
    await container.read(transactionListViewModelProvider.notifier).loadMore();

    expect(state.hasMore, isFalse);
    expect(repo.queries.length, 1);
  });
}
