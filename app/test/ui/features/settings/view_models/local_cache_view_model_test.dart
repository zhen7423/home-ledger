import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/data/models/reminder_state.dart';
import 'package:homeledger/data/services/baby_overview_cache_store.dart';
import 'package:homeledger/data/services/cat_overview_cache_store.dart';
import 'package:homeledger/data/services/dict_cache_store.dart';
import 'package:homeledger/data/services/reminder_state_store.dart';
import 'package:homeledger/data/services/statistics_cache_store.dart';
import 'package:homeledger/data/services/transaction_cache_store.dart';
import 'package:homeledger/ui/features/settings/view_models/local_cache_view_model.dart';

import '../../../../support/finance_fixtures.dart';
import '../../../../support/s5_fixtures.dart';

/// 设置页「清除本地缓存」。五份 store 都是真的、指向同一个临时目录：
/// 这一项唯一会被做错的地方就是「清多了」或「清少了」，只有真文件能看出来。
void main() {
  late Directory root;
  late DictCacheStore dict;
  late TransactionCacheStore transactions;
  late StatisticsCacheStore statistics;
  late CatOverviewCacheStore catOverview;
  late BabyOverviewCacheStore babyOverview;
  late LocalCacheViewModel viewModel;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('local_cache');
    dict = DictCacheStore(directoryResolver: () async => root);
    transactions = TransactionCacheStore(directoryResolver: () async => root);
    statistics = StatisticsCacheStore(directoryResolver: () async => root);
    catOverview = CatOverviewCacheStore(directoryResolver: () async => root);
    babyOverview = BabyOverviewCacheStore(directoryResolver: () async => root);
    viewModel = LocalCacheViewModel(
      dict: dict,
      transactions: transactions,
      statistics: statistics,
      catOverview: catOverview,
      babyOverview: babyOverview,
    );

    await dict.writeCategories(categories());
    await transactions.merge([tx(id: 1, bizDate: DateTime(2026, 9, 10))]);
    await statistics.write(
      query: const StatisticsQuery(),
      summary: summary(),
      overview: overview(),
    );
    // 内容不是这一条要验的东西，空快照同样会落下 cat-overview.json 那个文件
    await catOverview.write(
      cats: const [],
      bag: null,
      estimate: null,
      dueCountdown: const [],
    );
    await babyOverview.write(babies: const []);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('五份能从服务端再生的缓存都没了', () async {
    await viewModel.clear();

    expect(await dict.readCategories(), isEmpty);
    expect((await transactions.readRange(null, null)).rows, isEmpty);
    expect(await statistics.read(), isNull);
    expect(await catOverview.read(), isNull);
    expect(await babyOverview.read(), isNull);
  });

  test('提醒去重状态不在清除范围内', () async {
    const state = ReminderState(
      notified: {'BUDGET_OVERRUN:FAMILY': '2026-09-14'},
    );
    await ReminderStateStore(directoryResolver: () async => root).write(state);

    await viewModel.clear();

    // 那份记的是「这台设备今天为哪条提醒发过通知、用户划过哪几条」，
    // 删了它当天会重复弹通知、划掉的红点又长回来（§4.7）。
    expect(
      await ReminderStateStore(directoryResolver: () async => root).read(),
      state,
    );
  });
}
