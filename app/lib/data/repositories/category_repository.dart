import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/dict_cache_store.dart';

/// 类别树 + 它是从网络拿的还是从缓存兜的。
///
/// `fromCache` 在 S3 只回传、界面不展示，S5 的「数据截至 XX」横幅直接接这个标记（§6.4）。
class CategoryTreeResult {
  const CategoryTreeResult(this.categories, {required this.fromCache});

  final List<Category> categories;
  final bool fromCache;
}

/// §4.2.2 的类别管理：读一棵树，外加增、改名、停用/启用、删除、排序。
///
/// 写操作一律不回对象、由调用方重拉整棵树：后端写操作回的是扁平的 CategoryResponse，
/// 而界面上是一棵两层的树，拿一条记录去猜整棵树（父下少了一个子、兄弟序全变了）不如重问一次。
/// 重拉顺带把本地缓存刷新了，所以这里不单独维护缓存一致性。
class CategoryRepository {
  CategoryRepository({required this._api, required this._cache});

  final ApiClient _api;
  final DictCacheStore _cache;

  /// 收支两类一次取回，调用方按 `Category.type` 自己分。
  ///
  /// 不向后端要 `enabledOnly`，也不按类型分开缓存：本地只有一份 `dict-categories.json`，
  /// 它装的是「最近一次成功取回的全量」。一会儿存全量、一会儿只存启用项，离线兜底时就会拿到
  /// 一棵看不全的树；而停用的类别本就要在类别管理页里显示出来，滤不滤得掉交给界面。
  Future<CategoryTreeResult> tree() async {
    try {
      final rows = await _api.getList('/categories');
      final categories = rows.map(Category.fromJson).toList();
      await _cache.writeCategories(categories);
      return CategoryTreeResult(categories, fromCache: false);
    } on ApiException catch (e) {
      // 只有传输层失败才回落。业务错误（401、403、404）回落缓存会把真实故障藏起来：
      // 用户拿一份旧字典去选一个已经被删掉的类别。
      if (!e.isTransportFailure) rethrow;
      final cached = await _cache.readCategories();
      // 缓存是空的就没有东西可兜，照原样抛：返回空列表会把「后端挂了」演成「你还没有类别」。
      if (cached.isEmpty) rethrow;
      return CategoryTreeResult(cached, fromCache: true);
    }
  }

  /// `parentId` 为空即建大类。大类名 ≤ 6 字、小类 ≤ 8 字，后端也会拦一遍。
  Future<void> create({
    required String type,
    int? parentId,
    required String name,
  }) => _api.post(
    '/categories',
    body: {'type': type, 'parentId': parentId, 'name': name},
  );

  /// 改名不回溯历史流水：那条流水上存的是记账当时的类别名快照（需求文档 A3）。
  Future<void> rename(int id, String name) =>
      _api.patch('/categories/$id', body: {'name': name});

  /// 有流水的类别只能停用不能删，停用后不影响历史，只是新建流水时选不到它。
  Future<void> toggle(int id) => _api.patch('/categories/$id/toggle');

  /// 后端在这里挡三种情况：预置类别不可删（PRESET_IMMUTABLE）、有子类别不可删、有流水不可删。
  /// 「有没有流水」的判定含已软删的流水，所以这条限制不会因为删了几笔就松动。
  Future<void> remove(int id) => _api.delete('/categories/$id');

  /// 整层一起提交：同一大类下的小类按 `orderedIds` 重排，`sortNo` 由后端按序重写。
  Future<void> sort({
    required String type,
    int? parentId,
    required List<int> orderedIds,
  }) => _api.put(
    '/categories/sort',
    body: {'type': type, 'parentId': parentId, 'orderedIds': orderedIds},
  );
}

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(
    api: ref.watch(apiClientProvider),
    cache: ref.watch(dictCacheStoreProvider),
  ),
);
