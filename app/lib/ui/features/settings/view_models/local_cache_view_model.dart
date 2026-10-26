import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/services/baby_overview_cache_store.dart';
import '../../../../data/services/cat_overview_cache_store.dart';
import '../../../../data/services/dict_cache_store.dart';
import '../../../../data/services/statistics_cache_store.dart';
import '../../../../data/services/transaction_cache_store.dart';

/// 设置页「数据 → 清除本地缓存」（§4.4）。
///
/// 是个普通类，不是 `Notifier`：删几个本地文件是毫秒级的事，没有要观察的中间状态，
/// 页面 await 完弹一句「已清除本地缓存」就够了。为它建一份状态只是多一处要同步的地方。
class LocalCacheViewModel {
  LocalCacheViewModel({
    required this._dict,
    required this._transactions,
    required this._statistics,
    required this._catOverview,
    required this._babyOverview,
  });

  final DictCacheStore _dict;
  final TransactionCacheStore _transactions;
  final StatisticsCacheStore _statistics;
  final CatOverviewCacheStore _catOverview;
  final BabyOverviewCacheStore _babyOverview;

  /// 清的是五份**可从服务端再生**的缓存：字典、流水、统计快照、猫咪总览快照、宝宝总览快照。
  ///
  /// 不清 `ReminderStateStore`——那份存的是「这台设备今天为哪条提醒发过通知、用户划过
  /// 哪几条」（S4），删了它当天会重复弹通知、划掉的红点又长回来。它记的是设备级行为，
  /// 不是业务数据的副本，跟这一项不是一回事。
  Future<void> clear() async {
    await _dict.clear();
    await _transactions.clear();
    await _statistics.clear();
    await _catOverview.clear();
    await _babyOverview.clear();
  }
}

final localCacheViewModelProvider = Provider<LocalCacheViewModel>(
  (ref) => LocalCacheViewModel(
    dict: ref.watch(dictCacheStoreProvider),
    transactions: ref.watch(transactionCacheStoreProvider),
    statistics: ref.watch(statisticsCacheStoreProvider),
    catOverview: ref.watch(catOverviewCacheStoreProvider),
    babyOverview: ref.watch(babyOverviewCacheStoreProvider),
  ),
);
