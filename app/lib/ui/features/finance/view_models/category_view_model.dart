import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/category.dart';
import '../../../../data/repositories/category_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';

/// §4.2.2 的类别字典。整棵树一次取回，两个收支类型共用，界面按 `Category.type` 取自己那一半。
///
/// 状态直接用仓库的 `CategoryTreeResult` 而不是剥成一个 List：`fromCache` 这个标记要一路留到
/// S5 的「数据截至 XX」横幅，现在剥掉了，S5 就得回来把这条链再挖一遍。
class CategoryViewModel extends AsyncNotifier<CategoryTreeResult> {
  @override
  Future<CategoryTreeResult> build() async {
    // 未登录不请求；退出登录时这条 watch 会自动把缓存清掉（同 family_view_model）
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const CategoryTreeResult([], fromCache: false);
    }
    return _repository.tree();
  }

  /// 记账时可选的类别：只留启用项，且大类一旦被停用，它整棵子树都不再可选。
  /// 后端不替我们滤（`enabledOnly` 会让缓存里只装得下一半字典，见仓库注释），所以滤在这里。
  List<Category> selectable(String type) => [
    for (final major in majors(type))
      if (major.enabled)
        major.copyWith(
          children: [
            for (final sub in major.children)
              if (sub.enabled) sub,
          ],
        ),
  ];

  /// 该收支类型下的全部大类（含停用的）。类别管理页要把停用项一并列出来。
  List<Category> majors(String type) => [
    for (final major in state.value?.categories ?? const <Category>[])
      if (major.type == type) major,
  ];

  /// 建大类时 `parentId` 留空。重名后端回 `CATEGORY_NAME_EXISTS`。
  Future<String?> create({
    required String type,
    int? parentId,
    required String name,
  }) => _write(
    () => _repository.create(type: type, parentId: parentId, name: name),
  );

  /// 改名不回溯历史流水——那些流水上存的是记账当时的名称快照（需求文档 A3）。
  Future<String?> rename(int id, String name) =>
      _write(() => _repository.rename(id, name));

  Future<String?> toggle(int id) => _write(() => _repository.toggle(id));

  /// 被后端拒绝的三种情况（预置项、有子类别、有流水）都直接展示后端文案，不在前端另写一份。
  Future<String?> remove(int id) => _write(() => _repository.remove(id));

  Future<String?> sort({
    required String type,
    int? parentId,
    required List<int> orderedIds,
  }) => _write(
    () => _repository.sort(
      type: type,
      parentId: parentId,
      orderedIds: orderedIds,
    ),
  );

  CategoryRepository get _repository => ref.read(categoryRepositoryProvider);

  /// 写成功后重拉整棵树：后端写接口回的是扁平的一条记录，拼不回界面上那棵树。
  /// 重拉顺带把本地缓存一起刷新，所以缓存不需要在这儿单独维护。
  Future<String?> _write(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      return errorCopy(e);
    }
    try {
      state = AsyncData(await _repository.tree());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return errorCopy(e);
    }
    return null;
  }
}

final categoryViewModelProvider =
    AsyncNotifierProvider<CategoryViewModel, CategoryTreeResult>(
      CategoryViewModel.new,
    );
