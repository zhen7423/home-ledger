import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/payment_account.dart';
import '../../../../data/services/network_status.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../../../core/validators.dart';
import '../view_models/payment_account_view_model.dart';

/// §4.2.1 的支付方式字典。它只是记账时贴的一枚标签，不维护余额、不做转账。
///
/// 默认那项不能停用也不能删除：它是记账页账户选择器的初始值，一旦允许，就会出现
/// 「默认是现金，而现金不在可选列表里」的死状态。要动它先把默认转移出去。
class PaymentAccountPage extends ConsumerStatefulWidget {
  const PaymentAccountPage({super.key});

  @override
  ConsumerState<PaymentAccountPage> createState() => _PaymentAccountPageState();
}

class _PaymentAccountPageState extends ConsumerState<PaymentAccountPage> {
  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(paymentAccountViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('支付方式'),
        actions: [
          IconButton(
            tooltip: '新建',
            icon: const Icon(Icons.add),
            onPressed: _create,
          ),
        ],
      ),
      body: accounts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorCopy(error), textAlign: TextAlign.center),
          ),
        ),
        data: (result) => result.accounts.isEmpty
            ? const Center(child: Text('还没有支付方式，点右上角 + 新建'))
            : ReorderableListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: result.accounts.length,
                // 顺序由后端定，写完由 VM 重拉回来渲染，本地不改序，理由同类别管理页
                onReorderItem: (oldIndex, newIndex) =>
                    _sort(result.accounts, oldIndex, newIndex),
                itemBuilder: (context, index) => _AccountTile(
                  key: ValueKey(result.accounts[index].id),
                  account: result.accounts[index],
                  index: index,
                  onRename: () => _rename(result.accounts[index]),
                  onSetDefault: () => _setDefault(result.accounts[index]),
                  onToggle: () => _toggle(result.accounts[index]),
                  onDelete: () => _delete(result.accounts[index]),
                ),
              ),
      ),
    );
  }

  /// `onReorderItem` 交来的 newIndex 已经算上了被抽走那一项，不用再自己校正。
  Future<void> _sort(
    List<PaymentAccount> accounts,
    int oldIndex,
    int newIndex,
  ) {
    final ordered = accounts.toList();
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);
    return _run(
      () => ref.read(paymentAccountViewModelProvider.notifier).sort([
        for (final account in ordered) account.id,
      ]),
    );
  }

  Future<void> _create() => _run(() async {
    final name = await promptForText(
      context,
      title: '新建支付方式',
      label: '名称（最多 8 个字）',
      validator: validatePaymentAccountName,
      confirmDisabledHint: ref.read(canSubmitProvider)
          ? null
          : offlineSubmitHint,
    );
    return name == null
        ? null
        : ref.read(paymentAccountViewModelProvider.notifier).create(name);
  });

  Future<void> _rename(PaymentAccount account) => _run(() async {
    final name = await promptForText(
      context,
      title: '改名',
      label: '名称（最多 8 个字）',
      initialValue: account.name,
      validator: validatePaymentAccountName,
      confirmDisabledHint: ref.read(canSubmitProvider)
          ? null
          : offlineSubmitHint,
    );
    return name == null
        ? null
        : ref
              .read(paymentAccountViewModelProvider.notifier)
              .rename(account.id, name);
  });

  /// 设默认会连带清掉别行的标记，所以 VM 写完必须重拉整份，不能只改列表里这一条。
  Future<void> _setDefault(PaymentAccount account) => _run(
    () => ref
        .read(paymentAccountViewModelProvider.notifier)
        .setDefault(account.id),
  );

  Future<void> _toggle(PaymentAccount account) => _run(
    () => ref.read(paymentAccountViewModelProvider.notifier).toggle(account.id),
  );

  Future<void> _delete(PaymentAccount account) => _run(() async {
    final confirmed = await confirmAction(
      context,
      title: '删除「${account.name}」？',
      message: '已有流水用过的支付方式不能删除，只能停用。',
      confirmLabel: '删除',
    );
    return confirmed
        ? ref.read(paymentAccountViewModelProvider.notifier).remove(account.id)
        : null;
  });

  Future<void> _run(Future<String?> Function() action) async {
    final error = await action();
    if (error != null && mounted) showSnackBar(context, error);
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    super.key,
    required this.account,
    required this.index,
    required this.onRename,
    required this.onSetDefault,
    required this.onToggle,
    required this.onDelete,
  });

  final PaymentAccount account;
  final int index;
  final VoidCallback onRename;
  final VoidCallback onSetDefault;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle),
      ),
      title: Row(
        children: [
          Flexible(child: Text(account.name, overflow: TextOverflow.ellipsis)),
          if (account.isDefault)
            const Padding(padding: EdgeInsets.only(left: 8), child: _Tag('默认')),
          if (!account.enabled)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: _Tag('已停用'),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: account.enabled,
            // 默认项置灰而不是藏起来：藏了会让人以为这个开关坏了
            onChanged: account.isDefault ? null : (_) => onToggle(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => switch (value) {
              'rename' => onRename(),
              'default' => onSetDefault(),
              'toggle' => onToggle(),
              _ => onDelete(),
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'rename', child: Text('改名')),
              PopupMenuItem(
                value: 'default',
                enabled: !account.isDefault,
                child: Text(account.isDefault ? '已是默认' : '设为默认'),
              ),
              PopupMenuItem(
                value: 'toggle',
                enabled: !account.isDefault,
                child: Text(account.enabled ? '停用' : '启用'),
              ),
              PopupMenuItem(
                value: 'delete',
                enabled: !account.isDefault,
                child: const Text('删除'),
              ),
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
