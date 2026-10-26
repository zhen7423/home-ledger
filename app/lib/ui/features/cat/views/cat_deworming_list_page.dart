import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/cat_deworming.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../cat_badges.dart';
import '../cat_copy.dart';
import '../view_models/cat_deworming_view_model.dart';

/// §4.3.3 的驱虫记录。同一个页面服务两种进入方式：
/// 总览页「驱虫记录」入口进全量，到期倒计时某一行进来看一只猫的历史。
///
/// 过滤是**本地** `where`（照周期规则列表那页），`catId` 从 URL 来、
/// 页面里没有改它的第二条路径——视图模型整体不自动释放，过滤状态也就不会被半路丢掉，这条理由在这里同样成立。
class CatDewormingListPage extends ConsumerWidget {
  const CatDewormingListPage({this.catId, super.key});

  /// null = 全部。由路由从 `?catId=` 解出来。
  final int? catId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(catDewormingViewModelProvider);
    // 过滤在 `when` 之前算：AppBar 的筛选条要读猫名，而 `when` 只喂 body 那一块。
    // AsyncLoading 时 `.value` 是 null，芯片退成「只看一只猫」，数据到了自然重建——
    // 比再 watch 一份 `catViewModelProvider` 少挂一个数据源（那一屏的猫可能还没加载）。
    final rows = [
      for (final row in records.value ?? const <CatDeworming>[])
        if (catId == null || row.catId == catId) row,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('驱虫记录'),
        actions: [
          IconButton(
            tooltip: '记一次',
            icon: const Icon(Icons.add),
            onPressed: () =>
                context.push(RoutePath.catDewormingNew(catId: catId)),
          ),
        ],
        bottom: catId == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InputChip(
                      avatar: const Icon(Icons.pets_outlined, size: 18),
                      label: Text(
                        rows.isEmpty ? '只看一只猫' : '只看 ${rows.first.catName}',
                      ),
                      onDeleted: () => context.pushReplacement(
                        RoutePath.catDewormings,
                      ),
                      onPressed: () => context.pushReplacement(
                        RoutePath.catDewormings,
                      ),
                    ),
                  ),
                ),
              ),
      ),
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorCopy(error), textAlign: TextAlign.center),
          ),
        ),
        data: (_) =>
            rows.isEmpty
                ? _EmptyDewormings(
                  filtered: catId != null,
                  onShowAll: () =>
                      context.pushReplacement(RoutePath.catDewormings),
                  onCreate: () =>
                      context.push(RoutePath.catDewormingNew(catId: catId)),
                )
                : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    // 记录每行一张独立小卡（问题单：卡片间有间距）。
                    for (final row in rows)
                      RowCard(child: _DewormingTile(row: row)),
                  ],
                ),
      ),
    );
  }
}

class _DewormingTile extends ConsumerWidget {
  const _DewormingTile({required this.row});

  final CatDeworming row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overdueDays = row.overdueDays;
    final dosage = row.dosage;

    return ListTile(
      onTap: () => context.push(RoutePath.catDewormingEditOf(row.id)),
      leading: CatTypeBadge(type: row.type),
      title: Text(row.catName),
      subtitle: Text(
        '${formatDate(row.doneDate)} 驱 · ${row.medicine}'
        '${dosage == null ? '' : ' · $dosage'}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dueLabel(daysToDue: row.daysToDue, overdueDays: overdueDays),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: overdueDays != null ? theme.colorScheme.error : null,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => switch (value) {
              'edit' => context.push(RoutePath.catDewormingEditOf(row.id)),
              _ => _delete(context, ref),
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('编辑')),
                  const PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: '删除这条驱虫记录？',
      message: '删掉之后倒计时会退回上一条记录算出的下次日期。删除后无法恢复。',
      confirmLabel: '删除',
    );
    if (!confirmed) return;
    final error = await ref
        .read(catDewormingViewModelProvider.notifier)
        .remove(row.id);
    if (error != null && context.mounted) showSnackBar(context, error);
  }
}

class _EmptyDewormings extends StatelessWidget {
  const _EmptyDewormings({
    required this.filtered,
    required this.onShowAll,
    required this.onCreate,
  });

  /// 「这只猫还没记过」与「全家一条都没有」是两件事：前者该把筛选清掉，后者才该引导记第一条。
  final bool filtered;
  final VoidCallback onShowAll;
  final VoidCallback onCreate;

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
              filtered ? Icons.filter_alt_off_outlined : Icons.pets_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              filtered ? '这只猫还没有驱虫记录' : '还没有驱虫记录',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '内驱外驱各记一次，之后按设置里的周期自动倒计时',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (filtered)
              OutlinedButton(
                onPressed: onShowAll,
                child: const Text('看全部'),
              )
            else
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('记一次'),
                onPressed: onCreate,
              ),
          ],
        ),
      ),
    );
  }
}
