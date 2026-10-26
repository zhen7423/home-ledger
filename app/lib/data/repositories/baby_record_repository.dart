import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/core/date_format.dart';
import '../models/baby_record.dart';
import '../services/api_client.dart';

/// 一条里程碑的表单值。手写而不是 freezed：它只被拼成请求体，从不被解析。
///
/// `title` 没有字典：内置常用项是 `baby_copy.dart` 里的一份常量清单，挑它和自由输入
/// 落的是同一列，库里分不出两者（§4.4.5）。
class MilestoneDraft {
  const MilestoneDraft({
    required this.babyId,
    required this.occurDate,
    required this.title,
    this.description,
  });

  final int babyId;
  final DateTime occurDate;
  final String title;
  final String? description;

  /// 编辑时 `babyId` 也照发：后端那条 `PATCH` 的 DTO 里没有这个键、多传的被忽略，
  /// 但整份覆盖的表单里宝宝选择器一直在，凭空漏掉一个字段反而让人以为是漏了。
  Map<String, dynamic> toJson() => {
    'babyId': babyId,
    'occurDate': formatDate(occurDate),
    'title': title,
    'description': description,
  };
}

/// 一条就诊记录的表单值。除宝宝与就诊日期外全是选填——带一次孩子看病未必记得住科室。
class MedicalDraft {
  const MedicalDraft({
    required this.babyId,
    required this.visitDate,
    this.hospital,
    this.department,
    this.diagnosis,
    this.medicine,
    this.costAmount,
    this.remark,
  });

  final int babyId;
  final DateTime visitDate;
  final String? hospital;
  final String? department;
  final String? diagnosis;
  final String? medicine;

  /// 字符串原样发出，与金额同一条理由：后端是 `BigDecimal`。
  /// 它只是记录，不同步生成流水——就诊与记账是两件事（§4.4.5）。
  final String? costAmount;
  final String? remark;

  Map<String, dynamic> toJson() => {
    'babyId': babyId,
    'visitDate': formatDate(visitDate),
    'hospital': hospital,
    'department': department,
    'diagnosis': diagnosis,
    'medicine': medicine,
    'costAmount': costAmount,
    'remark': remark,
  };
}

/// §4.4.5 的里程碑与就诊记录。两套 CRUD 合成一个仓库：它们同属「日期 + 类型 + 文本」这一类轻量记录，
/// 页面上也同屏两分段（§1.3 第 4 条），拆成两个仓库只会让那一页 watch 两个 provider。
///
/// **不接缓存**，理由同猫粮袋那一层。
class BabyRecordRepository {
  BabyRecordRepository({required this._api});

  final ApiClient _api;

  /// 按发生日期升序、同日按 id 升序——这个顺序就是统计页的里程碑时间轴。
  Future<List<BabyMilestone>> listMilestones({int? babyId}) async {
    final rows = await _api.getList(
      '/baby-milestones',
      query: {'babyId': babyId},
    );
    return rows.map(BabyMilestone.fromJson).toList();
  }

  Future<void> createMilestone(MilestoneDraft draft) =>
      _api.post('/baby-milestones', body: draft.toJson());

  Future<void> updateMilestone(int id, MilestoneDraft draft) =>
      _api.patch('/baby-milestones/$id', body: draft.toJson());

  Future<void> removeMilestone(int id) => _api.delete('/baby-milestones/$id');

  /// 按就诊日期降序、同日按 id 降序（就诊是回看）。
  Future<List<BabyMedical>> listMedicals({int? babyId}) async {
    final rows = await _api.getList('/baby-medicals', query: {'babyId': babyId});
    return rows.map(BabyMedical.fromJson).toList();
  }

  Future<void> createMedical(MedicalDraft draft) =>
      _api.post('/baby-medicals', body: draft.toJson());

  Future<void> updateMedical(int id, MedicalDraft draft) =>
      _api.patch('/baby-medicals/$id', body: draft.toJson());

  Future<void> removeMedical(int id) => _api.delete('/baby-medicals/$id');
}

final babyRecordRepositoryProvider = Provider<BabyRecordRepository>(
  (ref) => BabyRecordRepository(api: ref.watch(apiClientProvider)),
);
