import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/category.dart';
import '../../../../data/models/flow_type.dart';
import '../../../../data/models/member.dart';
import '../../../../data/models/payment_account.dart';
import '../../../../data/models/transaction.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/category_icons.dart';
import '../../../core/category_palette.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../../../core/money.dart';
import '../../../core/offline_banner.dart';
import '../../family/view_models/family_view_model.dart';
import '../view_models/category_view_model.dart';
import '../view_models/payment_account_view_model.dart';
import '../view_models/transaction_list_view_model.dart';
import 'transaction_filter_sheet.dart';

/// §4.2.5 流水列表，记账 Tab 的根页面。
///
/// 分组、翻页、筛选条件都在 `TransactionListViewModel` 里，这里只把它交出来的
/// `groups` 一段段画下来。
class TransactionListPage extends ConsumerStatefulWidget {
  const TransactionListPage({super.key, this.initialSource});

  /// 从首页「今天已自动生成 N 笔」那块切进来时带的来源筛选。
  /// null 表示进来不动筛选，保持用户上次看到的样子。
  final String? initialSource;

  @override
  ConsumerState<TransactionListPage> createState() =>
      _TransactionListPageState();
}

class _TransactionListPageState extends ConsumerState<TransactionListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _applyInitialSource();
  }

  @override
  void didUpdateWidget(TransactionListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 这一页被外壳的 IndexedStack 养着，第二次切进来不会再走 initState，
    // 只能在这里补。参数没变就不动：那时页面上是用户自己挑的筛选，不该被清掉。
    if (oldWidget.initialSource != widget.initialSource) _applyInitialSource();
  }

  void _applyInitialSource() {
    final source = widget.initialSource;
    if (source == null) return;
    ref
        .read(transactionListViewModelProvider.notifier)
        .apply(TransactionFilter(source: source));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 快到末尾就翻页。VM 里有 `hasMore` 与 `loadingMore` 两道闸，这里不用再自己防抖。
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(transactionListViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(transactionListViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记账'),
        actions: [
          IconButton(
            tooltip: '类别管理',
            icon: const Icon(Icons.category_outlined),
            onPressed: () => context.push(RoutePath.categories),
          ),
          IconButton(
            tooltip: '支付方式管理',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => context.push(RoutePath.paymentAccounts),
          ),
          IconButton(
            tooltip: '统计',
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => context.push(RoutePath.statistics),
          ),
        ],
      ),
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(errorCopy(error), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref
                      .read(transactionListViewModelProvider.notifier)
                      .reload(),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
        data: (state) => _buildList(context, state),
      ),
    );
  }

  Widget _buildList(BuildContext context, TransactionListState state) {
    if (state.groups.isEmpty) {
      return _EmptyLedger(
        filtered: state.filter != const TransactionFilter(),
        onClearFilter: () => ref
            .read(transactionListViewModelProvider.notifier)
            .apply(const TransactionFilter()),
      );
    }

    final majors = _majorsById(ref);
    // 三个 Tab 共用外壳上那颗 FAB，它会盖住最后一行的下沿，所以末尾多留一截空白
    const bottomPadding = EdgeInsets.only(bottom: 96);

    // 问题单（卡片化）：每行独立一张小卡、卡间带间距；月份标题是卡与卡之间的轻量小字，
    // 不再把整月吞进一张大卡。
    return ListView(
      controller: _scrollController,
      padding: bottomPadding,
      children: [
        if (state.fromCache) OfflineBanner(savedAt: state.savedAt),
        _FilterBar(filter: state.filter),
        for (final group in state.groups) ...[
          _MonthHeader(group: group),
          for (final item in group.items)
            RowCard(
              child: _TransactionRow(
                transaction: item,
                major: majors[item.categoryId],
              ),
            ),
        ],
        if (state.hasMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

/// 大类 id → 大类。列表行上的图标与配色由它查，流水本身不带这两个字段。
///
/// 查不到是正常情况：类别被删掉的历史流水上只有当时的名称快照（需求文档 A3），
/// 图标与配色就退成通用占位。
Map<int, Category> _majorsById(WidgetRef ref) {
  final tree = ref.watch(categoryViewModelProvider).value?.categories;
  return {for (final major in tree ?? const <Category>[]) major.id: major};
}

/// 当前生效的筛选条件，一枚条件一枚 chip，点叉回到「不限」。
/// 一个条件都没有时只显示「筛选」那一枚，打开的还是同一个面板。
class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filter});

  final TransactionFilter filter;

  Future<void> _apply(WidgetRef ref, TransactionFilter next) =>
      ref.read(transactionListViewModelProvider.notifier).apply(next);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chips = [
      if (filter.type != null)
        _namedChip(
          filter.type == FlowType.expense ? '支出' : '收入',
          () => _apply(ref, filter.copyWith(type: null)),
        ),
      if (filter.startDate != null || filter.endDate != null)
        _namedChip(
          '${_dateOr(filter.startDate)} 至 ${_dateOr(filter.endDate)}',
          () => _apply(ref, filter.copyWith(startDate: null, endDate: null)),
        ),
      if (filter.categoryId != null)
        _namedChip(
          _categoryName(ref, filter.categoryId!),
          () => _apply(
            ref,
            filter.copyWith(categoryId: null, subCategoryId: null),
          ),
        ),
      if (filter.subCategoryId != null)
        _namedChip(
          _categoryName(ref, filter.subCategoryId!),
          () => _apply(ref, filter.copyWith(subCategoryId: null)),
        ),
      if (filter.accountId != null)
        _namedChip(
          _accountName(ref, filter.accountId!),
          () => _apply(ref, filter.copyWith(accountId: null)),
        ),
      if (filter.createdBy != null)
        _namedChip(
          _memberName(ref, filter.createdBy!),
          () => _apply(ref, filter.copyWith(createdBy: null)),
        ),
      if ((filter.keyword ?? '').isNotEmpty)
        _namedChip(
          '「${filter.keyword}」',
          () => _apply(ref, filter.copyWith(keyword: null)),
        ),
      if ((filter.amount ?? '').isNotEmpty)
        _namedChip(
          '金额 ${filter.amount}',
          () => _apply(ref, filter.copyWith(amount: null)),
        ),
      if (filter.source != null)
        _namedChip(
          filter.source == 'AUTO' ? '系统自动记账' : '手动记录',
          () => _apply(ref, filter.copyWith(source: null)),
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.tune, size: 18),
            label: Text(chips.isEmpty ? '筛选' : '改筛选'),
            onPressed: () async {
              final next = await showTransactionFilterSheet(context, filter);
              if (next != null) await _apply(ref, next);
            },
          ),
          for (final chip in chips) chip,
          if (chips.isNotEmpty)
            TextButton(
              onPressed: () => _apply(ref, const TransactionFilter()),
              child: const Text('清空'),
            ),
        ],
      ),
    );
  }

  Widget _namedChip(String label, VoidCallback onDeleted) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InputChip(
        label: Text(label),
        onDeleted: onDeleted,
        deleteIcon: const Icon(Icons.close, size: 18),
      ),
    );
  }

  static String _dateOr(DateTime? value) =>
      value == null ? '不限' : formatDate(value);
}

/// 筛选条件落的是 id，chip 上要写名字。字典与成员都是别处已经在用的那几份缓存，
/// 这里只读不拉。查不到是会的：类别被删、成员退出之后，旧条件还留在内存里，
/// 那就退回带 id 的占位，至少看得出「有一条条件」。
String _categoryName(WidgetRef ref, int id) {
  final tree =
      ref.watch(categoryViewModelProvider).value?.categories ??
      const <Category>[];
  for (final major in tree) {
    if (major.id == id) return major.name;
    for (final sub in major.children) {
      if (sub.id == id) return sub.name;
    }
  }
  return '类别 #$id';
}

String _accountName(WidgetRef ref, int id) {
  final accounts =
      ref.watch(paymentAccountViewModelProvider).value?.accounts ??
      const <PaymentAccount>[];
  for (final account in accounts) {
    if (account.id == id) return account.name;
  }
  return '支付方式 #$id';
}

String _memberName(WidgetRef ref, int id) {
  final members =
      ref.watch(familyViewModelProvider).value?.members ?? const <Member>[];
  for (final member in members) {
    if (member.userId == id) return member.nickname;
  }
  return '成员 #$id';
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.group});

  final TransactionGroup group;

  @override
  Widget build(BuildContext context) {
    final summary = group.summary;
    final theme = Theme.of(context);

    // 月份标题：卡与卡之间的一行小字，不再带强调条与底色。
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 4),
      child: Row(
        children: [
          Text(
            formatMonthLabel(group.month),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (summary == null)
            Text('${group.items.length} 笔', style: theme.textTheme.bodySmall)
          else
            Text(
              '收 ${formatYuan(summary.income)}　'
              '支 ${formatYuan(summary.expense)}　'
              '余 ${formatYuan(summary.balance)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionRow extends ConsumerWidget {
  const _TransactionRow({required this.transaction, this.major});

  final Transaction transaction;
  final Category? major;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = categoryColor(major?.colorIndex ?? 0);
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(transaction.id),
      // 两个方向都不真的把行滑走：删除成功后整页重拉，行自然就没了；真让它消失反倒要
      // 在这儿手动维护一份列表，与「状态只有一个来源」冲突。
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await context.push(RoutePath.editTransaction(transaction.id));
          return false;
        }
        return _delete(context, ref);
      },
      background: const _SwipeBackground(
        icon: Icons.edit_outlined,
        color: Colors.blueGrey,
        label: '编辑',
      ),
      secondaryBackground: const _SwipeBackground(
        icon: Icons.delete_outline,
        color: Colors.redAccent,
        label: '删除',
        fromRight: true,
      ),
      child: ListTile(
        onTap: () => context.push(RoutePath.transactionOf(transaction.id)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: categoryTint(color),
            shape: BoxShape.circle,
          ),
          child: Icon(
            categoryIcon(major?.iconKey ?? ''),
            color: color,
            size: 22,
          ),
        ),
        title: Text(
          transaction.subCategoryName ?? transaction.categoryName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            formatDayLabel(transaction.bizDate),
            transaction.accountName,
            transaction.recorderName,
            if ((transaction.remark ?? '').isNotEmpty) transaction.remark!,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${transaction.isExpense ? '-' : '+'}${formatYuan(transaction.amount)}',
          style: theme.textTheme.titleMedium?.copyWith(
            // 「暖居」§5：行内金额支出暖红 / 收入主色橙，等宽对齐，扫一眼即知收与支
            color: transaction.isExpense
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Future<bool> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: '删除这笔记录？',
      message: '删除后它不再计入统计，数据仍保留在库里备查。',
      confirmLabel: '删除',
    );
    if (!confirmed) return false;

    final error = await ref
        .read(transactionListViewModelProvider.notifier)
        .remove(transaction.id);
    if (error != null && context.mounted) showSnackBar(context, error);
    return false;
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.icon,
    required this.color,
    required this.label,
    this.fromRight = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool fromRight;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: fromRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (fromRight) ...[
                Text(label, style: const TextStyle(color: Colors.white)),
                const SizedBox(width: 6),
              ],
              Icon(icon, color: Colors.white),
              if (!fromRight) ...[
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: Colors.white)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger({required this.filtered, required this.onClearFilter});

  /// 筛出来的空与本来就没记过是两件事：前者要让人清条件，后者才该引导记第一笔。
  final bool filtered;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 空态图标进一枚柔色圆底（「暖居」§3 的图标呈现），比裸图标更有「占了格子」的分量
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                filtered
                    ? Icons.filter_alt_off_outlined
                    : Icons.receipt_long_outlined,
                size: 40,
                color: theme.colorScheme.primary.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              filtered ? '没有符合条件的记录' : '还没有记过账',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              filtered ? '换个条件，或者把筛选清掉' : '点右下角的 + 记下第一笔',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (filtered) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onClearFilter,
                child: const Text('清空筛选'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
