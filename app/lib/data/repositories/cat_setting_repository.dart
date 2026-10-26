import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cat_setting.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

/// 猫咪设置的表单值。三个字段就是 `PUT` 的整份 body，第四个出参字段
/// `estimateTakenOverByHistory` 由服务端算，客户端传了也不认（判据在它手里，见 `CatSetting`）。
class CatSettingDraft {
  const CatSettingDraft({
    required this.internalMonths,
    required this.externalMonths,
    this.estimatedDailyGrams,
  });

  final int internalMonths;
  final int externalMonths;

  /// 可空：清空这一栏是一个真实的用户意图（改回「按历史袋算」），所以 `toJson()` 里它必须出现，
  /// 而不是被 `if` 摘掉——`PUT` 在这里是整份 upsert。
  final int? estimatedDailyGrams;

  Map<String, dynamic> toJson() => {
    'internalMonths': internalMonths,
    'externalMonths': externalMonths,
    'estimatedDailyGrams': estimatedDailyGrams,
  };
}

/// §4.3.3 + §4.3.4 的猫咪设置。一个家庭一份，没有列表也没有 id。
///
/// `save` 回的是保存后的整份：PUT 的响应里带着现算的 `estimateTakenOverByHistory`，
/// 那一栏的判断在服务端，前端自己拼一份迟早与它不一致，重拉一次 GET 也只是多一趟往返。
class CatSettingRepository {
  CatSettingRepository({required this._api});

  final ApiClient _api;

  /// 从没存过设置时服务端回的是 3 / 1 / null 那三个默认值，**不会**回 null 数据，
  /// 因此这里过 `requireData`：真回 null 就是契约被破坏了。
  Future<CatSetting> get() async =>
      CatSetting.fromJson(requireData(await _api.get('/cat-settings')));

  Future<CatSetting> save(CatSettingDraft draft) async =>
      CatSetting.fromJson(
        requireData(
          await _api.put('/cat-settings', body: draft.toJson()),
        ),
      );
}

final catSettingRepositoryProvider = Provider<CatSettingRepository>(
  (ref) => CatSettingRepository(api: ref.watch(apiClientProvider)),
);
