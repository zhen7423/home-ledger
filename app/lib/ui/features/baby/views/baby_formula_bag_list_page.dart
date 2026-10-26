import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/baby_formula_bag.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../baby_copy.dart';
import '../view_models/baby_formula_view_model.dart';

/// §4.5.3 的奶粉开罐时间线。一罐一行，最早那罐在上方。
///
/// 顺序**不在客户端动**：服务端按 `startedDate` 升序回，而「这一罐用到哪天」的答案是
/// **下一行的开罐日期**，`reversed` 一下邻接关系就断了。
///
/// 这一页不放余量。同一份推算在宝宝主页那张卡上已经是「还能喝 9 天」，这里再放一遍会多出两个
/// 日均、两个耗尽日，而它们只有主页那条链路会同步刷新。
class BabyFormulaBagListPage extends ConsumerWidget {
  const BabyFormulaBagListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bags = ref.watch(babyFormulaViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('奶粉'),
        actions: [
          IconButton(
            tooltip: '记一罐',
            icon: const Icon(Icons.add),
            onPressed: () => context.push(RoutePath.babyFormulaEdit),
          ),
        ],
      ),
      body: bags.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorCopy(error), textAlign: TextAlign.center),
          ),
        ),
        data: (rows) => rows.isEmpty
            ? _EmptyBags(onCreate: () => context.push(RoutePath.babyFormulaEdit))
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  for (var i = 0; i < rows.length; i++)
                    RowCard(
                      child: _BagTile(
                        bag: rows[i],
                        nextStartedDate: i + 1 < rows.length
                            ? rows[i + 1].startedDate
                            : null,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _BagTile extends ConsumerWidget {
  const _BagTile({required this.bag, required this.nextStartedDate});

  final BabyFormulaBag bag;

  /// 下一罐的开罐日。null = 这是时间线上最后一罐，也就是在用的那一罐。
  final DateTime? nextStartedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final next = nextStartedDate;

    return ListTile(
      onTap: () => context.push(RoutePath.babyFormulaEditOf(bag.id)),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.water_drop_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(bag.brand, overflow: TextOverflow.ellipsis),
          ),
          if (bag.current) ...[
            const SizedBox(width: 8),
            const _CurrentTag(),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatDateWithTime(bag.startedDate, bag.startedTime)} 开罐 · '
            '${next == null ? '喝到现在' : '喝到 ${formatDate(next)}'}',
          ),
          Text(formulaBagSummaryLine(bag)),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => switch (value) {
          'edit' => context.push(RoutePath.babyFormulaEditOf(bag.id)),
          _ => _delete(context, ref),
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('编辑')),
          const PopupMenuItem(value: 'delete', child: Text('删除')),
        ],
      ),
    );
  }

  /// 删一罐不是「把那一行摘掉」：§4.5.3 的推导链上，它后面每一罐的结束日都要跟着左移。
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: '删除「${bag.brand}」这一罐？',
      message: '后面每一罐的结束日期与使用天数都会重新推算，奶粉卡与统计也会跟着变。删除后无法恢复。',
      confirmLabel: '删除',
    );
    if (!confirmed) return;
    final error = await ref
        .read(babyFormulaViewModelProvider.notifier)
        .remove(bag.id);
    if (error != null && context.mounted) showSnackBar(context, error);
  }
}

/// 「在用」那一格。主页的奶粉卡整张卡就是在用那罐，这一枚只有列表页要，留成私有。
class _CurrentTag extends StatelessWidget {
  const _CurrentTag();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '在用',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _EmptyBags extends StatelessWidget {
  const _EmptyBags({required this.onCreate});

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
              Icons.water_drop_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('还没有奶粉记录', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '开一罐记一次：填品牌与包装克数，什么时候喝完由下一罐的开罐日推出来',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('记一罐'),
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}