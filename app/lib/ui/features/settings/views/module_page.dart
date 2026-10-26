import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/module_preference.dart';
import '../../../core/error_copy.dart';
import '../view_models/module_preference_view_model.dart';

/// §4.7 的「模块与 Tab」：三个模块的开关 + 已启用模块的 Tab 顺序。
///
/// 列表里三项都在（含关掉的那一项），拖拽改的是整份三项的顺序，底栏只画启用的那些。
/// 做成「只列启用项」的话，关掉一个再打开，它的位置会掉到末尾——用户没动过它，
/// 顺序却变了，而顺序正是他上次亲手排好的。
class ModulePage extends ConsumerWidget {
  const ModulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final prefs = ref.watch(modulePreferenceViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('模块与 Tab')),
      body: prefs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorCopy(error), textAlign: TextAlign.center),
          ),
        ),
        data: (rows) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                '关掉的模块不会出现在底部栏，首页也不再显示它的内容。'
                '数据都还在服务端，重新打开就回来。顺序决定它们在底部栏里谁在前。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: rows.length,
                // 先让服务端落定新顺序，再由 VM 重拉回来渲染（同类别管理页）：写失败时本地顺序
                // 会变成一份服务端没认过的假账
                onReorderItem: (oldIndex, newIndex) =>
                    _move(context, ref, oldIndex, newIndex),
                itemBuilder: (context, index) => _ModuleTile(
                  key: ValueKey(rows[index].moduleKey),
                  module: rows[index],
                  index: index,
                  onChanged: (enabled) => _setEnabled(
                    context,
                    ref,
                    rows[index].moduleKey,
                    enabled,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// `onReorderItem` 交来的 newIndex 已经算上了被抽走那一项，不用再自己校正。
  Future<void> _move(
    BuildContext context,
    WidgetRef ref,
    int oldIndex,
    int newIndex,
  ) async {
    final error = await ref
        .read(modulePreferenceViewModelProvider.notifier)
        .move(oldIndex, newIndex);
    if (error != null && context.mounted) showSnackBar(context, error);
  }

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    String moduleKey,
    bool enabled,
  ) async {
    final error = await ref
        .read(modulePreferenceViewModelProvider.notifier)
        .setEnabled(moduleKey, enabled);
    if (error != null && context.mounted) showSnackBar(context, error);
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.index,
    required this.onChanged,
    super.key,
  });

  final ModulePreference module;

  final int index;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle),
      ),
      title: Text(module.label),
      subtitle: Text(module.enabled ? '显示在底部栏' : '已关闭'),
      trailing: Switch(value: module.enabled, onChanged: onChanged),
    );
  }
}
