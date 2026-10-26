import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/export_format.dart';
import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/data/models/transaction_summary.dart';
import 'package:homeledger/data/repositories/export_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/file_sharer.dart';
import 'package:homeledger/ui/features/finance/view_models/export_view_model.dart';

import '../../../../support/fake_export_repository.dart';
import '../../../../support/fake_file_sharer.dart';
import '../../../../support/s5_fixtures.dart';

/// 导出页的状态。行数只是提示、按钮才是闸门，这两件事在状态机上是分开的两截，
/// 而 `_generation` 那道闸只有并发的时候才看得见。
void main() {
  const thisMonth = StatisticsQuery(
    startDate: '2026-09-01',
    endDate: '2026-09-14',
  );
  const lastMonth = StatisticsQuery(
    startDate: '2026-08-01',
    endDate: '2026-08-31',
  );
  const all = StatisticsQuery();

  late FakeExportRepository repo;
  late FakeFileSharer sharer;
  late ProviderContainer container;

  ExportViewModel viewModel() =>
      container.read(exportViewModelProvider.notifier);
  ExportState state() => container.read(exportViewModelProvider);

  setUp(() {
    repo = FakeExportRepository(summary: summary());
    sharer = FakeFileSharer();
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        exportRepositoryProvider.overrideWithValue(repo),
        fileSharerProvider.overrideWithValue(sharer),
      ],
    );
    addTearDown(container.dispose);
    container.listen(exportViewModelProvider, (_, _) {});
  });

  test('进页面装进继承来的条件，并只查一趟行数', () async {
    await viewModel().open(thisMonth);

    expect(state().query, thisMonth);
    expect(repo.countQueries, [thisMonth]);
  });

  test('换格式只是换个说法，不再查一遍行数', () async {
    await viewModel().open(thisMonth);

    viewModel().selectFormat(ExportFormat.csv);

    expect(state().format, ExportFormat.csv);
    expect(repo.countQueries, hasLength(1));
  });

  test('改条件先把旧笔数清掉，免得旧数字配新条件', () async {
    await viewModel().open(all);
    expect(state().summary, isNotNull);

    final applying = viewModel().applyQuery(thisMonth);
    expect(state().summary, isNull);
    await applying;

    expect(state().query, thisMonth);
    expect(repo.countQueries, [all, thisMonth]);
  });

  test('两趟行数查询同时在飞时，只有后发起的那一趟说话', () async {
    final hold = Completer<TransactionSummary>();
    repo.holdCount = hold;

    // 进页面预查的那一趟挂住；摘掉挂钩后用户改了条件，这一趟正常回来。
    final opening = viewModel().open(all);
    repo.holdCount = null;
    await viewModel().applyQuery(thisMonth);
    hold.complete(summary(count: 99));
    await opening;

    // 慢的那趟后到也不能把笔数盖回去：chips 写着本月而规模写着 99 笔，用户会照着那个数决定导不导。
    expect(state().summary?.count, 12);
  });

  test('行数查不到不拦导出', () async {
    repo.countError = const ApiException(code: ClientErrorCode.network);

    await viewModel().open(thisMonth);

    expect(state().error, isNotNull);
    expect(state().summary, isNull);

    expect(await viewModel().export(), isNull);
    expect(repo.downloads, hasLength(1));
  });

  test('导出成功把字节、文件名与类型一并交给分享面板', () async {
    await viewModel().open(thisMonth);

    expect(await viewModel().export(), isNull);

    final shared = sharer.shared.single;
    expect(shared.bytes, repo.bytes);
    expect(shared.filename, repo.filename);
    // DownloadedFile 那边叫 contentType，这边叫 mimeType，是同一个值的两种说法。
    expect(shared.mimeType, repo.contentType);
  });

  test('超限的 400 把后端那句话交回去，转圈的状态也收回来', () async {
    const message = '本次要导出 80000 笔，超过上限 50000 笔，请缩小时间区间后再试';
    repo.downloadError = const ApiException(
      code: 'BAD_REQUEST',
      message: message,
    );
    await viewModel().open(thisMonth);

    expect(await viewModel().export(), message);

    expect(state().error, message);
    expect(state().exporting, isFalse);
    expect(sharer.shared, isEmpty);
  });

  test('导出进行中的第二次点击不会再起一个下载', () async {
    await viewModel().open(thisMonth);

    final first = viewModel().export();
    final second = await viewModel().export();
    await first;

    expect(second, isNull);
    expect(repo.downloads, hasLength(1));
  });

  test('单选里选的格式真的进了下载请求', () async {
    await viewModel().open(thisMonth);
    viewModel().selectFormat(ExportFormat.csv);

    await viewModel().export();

    expect(repo.downloads.single.format, ExportFormat.csv);
  });

  test('导出用的是当前条件而不是进页面时那一份', () async {
    await viewModel().open(all);
    await viewModel().applyQuery(lastMonth);

    await viewModel().export();

    expect(repo.downloads.single.query, lastMonth);
  });

  test('分享面板抛非 ApiException 时导出按钮不卡死', () async {
    await viewModel().open(thisMonth);
    sharer.shareError = Exception('磁盘空间不足');

    final result = await viewModel().export();

    expect(result, isNotNull);
    expect(state().exporting, isFalse);
    expect(state().error, isNotNull);
  });
}
