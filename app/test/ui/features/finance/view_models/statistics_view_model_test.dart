import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/data/repositories/statistics_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/finance/view_models/statistics_view_model.dart';

import '../../../../support/fake_statistics_repository.dart';
import '../../../../support/s5_fixtures.dart';

final DateTime _now = DateTime(2026, 9, 14);

void main() {
  late FakeStatisticsRepository repo;

  setUp(() {
    repo = FakeStatisticsRepository(summary: summary(), overview: overview());
  });

  ProviderContainer newContainer({bool signedIn = true}) {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        authViewModelProvider.overrideWith(
          () => signedIn
              ? _AlwaysSignedInAuthViewModel()
              : _SignedOutAuthViewModel(),
        ),
        statisticsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    // 只 read 一次的 provider 可能算完就被回收，先挂个监听把它留住。
    container.listen(statisticsViewModelProvider, (_, _) {});
    addTearDown(container.dispose);
    return container;
  }

  StatisticsState stateOf(ProviderContainer container) =>
      container.read(statisticsViewModelProvider).requireValue;

  group('queryFor', () {
    test('本月的结束日是今天，不是月末', () {
      expect(
        queryFor(const StatisticsState(), now: _now),
        const StatisticsQuery(startDate: '2026-09-01', endDate: '2026-09-14'),
      );
    });

    test('本年同样只到今天', () {
      expect(
        queryFor(
          const StatisticsState(range: StatisticsRange.thisYear),
          now: _now,
        ),
        const StatisticsQuery(startDate: '2026-01-01', endDate: '2026-09-14'),
      );
    });

    test('上月是整月，跨年靠 Dart 自己回卷', () {
      expect(
        queryFor(
          const StatisticsState(range: StatisticsRange.lastMonth),
          now: _now,
        ),
        const StatisticsQuery(startDate: '2026-08-01', endDate: '2026-08-31'),
      );
      expect(
        queryFor(
          const StatisticsState(range: StatisticsRange.lastMonth),
          now: DateTime(2026, 1, 5),
        ),
        const StatisticsQuery(startDate: '2025-12-01', endDate: '2025-12-31'),
      );
    });

    test('去年是整年', () {
      expect(
        queryFor(
          const StatisticsState(range: StatisticsRange.lastYear),
          now: _now,
        ),
        const StatisticsQuery(startDate: '2025-01-01', endDate: '2025-12-31'),
      );
    });

    test('自定义要两头的日期都挑完，挑完的时分秒会被削掉', () {
      expect(
        queryFor(
          StatisticsState(
            range: StatisticsRange.custom,
            customStart: DateTime(2026, 9, 5, 13, 30),
            customEnd: DateTime(2026, 9, 9, 8),
          ),
          now: _now,
        ),
        const StatisticsQuery(startDate: '2026-09-05', endDate: '2026-09-09'),
      );
      expect(
        queryFor(
          StatisticsState(
            range: StatisticsRange.custom,
            customStart: DateTime(2026, 9, 5),
          ),
          now: _now,
        ),
        isNull,
      );
    });

    test('起始晚于结束时不发请求', () {
      expect(
        queryFor(
          StatisticsState(
            range: StatisticsRange.custom,
            customStart: DateTime(2026, 9, 9),
            customEnd: DateTime(2026, 9, 5),
          ),
          now: _now,
        ),
        isNull,
      );
    });

    test('记录人原样带进查询', () {
      final query = queryFor(const StatisticsState(createdBy: 11), now: _now);
      expect(query?.createdBy, 11);
    });
  });

  group('alignToQuery', () {
    test('快照条件就是本月时，chips 拨回本月并清掉自定义日期', () {
      final picked = queryFor(const StatisticsState(createdBy: 11), now: _now);
      final aligned = alignToQuery(
        StatisticsState(
          range: StatisticsRange.custom,
          customStart: DateTime(2020, 1, 1),
          customEnd: DateTime(2020, 2, 2),
          createdBy: 99,
        ),
        picked!,
        now: _now,
      );

      expect(aligned.range, StatisticsRange.thisMonth);
      expect(aligned.customStart, isNull);
      expect(aligned.customEnd, isNull);
      expect(aligned.createdBy, 11);
    });

    test('对不上任何一格时退回自定义，日期照快照给（两个 null 也照给）', () {
      final dated = alignToQuery(
        const StatisticsState(),
        const StatisticsQuery(startDate: '2024-03-08', endDate: '2024-05-20'),
        now: _now,
      );
      expect(dated.range, StatisticsRange.custom);
      expect(dated.customStart, DateTime(2024, 3, 8));
      expect(dated.customEnd, DateTime(2024, 5, 20));

      final whole = alignToQuery(
        const StatisticsState(range: StatisticsRange.lastYear),
        const StatisticsQuery(),
        now: _now,
      );
      expect(whole.range, StatisticsRange.custom);
      expect(whole.customStart, isNull);
      expect(whole.customEnd, isNull);
    });
  });

  test('没登录时不建查询、一次请求都不发', () async {
    final container = newContainer(signedIn: false);

    final loaded = await container.read(statisticsViewModelProvider.future);

    expect(loaded, const StatisticsState());
    expect(repo.loadCalls, 0);
  });

  test('点区间 chip 先把条件落地、旧数字清空，再等请求回来', () async {
    final container = newContainer();
    await container.read(statisticsViewModelProvider.future);
    final notifier = container.read(statisticsViewModelProvider.notifier);

    final loading = notifier.selectRange(StatisticsRange.lastMonth);

    // _apply 里 state 那行排在 await 之前，所以这一步读到的是「条件已换、数据已清」那一格。
    final pending = stateOf(container);
    expect(pending.range, StatisticsRange.lastMonth);
    expect(pending.summary, isNull);
    expect(pending.overview, isNull);

    await loading;
    expect(stateOf(container).summary, isNotNull);
  });

  test('加载成功后两份数据都在，并且不是快照来的', () async {
    final container = newContainer();

    final loaded = await container.read(statisticsViewModelProvider.future);

    expect(loaded.fromCache, isFalse);
    expect(loaded.summary, isNotNull);
    expect(loaded.overview, isNotNull);
    expect(repo.queries, [queryFor(const StatisticsState())]);
  });

  test('失败后重试，重发的是用户刚挑的那组条件而不是本月', () async {
    final container = newContainer();
    await container.read(statisticsViewModelProvider.future);
    final notifier = container.read(statisticsViewModelProvider.notifier);
    repo.error = const ApiException(code: ClientErrorCode.network);

    await notifier.selectRange(StatisticsRange.thisYear);

    expect(
      container.read(statisticsViewModelProvider),
      isA<AsyncError<StatisticsState>>(),
    );
    final picked = repo.queries.last;

    repo.error = null;
    await notifier.retry();

    expect(repo.loadCalls, 3);
    expect(repo.queries.last, picked);
    expect(stateOf(container).overview, isNotNull);
  });

  test('命中快照时挂上离线标记，并把区间拨到快照真正覆盖的那一格', () async {
    final savedAt = DateTime(2026, 9, 14, 8, 30);
    repo.snapshot = StatisticsLoadResult(
      summary(),
      overview(),
      query: queryFor(const StatisticsState(range: StatisticsRange.lastMonth))!,
      fromCache: true,
      savedAt: savedAt,
    );
    final container = newContainer();

    final loaded = await container.read(statisticsViewModelProvider.future);

    expect(loaded.fromCache, isTrue);
    expect(loaded.savedAt, savedAt);
    expect(loaded.range, StatisticsRange.lastMonth);
    expect(loaded.summary, isNotNull);
  });
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

class _SignedOutAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedOut);
}
