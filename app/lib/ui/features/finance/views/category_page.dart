import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/category.dart';
import '../../../../data/models/flow_type.dart';
import '../../../../data/services/network_status.dart';
import '../../../core/category_icons.dart';
import '../../../core/category_palette.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../../../core/validators.dart';
import '../view_models/category_view_model.dart';

/// §4.2.2 类别管理。支出与收入是两棵各自独立的树，顶部一段切换分开管。
///
/// 小类的增删改放在点进大类后的底部面板里，不在这棵列表上就地展开：
/// `ReorderableListView` 不能套 `ReorderableListView`，两级都要能拖拽排序，
/// 就只能各占一个滚动区。
class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({super.key});

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  String _type = FlowType.expense;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('类别管理'),
        actions: [
          IconButton(
            tooltip: '新建大类',
            icon: const Icon(Icons.add),
            onPressed: _createMajor,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: FlowType.expense, label: Text('支出')),
                  ButtonSegment(value: FlowType.income, label: Text('收入')),
                ],
                selected: {_type},
                showSelectedIcon: false,
                // 「暖居」§6.6：分类切换全宽等分
                expandedInsets: EdgeInsets.zero,
                onSelectionChanged: (selection) =>
                    setState(() => _type = selection.first),
              ),
            ),
          ),
        ),
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorCopy(error), textAlign: TextAlign.center),
          ),
        ),
        data: (result) => _buildMajors(context, result.categories),
      ),
    );
  }

  Widget _buildMajors(BuildContext context, List<Category> tree) {
    final majors = [
      for (final major in tree)
        if (major.type == _type) major,
    ];

    if (majors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_typeLabel 还没有大类',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text('预置类别被全部停用的话，在这里新建一个'),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('新建大类'),
              onPressed: _createMajor,
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: majors.length,
      // 先让后端把新顺序落定，再由 VM 重拉回来的那棵树渲染。这里不本地改序：
      // 一旦写失败，本地顺序就成了服务端没认过的假账。
      onReorderItem: (oldIndex, newIndex) =>
          _sortMajors(majors, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final major = majors[index];
        return _CategoryTile(
          key: ValueKey(major.id),
          category: major,
          index: index,
          isMajor: true,
          trailingActions: [
            IconButton(
              tooltip: '管理小类',
              icon: const Icon(Icons.unfold_more),
              onPressed: () => _openSubs(major),
            ),
          ],
          onRename: () => _rename(major),
          onToggle: () => _toggle(major),
          onDelete: () => _delete(major),
        );
      },
    );
  }

  String get _typeLabel => _type == FlowType.expense ? '支出' : '收入';

  /// `onReorderItem` 交来的 newIndex 已经算上了被抽走那一项，不用再自己校正。
  Future<void> _sortMajors(List<Category> majors, int oldIndex, int newIndex) {
    final ordered = majors.toList();
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);
    return _run(
      () => ref
          .read(categoryViewModelProvider.notifier)
          .sort(
            type: _type,
            parentId: null,
            orderedIds: [for (final major in ordered) major.id],
          ),
    );
  }

  Future<void> _createMajor() => _run(() async {
    final name = await promptForText(
      context,
      title: '新建$_typeLabel大类',
      label: '名称（最多 6 个字）',
      validator: validateMajorCategoryName,
      confirmDisabledHint: ref.read(canSubmitProvider)
          ? null
          : offlineSubmitHint,
    );
    return name == null
        ? null
        : ref
              .read(categoryViewModelProvider.notifier)
              .create(type: _type, name: name);
  });

  /// 只有大类走这里；小类的改名在底部面板里，文案与上限都不一样。
  Future<void> _rename(Category category) => _run(() async {
    final name = await promptForText(
      context,
      title: '改名',
      label: '大类名称（最多 6 个字）',
      initialValue: category.name,
      validator: validateMajorCategoryName,
      confirmDisabledHint: ref.read(canSubmitProvider)
          ? null
          : offlineSubmitHint,
    );
    return name == null
        ? null
        : ref
              .read(categoryViewModelProvider.notifier)
              .rename(category.id, name);
  });

  Future<void> _toggle(Category category) => _run(
    () => ref.read(categoryViewModelProvider.notifier).toggle(category.id),
  );

  /// 被拒的几种情况（预置项、下面还有小类、下面有流水）后端都给了现成文案，
  /// 这里原样弹出来，不在前端另抄一份。
  Future<void> _delete(Category category) => _run(() async {
    final confirmed = await confirmAction(
      context,
      title: '删除「${category.name}」？',
      message: '删除后它不再出现在记账选项里。已有流水的类别不能删除，只能停用。',
      confirmLabel: '删除',
    );
    return confirmed
        ? ref.read(categoryViewModelProvider.notifier).remove(category.id)
        : null;
  });

  Future<void> _run(Future<String?> Function() action) async {
    final error = await action();
    if (error != null && mounted) showSnackBar(context, error);
  }

  Future<void> _openSubs(Category major) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SubCategorySheet(majorId: major.id),
  );
}

/// 一个大类下面的小类管理：列表、新建、改名、停用、删除、拖拽排序。
///
/// 面板只记住大类的 id，内容每次从字典现取。改名或新建之后 VM 会重拉整棵树，
/// 抓住旧 `Category` 不放的话，这里显示的就永远是打开面板那一刻的名字。
class _SubCategorySheet extends ConsumerStatefulWidget {
  const _SubCategorySheet({required this.majorId});

  final int majorId;

  @override
  ConsumerState<_SubCategorySheet> createState() => _SubCategorySheetState();
}

class _SubCategorySheetState extends ConsumerState<_SubCategorySheet> {
  @override
  Widget build(BuildContext context) {
    final tree =
        ref.watch(categoryViewModelProvider).value?.categories ??
        const <Category>[];
    final major = _byId(tree, widget.majorId);
    if (major == null) {
      // 面板开着的时候大类被另一台设备删了，没内容可显示，收掉
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    final subs = major.children;

    return SafeArea(
      child: SizedBox(
        height: 460,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${major.name} 的小类',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新建小类'),
                    onPressed: () => _createSub(major),
                  ),
                ],
              ),
            ),
            if (subs.isEmpty)
              const Expanded(child: Center(child: Text('还没有小类，记账时可以只选到大类')))
            else
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: subs.length,
                  onReorderItem: (oldIndex, newIndex) =>
                      _sortSubs(major, subs, oldIndex, newIndex),
                  itemBuilder: (context, index) => _CategoryTile(
                    key: ValueKey(subs[index].id),
                    category: subs[index],
                    index: index,
                    isMajor: false,
                    onRename: () => _rename(subs[index]),
                    onToggle: () => _toggle(subs[index]),
                    onDelete: () => _delete(subs[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sortSubs(
    Category major,
    List<Category> subs,
    int oldIndex,
    int newIndex,
  ) {
    final ordered = subs.toList();
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);
    return _run(
      () => ref
          .read(categoryViewModelProvider.notifier)
          .sort(
            type: major.type,
            parentId: major.id,
            orderedIds: [for (final sub in ordered) sub.id],
          ),
    );
  }

  Future<void> _createSub(Category major) => _run(() async {
    final name = await promptForText(
      context,
      title: '在「${major.name}」下新建小类',
      label: '名称（最多 8 个字）',
      validator: validateSubCategoryName,
      confirmDisabledHint: ref.read(canSubmitProvider)
          ? null
          : offlineSubmitHint,
    );
    return name == null
        ? null
        : ref
              .read(categoryViewModelProvider.notifier)
              .create(type: major.type, parentId: major.id, name: name);
  });

  Future<void> _rename(Category category) => _run(() async {
    final name = await promptForText(
      context,
      title: '改名',
      label: '小类名称（最多 8 个字）',
      initialValue: category.name,
      validator: validateSubCategoryName,
      confirmDisabledHint: ref.read(canSubmitProvider)
          ? null
          : offlineSubmitHint,
    );
    return name == null
        ? null
        : ref
              .read(categoryViewModelProvider.notifier)
              .rename(category.id, name);
  });

  Future<void> _toggle(Category category) => _run(
    () => ref.read(categoryViewModelProvider.notifier).toggle(category.id),
  );

  Future<void> _delete(Category category) => _run(() async {
    final confirmed = await confirmAction(
      context,
      title: '删除「${category.name}」？',
      message: '删除后它不再出现在记账选项里。若下面已有流水，需要先处理那些记录。',
      confirmLabel: '删除',
    );
    return confirmed
        ? ref.read(categoryViewModelProvider.notifier).remove(category.id)
        : null;
  });

  Future<void> _run(Future<String?> Function() action) async {
    final error = await action();
    if (error != null && mounted) showSnackBar(context, error);
  }
}

/// 大类与小类共用一行的样子，差别只在有没有图标色块与小类计数。
/// 谁是层级 1 谁在层级 2 由调用方给（`isMajor`）：模型里没有这个字段，
/// 后端回的树只有「最外层」与「children 里」两种位置。
class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({
    super.key,
    required this.category,
    required this.index,
    required this.isMajor,
    required this.onRename,
    required this.onToggle,
    required this.onDelete,
    this.trailingActions = const [],
  });

  final Category category;
  final int index;
  final bool isMajor;
  final VoidCallback onRename;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final List<Widget> trailingActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = categoryColor(category.colorIndex ?? 0);

    return ListTile(
      leading: ReorderableDragStartListener(
        index: index,
        child: isMajor
            ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryTint(color),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  categoryIcon(category.iconKey ?? ''),
                  color: color,
                  size: 22,
                ),
              )
            : const Icon(Icons.drag_handle),
      ),
      title: Row(
        children: [
          Flexible(child: Text(category.name, overflow: TextOverflow.ellipsis)),
          if (category.preset)
            const Padding(padding: EdgeInsets.only(left: 6), child: _Tag('预置')),
          if (!category.enabled)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: _Tag('已停用'),
            ),
        ],
      ),
      subtitle: isMajor
          ? Text(
              category.children.isEmpty
                  ? '没有小类'
                  : '${category.children.length} 个小类',
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...trailingActions,
          Switch(value: category.enabled, onChanged: (_) => onToggle()),
          PopupMenuButton<String>(
            onSelected: (value) => switch (value) {
              'rename' => onRename(),
              'toggle' => onToggle(),
              _ => onDelete(),
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'rename', child: Text('改名')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(category.enabled ? '停用' : '启用'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

Category? _byId(List<Category> majors, int id) {
  for (final major in majors) {
    if (major.id == id) return major;
  }
  return null;
}
