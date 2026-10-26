import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import '../models/budget_progress.dart';
import '../services/api_client.dart';

/// §4.2.4 的预算：配置清单、整体保存、执行进度。同样**不做本地缓存**，理由见
/// `RecurringRuleRepository` 的类注释——配置数据给一份旧的看比不给更糟。
class BudgetRepository {
  BudgetRepository({required this._api});

  final ApiClient _api;

  Future<List<Budget>> list() async {
    final rows = await _api.getList('/budgets');
    return rows.map(Budget.fromJson).toList();
  }

  /// 整体替换：后端先删光本家庭的所有预算行再插入，所以每次保存后 `id` 都会变。
  /// 上层别拿 id 当 key 缓存自己编辑过的那几行，会串。
  ///
  /// `items` 传 null 表示「清空」，传 `[]` 表示「保存一份空的」。后端把两者都落成删光
  /// （`BudgetServiceImpl.save` 里 null 先归一成空表），所以这不是两个不同的结果，只是两种不同的说法。
  /// 界面全删光了就是 `[]`——留着这个区分是为了请求体上看得出用户点了保存，而不是页面没提交。
  Future<void> save(List<BudgetDraftItem>? items) => _api.put(
    '/budgets',
    body: {'items': items?.map((item) => item.toJson()).toList()},
  );

  /// `month` 是 `'2026-09'` 这种形状，不传就是本月。返回的是每个已配置维度一行，
  /// 没有配预算的维度不会凭空出现一行零。
  Future<List<BudgetProgress>> progress({String? month}) async {
    final rows = await _api.getList(
      '/budgets/progress',
      query: {'month': month},
    );
    return rows.map(BudgetProgress.fromJson).toList();
  }
}

/// 一条预算的提交形状。维度三选一，`categoryId` 与 `memberUserId` 由 `scope` 决定谁该有值，
/// 这套双向核对在后端做（少了报、多了也报），前端只要别把上一个维度的残留 id 带过来。
class BudgetDraftItem {
  const BudgetDraftItem({
    required this.scope,
    required this.amount,
    this.categoryId,
    this.memberUserId,
  });

  final String scope;

  final String amount;

  final int? categoryId;

  final int? memberUserId;

  Map<String, Object?> toJson() => {
    'scope': scope,
    'categoryId': categoryId,
    'memberUserId': memberUserId,
    'amount': amount,
  };
}

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepository(api: ref.watch(apiClientProvider)),
);
