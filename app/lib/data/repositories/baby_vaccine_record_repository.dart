import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/core/date_format.dart';
import '../models/baby_vaccine.dart';
import '../services/api_client.dart';

/// 一条接种记录的表单值。手写而不是 freezed：它只被拼成请求体，从不被解析。
///
/// **`nextDate` 不在这里**（§4.4.4）：服务端把「没给」与「给了 null」当同一件事，
/// 一律按该疫苗下一个未完成剂次推算，前端因此没有「清空下一针日期」这个操作。
/// 把它放进 Draft 就等于提供了一个点了没反应的输入框，比不显示更糟。
///
/// 批号与不良反应也不在这里：录入表单不收集这两栏，而 `PATCH` 是整份覆盖，
/// 带两个永远为 null 的键只会让人以为界面上有这两格。
class VaccineRecordDraft {
  const VaccineRecordDraft({
    required this.babyId,
    required this.vaccineName,
    required this.doseNo,
    required this.givenDate,
    this.planId,
    this.clinic,
    this.remark,
  });

  final int babyId;
  final String vaccineName;
  final String doseNo;
  final DateTime givenDate;

  /// 为空即交给服务端按「疫苗名称 + 剂次」自动匹配该宝宝的应种项（§4.4.4）。
  final int? planId;
  final String? clinic;
  final String? remark;

  /// 可空字段照样进 body：`PATCH` 是整份覆盖，不传的栏位即清空。
  ///
  /// 编辑时 `babyId` 也照发：后端这条 `PATCH` 收它（记录可以挪到另一个宝宝头上），
  /// 而整份覆盖的表单里宝宝选择器一直在。
  Map<String, dynamic> toJson() => {
    'babyId': babyId,
    'vaccineName': vaccineName,
    'doseNo': doseNo,
    'givenDate': formatDate(givenDate),
    'planId': planId,
    'clinic': clinic,
    'remark': remark,
  };
}

/// §4.4.4 的接种记录。**不接缓存**，理由同猫粮袋那一层。
class BabyVaccineRecordRepository {
  BabyVaccineRecordRepository({required this._api});

  final ApiClient _api;

  /// 接种日期倒序、同日按 id 倒序，不分页。`nextDate` 是落库值，只读展示。
  Future<List<BabyVaccineRecord>> list({int? babyId}) async {
    final rows = await _api.getList(
      '/baby-vaccine-records',
      query: {'babyId': babyId},
    );
    return rows.map(BabyVaccineRecord.fromJson).toList();
  }

  /// 匹配到应种项时服务端在同一事务里回写 `DONE` 并记 `record_id`，匹配不到只记一条独立记录。
  Future<void> create(VaccineRecordDraft draft) =>
      _api.post('/baby-vaccine-records', body: draft.toJson());

  /// 允许改疫苗名称与剂次：服务端先撤销旧绑定、再按新键重新匹配（§1.4 第 20 条）。
  Future<void> update(int id, VaccineRecordDraft draft) =>
      _api.patch('/baby-vaccine-records/$id', body: draft.toJson());

  /// 删掉一条会把对应应种项退回 `PENDING`，所以录错了改得回来。
  Future<void> remove(int id) => _api.delete('/baby-vaccine-records/$id');
}

final babyVaccineRecordRepositoryProvider =
    Provider<BabyVaccineRecordRepository>(
      (ref) => BabyVaccineRecordRepository(api: ref.watch(apiClientProvider)),
    );
