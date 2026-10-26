import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/budget.dart';
import '../../../../data/models/budget_progress.dart';
import '../../../../data/repositories/budget_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';

/// §4.2.4 的预算配置，管理页用它编辑那几行额度。
///
/// 与 `BudgetProgressViewModel` 分成两个而不是并成一个状态：保存只动额度、切月份只动进度，
/// 合成一个会让「改个金额」把进度条也刷成 loading，界面上白闪一下。
class BudgetViewModel extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    return _repository.list();
  }

  Future<String?> load() => _run(_repository.list);

  /// 整体提交。`items` 为空列表就是把预算全删了——后端先删光再插入，所以保存之后每一行的
  /// `id` 都会变，界面上别拿旧 id 当 key 去找刚提交的那一行。
  ///
  /// 同一维度在一次提交里出现两次，后端回 `BUDGET_DUPLICATED` 并整笔回滚，库里一条都不留。
  Future<String?> save(List<BudgetDraftItem> items) => _run(() async {
    await _repository.save(items);
    // 额度一变，进度条的分母就是另一回事了。进度页可能正开着（首页也读它）。
    ref.invalidate(budgetProgressViewModelProvider);
    return _repository.list();
  });

  BudgetRepository get _repository => ref.read(budgetRepositoryProvider);

  Future<String?> _run(Future<List<Budget>> Function() action) async {
    try {
      state = AsyncData(await action());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return errorCopy(e);
    }
    return null;
  }
}

final budgetViewModelProvider =
    AsyncNotifierProvider<BudgetViewModel, List<Budget>>(BudgetViewModel.new);

/// 预算执行进度。一行一个已配置的维度，进度口径含周期规则自动生成的流水（§4.2.4）。
///
/// 只配了预算的维度才有行：没设过类别预算时这里不会冒出一条「餐饮 0 / 0」，
/// 界面上那一段就直接不显示。
class BudgetProgressViewModel extends AsyncNotifier<List<BudgetProgress>> {
  @override
  Future<List<BudgetProgress>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    return _repository.progress();
  }

  /// `month` 形如 `'2026-09'`，不传就是本月。切月份是换一份数据，不是在本地上再算一遍——
  /// 已用金额由后端按 `biz_date` 聚合，前端没有那份流水。
  Future<String?> load({String? month}) =>
      _run(() => _repository.progress(month: month));

  BudgetRepository get _repository => ref.read(budgetRepositoryProvider);

  Future<String?> _run(Future<List<BudgetProgress>> Function() action) async {
    try {
      state = AsyncData(await action());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return errorCopy(e);
    }
    return null;
  }
}

final budgetProgressViewModelProvider =
    AsyncNotifierProvider<BudgetProgressViewModel, List<BudgetProgress>>(
      BudgetProgressViewModel.new,
    );
