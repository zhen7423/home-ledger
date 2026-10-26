import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_account.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/dict_cache_store.dart';

/// 支付方式清单 + 它是从网络拿的还是从缓存兜的。理由同 `CategoryTreeResult`。
class PaymentAccountListResult {
  const PaymentAccountListResult(this.accounts, {required this.fromCache});

  final List<PaymentAccount> accounts;
  final bool fromCache;
}

/// §4.2.4 的支付方式管理。
///
/// 「每个家庭恰好一行 `isDefault = 1`」是后端维持的不变量，所以这里不存在「找不到默认项」的分支。
/// 写操作同样不回对象：设默认会连带改掉其他行，界面拿一条记录无法修正整份列表，重拉一次最省事。
class PaymentAccountRepository {
  PaymentAccountRepository({required this._api, required this._cache});

  final ApiClient _api;
  final DictCacheStore _cache;

  /// 一次取全量（含停用项），停用与否由界面区分显示。缓存里始终只有这一种形状。
  Future<PaymentAccountListResult> list() async {
    try {
      final rows = await _api.getList('/payment-accounts');
      final accounts = rows.map(PaymentAccount.fromJson).toList();
      await _cache.writeAccounts(accounts);
      return PaymentAccountListResult(accounts, fromCache: false);
    } on ApiException catch (e) {
      if (!e.isTransportFailure) rethrow;
      final cached = await _cache.readAccounts();
      if (cached.isEmpty) rethrow;
      return PaymentAccountListResult(cached, fromCache: true);
    }
  }

  Future<void> create(String name) =>
      _api.post('/payment-accounts', body: {'name': name});

  /// 改名与设默认共用这一个端点：传 `isDefault: true` 时后端在同一事务里清掉其他行的默认标记，
  /// 没有独立的「设为默认」端点（需求文档 §8）。两个参数都为 null 时这条 PATCH 什么都不改。
  Future<void> update(int id, {String? name, bool? isDefault}) => _api.patch(
    '/payment-accounts/$id',
    body: {'name': name, 'isDefault': isDefault},
  );

  /// 默认项不可停用，后端回 `PAYMENT_ACCOUNT_IS_DEFAULT` 并提示先转移默认。
  Future<void> toggle(int id) => _api.patch('/payment-accounts/$id/toggle');

  /// 默认项同样不可删除。历史流水带的是名称快照，删掉支付方式不会改动它们。
  Future<void> remove(int id) => _api.delete('/payment-accounts/$id');

  Future<void> sort(List<int> orderedIds) =>
      _api.put('/payment-accounts/sort', body: {'orderedIds': orderedIds});
}

final paymentAccountRepositoryProvider = Provider<PaymentAccountRepository>(
  (ref) => PaymentAccountRepository(
    api: ref.watch(apiClientProvider),
    cache: ref.watch(dictCacheStoreProvider),
  ),
);
