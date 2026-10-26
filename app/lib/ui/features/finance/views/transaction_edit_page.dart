import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/category.dart';
import '../../../../data/models/flow_type.dart';
import '../../../../data/models/payment_account.dart';
import '../../../../data/models/transaction.dart';
import '../../../../data/services/network_status.dart';
import '../../../../router/app_router.dart';
import '../../../core/amount_input_formatter.dart';
import '../../../core/app_widgets.dart';
import '../../../core/category_cell.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../../../core/validators.dart';
import '../view_models/category_view_model.dart';
import '../view_models/payment_account_view_model.dart';
import '../view_models/transaction_edit_view_model.dart';
import '../view_models/transaction_list_view_model.dart';

/// §4.2.1 记一笔。新增与编辑共用这一页，靠 `id` 有没有值区分。
class TransactionEditPage extends ConsumerStatefulWidget {
  const TransactionEditPage({super.key, this.id});

  final int? id;

  bool get isEdit => id != null;

  @override
  ConsumerState<TransactionEditPage> createState() =>
      _TransactionEditPageState();
}

class _TransactionEditPageState extends ConsumerState<TransactionEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _remark = TextEditingController();

  String _type = FlowType.expense;
  int? _majorId;
  int? _subId;
  int? _accountId;
  DateTime _bizDate = DateTime.now();

  /// 提交中的页面级开关，覆盖「POST + 列表重拉」整个窗口（问题单：保存后要等列表刷完才返回，
  /// 这一段如果按钮先恢复了「保存」两个字，页面看起来就像卡住了）。VM 里那份 `submitting`
  /// 只盖 POST 那一截，所以这里再留一份从按下到 pop 前都保持的。
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _loadOriginal();
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _remark.dispose();
    super.dispose();
  }

  /// 编辑模式先取回原值再回填。原值走 ViewModel，字典走各自的 provider，两边互等不得。
  Future<void> _loadOriginal() async {
    final notifier = ref.read(transactionEditViewModelProvider.notifier);
    final error = await notifier.load(widget.id!);
    if (!mounted) return;
    if (error != null) {
      showSnackBar(context, error);
      return;
    }
    final original = ref.read(transactionEditViewModelProvider).original;
    if (original == null) return;
    setState(_applyOriginal(original));
  }

  VoidCallback _applyOriginal(Transaction original) {
    _amount.text = original.amount;
    _remark.text = original.remark ?? '';
    return () {
      _type = original.type;
      _majorId = original.categoryId;
      _subId = original.subCategoryId;
      _accountId = original.accountId;
      _bizDate = original.bizDate;
    };
  }

  /// 没手动挑过就用家庭默认。「每个家庭恰好一行 isDefault = 1」由后端保证。
  /// 现算而不是 initState 时塞进 _accountId：冷启动时字典可能还没到，那一刻没有默认项可言。
  int? get _selectedAccountId =>
      _accountId ??
      ref.read(paymentAccountViewModelProvider.notifier).defaultAccount?.id;

  @override
  Widget build(BuildContext context) {
    final canSubmit = ref.watch(canSubmitProvider);
    // 两份字典要 watch 的是 provider 本身：notifier 一直是同一个对象，字典拉回来不会让它「变化」，
    // 只 watch notifier 的话这一页会永远停在空列表上。取数据仍是找 notifier 要，它认得当前状态。
    ref.watch(categoryViewModelProvider);
    ref.watch(paymentAccountViewModelProvider);
    final majors = ref
        .read(categoryViewModelProvider.notifier)
        .selectable(_type);
    final accounts = ref
        .read(paymentAccountViewModelProvider.notifier)
        .selectable;
    final selectedMajor = _firstById(majors, _majorId);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? '编辑记录' : '记一笔')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: FlowType.expense, label: Text('支出')),
                ButtonSegment(value: FlowType.income, label: Text('收入')),
              ],
              selected: {_type},
              showSelectedIcon: false,
              // 「暖居」§6.6：分段选择全宽等分，支出/收入各占一半
              expandedInsets: EdgeInsets.zero,
              onSelectionChanged: (selection) => setState(() {
                _type = selection.first;
                // 类别树按收支类型分家，跨过去 _majorId 就不属于这一棵树了
                _majorId = null;
                _subId = null;
              }),
            ),
            const SizedBox(height: 16),
            _amountField(),
            const SizedBox(height: 8),
            _categoryGrid(majors),
            if (selectedMajor != null && selectedMajor.children.isNotEmpty) ...[
              const SizedBox(height: 12),
              _subChips(selectedMajor),
            ],
            const SizedBox(height: 16),
            _accountChips(accounts),
            const SizedBox(height: 8),
            _dateTile(),
            const SizedBox(height: 8),
            TextFormField(
              controller: _remark,
              minLines: 2,
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(labelText: '备注（选填）'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: (_saving || !canSubmit) ? null : _submit,
              child: submitButtonText(
                saving: _saving,
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            if (!canSubmit) const OfflineSubmitHint(),
          ],
        ),
      ),
    );
  }

  Widget _amountField() => TextFormField(
    controller: _amount,
    autofocus: !widget.isEdit,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    // 整串判形（一个小数点 + 两位小数）：allow 正则拦不住 "1.2.3"，与筛选面板同一套
    inputFormatters: [AmountInputFormatter()],
    textAlign: TextAlign.right,
    style: const TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    decoration: const InputDecoration(
      labelText: '金额',
      prefixIcon: Icon(Icons.paid_outlined),
      // 边框交回主题（「暖居」§6.8：Filled + 聚焦描边），不再各页手写 OutlineInputBorder
    ),
    validator: validateAmount,
  );

  Widget _categoryGrid(List<Category> majors) {
    if (majors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('这个收支类型下还没有可选的类别，先到「类别管理」启用或新建'),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.76,
      ),
      itemCount: majors.length,
      itemBuilder: (context, index) {
        final major = majors[index];
        return CategoryCell(
          category: major,
          selected: major.id == _majorId,
          onTap: () => setState(() {
            _majorId = major.id;
            _subId = null;
          }),
        );
      },
    );
  }

  Widget _subChips(Category major) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('小类（可不选）', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final sub in major.children)
              ChoiceChip(
                label: Text(sub.name),
                selected: sub.id == _subId,
                // 再点一次取消选择，与「不选小类」是同一个意思
                onSelected: (_) =>
                    setState(() => _subId = _subId == sub.id ? null : sub.id),
              ),
          ],
        ),
      ],
    );
  }

  Widget _accountChips(List<PaymentAccount> accounts) {
    if (accounts.isEmpty) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('还没有支付方式，去添加'),
        onPressed: () => context.push(RoutePath.paymentAccounts),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('支付方式', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final account in accounts)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(account.name),
                    selected: account.id == _selectedAccountId,
                    onSelected: (_) => setState(() => _accountId = account.id),
                  ),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('新增'),
                onPressed: () => context.push(RoutePath.paymentAccounts),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateTile() {
    final today = DateTime.now();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: const Text('记账日期'),
      trailing: Text(
        formatDate(_bizDate),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      // 允许补记过去，不允许记未来（需求文档 §4.2.1）
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _bizDate,
          firstDate: DateTime(today.year - 5),
          lastDate: today,
        );
        if (picked != null) setState(() => _bizDate = picked);
      },
    );
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_majorId == null) {
      showSnackBar(context, '请选择类别');
      return;
    }
    final accountId = _selectedAccountId;
    if (accountId == null) {
      showSnackBar(context, '请选择支付方式');
      return;
    }

    setState(() => _saving = true);
    final error = await ref
        .read(transactionEditViewModelProvider.notifier)
        .submit(
          id: widget.id,
          amount: _amount.text.trim(),
          categoryId: _majorId!,
          subCategoryId: _subId,
          accountId: accountId,
          bizDate: _bizDate,
          remark: _remark.text.trim().isEmpty ? null : _remark.text.trim(),
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      showSnackBar(context, error);
      return;
    }

    // 列表页在壳里被 IndexedStack 养着，pop 不会触发它重新 build，写完得点名让它重拉。
    // 等它刷完再返回，这段延迟用按钮里的转圈盖住（按钮直到这里还没恢复「保存」二字）。
    await ref.read(transactionListViewModelProvider.notifier).reload();
    if (!mounted) return;
    context.pop();
  }
}

Category? _firstById(List<Category> categories, int? id) {
  if (id == null) return null;
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
}
