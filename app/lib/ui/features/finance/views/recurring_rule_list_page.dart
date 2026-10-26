import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/flow_type.dart';
import '../../../../data/models/recurring_rule.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/error_copy.dart';
import '../../../core/money.dart';
import '../../../core/period_copy.dart';
import '../view_models/recurring_rule_view_model.dart';

/// §4.2.3 的规则清单。
///
/// 这里只负责「有哪些规则、开着还是关着」。一条规则有九个字段，改它得整页表单，
/// 所以新增与编辑都在推开的页面上做，列表行上只留启停开关这一个动作。
class RecurringRuleListPage extends ConsumerStatefulWidget {
  const RecurringRuleListPage({super.key});

  @override
  ConsumerState<RecurringRuleListPage> createState() =>
      _RecurringRuleListPageState();
}

class _RecurringRuleListPageState extends ConsumerState<RecurringRuleListPage> {
  /// 用 'ALL' 而不是 null 表示「全部」：`SegmentedButton` 的段值要跟 `selected` 那个
  /// 非空集合比，拿 null 当段值得为一枚芯片写一套泛型。
  static const String _all = 'ALL';

  String _scope = _all;

  String? get _type => _scope == _all ? null : _scope;

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(recurringRuleViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('周期记账'),
        actions: [
          IconButton(
            tooltip: '新建规则',
            icon: const Icon(Icons.add),
            onPressed: () => context.push(RoutePath.recurringRuleNew),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: _all, label: Text('全部')),
                  ButtonSegment(value: FlowType.expense, label: Text('支出')),
                  ButtonSegment(value: FlowType.income, label: Text('收入')),
                ],
                selected: {_scope},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setState(() => _scope = selection.first),
              ),
            ),
          ),
        ),
      ),
      body: rules.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorCopy(error), textAlign: TextAlign.center),
          ),
        ),
        data: (rows) => _buildList(context, [
          for (final rule in rows)
            if (_type == null || rule.type == _type) rule,
        ]),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<RecurringRule> rules) {
    if (rules.isEmpty) {
      return _EmptyRules(
        filtered: _type != null,
        onShowAll: () => setState(() => _scope = _all),
        onCreate: () => context.push(RoutePath.recurringRuleNew),
      );
    }

    // 规则每行一张独立小卡（问题单：卡片间有间距）。
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final rule in rules) RowCard(child: _RuleTile(rule: rule)),
      ],
    );
  }
}

class _RuleTile extends ConsumerWidget {
  const _RuleTile({required this.rule});

  final RecurringRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpense = rule.type == FlowType.expense;

    return ListTile(
      onTap: () => context.push(RoutePath.recurringRuleOf(rule.id)),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          isExpense ? Icons.trending_down : Icons.trending_up,
          color: isExpense ? Colors.red.shade300 : Colors.green.shade400,
        ),
      ),
      title: Row(
        children: [
          Expanded(child: Text(rule.name, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          // 卡片内的可用宽度比裸列表窄一截，金额长时等比缩小而不是把整行顶出屏幕
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${isExpense ? '-' : '+'}${formatYuan(rule.amount)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ],
      ),
      // ListTile 按各槽位的固有宽度分宽：开关与金额并排放进 trailing 时只分到二十几像素，整行溢出。
      // 于是 trailing 只留开关，标签挪到副标题末尾，两处文字都套 Expanded 自己收缩。
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              '${periodCopy(rule.periodType, rule.periodValue)} · '
              '${rule.categoryName} · ${rule.accountName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!rule.enabled)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('已停用', style: Theme.of(context).textTheme.labelSmall),
            ),
        ],
      ),
      // 开关只改启停，不碰别的字段，所以不必进编辑页
      trailing: Switch(
        value: rule.enabled,
        onChanged: (_) => _toggle(context, ref),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final error = await ref
        .read(recurringRuleViewModelProvider.notifier)
        .toggle(rule.id);
    if (error != null && context.mounted) showSnackBar(context, error);
  }
}

class _EmptyRules extends StatelessWidget {
  const _EmptyRules({
    required this.filtered,
    required this.onShowAll,
    required this.onCreate,
  });

  /// 「切到支出的空」与「一条规则都没有」是两件事：前者该把筛选清掉，后者才该引导建第一条。
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
              filtered ? Icons.filter_alt_off_outlined : Icons.repeat_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              filtered ? '这个类型下还没有规则' : '还没有周期记账规则',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              filtered ? '换回「全部」看看' : '房租、订阅这类固定支出建一条，到期自动记上',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (filtered)
              OutlinedButton(onPressed: onShowAll, child: const Text('看全部'))
            else
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('新建规则'),
                onPressed: onCreate,
              ),
          ],
        ),
      ),
    );
  }
}
