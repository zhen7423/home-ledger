import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/budget.dart';
import '../../../../data/models/budget_progress.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/flow_type.dart';
import '../../../../data/models/member.dart';
import '../../../../data/repositories/budget_repository.dart';
import '../../../../data/services/network_status.dart';
import '../../../core/app_widgets.dart';
import '../../../core/budget_copy.dart';
import '../../../core/error_copy.dart';
import '../../../core/money.dart';
import '../../../core/offline_banner.dart';
import '../../../core/validators.dart';
import '../../family/view_models/family_view_model.dart';
import '../view_models/budget_view_model.dart';
import '../view_models/category_view_model.dart';

/// §4.2.4 的预算管理：三个维度的额度编辑 + 本月进度。
///
/// 保存是**整体替换**，不是一行一行 PATCH（后端先删光再重插，每次保存后 `id` 都会变），
/// 所以这一页攒的只是「这次要交上去的那一份」，底部那颗按钮提交的永远是全部行。
///
/// 三维度全量的进度条只有这一页有（第 19 轮把 §4.2.4 的进度条从统计页挪到了这里），
/// 首页只挂家庭那一条。
class BudgetPage extends ConsumerStatefulWidget {
  const BudgetPage({super.key});

  @override
  ConsumerState<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends ConsumerState<BudgetPage> {
  static const String _familyKey = 'FAMILY';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// 键沿用后端的 `bucket_key` 格式（`FAMILY` / `C:12` / `M:34`），
  /// 「同一个维度只能有一行」在界面上因此是天然成立的，不用另做去重。
  final Set<String> _added = <String>{};
  final Set<String> _removed = <String>{};

  /// 改过、还没提交的额度。没改过的行显示服务端那份。
  final Map<String, String> _edited = <String, String>{};

  /// 本次 build 算出来的待提交清单。底部栏与 `body` 是 `Scaffold` 的两个兄弟参数，
  /// 拿不到彼此的局部变量，所以放字段上；它每次 build 重算，不是一份要维护的状态。
  List<_Row> _draft = const [];

  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(budgetViewModelProvider);
    final canSubmit = ref.watch(canSubmitProvider);
    final progress = ref.watch(budgetProgressViewModelProvider);
    // §4.2.4：三个维度的预算都是支出预算，收入大类设了额度也永远停在 0
    final majors = [
      for (final major
          in ref.watch(categoryViewModelProvider).value?.categories ??
              const <Category>[])
        if (major.type == FlowType.expense) major,
    ];
    final members =
        ref.watch(familyViewModelProvider).value?.members ?? const <Member>[];

    _draft = _rowsOf(budgets.value ?? const <Budget>[], majors, members);
    final categoryRows = [
      for (final row in _draft)
        if (row.scope == 'CATEGORY') row,
    ];
    final memberRows = [
      for (final row in _draft)
        if (row.scope == 'MEMBER') row,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('预算管理')),
      body: budgets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorCopy(error), textAlign: TextAlign.center),
          ),
        ),
        data: (_) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text('本月进度', style: Theme.of(context).textTheme.titleSmall),
              _progressBlock(progress),
              const SizedBox(height: 20),
              Text('设置额度', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              _amountField(_familyRowOf(budgets.value ?? const [])),
              _groupHeader(
                '类别预算',
                onAdd: () => _pickCategory(majors, _usedKeys(categoryRows)),
              ),
              for (final row in categoryRows)
                _amountField(row, deletable: true),
              _groupHeader(
                '成员预算',
                onAdd: () => _pickMember(members, _usedKeys(memberRows)),
              ),
              for (final row in memberRows) _amountField(row, deletable: true),
              const SizedBox(height: 12),
              Text(
                '留空表示这一项不设预算。类别按大类统计，小类的花费算进它所属的大类；'
                '额度按自然月计，每月 1 日重新从 0 开始。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 通栏。bottomNavigationBar 这个槽拿到的是宽松宽度约束，Material 按钮在宽松约束下
              // 按内容宽度自适应，不包这一层就是一颗贴着左边缘的小胶囊。
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  // 列表还没拉回来时不让人点：那时 `_draft` 只有家庭那一行，
                  // 提交上去会把另外两个维度的预算当成被用户删掉了。
                  onPressed: (budgets.hasValue && !_saving && canSubmit)
                      ? _save
                      : null,
                  child: submitButtonText(saving: _saving),
                ),
              ),
              if (!canSubmit) const OfflineSubmitHint(),
            ],
          ),
        ),
      ),
    );
  }

  List<_Row> _rowsOf(
    List<Budget> budgets,
    List<Category> majors,
    List<Member> members,
  ) {
    return [
      _familyRowOf(budgets),
      ..._scopeRows(
        budgets,
        scope: 'CATEGORY',
        prefix: 'C:',
        keyOf: (budget) => 'C:${budget.categoryId}',
        titleOf: (budget) => budgetTitle('CATEGORY', budget.categoryName),
        addedOf: (key) => _addedCategoryRow(key, majors),
      ),
      ..._scopeRows(
        budgets,
        scope: 'MEMBER',
        prefix: 'M:',
        keyOf: (budget) => 'M:${budget.memberUserId}',
        titleOf: (budget) => budgetTitle('MEMBER', budget.memberName),
        addedOf: (key) => _addedMemberRow(key, members),
      ),
    ];
  }

  _Row _familyRowOf(List<Budget> budgets) {
    for (final row in budgets) {
      if (row.scope == 'FAMILY') {
        return _Row(
          key: _familyKey,
          scope: 'FAMILY',
          title: '家庭总预算',
          serverAmount: row.amount,
        );
      }
    }
    // 家庭维度固定一行，没设过就摆一个空着的不设预算
    return const _Row(key: _familyKey, scope: 'FAMILY', title: '家庭总预算');
  }

  /// 服务端已有的行 + 这次新加的行，去掉被划掉的。
  List<_Row> _scopeRows(
    List<Budget> budgets, {
    required String scope,
    required String prefix,
    required String Function(Budget) keyOf,
    required String Function(Budget) titleOf,
    required _Row Function(String key) addedOf,
  }) {
    return [
      for (final row in budgets)
        if (row.scope == scope && !_removed.contains(keyOf(row)))
          _Row(
            key: keyOf(row),
            scope: scope,
            title: titleOf(row),
            serverAmount: row.amount,
            categoryId: row.categoryId,
            memberUserId: row.memberUserId,
          ),
      for (final key in _added)
        if (key.startsWith(prefix)) addedOf(key),
    ];
  }

  _Row _addedCategoryRow(String key, List<Category> majors) {
    final id = int.parse(key.substring(2));
    for (final major in majors) {
      if (major.id == id) {
        return _Row(
          key: key,
          scope: 'CATEGORY',
          title: major.name,
          categoryId: id,
        );
      }
    }
    return _Row(key: key, scope: 'CATEGORY', title: '类别 #$id', categoryId: id);
  }

  _Row _addedMemberRow(String key, List<Member> members) {
    final id = int.parse(key.substring(2));
    for (final member in members) {
      if (member.userId == id) {
        return _Row(
          key: key,
          scope: 'MEMBER',
          title: member.nickname,
          memberUserId: id,
        );
      }
    }
    return _Row(key: key, scope: 'MEMBER', title: '成员 #$id', memberUserId: id);
  }

  String _amountOf(_Row row) => _edited[row.key] ?? row.serverAmount;

  Set<String> _usedKeys(List<_Row> rows) => {for (final row in rows) row.key};

  Widget _groupHeader(String title, {required VoidCallback onAdd}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('添加'),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }

  Widget _amountField(_Row row, {bool deletable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              key: ValueKey(row.key),
              initialValue: _amountOf(row),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: row.title,
                suffixText: '元 / 月',
                isDense: true,
              ),
              validator: _validateAmountOrEmpty,
              // 这里不 setState：值交给 _edited 存着，输入框自己就是显示的那一份
              onChanged: (value) => _edited[row.key] = value,
            ),
          ),
          if (deletable)
            IconButton(
              tooltip: '删掉这一项',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _remove(row),
            ),
        ],
      ),
    );
  }

  /// 空着不报错：留空在这一页就是「这一项不设预算」，交给 `_save` 跳过。
  /// 另写一份而不是改 `validateAmount`，是因为记一笔那边空值必须报。
  String? _validateAmountOrEmpty(String? value) {
    final text = (value ?? '').trim();
    return text.isEmpty ? null : validateAmount(text);
  }

  void _remove(_Row row) {
    setState(() {
      _edited.remove(row.key);
      if (!_added.remove(row.key)) _removed.add(row.key);
    });
  }

  /// 可选的大类**不按启用状态过滤**：后端明确允许给已停用的大类设预算
  /// （`assertMajorCategory` 只核对它是不是大类）——停用只是「以后不再往这里记」，
  /// 而它的历史花费仍然得有人看着。
  Future<void> _pickCategory(List<Category> majors, Set<String> used) {
    final options = [
      for (final major in majors)
        if (!used.contains('C:${major.id}'))
          ('C:${major.id}', major.enabled ? major.name : '${major.name}（已停用）'),
    ];
    return _pickFrom(
      options,
      '添加类别预算',
      (key) => setState(() => _added.add(key)),
    );
  }

  Future<void> _pickMember(List<Member> members, Set<String> used) {
    final options = [
      for (final member in members)
        if (!used.contains('M:${member.userId}'))
          ('M:${member.userId}', member.nickname),
    ];
    return _pickFrom(
      options,
      '添加成员预算',
      (key) => setState(() => _added.add(key)),
    );
  }

  Future<void> _pickFrom(
    List<(String, String)> options,
    String title,
    ValueChanged<String> onPicked,
  ) async {
    if (options.isEmpty) {
      showSnackBar(context, '这个维度都已经设过预算了');
      return;
    }
    final picked = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (key, label) in options)
                  ListTile(
                    title: Text(label),
                    onTap: () => Navigator.pop(dialogContext, key),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final items = <BudgetDraftItem>[];
    for (final row in _draft) {
      final amount = _amountOf(row).trim();
      if (amount.isEmpty) {
        // 刚点「添加」就空着保存：这行不会被交上去，得说清楚，否则用户以为设上了
        if (_added.contains(row.key)) {
          showSnackBar(context, '「${row.title}」的额度还没填，填一个再保存');
          return;
        }
        continue;
      }
      items.add(
        BudgetDraftItem(
          scope: row.scope,
          amount: amount,
          categoryId: row.categoryId,
          memberUserId: row.memberUserId,
        ),
      );
    }

    setState(() => _saving = true);
    final error = await ref.read(budgetViewModelProvider.notifier).save(items);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showSnackBar(context, error);
      return;
    }
    // 已经交上去了，服务端那份就是新的基准，本地这三堆增量没有意义了
    _added.clear();
    _removed.clear();
    _edited.clear();
    showSnackBar(context, '已保存');
  }

  Widget _progressBlock(AsyncValue<List<BudgetProgress>> progress) {
    return progress.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(errorCopy(error)),
      ),
      data: (rows) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (final row in rows) _ProgressTile(row: row),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('还没有设置预算，设了额度的维度才会出现在这里。'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({required this.row});

  final BudgetProgress row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = budgetLevelColor(theme.colorScheme, row.level);
    final remainingCents = toCents(row.remaining);
    final left = remainingCents >= 0
        ? '还剩 ${formatYuan(row.remaining)}'
        : '已超支 ${formatYuan(fromCents(remainingCents.abs()))}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  budgetTitle(row.scope, row.categoryName ?? row.memberName),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                row.level == 'NORMAL' ? left : budgetLevelLabel(row.level),
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (row.usedPercent / 100).clamp(0.0, 1.0),
              color: color,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '已用 ${formatYuan(row.used)} / ${formatYuan(row.amount)}'
            '　${row.usedPercent}%　本月还有 ${row.remainingDays} 天',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 一行待编辑的预算。`serverAmount` 是服务端当前那份，用户没改过就显示它。
class _Row {
  const _Row({
    required this.key,
    required this.scope,
    required this.title,
    this.serverAmount = '',
    this.categoryId,
    this.memberUserId,
  });

  final String key;
  final String scope;
  final String title;
  final String serverAmount;
  final int? categoryId;
  final int? memberUserId;
}
