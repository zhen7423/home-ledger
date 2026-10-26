import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/module_preference.dart';
import '../../../../data/repositories/module_preference_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';

/// 服务端三项目默认全开、顺序记账 → 猫咪 → 宝宝（§3.2）。客户端这一份只在「还没读到偏好」时用：
/// 底栏要是先只画「首页 + 设置」再突然长出三个 Tab，用户会以为设置被重置了。
const List<ModulePreference> defaultModulePreferences = [
  ModulePreference(
    moduleKey: 'FINANCE',
    label: '记账',
    enabled: true,
    sortNo: 0,
  ),
  ModulePreference(moduleKey: 'CAT', label: '猫咪', enabled: true, sortNo: 1),
  ModulePreference(moduleKey: 'BABY', label: '宝宝', enabled: true, sortNo: 2),
];

/// §3.2 的模块开关与 Tab 顺序。
///
/// 与类别 / 支付方式那两个排序页同一套做法：本地不改序，写完由服务端回来那一份渲染。
/// 顺序是「Tab 长什么样」的一部分，本地先改再回滚会让底栏闪一下再弹回去。
class ModulePreferenceViewModel extends AsyncNotifier<List<ModulePreference>> {
  @override
  Future<List<ModulePreference>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return defaultModulePreferences;
    }
    return _repository.modules();
  }

  /// 切一个模块的开关。交上去的是整份三项：服务端按数组顺序定 Tab 顺序，
  /// 只交被点的那一项会把它的位置挤到最前（未提交的接在后面），Tab 顺序就莫名其妙地变了。
  Future<String?> setEnabled(String moduleKey, bool enabled) => _write(
    () => _repository.saveModules([
      for (final row in _current)
        ModulePreferenceItem(
          moduleKey: row.moduleKey,
          enabled: row.moduleKey == moduleKey ? enabled : row.enabled,
        ),
    ]),
  );

  /// 拖拽排序。`newIndex` 已经算上了被抽走那一项，不用再自己校正（同支付方式管理页）。
  Future<String?> move(int oldIndex, int newIndex) => _write(() {
    final ordered = _current.toList();
    ordered.insert(newIndex, ordered.removeAt(oldIndex));
    return _repository.saveModules([
      for (final row in ordered)
        ModulePreferenceItem(moduleKey: row.moduleKey, enabled: row.enabled),
    ]);
  });

  List<ModulePreference> get _current =>
      state.value ?? defaultModulePreferences;

  ModulePreferenceRepository get _repository =>
      ref.read(modulePreferenceRepositoryProvider);

  Future<String?> _write(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      return errorCopy(e);
    }
    try {
      state = AsyncData(await _repository.modules());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return errorCopy(e);
    }
    return null;
  }
}

final modulePreferenceViewModelProvider =
    AsyncNotifierProvider<ModulePreferenceViewModel, List<ModulePreference>>(
      ModulePreferenceViewModel.new,
    );

/// 已启用的模块，顺序即 Tab 顺序。底栏、首页的快捷区与最近动态的可见性都读它。
///
/// 读不到偏好（加载中、离线、未登录）时回落到 [defaultModulePreferences] 里已启用的那几项：
/// 底栏与首页宁可先按默认值画，也不要空一截再补上。
final enabledModulesProvider = Provider<List<ModulePreference>>((ref) {
  final rows =
      ref.watch(modulePreferenceViewModelProvider).value ??
      defaultModulePreferences;
  return [
    for (final row in rows)
      if (row.enabled) row,
  ];
});

/// 某个模块此刻开没开。首页各区块与快捷区按它决定显不显示（§4.6）。
final moduleEnabledProvider = Provider.family<bool, String>(
  (ref, moduleKey) =>
      ref.watch(enabledModulesProvider).any((row) => row.moduleKey == moduleKey),
);
