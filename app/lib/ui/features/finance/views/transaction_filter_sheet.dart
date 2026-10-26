import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/category.dart';
import '../../../../data/models/flow_type.dart';
import '../../../../data/models/member.dart';
import '../../../../data/models/payment_account.dart';
import '../../../core/amount_input_formatter.dart';
import '../../../core/date_format.dart';
import '../../family/view_models/family_view_model.dart';
import '../view_models/category_view_model.dart';
import '../view_models/payment_account_view_model.dart';
import '../view_models/transaction_list_view_model.dart';

/// 打开筛选面板。回 `null` 表示取消，界面上的条件保持原样；
/// 回一个 `TransactionFilter` 由调用方 `apply`，面板自己不动列表状态。
Future<TransactionFilter?> showTransactionFilterSheet(
  BuildContext context,
  TransactionFilter current,
) => showModalBottomSheet<TransactionFilter>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _FilterSheet(initial: current),
);

/// 面板里改的是本地副本，点「查看结果」才交出去。
/// 每选一项就发一次请求的话，挑三个条件就是三次翻页，中间的页码还会互相打断。
class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial});

  final TransactionFilter initial;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late TransactionFilter _draft = widget.initial;
  late final TextEditingController _keyword = TextEditingController(
    text: widget.initial.keyword ?? '',
  );
  late final TextEditingController _amount = TextEditingController(
    text: widget.initial.amount ?? '',
  );

  @override
  void dispose() {
    _keyword.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 大类按收支类型各取一棵树；「不限」时两棵一并列出，标签带上是支出还是收入
    final categories =
        ref.watch(categoryViewModelProvider).value?.categories ??
        const <Category>[];
    final accounts =
        ref.watch(paymentAccountViewModelProvider).value?.accounts ??
        const <PaymentAccount>[];
    final members =
        ref.watch(familyViewModelProvider).value?.members ?? const <Member>[];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _header(context),
            _section('收支类型'),
            Wrap(
              spacing: 8,
              children: [
                _choice(
                  label: '不限',
                  selected: _draft.type == null,
                  onTap: () => setState(() => _draft = _resetTypes(_draft)),
                ),
                for (final entry in const {
                  '支出': FlowType.expense,
                  '收入': FlowType.income,
                }.entries)
                  _choice(
                    label: entry.key,
                    selected: _draft.type == entry.value,
                    onTap: () => setState(() {
                      // 类别是跟着收支类型走的，换了类型再留着旧类别就成了「收入里筛支出类别」
                      _draft = _draft.copyWith(
                        type: entry.value,
                        categoryId: null,
                        subCategoryId: null,
                      );
                    }),
                  ),
              ],
            ),
            _section('时间区间'),
            Row(
              children: [
                Expanded(
                  child: _dateButton(
                    label: '开始',
                    value: _draft.startDate,
                    // 两边互钳：开始不许晚于已选的结束，结束不许早于已选的开始，
                    // 倒挂区间在选择器层面就发生不了（与统计页同一口径）。
                    maxDate: _draft.endDate,
                    onPick: (date) => setState(
                      () => _draft = _draft.copyWith(startDate: date),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _dateButton(
                    label: '结束',
                    value: _draft.endDate,
                    minDate: _draft.startDate,
                    onPick: (date) =>
                        setState(() => _draft = _draft.copyWith(endDate: date)),
                  ),
                ),
                if (_draft.startDate != null || _draft.endDate != null)
                  TextButton(
                    onPressed: () => setState(
                      () => _draft = _draft.copyWith(
                        startDate: null,
                        endDate: null,
                      ),
                    ),
                    child: const Text('清除'),
                  ),
              ],
            ),
            _section('大类'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final major in _majorsFor(categories, _draft.type))
                  _choice(
                    label: _draft.type == null
                        ? '${major.name}·${major.type == FlowType.expense ? '支' : '收'}'
                        : major.name,
                    selected: _draft.categoryId == major.id,
                    onTap: () => setState(() {
                      final picked = _draft.categoryId == major.id;
                      _draft = _draft.copyWith(
                        categoryId: picked ? null : major.id,
                        subCategoryId: null,
                      );
                    }),
                  ),
              ],
            ),
            if (_selectedMajor(categories) case final major?) ...[
              _section('小类'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sub in major.children)
                    _choice(
                      label: sub.name,
                      selected: _draft.subCategoryId == sub.id,
                      onTap: () => setState(() {
                        final picked = _draft.subCategoryId == sub.id;
                        _draft = _draft.copyWith(
                          subCategoryId: picked ? null : sub.id,
                        );
                      }),
                    ),
                ],
              ),
            ],
            _section('支付方式'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final account in accounts)
                  _choice(
                    label: account.name,
                    selected: _draft.accountId == account.id,
                    onTap: () => setState(() {
                      final picked = _draft.accountId == account.id;
                      _draft = _draft.copyWith(
                        accountId: picked ? null : account.id,
                      );
                    }),
                  ),
              ],
            ),
            _section('记录人'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final member in members)
                  _choice(
                    label: member.nickname,
                    selected: _draft.createdBy == member.userId,
                    onTap: () => setState(() {
                      final picked = _draft.createdBy == member.userId;
                      _draft = _draft.copyWith(
                        createdBy: picked ? null : member.userId,
                      );
                    }),
                  ),
              ],
            ),
            _section('备注关键字'),
            TextField(
              controller: _keyword,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: '例如「打车」',
                isDense: true,
              ),
            ),
            _section('按金额精确查找'),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              // 金额条件是原样发后端的字符串：整串判形（一个小数点 + 两位小数 + 整数位上限），
              // 与记一笔的金额框同一套（复扫 P3：旧 allow 正则拦不住 "1.2.3" 这种输入）
              inputFormatters: [AmountInputFormatter()],
              decoration: const InputDecoration(
                hintText: '128.50',
                isDense: true,
                prefixText: '¥ ',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Text('筛选', style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        TextButton(
          onPressed: () => setState(() {
            _draft = const TransactionFilter();
            _keyword.clear();
            _amount.clear();
          }),
          child: const Text('重置'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _draft.copyWith(
              keyword: _keyword.text.trim().isEmpty
                  ? null
                  : _keyword.text.trim(),
              amount: _amount.text.trim().isEmpty ? null : _amount.text.trim(),
            ),
          ),
          child: const Text('查看结果'),
        ),
      ],
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _choice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
  );

  Widget _dateButton({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPick,
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    final today = DateTime.now();
    final first = minDate ?? DateTime(today.year - 5);
    final last = maxDate ?? today;
    // value 可能落在新的边界外（另一边刚改过），钳进去再进选择器，
    // 否则 initialDate 越界会让 showDatePicker 断言失败。
    var initial = value ?? today;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: first,
          lastDate: last,
          helpText: '选择$label日期',
        );
        if (picked != null) onPick(picked);
      },
      child: Text(value == null ? label : formatDate(value)),
    );
  }

  Category? _selectedMajor(List<Category> categories) {
    if (_draft.categoryId == null) return null;
    for (final major in _majorsFor(categories, _draft.type)) {
      if (major.id == _draft.categoryId) return major;
    }
    return null;
  }
}

/// 该收支类型下可筛的大类。类型留空时两棵树一并给出，标签上带「支/收」区分。
/// 这里刻意不过滤停用项——停用的大类下照样有历史流水，筛不出来就等于查不了。
List<Category> _majorsFor(List<Category> categories, String? type) => [
  for (final major in categories)
    if (type == null || major.type == type) major,
];

TransactionFilter _resetTypes(TransactionFilter filter) =>
    filter.copyWith(type: null, categoryId: null, subCategoryId: null);
