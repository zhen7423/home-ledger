import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/core/date_format.dart';
import '../models/period_value.dart';
import '../models/recurring_execution.dart';
import '../models/recurring_rule.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

/// §4.4 的周期记账规则：清单、详情、新增、整体覆盖、启停、删除、执行记录。
///
/// **不接本地缓存**。规则是配置数据，离线时给用户看一份旧配置比不给更危险——他会以为
/// 改动已经生效了。`DictCacheStore` 那一层在这里完全不出现。
///
/// 列表里的 `categoryName` / `accountName` 是后端每次实时解析出来的，不是建规则时定格的快照，
/// 所以改个类别名，这里跟着变（需求文档 §4.4.2）。
class RecurringRuleRepository {
  RecurringRuleRepository({required this._api});

  final ApiClient _api;

  /// `type` 传 `'EXPENSE'` / `'INCOME'` 只回一类，不传回全部。
  /// 不在这判 null：值为 null 的键由 `ApiClient` 出门前统一摘掉。
  Future<List<RecurringRule>> list({String? type}) async {
    final rows = await _api.getList('/recurring-rules', query: {'type': type});
    return rows.map(RecurringRule.fromJson).toList();
  }

  Future<RecurringRule> byId(int id) async {
    final data = await _api.get('/recurring-rules/$id');
    return RecurringRule.fromJson(requireData(data));
  }

  Future<RecurringRule> create(RecurringRuleDraft draft) async {
    final data = await _api.post('/recurring-rules', body: draft.toJson());
    return RecurringRule.fromJson(requireData(data));
  }

  /// 与新增入参形状相同，差别只有一个 id：后端是整体覆盖语义，没有「只改这一项」的端点。
  Future<RecurringRule> update(int id, RecurringRuleDraft draft) async {
    final data = await _api.put('/recurring-rules/$id', body: draft.toJson());
    return RecurringRule.fromJson(requireData(data));
  }

  Future<RecurringRule> toggle(int id) async {
    final data = await _api.patch('/recurring-rules/$id/toggle');
    return RecurringRule.fromJson(requireData(data));
  }

  /// 软删除。已经生成的历史流水一行都不动，停的是「以后还生不生成」。
  Future<void> remove(int id) => _api.delete('/recurring-rules/$id');

  Future<List<RecurringExecution>> executions(int id) async {
    final rows = await _api.getList('/recurring-rules/$id/executions');
    return rows.map(RecurringExecution.fromJson).toList();
  }
}

/// 一次提交（新增或覆盖都用它）。字段与 `RecurringRuleCreateRequest` 一一对应，
/// 唯独收支类型不在这里——那是后端从所选类别推出来的，客户端传了也不算。
///
/// 手写的普通类而不是 freezed 模型：它只出不进，没有 `fromJson`，做成 freezed 要多养一份
/// 反序列化，而「哪个 periodType 该填哪几个周期参数」的判定本来就在后端（B3 第 7 条）。
class RecurringRuleDraft {
  const RecurringRuleDraft({
    required this.name,
    required this.amount,
    required this.categoryId,
    this.subCategoryId,
    required this.accountId,
    required this.periodType,
    required this.periodValue,
    required this.startDate,
    this.endDate,
  });

  final String name;

  /// 字符串原样发出，不做「补零到两位」的归一化：后端是 `BigDecimal`，
  /// `"12.3"` 与 `"12.30"` 是同一个值，多归一化一次只是多一处口径。
  final String amount;

  final int categoryId;

  final int? subCategoryId;

  final int accountId;

  final String periodType;

  final PeriodValue periodValue;

  final DateTime startDate;

  final DateTime? endDate;

  /// 日期在这一刻才变成 `"2026-09-13"`。放这里做而不是让表单传字符串，是为了让
  /// 「编辑规则」能直接把模型上的 `DateTime startDate` 原样搬进草稿——否则表单里
  /// 会出现一份 DateTime（回填日期选择器用）和一份 String（提交用），两份状态迟早对不上。
  /// `ui/core/date_format.dart` 是这层唯一跨目录的依赖，就为这一个函数。
  Map<String, Object?> toJson() {
    final end = endDate;
    return {
      'name': name,
      'amount': amount,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'accountId': accountId,
      'periodType': periodType,
      'periodValue': periodValue.toJson(),
      'startDate': formatDate(startDate),
      'endDate': end == null ? null : formatDate(end),
    };
  }
}

final recurringRuleRepositoryProvider = Provider<RecurringRuleRepository>(
  (ref) => RecurringRuleRepository(api: ref.watch(apiClientProvider)),
);
