import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/export_format.dart';
import 'package:homeledger/data/models/family.dart';
import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/data/models/transaction_summary.dart';
import 'package:homeledger/data/repositories/export_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/file_sharer.dart';
import 'package:homeledger/data/services/network_status.dart';
import 'package:homeledger/ui/core/offline_banner.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/family/view_models/family_view_model.dart';
import 'package:homeledger/ui/features/finance/view_models/statistics_view_model.dart';
import 'package:homeledger/ui/features/finance/views/export_page.dart';

import '../../../../support/fake_export_repository.dart';
import '../../../../support/fake_file_sharer.dart';
import '../../../../support/s5_fixtures.dart';

/// 导出页。条件那一排 chips 是从 `state.query` 反推出来的，所以每条用例都要同时
/// 盯住「chip 停在哪一格」和「替身收到的那组条件」，两边对不上就是同步漏了。
void main() {
  late FakeExportRepository repo;
  late FakeFileSharer sharer;

  setUp(() {
    repo = FakeExportRepository(summary: summary());
    sharer = FakeFileSharer();
  });

  Future<void> open(
    WidgetTester tester, {
    StatisticsQuery query = const StatisticsQuery(),
    NetworkStatus? network,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
          exportRepositoryProvider.overrideWithValue(repo),
          fileSharerProvider.overrideWithValue(sharer),
          familyViewModelProvider.overrideWith(_StubFamily.new),
          if (network != null)
            networkStatusProvider.overrideWith(
              () => _FixedNetworkStatus(network),
            ),
        ],
        child: MaterialApp(home: ExportPage(query: query)),
      ),
    );
    // settle=false 是给「正在统计行数」那一格的：转圈的进度条每帧都在重绘，
    // pumpAndSettle 等的是「没有帧要画」，那种状态永远等不到，只能自己泵两帧。
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump();
    }
  }

  RadioGroup<ExportFormat> formatGroup(WidgetTester tester) => tester
      .widget<RadioGroup<ExportFormat>>(find.byType(RadioGroup<ExportFormat>));

  ChoiceChip chip(WidgetTester tester, String label) =>
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));

  FilledButton exportButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, '导出并分享'));

  testWidgets('默认选 Excel，换格式不再查一遍行数', (tester) async {
    await open(tester);

    expect(find.text('Excel (.xlsx)'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
    expect(formatGroup(tester).groupValue, ExportFormat.xlsx);

    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();

    expect(formatGroup(tester).groupValue, ExportFormat.csv);
    expect(repo.countQueries, hasLength(1));
  });

  testWidgets('「全部」在最前面且是默认那一格', (tester) async {
    await open(tester);

    expect(
      tester.getCenter(find.text('全部')).dx,
      lessThan(tester.getCenter(find.text('本月')).dx),
    );
    expect(chip(tester, '全部').selected, isTrue);
    expect(repo.countQueries.single, const StatisticsQuery());

    await tester.tap(find.text('本月'));
    await tester.pumpAndSettle();

    expect(
      repo.countQueries.last,
      queryFor(const StatisticsState(range: StatisticsRange.thisMonth)),
    );
  });

  testWidgets('统计页带来的条件停在「上月」，不落回全部', (tester) async {
    // 「上月」是相对今天的，日期写死的话这条用例每月 1 号都会假失败（时间炸弹）。
    final now = DateTime.now();
    String pad(int v) => v.toString().padLeft(2, '0');
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);
    String fmt(DateTime d) => '${d.year}-${pad(d.month)}-${pad(d.day)}';
    await open(
      tester,
      query: StatisticsQuery(
        startDate: fmt(startOfLastMonth),
        endDate: fmt(endOfLastMonth),
      ),
    );

    expect(chip(tester, '上月').selected, isTrue);
    expect(chip(tester, '全部').selected, isFalse);
  });

  testWidgets('点记录人把 id 带进行数查询', (tester) async {
    await open(tester);

    expect(find.text('全部成员'), findsOneWidget);
    await tester.tap(find.text('阿芳'));
    await tester.pumpAndSettle();

    expect(repo.countQueries.last.createdBy, 11);
  });

  testWidgets('规模那一块写笔数与实际区间，日期取 summary 而不是 chips', (tester) async {
    await open(
      tester,
      query: const StatisticsQuery(
        startDate: '2026-08-01',
        endDate: '2026-08-31',
      ),
    );

    expect(find.text('共 12 笔'), findsOneWidget);
    expect(find.text('2026-09-01 ~ 2026-09-14 · 14 天'), findsOneWidget);
  });

  testWidgets('行数在查时转圈，查不到也只说一句灰话并且按钮照点', (tester) async {
    final hold = Completer<TransactionSummary>();
    repo.holdCount = hold;
    // 这一格不能 settle：进度条每帧都重绘，pumpAndSettle 等不到「没有帧要画」的那一刻
    await open(tester, settle: false);

    expect(find.text('正在统计行数'), findsOneWidget);

    hold.complete(summary());
    repo.holdCount = null;
    await tester.pumpAndSettle();
    expect(find.text('共 12 笔'), findsOneWidget);

    repo.countError = const ApiException(code: ClientErrorCode.network);
    // 点标签本体，不点里面那三个字：字的渲染对象不在命中路径上，点它会报 hit test 警告
    await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
    await tester.pumpAndSettle();

    expect(find.text('笔数没查到，不影响导出'), findsOneWidget);
    expect(exportButton(tester).onPressed, isNotNull);
  });

  testWidgets('点导出把文件交给分享面板，文件名照服务端给的', (tester) async {
    await open(tester);

    await tester.tap(find.text('导出并分享'));
    await tester.pumpAndSettle();

    expect(repo.downloads, hasLength(1));
    final shared = sharer.shared.single;
    expect(shared.filename, repo.filename);
    expect(shared.bytes, repo.bytes);
  });

  testWidgets('超限那句原样显示在按钮下面，按钮回到可点', (tester) async {
    const message = '本次要导出 80000 笔，超过上限 50000 笔，请缩小时间区间后再试';
    repo.downloadError = const ApiException(
      code: 'BAD_REQUEST',
      message: message,
      statusCode: 400,
    );
    await open(tester);

    await tester.tap(find.text('导出并分享'));
    await tester.pumpAndSettle();

    expect(find.text(message), findsOneWidget);
    expect(exportButton(tester).onPressed, isNotNull);
    expect(sharer.shared, isEmpty);
  });

  testWidgets('离线时按钮与两组选择器一并按住，但这一页不挂横幅', (tester) async {
    await open(tester, network: NetworkStatus.offline);

    expect(exportButton(tester).onPressed, isNull);
    expect(find.text('离线时无法生成导出文件'), findsOneWidget);
    for (final tile in tester.widgetList<RadioListTile<ExportFormat>>(
      find.byType(RadioListTile<ExportFormat>),
    )) {
      expect(tile.enabled, isFalse, reason: tile.value.name);
    }
    for (final chip in tester.widgetList<ChoiceChip>(find.byType(ChoiceChip))) {
      expect(chip.onSelected, isNull, reason: '${chip.label}');
    }
    // 导出页没有「离线模式 · 数据截至」这回事：它手里没有缓存副本，条件选择器已经按住了
    expect(find.byType(OfflineBanner), findsNothing);
  });

  testWidgets('离线又刚好有错误时按钮下面只给一句，错误优先', (tester) async {
    repo.countError = const ApiException(
      code: 'RANGE_TOO_LONG',
      message: '时间跨度不能超过 366 天',
      statusCode: 400,
    );
    await open(tester, network: NetworkStatus.offline);

    expect(find.text('时间跨度不能超过 366 天'), findsOneWidget);
    expect(find.text('离线时无法生成导出文件'), findsNothing);
  });
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

class _StubFamily extends FamilyViewModel {
  @override
  Future<Family?> build() async => family();
}

class _FixedNetworkStatus extends NetworkStatusNotifier {
  _FixedNetworkStatus(this.status);

  final NetworkStatus status;

  @override
  NetworkStatus build() => status;
}
