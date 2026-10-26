import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/category.dart';
import '../../../../data/models/transaction.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../../data/services/network_status.dart';
import '../../../../router/app_router.dart';
import '../../../core/category_icons.dart';
import '../../../core/category_palette.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../../../core/money.dart';
import '../../../core/offline_banner.dart';
import '../view_models/category_view_model.dart';
import '../view_models/transaction_list_view_model.dart';

/// 一条流水的全部字段，只读。§4.2.5 的「点击进详情」。
///
/// 取数用 `GET /transactions/{id}` 而不是从列表里捞：这一页要能单独打开（编辑完回来、
/// 从通知进），列表那一页数据未必含它。
class TransactionDetailPage extends ConsumerStatefulWidget {
  const TransactionDetailPage({super.key, required this.id});

  final int id;

  @override
  ConsumerState<TransactionDetailPage> createState() =>
      _TransactionDetailPageState();
}

class _TransactionDetailPageState extends ConsumerState<TransactionDetailPage> {
  Transaction? _transaction;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final transaction = await ref
          .read(transactionRepositoryProvider)
          .get(widget.id);
      if (!mounted) return;
      setState(() {
        _transaction = transaction;
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
    final transaction = _transaction;

    return Scaffold(
      appBar: AppBar(
        title: const Text('记录详情'),
        actions: [
          if (transaction != null)
            IconButton(
              tooltip: '编辑',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await context.push(RoutePath.editTransaction(transaction.id));
                if (mounted) _load();
              },
            ),
          if (transaction != null)
            IconButton(
              tooltip: '删除',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Column(
        children: [
          // 这一页的判据只能用全局网络状态：`get(id)` 回的是裸 Transaction，带不出 fromCache。
          // 在这一页上两者是等价的——离线时它能显示出内容，就只可能是 F4 那条缓存回落供的。
          if (ref.watch(networkStatusProvider) == NetworkStatus.offline)
            const OfflineBanner(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  )
                : transaction == null
                ? const SizedBox.shrink()
                : _Content(transaction: transaction),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await confirmAction(
      context,
      title: '删除这笔记录？',
      message: '删除后它不再计入统计，数据仍保留在库里备查。',
      confirmLabel: '删除',
    );
    if (!confirmed) return;

    final error = await ref
        .read(transactionListViewModelProvider.notifier)
        .remove(widget.id);
    if (!mounted) return;
    if (error != null) {
      showSnackBar(context, error);
      return;
    }
    context.pop();
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tree =
        ref.watch(categoryViewModelProvider).value?.categories ??
        const <Category>[];
    final major = _find(tree, transaction.categoryId);
    final color = categoryColor(major?.colorIndex ?? 0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            // 「暖居」§3 图标呈现：柔色圆底 + 本色图标 + 一圈同类色描边，详情页头更有分量
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: categoryTint(color),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: Icon(
                categoryIcon(major?.iconKey ?? ''),
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                transaction.subCategoryName ?? transaction.categoryName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${transaction.isExpense ? '-' : '+'}${formatYuan(transaction.amount)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: transaction.isExpense
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const Divider(height: 32),
        _row(context, '收支类型', transaction.isExpense ? '支出' : '收入'),
        _row(
          context,
          '大类 / 小类',
          '${transaction.categoryName}'
              ' / ${transaction.subCategoryName ?? '未细分'}',
        ),
        _row(context, '支付方式', transaction.accountName),
        _row(context, '记账日期', formatDate(transaction.bizDate)),
        _row(
          context,
          '备注',
          (transaction.remark ?? '').isEmpty ? '无' : transaction.remark!,
        ),
        _row(context, '记录人', transaction.recorderName),
        if (transaction.ruleId != null)
          // 不给成可点的链接：规则随时可能被删，点进去是一个「规则不存在」
          _row(context, '来源', '周期规则自动生成'),
        _row(context, '创建时间', formatDateTime(transaction.createdAt)),
        _row(context, '最后修改', formatDateTime(transaction.updatedAt)),
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

/// 树只有两层，且大类不超过二十个，直接扫。
Category? _find(List<Category> majors, int id) {
  for (final major in majors) {
    if (major.id == id) return major;
  }
  return null;
}
