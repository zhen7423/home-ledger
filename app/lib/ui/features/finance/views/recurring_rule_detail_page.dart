import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/flow_type.dart';
import '../../../../data/models/recurring_execution.dart';
import '../../../../data/models/recurring_rule.dart';
import '../../../../data/services/api_exception.dart';
import '../../../../router/app_router.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../../../core/money.dart';
import '../../../core/period_copy.dart';
import '../view_models/recurring_rule_view_model.dart';

/// 一条规则的全部字段 + 它的执行记录，只读。
///
/// 取数走 `GET /recurring-rules/{id}` 而不是从列表里捞：通知的跳转、编辑页返回后刷新
/// 都可能带着一个列表那 20 条里没有的 id 进来。
class RecurringRuleDetailPage extends ConsumerStatefulWidget {
  const RecurringRuleDetailPage({super.key, required this.id});

  final int id;

  @override
  ConsumerState<RecurringRuleDetailPage> createState() =>
      _RecurringRuleDetailPageState();
}

class _RecurringRuleDetailPageState
    extends ConsumerState<RecurringRuleDetailPage> {
  RecurringRule? _rule;
  List<RecurringExecution> _executions = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notifier = ref.read(recurringRuleViewModelProvider.notifier);
    try {
      final rule = await notifier.byId(widget.id);
      // 执行记录是详情页的一个区块，不是主角：它拉失败时不该把整页变成错误态，
      // 让用户看不到任何规则字段。规则本体已经拿到了，就先按「没有记录」显示。
      List<RecurringExecution> executions = const [];
      try {
        executions = await notifier.executions(widget.id);
      } on ApiException {
        executions = const [];
      }
      if (!mounted) return;
      setState(() {
        _rule = rule;
        _executions = executions;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = errorCopy(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rule = _rule;

    return Scaffold(
      appBar: AppBar(
        title: const Text('规则详情'),
        actions: [
          if (rule != null)
            IconButton(
              tooltip: '编辑',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await context.push(RoutePath.editRecurringRule(rule.id));
                if (mounted) _load();
              },
            ),
          if (rule != null)
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : rule == null
          ? const SizedBox.shrink()
          : _Content(rule: rule, executions: _executions),
    );
  }

  Future<void> _delete() async {
    final rule = _rule;
    if (rule == null) return;
    final confirmed = await confirmAction(
      context,
      title: '删除「${rule.name}」？',
      message: '已经生成的流水会保留，只是不再按这条规则继续往下记。',
      confirmLabel: '删除',
    );
    if (!confirmed) return;

    final error = await ref
        .read(recurringRuleViewModelProvider.notifier)
        .remove(rule.id);
    if (!mounted) return;
    if (error != null) {
      showSnackBar(context, error);
      return;
    }
    context.pop();
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.rule, required this.executions});

  final RecurringRule rule;
  final List<RecurringExecution> executions;

  @override
  Widget build(BuildContext context) {
    final isExpense = rule.type == FlowType.expense;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                rule.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}${formatYuan(rule.amount)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          periodCopy(rule.periodType, rule.periodValue),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Divider(height: 32),
        _row(context, '收支类型', isExpense ? '支出' : '收入'),
        _row(
          context,
          '大类 / 小类',
          '${rule.categoryName} / ${rule.subCategoryName ?? '未细分'}',
        ),
        _row(context, '支付方式', rule.accountName),
        _row(context, '起始日期', formatDate(rule.startDate)),
        _row(
          context,
          '截止日期',
          rule.endDate == null ? '不限，一直记下去' : formatDate(rule.endDate!),
        ),
        _row(context, '状态', rule.enabled ? '启用中' : '已停用'),
        _row(context, '创建时间', formatDateTime(rule.createdAt)),
        _row(context, '最后修改', formatDateTime(rule.updatedAt)),
        const SizedBox(height: 16),
        Text('执行记录', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        if (executions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '还没有生成过流水。到了周期上的那一天，定时任务会补上。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final execution in executions)
            _ExecutionRow(execution: execution),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// 一次执行的一行。**不可点**：`transactionId` 指向的流水可能已经被删掉，
/// 点进去是一个空态页，比不给点更让人困惑（B3 第 14 条）。
class _ExecutionRow extends StatelessWidget {
  const _ExecutionRow({required this.execution});

  final RecurringExecution execution;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        execution.backfilled ? Icons.more_time : Icons.check_circle_outline,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(formatDate(execution.bizDate)),
      subtitle: Text('执行于 ${formatDate(execution.executedDate)}'),
      trailing: execution.backfilled ? const _Tag('补记') : null,
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
