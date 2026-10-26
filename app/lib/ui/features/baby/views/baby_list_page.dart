import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/baby.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/auth_image.dart';
import '../../../core/category_palette.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../baby_copy.dart';
import '../view_models/baby_list_view_model.dart';

/// §4.4.1 的档案清单。**「显示已归档」是一个纯界面过滤**：`BabyListViewModel` 一次把在册与
/// 归档两份都装进来（编辑页要回填的那一行只能从这份列表里找，服务端没有单宝宝的详情端点），
/// 所以这个开关不动任何请求。
class BabyListPage extends ConsumerStatefulWidget {
  const BabyListPage({super.key});

  @override
  ConsumerState<BabyListPage> createState() => _BabyListPageState();
}

class _BabyListPageState extends ConsumerState<BabyListPage> {
  /// 默认关：归档是把宝宝从记录表单里摘掉，绝大多数时候用户要看的是在册那份。
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final babies = ref.watch(babyListViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('宝宝档案'),
        actions: [
          IconButton(
            tooltip: '建档',
            icon: const Icon(Icons.add),
            onPressed: () => context.push(RoutePath.babyEdit),
          ),
        ],
      ),
      body: babies.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorCopy(error), textAlign: TextAlign.center),
          ),
        ),
        data: (rows) => rows.isEmpty
            ? const _EmptyBabies()
            : Column(
                children: [
                  SwitchListTile(
                    title: const Text('显示已归档'),
                    subtitle: const Text('归档的宝宝仍在历史记录里，只是不再出现在记录表单中'),
                    value: _showArchived,
                    onChanged: (value) => setState(() => _showArchived = value),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _BabyTiles(rows: rows, showArchived: _showArchived),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BabyTiles extends StatelessWidget {
  const _BabyTiles({required this.rows, required this.showArchived});

  final List<Baby> rows;
  final bool showArchived;

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final baby in rows)
        if (showArchived || !baby.archived) baby,
    ];

    // 在册一个都没有、又没打开归档视图时，空的是这一屏而不是这份档案：
    // 那句提示要说清「还有归档的宝宝」，否则用户会以为档案丢了。
    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            rows.isEmpty ? '还没有宝宝档案' : '在册的宝宝一个都没有，打开上面的开关看已归档的',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 档案每行一张独立小卡（问题单：卡片间有间距）。
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final baby in visible)
          RowCard(
            child: _BabyTile(baby: baby, index: visible.indexOf(baby)),
          ),
      ],
    );
  }
}

class _BabyTile extends ConsumerWidget {
  const _BabyTile({required this.baby, required this.index});

  final Baby baby;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(babyListViewModelProvider.notifier);

    return ListTile(
      onTap: () => context.push(RoutePath.babyEditOf(baby.id)),
      leading: CircleAvatar(
        backgroundColor: categoryTint(categoryColor(index)),
        child: baby.photoUrl == null
            ? Text(
                baby.name.characters.first,
                style: TextStyle(
                  color: categoryColor(index),
                  fontWeight: FontWeight.w600,
                ),
              )
            : ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: AuthImage(
                    photoUrl: baby.photoUrl,
                    placeholderIcon: Icons.child_care_outlined,
                    // 40 逻辑 px × 2 高 DPI，列表里避免全分辨率解码
                    cacheWidth: 80,
                  ),
                ),
              ),
      ),
      title: Text(baby.name),
      subtitle: Text(
        '${genderLabels[baby.gender] ?? baby.gender} · '
        '${formatDate(baby.birthDate)} · ${baby.ageText}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (baby.archived) const _ArchivedBadge(),
          PopupMenuButton<String>(
            onSelected: (value) => switch (value) {
              'toggle' => _toggleArchive(context, notifier),
              _ => _delete(context, notifier),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                // 后端那条端点是双向开关、按当前状态判方向，仓库那层没有 `bool` 参数，
                // 所以这里必须自己按 `archived` 出文案。
                child: Text(baby.archived ? '恢复到册' : '归档'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleArchive(
    BuildContext context,
    BabyListViewModel notifier,
  ) async {
    final confirmed = await confirmAction(
      context,
      title: baby.archived ? '把「${baby.name}」恢复到册？' : '归档「${baby.name}」？',
      message: baby.archived
          ? '恢复后重新出现在记录表单的宝宝选择器里。'
          : '归档后不再出现在记录表单的宝宝选择器里，历史记录照旧保留，随时可以恢复。',
      confirmLabel: baby.archived ? '恢复' : '归档',
    );
    if (!confirmed || !context.mounted) return;

    final error = await notifier.toggle(baby.id);
    if (error != null && context.mounted) showSnackBar(context, error);
  }

  Future<void> _delete(BuildContext context, BabyListViewModel notifier) async {
    final confirmed = await confirmAction(
      context,
      title: '删除「${baby.name}」？',
      message: '名下已有身高体重、疫苗或就诊记录时删不掉，只能归档。删除后无法恢复。',
      confirmLabel: '删除',
    );
    if (!confirmed || !context.mounted) return;

    // 删除成功后由 ViewModel 重拉整份清单并扇出刷新总览与统计，这里不手动摘掉这一行。
    final error = await notifier.remove(baby.id);
    if (error != null && context.mounted) showSnackBar(context, error);
  }
}

class _ArchivedBadge extends StatelessWidget {
  const _ArchivedBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.outline.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '已归档',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }
}

class _EmptyBabies extends StatelessWidget {
  const _EmptyBabies();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.child_care_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('还没有宝宝档案', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '先建一个宝宝，身高体重、疫苗与就诊记录都挂在它名下',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(RoutePath.babyEdit),
              icon: const Icon(Icons.add),
              label: const Text('建档'),
            ),
          ],
        ),
      ),
    );
  }
}
