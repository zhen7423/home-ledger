import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/cat.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/auth_image.dart';
import '../../../core/category_palette.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../cat_copy.dart';
import '../view_models/cat_view_model.dart';

/// §4.3.1 的档案清单。**在册一格、已归档一格**，归档那格只在有内容时出现。
///
/// `ConsumerWidget` 而不是 `ConsumerStatefulWidget`：这一页没有任何本地状态，
/// 过滤、分组都直接从 `List<Cat>` 现算（`CatViewModel` 一次把两份都装进来）。
class CatListPage extends ConsumerWidget {
  const CatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(catViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('猫咪档案'),
        actions: [
          IconButton(
            tooltip: '建档',
            icon: const Icon(Icons.add),
            onPressed: () => context.push(RoutePath.catCatEdit),
          ),
        ],
      ),
      body: cats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorCopy(error), textAlign: TextAlign.center),
          ),
        ),
        data: (rows) =>
            rows.isEmpty ? const _EmptyCats() : _CatGroups(rows: rows),
      ),
    );
  }
}

class _CatGroups extends StatelessWidget {
  const _CatGroups({required this.rows});

  final List<Cat> rows;

  @override
  Widget build(BuildContext context) {
    final active = [
      for (final cat in rows)
        if (!cat.archived) cat,
    ];
    final archived = [
      for (final cat in rows)
        if (cat.archived) cat,
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // 在册一段，每行一张独立小卡（问题单：卡片间有间距）。
        for (var index = 0; index < active.length; index++)
          RowCard(
            child: _CatTile(cat: active[index], index: index),
          ),
        if (archived.isNotEmpty) ...[
          _GroupHeader('已归档 ${archived.length} 只', top: active.isEmpty),
          for (var offset = 0; offset < archived.length; offset++)
            RowCard(
              child: _CatTile(
                cat: archived[offset],
                // 头像色接在册那一段往后数，否则第一只归档猫与第一只在册猫同色
                index: active.length + offset,
              ),
            ),
        ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.title, {this.top = false});

  final String title;

  /// 「已归档」是第一段时上面不留空，列表顶上本来就有 AppBar 分隔。
  final bool top;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, top ? 12 : 24, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CatTile extends ConsumerWidget {
  const _CatTile({required this.cat, required this.index});

  final Cat cat;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(catViewModelProvider.notifier);

    return ListTile(
      onTap: () => context.push(RoutePath.catCatEditOf(cat.id)),
      leading: _avatar(context),
      title: Text(cat.name),
      subtitle: Text('${birthdayLabel(cat)} · ${catSummaryLine(cat)}'),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => switch (value) {
          'edit' => context.push(RoutePath.catCatEditOf(cat.id)),
          'archive' => _toggleArchive(context, notifier),
          _ => _delete(context, notifier),
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('编辑')),
          PopupMenuItem(
            value: 'archive',
            child: Text(cat.archived ? '恢复到册' : '归档'),
          ),
          const PopupMenuItem(value: 'delete', child: Text('删除')),
        ],
      ),
    );
  }

  /// 有照片显示照片（带登录态读取），没有才退回首字头色块。
  Widget _avatar(BuildContext context) {
    return CircleAvatar(
      backgroundColor: categoryTint(categoryColor(index)),
      child: cat.photoUrl == null
          ? Text(
              cat.name.characters.first,
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
                  photoUrl: cat.photoUrl,
                  placeholderIcon: Icons.pets_outlined,
                  // 40 逻辑 px × 2 高 DPI，列表里避免全分辨率解码
                  cacheWidth: 80,
                ),
              ),
            ),
    );
  }

  /// 归档是可逆的，不必多问一句；删除不可逆，要问。「归档 ≠ 删除」这条区分是
  /// §4.3.1 写死的，界面上也只有删除带确认框。
  Future<void> _toggleArchive(
    BuildContext context,
    CatViewModel notifier,
  ) async {
    final error = await notifier.toggleArchive(cat.id);
    if (error != null && context.mounted) showSnackBar(context, error);
  }

  Future<void> _delete(BuildContext context, CatViewModel notifier) async {
    final confirmed = await confirmAction(
      context,
      title: '删除「${cat.name}」？',
      message: '名下已有猫粮袋或驱虫记录时要先处理那些记录。删除后无法恢复。',
      confirmLabel: '删除',
    );
    if (!confirmed) return;
    // 删除成功后由 ViewModel 重拉整份清单并扇出刷新总览，这里不手动摘掉这一行。
    final error = await notifier.remove(cat.id);
    if (error != null && context.mounted) showSnackBar(context, error);
  }
}

class _EmptyCats extends StatelessWidget {
  const _EmptyCats();

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
              Icons.pets_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('还没有猫咪档案', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '先建一只猫，之后猫粮与驱虫记录都挂在它名下',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(RoutePath.catCatEdit),
              icon: const Icon(Icons.add),
              label: const Text('建档'),
            ),
          ],
        ),
      ),
    );
  }
}
