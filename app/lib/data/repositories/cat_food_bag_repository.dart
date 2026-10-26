import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/core/date_format.dart';
import '../models/cat_food_bag.dart';
import '../services/api_client.dart';

/// 一袋猫粮的表单值（§4.3.2）。手写普通类，口径同 `CatDraft`：只出不进。
class CatFoodBagDraft {
  const CatFoodBagDraft({
    required this.brand,
    required this.packGrams,
    required this.startedDate,
    this.remark,
  });

  final String brand;

  /// 整数克。界面上那个「kg」是显示层换算出来的，这里不出现小数，也就不会出现 `double`。
  final int packGrams;

  final DateTime startedDate;
  final String? remark;

  Map<String, dynamic> toJson() => {
    'brand': brand,
    'packGrams': packGrams,
    'startedDate': formatDate(startedDate),
    'remark': remark,
  };
}

/// §4.3.2 的猫粮袋清单。**不接缓存**：余量卡的快照在 `CatOverviewRepository` 那条链路上，
/// 这里再存一份会有两个「上次成功加载」。
class CatFoodBagRepository {
  CatFoodBagRepository({required this._api});

  final ApiClient _api;

  /// 按开始日期**升序**（当前袋在最后一条，因为它是开始日最大的那袋）；每行带服务端算好的
  /// `usageDays` 与 `dailyAverage`，当前袋那两栏为 null，显示「—」。
  Future<List<CatFoodBag>> list() async {
    final rows = await _api.getList('/cat-food-bags');
    return rows.map(CatFoodBag.fromJson).toList();
  }

  /// 在用那一袋与它的余量推算。**`data` 为 null 不是异常**，是「一袋都还没开」，
  /// 所以这里不能过 `requireData`（那会抛「服务端没有返回数据」）。
  /// 有袋而推不出时 `data` 非空而 `estimate` 为 null，界面上是另一句提示语（§4.3.4）。
  Future<CatFoodCurrent?> current() async {
    final data = await _api.get('/cat-food-bags/current');
    return data == null ? null : CatFoodCurrent.fromJson(data);
  }

  Future<void> create(CatFoodBagDraft draft) =>
      _api.post('/cat-food-bags', body: draft.toJson());

  Future<void> update(int id, CatFoodBagDraft draft) =>
      _api.patch('/cat-food-bags/$id', body: draft.toJson());

  Future<void> remove(int id) => _api.delete('/cat-food-bags/$id');
}

final catFoodBagRepositoryProvider = Provider<CatFoodBagRepository>(
  (ref) => CatFoodBagRepository(api: ref.watch(apiClientProvider)),
);
