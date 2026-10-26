import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/core/date_format.dart';
import '../models/cat_deworming.dart';
import '../services/api_client.dart';

/// 一条驱虫记录的表单值。手写而不是 freezed：它只被拼成请求体，从不被解析，
/// `copyWith` 与 `==` 对一个还没提交成功的表单没有意义（口径同 `RecurringRuleDraft`）。
class CatDewormingDraft {
  const CatDewormingDraft({
    required this.catId,
    required this.type,
    required this.doneDate,
    required this.medicine,
    this.dosage,
    this.nextDate,
    this.remark,
  });

  final int catId;
  final String type;
  final DateTime doneDate;
  final String medicine;
  final String? dosage;

  /// `null` 表示「按周期帮我算」，非空是用户覆盖——这一格在界面上要有一行说明，
  /// 因为它跟服务端到底写不写 `next_date` 直接相关（§4.3.3）。
  final DateTime? nextDate;
  final String? remark;

  /// 可空字段照样进 body：`PATCH` 是整份覆盖，漏传等于「保留旧值」，
  /// 而用户把剂量删空了就该真的删空。
  Map<String, dynamic> toJson() {
    final next = nextDate;
    return {
      'catId': catId,
      'type': type,
      'doneDate': formatDate(doneDate),
      'medicine': medicine,
      'dosage': dosage,
      'nextDate': next == null ? null : formatDate(next),
      'remark': remark,
    };
  }
}

/// §4.3.3 的驱虫记录。**不接缓存**，理由同猫粮袋那一层。
class CatDewormingRepository {
  CatDewormingRepository({required this._api});

  final ApiClient _api;

  /// 按驱虫日期倒序。`catId` 为空是整个家庭的记录（猫咪统计页那一张表），
  /// 传了就是单只猫的时间轴。归档猫的历史记录照常出现——归档不等于删除（§4.3.1）。
  Future<List<CatDeworming>> list({int? catId}) async {
    final rows = await _api.getList(
      '/cat-dewormings',
      query: {'catId': catId},
    );
    return rows.map(CatDeworming.fromJson).toList();
  }

  Future<void> create(CatDewormingDraft draft) =>
      _api.post('/cat-dewormings', body: draft.toJson());

  Future<void> update(int id, CatDewormingDraft draft) =>
      _api.patch('/cat-dewormings/$id', body: draft.toJson());

  Future<void> remove(int id) => _api.delete('/cat-dewormings/$id');
}

final catDewormingRepositoryProvider = Provider<CatDewormingRepository>(
  (ref) => CatDewormingRepository(api: ref.watch(apiClientProvider)),
);
