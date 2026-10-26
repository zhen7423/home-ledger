import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/core/date_format.dart';
import '../models/baby_vaccine.dart';
import '../services/api_client.dart';

/// 一条手动新增的自费应种项。手写而不是 freezed：它只被拼成请求体，从不被解析。
///
/// **只有这四个字段**：应种日期是用户自己定的，手动行不参与改出生日期时的整份重算（§4.4.4），
/// 所以这里没有「跟着生日平移」这件事要表达。
class ManualPlanDraft {
  const ManualPlanDraft({
    required this.babyId,
    required this.vaccineName,
    required this.doseNo,
    required this.dueDate,
  });

  final int babyId;
  final String vaccineName;
  final String doseNo;
  final DateTime dueDate;

  Map<String, dynamic> toJson() => {
    'babyId': babyId,
    'vaccineName': vaccineName,
    'doseNo': doseNo,
    'dueDate': formatDate(dueDate),
  };
}

/// §4.4.4 的应种清单。**不接缓存**，理由同猫粮袋那一层。
class BabyVaccinePlanRepository {
  BabyVaccinePlanRepository({required this._api});

  final ApiClient _api;

  /// 按生效日期（服务端 COALESCE(plannedDate, dueDate)）升序、同日按 id 升序，不分页；前端不重排。
  /// `babyId` 为空是整个家庭。
  ///
  /// 每一行带 `displayStatus`，那是服务端按生效日期与今天现场算出来的展示态——
  /// 界面按它上色，而「标记跳过 / 撤销」要判的是落库的 `status`（§4.4.4）。
  Future<List<BabyVaccinePlan>> list({int? babyId}) async {
    final rows = await _api.getList(
      '/baby-vaccine-plans',
      query: {'babyId': babyId},
    );
    return rows.map(BabyVaccinePlan.fromJson).toList();
  }

  /// 落 `manual = 1`，只有这种行能删。同宝宝同「疫苗名称 + 剂次」已有行时被拒，
  /// 服务端文案已经是「已在应种清单里」，前端原样显示。
  Future<void> createManual(ManualPlanDraft draft) =>
      _api.post('/baby-vaccine-plans', body: draft.toJson());

  /// 设置 / 清除计划接种日期（2026-10-26 需求②）。`plannedDate` 为 null 表示清除、
  /// 回到程序表应种日期。已接种的行服务端拒绝，文案原样显示。
  Future<void> setPlannedDate(int id, DateTime? plannedDate) =>
      _api.put('/baby-vaccine-plans/$id/planned-date', body: {
        'plannedDate': plannedDate == null ? null : formatDate(plannedDate),
      });

  /// 标记跳过 / 不适用 / 撤销。`status` 只接受 `SKIPPED` / `NA` 与撤销用的 `PENDING`。
  ///
  /// `reason` 只在标记时有意义（撤销时服务端忽略并清空那一列），所以空值直接不带这个键：
  /// 撤销本来就没有原因可填，带一个 `null` 进去只是让请求体多一个没有含义的字段。
  /// 为这两个字段造一个 Draft 不值当（§4.4.4）。
  Future<void> mark(int id, String status, String? reason) {
    final body = <String, dynamic>{'status': status};
    if (reason != null) {
      body['reason'] = reason;
    }
    return _api.patch('/baby-vaccine-plans/$id', body: body);
  }

  /// 仅手动行可删；字典生成的行服务端拒绝并说明原因，前端原样显示那句话。
  Future<void> remove(int id) => _api.delete('/baby-vaccine-plans/$id');
}

final babyVaccinePlanRepositoryProvider = Provider<BabyVaccinePlanRepository>(
  (ref) => BabyVaccinePlanRepository(api: ref.watch(apiClientProvider)),
);
