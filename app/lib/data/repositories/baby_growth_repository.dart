import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/core/date_format.dart';
import '../models/baby_growth.dart';
import '../services/api_client.dart';

/// 一条身高体重记录的表单值。手写而不是 freezed：它只被拼成请求体，从不被解析。
///
/// 三个度量是 `String?` 而不是 `double?`：后端收发都是十进制字符串，前端把它当文本搬运，
/// 解析成 `double` 再格式化回去会在「3.50」与「3.5」之间反复横跳。
class BabyGrowthDraft {
  const BabyGrowthDraft({
    required this.babyId,
    required this.measureDate,
    this.heightCm,
    this.weightKg,
    this.headCm,
    this.remark,
  });

  final int babyId;
  final DateTime measureDate;
  final String? heightCm;
  final String? weightKg;
  final String? headCm;
  final String? remark;

  /// 可空字段照样进 body：`PATCH` 是整份覆盖，不传的度量列与备注即清空——用户把体重那一格
  /// 删干净了，就该真的没有体重，而不是留下上一次的值。
  ///
  /// 编辑时 `babyId` 也照发：后端这条 `PATCH` 收它（记录可以改到另一个宝宝头上），
  /// 而整份覆盖的表单里宝宝选择器一直在，漏掉它反而成了「这一格不参与保存」。
  Map<String, dynamic> toJson() => {
    'babyId': babyId,
    'measureDate': formatDate(measureDate),
    'heightCm': heightCm,
    'weightKg': weightKg,
    'headCm': headCm,
    'remark': remark,
  };
}

/// §4.4.2 的身高体重记录。**不接缓存**，理由同猫粮袋那一层。
class BabyGrowthRepository {
  BabyGrowthRepository({required this._api});

  final ApiClient _api;

  /// 测量日期倒序、同日按 id 倒序、不分页。`babyId` 为空是整个家庭，传了就是单个宝宝的列表。
  /// 每一行带 `deltaFromPrevious`（读时派生），改数值或日期都会自然反映到它上面。
  Future<List<BabyGrowth>> list({int? babyId}) async {
    final rows = await _api.getList('/baby-growths', query: {'babyId': babyId});
    return rows.map(BabyGrowth.fromJson).toList();
  }

  Future<void> create(BabyGrowthDraft draft) =>
      _api.post('/baby-growths', body: draft.toJson());

  Future<void> update(int id, BabyGrowthDraft draft) =>
      _api.patch('/baby-growths/$id', body: draft.toJson());

  /// 删掉一条会改这个宝宝后面各条的「较上一次」，服务端跟着失效统计缓存。
  Future<void> remove(int id) => _api.delete('/baby-growths/$id');
}

final babyGrowthRepositoryProvider = Provider<BabyGrowthRepository>(
  (ref) => BabyGrowthRepository(api: ref.watch(apiClientProvider)),
);
