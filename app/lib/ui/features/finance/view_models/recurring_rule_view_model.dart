import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/recurring_execution.dart';
import '../../../../data/models/recurring_rule.dart';
import '../../../../data/repositories/recurring_rule_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../home/view_models/home_view_model.dart';
import 'transaction_list_view_model.dart';

/// §4.4 的周期规则清单。整份读、写后重拉，与 `PaymentAccountViewModel` 同一形状。
class RecurringRuleViewModel extends AsyncNotifier<List<RecurringRule>> {
  @override
  Future<List<RecurringRule>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    return _repository.list();
  }

  /// 只看某一类收支，不传就是全部。列表页的「全部 / 支出 / 收入」筛选条走这里。
  Future<String?> load({String? type}) =>
      _run(() => _repository.list(type: type));

  /// 详情页与编辑页按 id 取一条：通知可以直接跳进详情页，那时列表里未必有它。
  /// 失败照抛，由页面的错误态接——把 ApiException 咽成 null 会把「服务坏了」演成「没有这条规则」。
  Future<RecurringRule> byId(int id) => _repository.byId(id);

  Future<List<RecurringExecution>> executions(int id) =>
      _repository.executions(id);

  Future<String?> create(RecurringRuleDraft draft) async {
    final error = await _write(() => _repository.create(draft));
    if (error == null) _refreshLedger();
    return error;
  }

  /// 编辑页提交既有规则。不叫 `update`：`AsyncNotifier` 自己就有一个 `update(...)`，
  /// 同名会变成签名不合法的覆写（Riverpod 3.4.3 实测报错）。
  Future<String?> save(int id, RecurringRuleDraft draft) async {
    final error = await _write(() => _repository.update(id, draft));
    if (error == null) _refreshLedger();
    return error;
  }

  Future<String?> toggle(int id) => _write(() => _repository.toggle(id));

  Future<String?> remove(int id) => _write(() => _repository.remove(id));

  RecurringRuleRepository get _repository =>
      ref.read(recurringRuleRepositoryProvider);

  /// 建 / 改规则会让后端在同一次请求里补上当期流水（A4），流水列表必须重拉。
  /// 漏掉这一步的症状很隐蔽：用户建完规则回记账 Tab 看不到那笔，下拉刷新才出来，像是后端没生成。
  /// 首页那个「今日自动生成 N 笔」现在长在聚合响应里（S9），一起失效。
  void _refreshLedger() {
    ref.invalidate(transactionListViewModelProvider);
    ref.invalidate(homeOverviewProvider);
  }

  Future<String?> _write(Future<void> Function() action) => _run(() async {
    await action();
    return _repository.list();
  });

  Future<String?> _run(Future<List<RecurringRule>> Function() action) async {
    try {
      state = AsyncData(await action());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return errorCopy(e);
    }
    return null;
  }
}

final recurringRuleViewModelProvider =
    AsyncNotifierProvider<RecurringRuleViewModel, List<RecurringRule>>(
      RecurringRuleViewModel.new,
    );
