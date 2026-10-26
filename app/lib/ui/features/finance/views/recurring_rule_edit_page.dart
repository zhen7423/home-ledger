import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/category.dart';
import '../../../../data/models/flow_type.dart';
import '../../../../data/models/payment_account.dart';
import '../../../../data/models/period_value.dart';
import '../../../../data/models/recurring_rule.dart';
import '../../../../data/repositories/recurring_rule_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../../data/services/network_status.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/category_cell.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../../../core/validators.dart';
import '../view_models/category_view_model.dart';
import '../view_models/payment_account_view_model.dart';
import '../view_models/recurring_rule_view_model.dart';

/// §4.2.3 的新建与编辑，同一页，靠 `id` 有没有值区分——照记一笔那页的做法。
///
/// 表单里没有「收支类型」这一项之外的类型选择：后端从所选大类反推规则的类型
/// （`RecurringRuleCreateRequest` 根本没有 type 字段），所以那个切换只用来决定
/// 展示哪一棵类别树，交上去的是 `categoryId`。
class RecurringRuleEditPage extends ConsumerStatefulWidget {
  const RecurringRuleEditPage({super.key, this.id});

  final int? id;

  bool get isEdit => id != null;

  @override
  ConsumerState<RecurringRuleEditPage> createState() =>
      _RecurringRuleEditPageState();
}

class _RecurringRuleEditPageState extends ConsumerState<RecurringRuleEditPage> {
  static const List<(String, String)> _periodTypes = [
    ('DAILY', '按天'),
    ('WEEKLY', '按周'),
    ('MONTHLY', '按月'),
    ('YEARLY', '按年'),
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _amount = TextEditingController();

  /// DAILY 的间隔天数。用输入框而不是步进器：365 这种值用 +1 点到手酸。
  final TextEditingController _interval = TextEditingController(text: '1');

  String _type = FlowType.expense;
  int? _majorId;
  int? _subId;
  int? _accountId;
  String _periodType = 'MONTHLY';
  final Set<int> _weekdays = <int>{};
  final Set<int> _daysOfMonth = <int>{};
  int _month = 1;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadOriginal();
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _interval.dispose();
    super.dispose();
  }

  Future<void> _loadOriginal() async {
    try {
      final rule = await ref
          .read(recurringRuleViewModelProvider.notifier)
          .byId(widget.id!);
      if (!mounted) return;
      setState(() => _apply(rule));
    } on ApiException catch (e) {
      if (mounted) showSnackBar(context, errorCopy(e));
    }
  }

  void _apply(RecurringRule rule) {
    _name.text = rule.name;
    _amount.text = rule.amount;
    _type = rule.type;
    _majorId = rule.categoryId;
    _subId = rule.subCategoryId;
    _accountId = rule.accountId;
    _periodType = rule.periodType;
    _startDate = rule.startDate;
    _endDate = rule.endDate;
    // 先清空再回填：从别的规则切过来时上一份的残留会被当成这一份的参数交上去
    _weekdays.clear();
    _daysOfMonth.clear();
    final value = rule.periodValue;
    switch (rule.periodType) {
      case 'DAILY':
        _interval.text = '${value.intervalDays ?? 1}';
      case 'WEEKLY':
        _weekdays.addAll(value.weekdays ?? const []);
      case 'MONTHLY':
        _daysOfMonth.addAll(value.daysOfMonth ?? const []);
      case 'YEARLY':
        _month = value.month ?? 1;
        _daysOfMonth.addAll(value.daysOfMonth ?? const []);
    }
  }

  int? get _intervalDays => int.tryParse(_interval.text.trim());

  /// 周期参数的校验口径与后端一致：结构对不对由选了哪种周期决定，数值只在各自范围内。
  String? _periodError() {
    switch (_periodType) {
      case 'DAILY':
        final days = _intervalDays;
        if (days == null || days < 1 || days > 365) {
          return '每隔几天要填 1 到 365';
        }
      case 'WEEKLY':
        if (_weekdays.isEmpty) return '至少选一个星期几';
      case 'MONTHLY':
        if (_daysOfMonth.isEmpty) return '至少选一个月中的日期';
      case 'YEARLY':
        if (_daysOfMonth.isEmpty) return '至少选一个月中的日期';
      default:
        return '请选择周期类型';
    }
    return null;
  }

  PeriodValue _periodValue() => switch (_periodType) {
    'DAILY' => PeriodValue(intervalDays: _intervalDays),
    'WEEKLY' => PeriodValue(weekdays: _ordered(_weekdays)),
    'MONTHLY' => PeriodValue(daysOfMonth: _ordered(_daysOfMonth)),
    'YEARLY' => PeriodValue(month: _month, daysOfMonth: _ordered(_daysOfMonth)),
    _ => const PeriodValue(),
  };

  /// 后端不重排传上来的数组，存进去什么顺序显示就是什么顺序。先在提交前排好，
  /// 免得用户按「31、5」点出来，详情页看到「每月 31、5 日」以为选错了。
  List<int> _ordered(Set<int> values) => [...values]..sort();

  int? get _selectedAccountId =>
      _accountId ??
      ref.read(paymentAccountViewModelProvider.notifier).defaultAccount?.id;

  @override
  Widget build(BuildContext context) {
    final canSubmit = ref.watch(canSubmitProvider);
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
      appBar: AppBar(title: Text(widget.isEdit ? '编辑规则' : '新建规则')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: '规则名称',
                hintText: '房租、视频会员',
              ),
              validator: validateRecurringRuleName,
            ),
            const SizedBox(height: 8),
            _amountField(),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: FlowType.expense, label: Text('支出')),
                ButtonSegment(value: FlowType.income, label: Text('收入')),
              ],
              selected: {_type},
              showSelectedIcon: false,
              // 「暖居」§6.6：收支类型全宽等分，与记一笔、类别管理同形
              expandedInsets: EdgeInsets.zero,
              onSelectionChanged: (selection) => setState(() {
                _type = selection.first;
                // 类别树按收支类型分家，跨过去 _majorId 就不属于这一棵树了
                _majorId = null;
                _subId = null;
              }),
            ),
            const SizedBox(height: 16),
            _categoryGrid(majors),
            if (selectedMajor != null && selectedMajor.children.isNotEmpty) ...[
              const SizedBox(height: 12),
              _subChips(selectedMajor),
            ],
            const SizedBox(height: 16),
            _accountChips(accounts),
            const SizedBox(height: 20),
            Text('周期', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                for (final (code, label) in _periodTypes)
                  ButtonSegment(value: code, label: Text(label)),
              ],
              selected: {_periodType},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _periodType = selection.first),
            ),
            const SizedBox(height: 12),
            _periodEditor(),
            const SizedBox(height: 20),
            _dateTile(
              label: '起始日期',
              value: formatDate(_startDate),
              initial: _startDate,
              // 允许从过去开始：错过的那几天由 7 天补记窗口捞回来（§4.2.3）
              firstDate: DateTime(DateTime.now().year - 5),
              lastDate: DateTime(DateTime.now().year + 5),
              onPicked: (picked) => setState(() {
                _startDate = picked;
                // 原来那份截止日期会落到起始日之前，留着它就是一句后端会拒的话
                final end = _endDate;
                if (end != null && end.isBefore(picked)) _endDate = null;
              }),
            ),
            _dateTile(
              label: '截止日期',
              value: _endDate == null ? '不限' : formatDate(_endDate!),
              initial: _endDate ?? _startDate,
              firstDate: _startDate,
              lastDate: DateTime(DateTime.now().year + 10),
              onPicked: (picked) => setState(() => _endDate = picked),
              onClear: _endDate == null
                  ? null
                  : () => setState(() => _endDate = null),
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
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'\d*\.?\d{0,2}')),
    ],
    textAlign: TextAlign.right,
    style: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    decoration: const InputDecoration(
      labelText: '每次金额',
      prefixIcon: Icon(Icons.paid_outlined),
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

  Widget _periodEditor() => switch (_periodType) {
    'DAILY' => TextFormField(
      controller: _interval,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: '每隔几天',
        suffixText: '天',
        helperText: '1 表示每天，7 表示每周同一天',
      ),
    ),
    'WEEKLY' => _chipField(
      label: '星期几',
      children: [
        for (var day = 1; day <= 7; day++)
          _toggleChip(
            label: _weekdayLabels[day - 1],
            selected: _weekdays.contains(day),
            onSelected: () => _toggleIn(_weekdays, day),
          ),
      ],
    ),
    'MONTHLY' => _chipField(
      label: '每月哪几天',
      children: [
        for (var day = 1; day <= 31; day++)
          _toggleChip(
            label: '$day',
            selected: _daysOfMonth.contains(day),
            onSelected: () => _toggleIn(_daysOfMonth, day),
          ),
      ],
    ),
    'YEARLY' => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chipField(
          label: '哪个月',
          children: [
            for (var month = 1; month <= 12; month++)
              _toggleChip(
                label: '$month 月',
                selected: _month == month,
                onSelected: () => setState(() => _month = month),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _chipField(
          label: '那个月的哪几天',
          children: [
            for (var day = 1; day <= 31; day++)
              _toggleChip(
                label: '$day',
                selected: _daysOfMonth.contains(day),
                onSelected: () => _toggleIn(_daysOfMonth, day),
              ),
          ],
        ),
      ],
    ),
    _ => const SizedBox.shrink(),
  };

  Widget _chipField({required String label, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: children),
      ],
    );
  }

  Widget _toggleChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }

  void _toggleIn(Set<int> target, int value) {
    setState(() {
      if (!target.remove(value)) target.add(value);
    });
  }

  Widget _dateTile({
    required String label,
    required String value,
    required DateTime initial,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onPicked,
    VoidCallback? onClear,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          if (onClear != null)
            IconButton(
              tooltip: '改为不限',
              icon: const Icon(Icons.clear, size: 20),
              onPressed: onClear,
            ),
        ],
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _clamp(initial, firstDate, lastDate),
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  Future<void> _submit() async {
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
    final periodError = _periodError();
    if (periodError != null) {
      showSnackBar(context, periodError);
      return;
    }

    final draft = RecurringRuleDraft(
      name: _name.text.trim(),
      amount: _amount.text.trim(),
      categoryId: _majorId!,
      subCategoryId: _subId,
      accountId: accountId,
      periodType: _periodType,
      periodValue: _periodValue(),
      startDate: _startDate,
      endDate: _endDate,
    );

    setState(() => _saving = true);
    final notifier = ref.read(recurringRuleViewModelProvider.notifier);
    final error = await (widget.isEdit
        ? notifier.save(widget.id!, draft)
        : notifier.create(draft));
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showSnackBar(context, error);
      return;
    }
    context.pop();
  }
}

const List<String> _weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

/// `showDatePicker` 要求 `initialDate` 落在可选区间内，否则它自己断言失败。
/// 截止日期那一栏的 `firstDate` 跟着起始日走，起始日改晚之后旧值就在区间外面了。
DateTime _clamp(DateTime value, DateTime first, DateTime last) {
  if (value.isBefore(first)) return first;
  if (value.isAfter(last)) return last;
  return value;
}

Category? _firstById(List<Category> categories, int? id) {
  if (id == null) return null;
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
}
