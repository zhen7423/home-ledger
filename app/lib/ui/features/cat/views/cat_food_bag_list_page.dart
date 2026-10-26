import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/cat_food_bag.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../cat_copy.dart';
import '../view_models/cat_food_bag_view_model.dart';

/// §4.3.2 的猫粮袋时间线。一袋一行，最早那袋在上方。
///
/// 顺序**不在客户端动**：服务端按 `startedDate` 升序回，而「这一袋用到哪天」的答案
/// 是**下一行的开始日期**，`reversed` 一下邻接关系就断了，症状是每一袋的结束日比开始日还早。
///
/// 这一页不放余量。同一份推算在总览页那张卡上已经是「还能吃 29 天」，这里再放一遍会多出两个
/// 日均、两个耗尽日，而它们只有总览页那条链路会同步刷新。
class CatFoodBagListPage extends ConsumerWidget {
  const CatFoodBagListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bags = ref.watch(catFoodBagViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('猫粮袋'),
        actions: [
          IconButton(
            tooltip: '记一袋',
            icon: const Icon(Icons.add),
            onPressed: () => context.push(RoutePath.catFoodBagEdit),
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
            ? _EmptyBags(onCreate: () => context.push(RoutePath.catFoodBagEdit))
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  // 时间线每袋一张独立小卡（问题单：卡片间有间距）。
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

  final CatFoodBag bag;

  /// 下一袋的开始日。null = 这是时间线上最后一袋，也就是在用的那一袋。
  final DateTime? nextStartedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final next = nextStartedDate;

    return ListTile(
      onTap: () => context.push(RoutePath.catFoodBagEditOf(bag.id)),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.local_bar_outlined,
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
            '${formatDate(bag.startedDate)} 开始 · '
            '${next == null ? '用到现在' : '用到 ${formatDate(next)}'}',
          ),
          // 那三个派生字段的句式在 `cat_copy.dart` 的 `bagSummaryLine` 里，统计页的「每袋用时」
          // 用的是同一个函数。当前袋的「日均 —」也在那一处：0 会被读成「这袋一天就吃完了」。
          Text(bagSummaryLine(bag)),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => switch (value) {
          'edit' => context.push(RoutePath.catFoodBagEditOf(bag.id)),
          _ => _delete(context, ref),
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('编辑')),
          const PopupMenuItem(value: 'delete', child: Text('删除')),
        ],
      ),
    );
  }

  /// 删一袋不是「把那一行摘掉」：§4.3.2 的推导链上，它后面每一袋的结束日都要跟着左移。
  /// 确认框把这件事说出来，因为它是这一屏唯一一个会改动**别的行**的动作。
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: '删除「${bag.brand}」这一袋？',
      message:
          '后面每一袋的结束日期与使用天数都会重新推算，总览页的余量也会跟着变。删除后无法恢复。',
      confirmLabel: '删除',
    );
    if (!confirmed) return;
    final error = await ref
        .read(catFoodBagViewModelProvider.notifier)
        .remove(bag.id);
    if (error != null && context.mounted) showSnackBar(context, error);
  }
}

/// 「在用」那一格。总览页的余量卡用的是另一套写法（它整张卡就是在用那袋），
/// 这一枚只有列表页要，留成私有。
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
              Icons.local_bar_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('还没有猫粮袋记录', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '一袋记一次就好：填品牌与包装规格，什么时候吃完由下一袋的开始日推出来',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('记一袋'),
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}
