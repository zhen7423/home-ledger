import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/cat_deworming.dart';
import '../../../../data/repositories/cat_deworming_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';
import 'cat_overview_view_model.dart';
import 'cat_statistics_view_model.dart';

/// §4.3.3 的驱虫记录清单。状态是**全量**（不带 `catId` 过滤）：「只看这只猫」由界面自己 `where`，
/// 照周期规则列表页那一处筛选用法。把过滤写进状态的后果是它跨页面残留——从倒计时点进来看过一次，
/// 下次从记录入口进来还留着上一次的过滤，而没有任何地方能把它清掉。
class CatDewormingViewModel extends AsyncNotifier<List<CatDeworming>> {
  @override
  Future<List<CatDeworming>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    return _repository.list();
  }

  /// §8 的驱虫记录同样没有 `GET /cat-dewormings/{id}`，所以编辑一条历史记录也是从这份列表里找。
  /// 列表是全量，因此按 id 一定找得到，哪怕用户是从「只看这只猫」的筛选页里点进来的。
  CatDeworming? byId(int id) {
    for (final row in state.value ?? const <CatDeworming>[]) {
      if (row.id == id) {
        return row;
      }
    }
    return null;
  }

  Future<String?> create(CatDewormingDraft draft) async {
    final error = await _write(() => _repository.create(draft));
    if (error == null) _fanOut();
    return error;
  }

  /// 编辑一条历史记录。归档猫的那条也能改：后端的 `update` 特意不重校验猫是否在册。
  Future<String?> save(int id, CatDewormingDraft draft) async {
    final error = await _write(() => _repository.update(id, draft));
    if (error == null) _fanOut();
    return error;
  }

  Future<String?> remove(int id) async {
    final error = await _write(() => _repository.remove(id));
    if (error == null) _fanOut();
    return error;
  }

  CatDewormingRepository get _repository =>
      ref.read(catDewormingRepositoryProvider);

  /// 新增一条会把旧的「下次日期」连同逾期状态一起改写（§4.3.3：下次日期按本次驱虫日期算），
  /// 所以总览的倒计时与统计页的完成度必须一起重取。
  void _fanOut() {
    ref.invalidate(catOverviewViewModelProvider);
    ref.invalidate(catStatisticsViewModelProvider);
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

final catDewormingViewModelProvider =
    AsyncNotifierProvider<CatDewormingViewModel, List<CatDeworming>>(
      CatDewormingViewModel.new,
    );
