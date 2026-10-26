import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/core/date_format.dart';
import '../models/baby_formula_bag.dart';
import '../services/api_client.dart';

/// 一罐奶粉的表单值（§4.5.3）。手写普通类，口径同 `CatFoodBagDraft`：只出不进。
class BabyFormulaBagDraft {
  const BabyFormulaBagDraft({
    required this.brand,
    required this.packGrams,
    required this.startedDate,
    this.startedTime,
    this.estimatedDailyGrams,
    this.remark,
  });

  final String brand;

  /// 整数克。界面上那个「kg」是显示层换算出来的，这里不出现小数，也就不会出现 `double`。
  final int packGrams;

  /// 开罐日期，可回溯补录、不可晚于今天。
  final DateTime startedDate;

  /// 开罐具体时刻（"HH:mm"），选填（2026-10-26 需求①）：只随日期一起展示，不参与任何推导。
  final String? startedTime;

  /// 开罐时填的预计每天克数，选填：只在没有可用历史罐时兜底（§4.5.3）。
  final int? estimatedDailyGrams;

  final String? remark;

  Map<String, dynamic> toJson() => {
    'brand': brand,
    'packGrams': packGrams,
    'startedDate': formatDate(startedDate),
    // 整份覆盖语义：键永远在，null 表示「清空时刻、只记日期」。
    'startedTime': startedTime,
    'estimatedDailyGrams': estimatedDailyGrams,
    'remark': remark,
  };
}

/// §4.5.3 的奶粉开罐清单。**不接缓存**：宝宝主页的奶粉卡是实时取的（记录类数据不值得快照，
/// 快照留给宝宝总览那三条端点），这里再存一份会有两个「上次成功加载」。
class BabyFormulaBagRepository {
  BabyFormulaBagRepository({required this._api});

  final ApiClient _api;

  /// 按开罐日期**升序**（当前罐在最后一条）；每行带服务端算好的 `usageDays` 与 `dailyAverage`，
  /// 当前罐那两栏为 null，显示「—」。
  Future<List<BabyFormulaBag>> list() async {
    final rows = await _api.getList('/baby-formula-bags');
    return rows.map(BabyFormulaBag.fromJson).toList();
  }

  /// 在用那一罐与它的余量推算。**`data` 为 null 不是异常**，是「一罐都还没开」；
  /// 有罐而推不出时 `data` 非空而 `estimate` 为 null，界面上是另一句提示语（§4.5.3）。
  Future<BabyFormulaCurrent?> current() async {
    final data = await _api.get('/baby-formula-bags/current');
    return data == null ? null : BabyFormulaCurrent.fromJson(data);
  }

  Future<void> create(BabyFormulaBagDraft draft) =>
      _api.post('/baby-formula-bags', body: draft.toJson());

  Future<void> update(int id, BabyFormulaBagDraft draft) =>
      _api.patch('/baby-formula-bags/$id', body: draft.toJson());

  Future<void> remove(int id) => _api.delete('/baby-formula-bags/$id');
}

final babyFormulaBagRepositoryProvider = Provider<BabyFormulaBagRepository>(
  (ref) => BabyFormulaBagRepository(api: ref.watch(apiClientProvider)),
);