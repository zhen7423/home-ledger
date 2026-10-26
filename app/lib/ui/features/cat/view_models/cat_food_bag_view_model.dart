import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/cat_food_bag.dart';
import '../../../../data/repositories/cat_food_bag_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';
import 'cat_overview_view_model.dart';
import 'cat_statistics_view_model.dart';

/// §4.3.2 的猫粮袋清单。**该端点没有归档概念**（§4.3.2 的袋只有「在不在时间线上」），
/// 也没有详情端点，所以编辑一袋同样从这份列表里按 id 找。
class CatFoodBagViewModel extends AsyncNotifier<List<CatFoodBag>> {
  @override
  Future<List<CatFoodBag>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    return _repository.list();
  }

  /// 编辑一袋时按 id 取那一行，取法就是上面那份列表。
  /// 与 `CatViewModel.byId` 同一个道理、同一句「找不到回 null」的约定。
  CatFoodBag? byId(int id) {
    for (final bag in state.value ?? const <CatFoodBag>[]) {
      if (bag.id == id) {
        return bag;
      }
    }
    return null;
  }

  Future<String?> create(CatFoodBagDraft draft) async {
    final error = await _write(() => _repository.create(draft));
    if (error == null) _fanOut();
    return error;
  }

  Future<String?> save(int id, CatFoodBagDraft draft) async {
    final error = await _write(() => _repository.update(id, draft));
    if (error == null) _fanOut();
    return error;
  }

  /// 删掉一袋会让**后面每一袋**的结束日与使用天数整体左移（§4.3.2 的推导链），
  /// 所以这里绝不做「本地把那一行摘掉」的增量删除——症状是余量卡还按旧时间线算。
  Future<String?> remove(int id) async {
    final error = await _write(() => _repository.remove(id));
    if (error == null) _fanOut();
    return error;
  }

  CatFoodBagRepository get _repository => ref.read(catFoodBagRepositoryProvider);

  /// 开袋 / 改袋 / 删袋改的是余量卡的**全部**数字（日均、剩余、可食天数、耗尽日），
  /// 以及统计页的分摊与每袋用时。没有 `toggleArchive`：在用状态由 `startedDate` 推导，不可手工设。
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

final catFoodBagViewModelProvider =
    AsyncNotifierProvider<CatFoodBagViewModel, List<CatFoodBag>>(
      CatFoodBagViewModel.new,
    );
