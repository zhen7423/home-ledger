import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/baby_formula_bag.dart';
import '../../../../data/repositories/baby_formula_bag_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../settings/view_models/reminder_view_model.dart';
import 'baby_formula_statistics_view_model.dart';
import 'baby_home_view_model.dart';
import 'baby_statistics_view_model.dart';

/// §4.5.3 的奶粉开罐清单。**该端点没有归档概念**（§4.5.3 的罐只有「在不在时间线上」），
/// 也没有详情端点，所以编辑一罐同样从这份列表里按 id 找。
class BabyFormulaViewModel extends AsyncNotifier<List<BabyFormulaBag>> {
  @override
  Future<List<BabyFormulaBag>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    return _repository.list();
  }

  /// 编辑一罐时按 id 取那一行，取法就是上面那份列表。
  BabyFormulaBag? byId(int id) {
    for (final bag in state.value ?? const <BabyFormulaBag>[]) {
      if (bag.id == id) {
        return bag;
      }
    }
    return null;
  }

  Future<String?> create(BabyFormulaBagDraft draft) async {
    final error = await _write(() => _repository.create(draft));
    if (error == null) _fanOut();
    return error;
  }

  Future<String?> save(int id, BabyFormulaBagDraft draft) async {
    final error = await _write(() => _repository.update(id, draft));
    if (error == null) _fanOut();
    return error;
  }

  /// 删掉一罐会让**后面每一罐**的结束日与使用天数整体左移（§4.5.3 的推导链），
  /// 所以这里绝不做「本地把那一行摘掉」的增量删除。
  Future<String?> remove(int id) async {
    final error = await _write(() => _repository.remove(id));
    if (error == null) _fanOut();
    return error;
  }

  BabyFormulaBagRepository get _repository =>
      ref.read(babyFormulaBagRepositoryProvider);

  /// 开罐 / 改罐 / 删罐改的是奶粉卡的**全部**数字（日均、剩余、可喝天数、耗尽日），
  /// 以及统计页的分摊；奶粉见底的待办提醒也要重算，所以待办 provider 一并失效。
  void _fanOut() {
    ref.invalidate(babyFormulaCurrentProvider);
    ref.invalidate(babyHomeViewModelProvider);
    ref.invalidate(babyStatisticsViewModelProvider(null));
    ref.invalidate(babyFormulaStatisticsViewModelProvider);
    ref.invalidate(pendingReminderViewModelProvider);
  }

  Future<String?> _write(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      return errorCopy(e);
    }
    try {
      state = AsyncData(await _repository.list());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return errorCopy(e);
    }
    return null;
  }
}

final babyFormulaViewModelProvider =
    AsyncNotifierProvider<BabyFormulaViewModel, List<BabyFormulaBag>>(
      BabyFormulaViewModel.new,
    );

/// 奶粉卡的当前罐与余量推算（§4.5.3）。与列表分开走 /current 端点：
/// 列表行里当前罐的两栏是 null，估算卡需要那份推算；页面加载时两者并行。
/// 离线时该 provider 失败回 error，卡片按「需要联网」处理（奶粉记录不做离线快照）。
final babyFormulaCurrentProvider = FutureProvider<BabyFormulaCurrent?>((
  ref,
) async {
  if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
      SessionStatus.signedIn) {
    return null;
  }
  return ref.watch(babyFormulaBagRepositoryProvider).current();
});
