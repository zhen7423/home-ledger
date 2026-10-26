import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/budget_progress.dart';
import 'package:homeledger/data/models/family.dart';
import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/data/repositories/category_repository.dart';
import 'package:homeledger/data/repositories/statistics_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/network_status.dart';
import 'package:homeledger/ui/core/date_format.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/family/view_models/family_view_model.dart';
import 'package:homeledger/ui/features/finance/view_models/budget_view_model.dart';
import 'package:homeledger/ui/features/finance/view_models/category_view_model.dart';
import 'package:homeledger/ui/features/finance/view_models/statistics_view_model.dart';
import 'package:homeledger/ui/features/finance/views/statistics_page.dart';

import '../../../../support/fake_statistics_repository.dart';
import '../../../../support/s5_fixtures.dart';

/// 统计页。图本身是 CustomPainter，断言全落在图例、副标题与概览那几格文字上。
void main() {
  Future<FakeStatisticsRepository> open(
    WidgetTester tester, {
    FakeStatisticsRepository? withRepo,
    NetworkStatus? network,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final repo =
        withRepo ??
        FakeStatisticsRepository(
          summary: summary(),
          overview: overview(monthlyTrend: twelveMonths()),
        );
    await tester.pumpWidget(
      ProviderScope(
        // 失败的异步 provider 默认按指数退避重试 10 次，失败那条用例会把它们全走完，
        // 请求数就成了 11。测试只验自己的接线，重试是容器的事。
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
          statisticsRepositoryProvider.overrideWithValue(repo),
          budgetProgressViewModelProvider.overrideWith(
            () => _StubBudgetProgress(const <BudgetProgress>[]),
          ),
          categoryViewModelProvider.overrideWith(_StubCategories.new),
          familyViewModelProvider.overrideWith(_StubFamily.new),
          if (network != null)
            networkStatusProvider.overrideWith(
              () => _FixedNetworkStatus(network),
            ),
        ],
        child: const MaterialApp(home: StatisticsPage()),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  /// 竖向那一列才是页面主体；`find.byType(Scrollable).first` 会抓到区间 chips 的横向滚动条。
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      120,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('概览四格都在，笔数不做千分位', (tester) async {
    await open(tester);

    expect(find.text('收入'), findsOneWidget);
    expect(find.text('¥8,000.00'), findsOneWidget);
    expect(find.text('支出'), findsOneWidget);
    expect(find.text('¥3,200.00'), findsOneWidget);
    expect(find.text('结余'), findsOneWidget);
    expect(find.text('¥4,800.00'), findsOneWidget);
    expect(find.text('日均支出'), findsOneWidget);
    expect(find.text('¥228.57'), findsOneWidget);
    expect(find.text('笔数'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('一天都没有时日均支出画一个破折号，不写 ¥0.00', (tester) async {
    await open(
      tester,
      withRepo: FakeStatisticsRepository(
        summary: summary(days: 0, count: 0),
        overview: overview(),
      ),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('¥0.00'), findsNothing);
  });

  testWidgets('五个图区块按线框图的顺序排下来', (tester) async {
    await open(tester);

    // 只有「从上往下滚」这一条路能让每个标题依次出现，所以这一串本身就在验顺序：
    // 哪个区块挪到了前面，轮到它时就已经在视口里，而后面那个找不到的会滚到尽头失败。
    for (final title in const [
      '类别占比',
      '月度收支趋势',
      '区间内每日支出',
      '支付方式占比',
      '成员支出对比',
    ]) {
      await scrollTo(tester, find.text(title));
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });

  testWidgets('点大类图例下钻到小类，返回大类再回顶层', (tester) async {
    await open(tester);

    expect(find.text('餐饮'), findsOneWidget);
    expect(find.text('56%'), findsOneWidget);

    await tester.tap(find.text('餐饮'));
    await tester.pumpAndSettle();

    expect(find.text('餐饮 的小类'), findsOneWidget);
    expect(find.text('早餐'), findsOneWidget);
    expect(find.text('外卖'), findsOneWidget);
    expect(find.text('交通'), findsNothing);

    await tester.tap(find.text('返回大类'));
    await tester.pumpAndSettle();

    expect(find.text('类别占比'), findsOneWidget);
    expect(find.text('交通'), findsOneWidget);
  });

  testWidgets('「其他」是一片合并出来的假类别，点它不下钻', (tester) async {
    await open(tester);

    await tester.tap(find.text('其他'));
    await tester.pumpAndSettle();

    expect(find.text('类别占比'), findsOneWidget);
    expect(find.text('交通'), findsOneWidget);
  });

  testWidgets('趋势图那句「12 个自然月」切区间也不跟着动', (tester) async {
    final repo = await open(tester);

    await scrollTo(tester, find.text('月度收支趋势'));
    expect(find.textContaining('固定最近 12 个自然月'), findsOneWidget);

    await tester.tap(find.text('上月'));
    await tester.pumpAndSettle();
    expect(repo.queries, hasLength(2));

    await scrollTo(tester, find.text('月度收支趋势'));
    expect(find.textContaining('固定最近 12 个自然月'), findsOneWidget);
  });

  testWidgets('每日支出上面那句话指出最高的一天并说明能横着滚', (tester) async {
    await open(tester);

    await scrollTo(tester, find.text('区间内每日支出'));

    expect(find.text('最高：9月14日 ¥320.00　横向滚动看整个区间'), findsOneWidget);
  });

  testWidgets('区间里每天有数但全是 0 时不画一张空图', (tester) async {
    await open(
      tester,
      withRepo: FakeStatisticsRepository(
        summary: summary(),
        overview: overview(
          dailyTrend: [
            DailyPoint(date: DateTime(2026, 9, 12), expense: '0.00'),
            DailyPoint(date: DateTime(2026, 9, 13), expense: '0.00'),
          ],
        ),
      ),
    );

    await scrollTo(tester, find.text('区间内每日支出'));

    expect(find.text('这个区间每天都没有支出'), findsOneWidget);
  });

  testWidgets('点记录人 chips 把 id 带进查询', (tester) async {
    final repo = await open(tester);

    expect(find.text('全部成员'), findsOneWidget);
    await tester.tap(find.text('小明'));
    await tester.pumpAndSettle();

    expect(repo.queries.last.createdBy, 10);
  });

  testWidgets('点「上月」发的是按当前时间算出来的那一段，不是硬编码的八月', (tester) async {
    final repo = await open(tester);

    await tester.tap(find.text('上月'));
    await tester.pumpAndSettle();

    expect(
      repo.queries.last,
      queryFor(const StatisticsState(range: StatisticsRange.lastMonth)),
    );
  });

  testWidgets('加载失败给一句准话，重试重发的是刚才那组条件', (tester) async {
    final repo = await open(
      tester,
      withRepo:
          FakeStatisticsRepository(summary: summary(), overview: overview())
            ..error = const ApiException(
              code: 'FORBIDDEN',
              message: '无权查看这个家庭的数据',
              statusCode: 403,
            ),
    );

    expect(find.text('无权查看这个家庭的数据'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    final picked = repo.queries.last;

    repo.error = null;
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(repo.queries.last, picked);
    expect(repo.loadCalls, 2);
    expect(find.text('类别占比'), findsOneWidget);
  });

  testWidgets('看快照时横幅在内容顶部、chips 整排禁用', (tester) async {
    final savedAt = DateTime(2026, 9, 14, 15, 20);
    await open(
      tester,
      network: NetworkStatus.offline,
      withRepo:
          FakeStatisticsRepository(summary: summary(), overview: overview())
            ..snapshot = StatisticsLoadResult(
              summary(),
              overview(),
              query: queryFor(const StatisticsState())!,
              fromCache: true,
              savedAt: savedAt,
            ),
    );

    expect(find.textContaining('离线模式'), findsOneWidget);
    expect(find.textContaining(formatDateTime(savedAt)), findsOneWidget);
    // 换条件必然要打服务端，而这一趟必然失败，所以整排按住
    for (final chip in tester.widgetList<ChoiceChip>(find.byType(ChoiceChip))) {
      expect(chip.onSelected, isNull, reason: chip.label.toString());
    }
    expect(find.text('离线时只看已缓存的区间'), findsOneWidget);
  });
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

/// 统计页 initState 会调 `budgetProgressViewModelProvider.notifier.load()`，
/// 真那份一路打到 apiClientProvider → 真 dio。连 `load()` 一起截住，省掉再 override 三个仓库。
class _StubBudgetProgress extends BudgetProgressViewModel {
  _StubBudgetProgress(this.rows);

  final List<BudgetProgress> rows;

  @override
  Future<List<BudgetProgress>> build() async => rows;

  /// 不写 state：`build()` 已经交出那份 rows，而这一句是在页面的 `initState` 里被调的，
  /// 当场改 provider 会被 Riverpod 判成「build 期间改 provider」。
  @override
  Future<String?> load({String? month}) async => null;
}

class _StubCategories extends CategoryViewModel {
  @override
  Future<CategoryTreeResult> build() async =>
      CategoryTreeResult(categories(), fromCache: false);
}

class _StubFamily extends FamilyViewModel {
  @override
  Future<Family?> build() async => family();
}

/// 真那份要等一次失败的请求才翻状态，页面测试里不必绕这一圈。
class _FixedNetworkStatus extends NetworkStatusNotifier {
  _FixedNetworkStatus(this.status);

  final NetworkStatus status;

  @override
  NetworkStatus build() => status;
}
