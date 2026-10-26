import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/baby_growth.dart';
import '../../../../data/repositories/baby_growth_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';
import 'baby_curve_view_model.dart';
import 'baby_home_view_model.dart';
import 'baby_statistics_view_model.dart';

/// §4.4.2 的身高体重记录。状态是**全量**（不带 `babyId` 过滤）：「只看这个宝宝」由界面自己 `where`，
/// 照猫驱虫清单那一处用法。列表页与曲线页各有自己的 `?babyId=`，把过滤写进状态的后果是它跨页面残留，
/// 而没有任何地方能把它清掉。
class BabyGrowthViewModel extends AsyncNotifier<List<BabyGrowth>> {
  @override
  Future<List<BabyGrowth>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    return _repository.list();
  }

  /// 没有 `GET /baby-growths/{id}`，编辑表单从这份列表里回填。列表是全量，因此按 id 一定找得到，
  /// 哪怕用户是从「只看这个宝宝」的筛选页里点进来的。
  BabyGrowth? byId(int id) {
    for (final row in state.value ?? const <BabyGrowth>[]) {
      if (row.id == id) {
        return row;
      }
    }
    return null;
  }

  Future<String?> create(BabyGrowthDraft draft) async {
    final error = await _write(() => _repository.create(draft));
    if (error == null) {
      _fanOut();
    }
    return error;
  }

  Future<String?> save(int id, BabyGrowthDraft draft) async {
    final error = await _write(() => _repository.update(id, draft));
    if (error == null) {
      _fanOut();
    }
    return error;
  }

  Future<String?> remove(int id) async {
    final error = await _write(() => _repository.remove(id));
    if (error == null) {
      _fanOut();
    }
    return error;
  }

  BabyGrowthRepository get _repository =>
      ref.read(babyGrowthRepositoryProvider);

  /// 改动会同时落到三处：曲线的点集、统计的「最新一档 + 三段增量」、总览卡上的最新体格一行。
  /// 「较上一次」是读时派生的，删掉一条也会改到它，所以三处都得重取（§4.4.2）。
  void _fanOut() {
    ref.invalidate(babyCurveViewModelProvider);
    ref.invalidate(babyStatisticsViewModelProvider);
    ref.invalidate(babyHomeViewModelProvider);
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

final babyGrowthViewModelProvider =
    AsyncNotifierProvider<BabyGrowthViewModel, List<BabyGrowth>>(
      BabyGrowthViewModel.new,
    );
