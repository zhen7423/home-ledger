import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/module_preference.dart';
import '../services/api_client.dart';

/// §3.2 的模块开关与 Tab 顺序。用户级偏好，服务端按登录用户存。
///
/// 不做本地缓存：它决定底栏长什么样，缓存一份旧的会出现「设置页说关了、底栏还挂着」这种
/// 自己跟自己不一致的画面，而这份数据一次请求就有了。
class ModulePreferenceRepository {
  ModulePreferenceRepository({required this._api});

  final ApiClient _api;

  /// 恒返回三个模块，顺序由服务端按 `sortNo` 给全。
  Future<List<ModulePreference>> modules() async {
    final rows = await _api.getList('/preferences/modules');
    return rows.map(ModulePreference.fromJson).toList();
  }

  /// 数组顺序即 Tab 顺序，`sortNo` 由服务端派生。未提交的模块沿用服务端已存的值。
  Future<void> saveModules(List<ModulePreferenceItem> items) => _api.put(
    '/preferences/modules',
    body: {'items': items.map((item) => item.toJson()).toList()},
  );
}

/// 一次提交里的一项。只带 key 与开关：标签与序号都是服务端的事。
class ModulePreferenceItem {
  const ModulePreferenceItem({required this.moduleKey, required this.enabled});

  final String moduleKey;

  final bool enabled;

  Map<String, Object?> toJson() => {'moduleKey': moduleKey, 'enabled': enabled};
}

final modulePreferenceRepositoryProvider = Provider<ModulePreferenceRepository>(
  (ref) => ModulePreferenceRepository(api: ref.watch(apiClientProvider)),
);
