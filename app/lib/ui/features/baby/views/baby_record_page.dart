import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/baby.dart';
import '../../../../data/models/baby_record.dart';
import '../../../../data/repositories/baby_record_repository.dart';
import '../../../../data/services/network_status.dart';
import '../../../core/app_widgets.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../../../core/money.dart';
import '../../../core/offline_banner.dart';
import '../baby_copy.dart';
import '../view_models/baby_list_view_model.dart';
import '../view_models/baby_record_view_model.dart';

const String _milestonesSegment = 'milestones';
const String _medicalsSegment = 'medicals';

/// 费用列是 `DECIMAL(12,2)`，多出来的小数位由 MySQL 悄悄四舍五入，界面上看到的与库里存的对不上，
/// 所以形态在这一格就挡。**只挡形态不挡范围**：非负由服务端的 `@DecimalMin("0")` 出文案。
final RegExp _twoDecimals = RegExp(r'^\d+(?:\.\d{1,2})?$');
final List<TextInputFormatter> _twoDecimalsInput = [
  FilteringTextInputFormatter.allow(RegExp(r'\d*\.?\d{0,2}')),
];

/// §4.4.5 的里程碑与就诊记录。两套形状相同的 CRUD 合成一屏两分段：入参 `babyId` 有值时
/// 只看这一个宝宝（从 ① 的宝宝卡片进来就是这条路径）。
///
/// 列表是**本地** `where`（照身高体重那一页）：视图模型装的是全量那份，而统计页顶层的
/// 里程碑时间轴读的正是全量。**`babyId` 可空**，手敲一条不带参数的 URL 进来不该白屏——
/// 那一份每行重复宝宝名，两张表单的宝宝一栏也退成选择器。
///
/// 两类记录都可编辑、可删除（§4.4.5），没有归档语义，所以这一页没有「归档」入口，
/// 删除直接走 §5.2 的二次确认。
class BabyRecordPage extends ConsumerStatefulWidget {
  const BabyRecordPage({this.babyId, super.key});

  /// null = 全部宝宝。由路由从 `?babyId=` 解出来。
  final int? babyId;

  @override
  ConsumerState<BabyRecordPage> createState() => _BabyRecordPageState();
}

class _BabyRecordPageState extends ConsumerState<BabyRecordPage> {
  String _segment = _milestonesSegment;

  @override
  Widget build(BuildContext context) {
    final babies = ref.watch(babyListViewModelProvider).value ?? const <Baby>[];
    final offline = ref.watch(networkStatusProvider) == NetworkStatus.offline;

    // 名字从档案列表里查，记录上不留快照：改完名字回来要看到新的那个。
    String? nameOf(int id) {
      for (final baby in babies) {
        if (baby.id == id) return baby.name;
      }
      return null;
    }

    final subject = widget.babyId == null ? null : nameOf(widget.babyId!);
    final milestones = _segment == _milestonesSegment;

    return Scaffold(
      appBar: AppBar(
        title: Text(subject == null ? '里程碑与就诊' : '$subject 的里程碑与就诊'),
        actions: [
          IconButton(
            tooltip: milestones ? '记一条里程碑' : '记一次就诊',
            icon: const Icon(Icons.add),
            // 两个分段的「+」不是同一件事：这一页没有第三段，按钮跟着当前分段走。
            onPressed: milestones ? _addMilestone : _addMedical,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: _milestonesSegment, label: Text('里程碑')),
                  ButtonSegment(value: _medicalsSegment, label: Text('就诊')),
                ],
                selected: {_segment},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    setState(() => _segment = selection.first),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (offline) const OfflineBanner(),
          Expanded(
            child: milestones
                ? _MilestoneSegment(
                    babyId: widget.babyId,
                    nameOf: nameOf,
                    onEdit: _openMilestoneForm,
                    onDelete: _deleteMilestone,
                  )
                : _MedicalSegment(
                    babyId: widget.babyId,
                    nameOf: nameOf,
                    onEdit: _openMedicalForm,
                    onDelete: _deleteMedical,
                  ),
          ),
        ],
      ),
    );
  }

  /// 表单里的宝宝选择器只列在册的：既有记录挂的宝宝可能已经归档，归档的宝宝不在选择器里，
  /// 做成可改就等于「把这条记录挂到一个选不出来的宝宝身上」。
  List<Baby> _activeBabies() => [
    for (final baby
        in ref.read(babyListViewModelProvider).value ?? const <Baby>[])
      if (!baby.archived) baby,
  ];

  /// 新增时先在页面上挡一道：表单里那个宝宝选择器此刻是空的，进去只能对着一格选不出东西。
  /// 编辑不作这个要求——既有记录挂的宝宝可能已归档，那时家里一个在册宝宝都没有，
  /// 而改动一条老记录与「有没有在册宝宝」无关。
  void _addMilestone() {
    if (_activeBabies().isEmpty) {
      showSnackBar(context, '还没有在册的宝宝，先建档再记录里程碑');
      return;
    }
    _openMilestoneForm(null);
  }

  void _addMedical() {
    if (_activeBabies().isEmpty) {
      showSnackBar(context, '还没有在册的宝宝，先建档再记录就诊');
      return;
    }
    _openMedicalForm(null);
  }

  /// 新增与编辑同一个表单，靠 `original` 有没有值区分。表单做成底部弹层而不是第八、第九条路由：
  /// 它的字段全是这一页已有的，单开一页只会让「保存后回哪一屏」多一个要维护的答案。
  Future<void> _openMilestoneForm(BabyMilestone? original) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _MilestoneForm(original: original, initialBabyId: widget.babyId),
    );
    if (saved == true && mounted) showSnackBar(context, '已保存');
  }

  Future<void> _openMedicalForm(BabyMedical? original) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _MedicalForm(original: original, initialBabyId: widget.babyId),
    );
    if (saved == true && mounted) showSnackBar(context, '已保存');
  }

  /// 里程碑是统计页那条时间轴的原料，删掉它那边跟着少一条，确认框把这件事说出来。
  Future<void> _deleteMilestone(BabyMilestone row) async {
    final confirmed = await confirmAction(
      context,
      title: '删除「${row.title}」这条里程碑？',
      message: '统计页的里程碑时间轴会跟着少一条。删除后无法恢复。',
      confirmLabel: '删除',
    );
    if (!confirmed) return;
    final error = await ref
        .read(babyMilestoneViewModelProvider.notifier)
        .remove(row.id);
    if (error != null && mounted) showSnackBar(context, error);
  }

  /// 就诊记录谁都不读（§4.4.5：费用不同步生成流水），删它只影响这一屏。
  Future<void> _deleteMedical(BabyMedical row) async {
    final confirmed = await confirmAction(
      context,
      title: '删除 ${formatDate(row.visitDate)} 这条就诊记录？',
      message: '它只是留档，删掉不影响记账。删除后无法恢复。',
      confirmLabel: '删除',
    );
    if (!confirmed) return;
    final error = await ref
        .read(babyMedicalViewModelProvider.notifier)
        .remove(row.id);
    if (error != null && mounted) showSnackBar(context, error);
  }
}

/// 分段一：里程碑。时间轴按 `occurDate` 升序（服务端 `occur_date ASC, id ASC`，§4.4.5），
/// 前端不重排——统计页那条同序的时间轴与这一屏读的是同一份顺序。
class _MilestoneSegment extends ConsumerWidget {
  const _MilestoneSegment({
    required this.babyId,
    required this.nameOf,
    required this.onEdit,
    required this.onDelete,
  });

  final int? babyId;
  final String? Function(int) nameOf;
  final void Function(BabyMilestone?) onEdit;
  final void Function(BabyMilestone) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(babyMilestoneViewModelProvider);
    final rows = [
      for (final row in records.value ?? const <BabyMilestone>[])
        if (babyId == null || row.babyId == babyId) row,
    ];

    return records.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Failure(
        message: errorCopy(error),
        onRetry: () => ref.invalidate(babyMilestoneViewModelProvider),
      ),
      data: (_) => rows.isEmpty
          ? const _Empty(
              icon: Icons.emoji_events_outlined,
              title: '还没有里程碑',
              hint: '第一次抬头、第一颗牙——记下来，统计页的时间轴就有内容',
            )
          : ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              children: [
                for (var i = 0; i < rows.length; i++)
                  _MilestoneTile(
                    row: rows[i],
                    isLast: i == rows.length - 1,
                    // 「全部宝宝」那一份才逐行重复宝宝名。
                    babyName: babyId == null ? nameOf(rows[i].babyId) : null,
                    onEdit: () => onEdit(rows[i]),
                    onDelete: () => onDelete(rows[i]),
                  ),
              ],
            ),
    );
  }
}

/// 时间轴的一行。竖线串起节点，与猫咪统计页那条同形；差异只在右端多一格菜单——
/// `PATCH` 与 `DELETE` 的入口都在这里（§4.4.5）。
class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.row,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
    this.babyName,
  });

  final BabyMilestone row;
  final bool isLast;
  final String? babyName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // `IntrinsicHeight` + `stretch` 是必需的：`Column` 里的 `Expanded` 要一个有界高度才存在，
    // 而 `Row` 的自然高度由右边那块文字决定。换成固定高度会在说明换行时挤掉一行。
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            // 圆点与竖线都不靠 margin 对齐：`Column` 默认 `center`，16 宽盒子里 8 的点
            // 和 2 的线各自居中，中心都在 x=8。
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      babyName == null ? row.title : '$babyName · ${row.title}',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDate(row.occurDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (row.description != null)
                      Text(row.description!, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('编辑')),
              PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
          ),
        ],
      ),
    );
  }
}

/// 分段二：就诊。按 `visitDate` 倒序（服务端 `visit_date DESC, id DESC`，就诊是回看），
/// 前端不重排。
class _MedicalSegment extends ConsumerWidget {
  const _MedicalSegment({
    required this.babyId,
    required this.nameOf,
    required this.onEdit,
    required this.onDelete,
  });

  final int? babyId;
  final String? Function(int) nameOf;
  final void Function(BabyMedical?) onEdit;
  final void Function(BabyMedical) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(babyMedicalViewModelProvider);
    final rows = [
      for (final row in records.value ?? const <BabyMedical>[])
        if (babyId == null || row.babyId == babyId) row,
    ];

    return records.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Failure(
        message: errorCopy(error),
        onRetry: () => ref.invalidate(babyMedicalViewModelProvider),
      ),
      data: (_) => rows.isEmpty
          ? const _Empty(
              icon: Icons.local_hospital_outlined,
              title: '还没有就诊记录',
              hint: '记一次就诊留个档；费用只是一条记录，不会自动生成流水',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // 就诊记录每行一张独立小卡（问题单：卡片间有间距）。
                for (final row in rows)
                  RowCard(
                    child: _MedicalTile(
                      row: row,
                      babyName: babyId == null ? nameOf(row.babyId) : null,
                      onEdit: () => onEdit(row),
                      onDelete: () => onDelete(row),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// 行内那几行是可变的（诊断、用药、费用、备注都选填），所以不用 `ListTile`：
/// 它按行数预留空间，多一行就报 RenderFlex overflow。
class _MedicalTile extends StatelessWidget {
  const _MedicalTile({
    required this.row,
    required this.onEdit,
    required this.onDelete,
    this.babyName,
  });

  final BabyMedical row;
  final String? babyName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final where = [
      if (row.hospital != null) row.hospital!,
      if (row.department != null) row.department!,
    ];
    final cost = row.costAmount;

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    babyName == null
                        ? formatDate(row.visitDate)
                        : '$babyName · ${formatDate(row.visitDate)}',
                    style: theme.textTheme.titleSmall,
                  ),
                  if (where.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(where.join(' · '), style: theme.textTheme.bodyMedium),
                  ],
                  if (row.diagnosis != null)
                    Text(
                      '诊断 ${row.diagnosis!}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (row.medicine != null)
                    Text(
                      '用药 ${row.medicine!}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (cost != null)
                    Text('费用 ${formatYuan(cost)}', style: muted),
                  if (row.remark != null) Text(row.remark!, style: muted),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('编辑')),
                PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 里程碑的表单。**标题既有常用项又有自由输入**（§1.4 第 21 条）：内置项不是字典，
/// 点一下就填进下面那个输入框，两者写进库的是同一个 `title`，库里没有区别。
class _MilestoneForm extends ConsumerStatefulWidget {
  const _MilestoneForm({this.original, this.initialBabyId});

  final BabyMilestone? original;
  final int? initialBabyId;

  @override
  ConsumerState<_MilestoneForm> createState() => _MilestoneFormState();
}

class _MilestoneFormState extends ConsumerState<_MilestoneForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();

  int? _babyId;
  DateTime? _occurDate;

  /// 发生日期是必填，但它是 `ListTile` 不是 `TextFormField`，`Form.validate()` 管不到它。
  String? _dateError;
  String? _error;
  bool _saving = false;

  bool get _isEdit => widget.original != null;

  @override
  void initState() {
    super.initState();
    // 常用项的选中态跟着输入框里的字走，字一改就得重算。
    _title.addListener(_onTitleChanged);
    final original = widget.original;
    // 默认选中第一个在册宝宝：新增表单省一次手选。
    _babyId =
        original?.babyId ??
        widget.initialBabyId ??
        _firstActiveBabyId(
          ref.read(babyListViewModelProvider).value ?? const <Baby>[],
        );
    _occurDate = original?.occurDate;
    if (original != null) {
      _title.text = original.title;
      _description.text = original.description ?? '';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _onTitleChanged() => setState(() {});

  Future<void> _pickOccurDate() async {
    final today = DateTime.now();
    final earliest = _birthDateOf(
      ref.read(babyListViewModelProvider).value ?? const <Baby>[],
      _babyId,
    );
    final current = _occurDate;

    // 上界是今天（§4.4.5：不可晚于今天），服务端也会拒，这一格只是让它更好点。
    // 时钟回拨/异常数据会让 earliest 晚于今天，那时下界钳完又越过上界——先收窄 firstDate
    // 再按 [first, today] 夹 initial，两个参数越界都会让 showDatePicker 断言失败。
    final first = earliest.isAfter(today) ? today : earliest;
    var initial = current ?? today;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(today)) initial = today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: today,
    );
    if (picked == null) return;
    setState(() {
      _occurDate = picked;
      _dateError = null;
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;

    final occurDate = _occurDate;
    final babyId = _babyId;
    setState(() {
      _dateError = occurDate == null ? '请选择发生日期' : null;
    });
    if (!valid || occurDate == null || babyId == null) return;

    final draft = MilestoneDraft(
      babyId: babyId,
      occurDate: occurDate,
      title: _title.text.trim(),
      description: _optional(_description.text),
    );
    setState(() => _saving = true);

    final notifier = ref.read(babyMilestoneViewModelProvider.notifier);
    final error = _isEdit
        ? await notifier.save(widget.original!.id, draft)
        : await notifier.create(draft);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    // 成功就关掉弹层，提示由页面那一层发——弹层里的 snackbar 会挂在模态栅栏底下。
    if (error == null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = ref.watch(canSubmitProvider);
    final babies = [
      for (final baby
          in ref.watch(babyListViewModelProvider).value ?? const <Baby>[])
        if (!baby.archived) baby,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题固定在滚动区外：键盘弹出、表单内容自动滚动到底部的输入框时，
            // 标题不会跟着滚出、也不会被挤到弹层边界之外。
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                _isEdit ? '编辑里程碑' : '记一条里程碑',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  if (_isEdit)
                    ..._readOnlyBaby()
                  else
                    DropdownButtonFormField<int>(
                      initialValue: _babyId,
                      decoration: const InputDecoration(labelText: '宝宝'),
                      items: [
                        for (final baby in babies)
                          DropdownMenuItem(
                            value: baby.id,
                            child: Text(baby.name),
                          ),
                      ],
                      onChanged: (value) => setState(() => _babyId = value),
                      validator: (value) => value == null ? '请选择宝宝' : null,
                    ),
                  const SizedBox(height: 16),
                  const _FieldLabel('发生日期'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    trailing: Text(
                      _occurDate == null ? '请选择' : formatDate(_occurDate!),
                      style: theme.textTheme.titleMedium,
                    ),
                    onTap: _pickOccurDate,
                  ),
                  _ErrorLine(text: _dateError),
                  const SizedBox(height: 16),
                  const _FieldLabel('里程碑标题'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final preset in milestonePresets)
                        ChoiceChip(
                          label: Text(preset),
                          selected: _title.text.trim() == preset,
                          onSelected: (_) =>
                              setState(() => _title.text = preset),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _title,
                    maxLength: 30,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      hintText: '也可以自己写一个',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return '请填写标题';
                      return text.length > 30 ? '标题最多 30 个字' : null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _description,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: '说明（选填）',
                      hintText: '当时的样子、在哪里、谁在旁边',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) _ErrorLine(text: _error!),
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
          ],
        ),
      ),
    );
  }

  /// 编辑态的宝宝只读，理由同身高体重那一页：既有记录挂的宝宝可能已归档，
  /// 归档的宝宝不在上面的选择器里。
  List<Widget> _readOnlyBaby() {
    final babyId = widget.original?.babyId;
    var label = '加载中…';
    if (babyId != null) {
      for (final baby
          in ref.watch(babyListViewModelProvider).value ?? const <Baby>[]) {
        if (baby.id == babyId) {
          label = baby.archived ? '${baby.name}（已归档）' : baby.name;
          break;
        }
      }
    }

    return [
      const _FieldLabel('宝宝'),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.child_care_outlined),
        trailing: Text(label, style: Theme.of(context).textTheme.titleMedium),
      ),
    ];
  }
}

/// 就诊的表单。除宝宝与就诊日期外全是选填——带一次孩子看病未必记得住科室。
class _MedicalForm extends ConsumerStatefulWidget {
  const _MedicalForm({this.original, this.initialBabyId});

  final BabyMedical? original;
  final int? initialBabyId;

  @override
  ConsumerState<_MedicalForm> createState() => _MedicalFormState();
}

class _MedicalFormState extends ConsumerState<_MedicalForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _hospital = TextEditingController();
  final TextEditingController _department = TextEditingController();
  final TextEditingController _diagnosis = TextEditingController();
  final TextEditingController _medicine = TextEditingController();
  final TextEditingController _cost = TextEditingController();
  final TextEditingController _remark = TextEditingController();

  int? _babyId;
  DateTime? _visitDate;
  String? _dateError;
  String? _error;
  bool _saving = false;

  bool get _isEdit => widget.original != null;

  @override
  void initState() {
    super.initState();
    final original = widget.original;
    // 默认选中第一个在册宝宝（问题单 5）：新增表单省一次手选。
    _babyId =
        original?.babyId ??
        widget.initialBabyId ??
        _firstActiveBabyId(
          ref.read(babyListViewModelProvider).value ?? const <Baby>[],
        );
    _visitDate = original?.visitDate;
    if (original != null) {
      _hospital.text = original.hospital ?? '';
      _department.text = original.department ?? '';
      _diagnosis.text = original.diagnosis ?? '';
      _medicine.text = original.medicine ?? '';
      _cost.text = original.costAmount ?? '';
      _remark.text = original.remark ?? '';
    }
  }

  @override
  void dispose() {
    _hospital.dispose();
    _department.dispose();
    _diagnosis.dispose();
    _medicine.dispose();
    _cost.dispose();
    _remark.dispose();
    super.dispose();
  }

  Future<void> _pickVisitDate() async {
    final today = DateTime.now();
    final earliest = _birthDateOf(
      ref.read(babyListViewModelProvider).value ?? const <Baby>[],
      _babyId,
    );
    final current = _visitDate;

    // 与 _pickOccurDate 同一处修复：先收窄 firstDate 再按 [first, today] 夹 initial，
    // 时钟回拨时两个参数都不越界。
    final first = earliest.isAfter(today) ? today : earliest;
    var initial = current ?? today;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(today)) initial = today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: today,
    );
    if (picked == null) return;
    setState(() {
      _visitDate = picked;
      _dateError = null;
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;

    final visitDate = _visitDate;
    final babyId = _babyId;
    setState(() {
      _dateError = visitDate == null ? '请选择就诊日期' : null;
    });
    if (!valid || visitDate == null || babyId == null) return;

    final draft = MedicalDraft(
      babyId: babyId,
      visitDate: visitDate,
      hospital: _optional(_hospital.text),
      department: _optional(_department.text),
      diagnosis: _optional(_diagnosis.text),
      medicine: _optional(_medicine.text),
      costAmount: _optional(_cost.text),
      remark: _optional(_remark.text),
    );
    setState(() => _saving = true);

    final notifier = ref.read(babyMedicalViewModelProvider.notifier);
    final error = _isEdit
        ? await notifier.save(widget.original!.id, draft)
        : await notifier.create(draft);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = ref.watch(canSubmitProvider);
    final babies = [
      for (final baby
          in ref.watch(babyListViewModelProvider).value ?? const <Baby>[])
        if (!baby.archived) baby,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题固定在滚动区外（问题单 11）：键盘弹出时标题不跟着滚出弹层。
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                _isEdit ? '编辑就诊记录' : '记一次就诊',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  if (_isEdit)
                    ..._readOnlyBaby()
                  else
                    DropdownButtonFormField<int>(
                      initialValue: _babyId,
                      decoration: const InputDecoration(labelText: '宝宝'),
                      items: [
                        for (final baby in babies)
                          DropdownMenuItem(
                            value: baby.id,
                            child: Text(baby.name),
                          ),
                      ],
                      onChanged: (value) => setState(() => _babyId = value),
                      validator: (value) => value == null ? '请选择宝宝' : null,
                    ),
                  const SizedBox(height: 16),
                  const _FieldLabel('就诊日期'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    trailing: Text(
                      _visitDate == null ? '请选择' : formatDate(_visitDate!),
                      style: theme.textTheme.titleMedium,
                    ),
                    onTap: _pickVisitDate,
                  ),
                  _ErrorLine(text: _dateError),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _hospital,
                    maxLength: 50,
                    decoration: const InputDecoration(labelText: '医院（选填）'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _department,
                    maxLength: 30,
                    decoration: const InputDecoration(labelText: '科室（选填）'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _diagnosis,
                    maxLines: 2,
                    maxLength: 200,
                    decoration: const InputDecoration(labelText: '诊断（选填）'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _medicine,
                    maxLines: 2,
                    maxLength: 200,
                    decoration: const InputDecoration(labelText: '用药（选填）'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cost,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _twoDecimalsInput,
                    decoration: const InputDecoration(
                      labelText: '费用（元，选填）',
                      hintText: '320.00',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      return _twoDecimals.hasMatch(text) ? null : '费用最多两位小数';
                    },
                  ),
                  // 这一句是这一页最容易产生的那个误会：以为记了就诊就等于记了一笔账，
                  // 月底对账时发现少了一笔（§4.4.5：费用只是记录，不同步生成流水）。
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '只作记录，不会自动生成流水',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _remark,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(labelText: '备注（选填）'),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) _ErrorLine(text: _error!),
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
          ],
        ),
      ),
    );
  }

  List<Widget> _readOnlyBaby() {
    final babyId = widget.original?.babyId;
    var label = '加载中…';
    if (babyId != null) {
      for (final baby
          in ref.watch(babyListViewModelProvider).value ?? const <Baby>[]) {
        if (baby.id == babyId) {
          label = baby.archived ? '${baby.name}（已归档）' : baby.name;
          break;
        }
      }
    }

    return [
      const _FieldLabel('宝宝'),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.child_care_outlined),
        trailing: Text(label, style: Theme.of(context).textTheme.titleMedium),
      ),
    ];
  }
}

String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

/// 第一个在册宝宝（问题单 5）：新增表单默认选中它。档案列表在弹层打开前已被页面读过，
/// 所以在 initState 里同步读一次就能拿到；一个都没有时回 null，表单照旧要求手选。
int? _firstActiveBabyId(List<Baby> babies) {
  for (final baby in babies) {
    if (!baby.archived) return baby.id;
  }
  return null;
}

/// 日期下界取所选宝宝的出生日期；还没选出宝宝时退成 1990——与身高体重那一页同一个下界。
DateTime _birthDateOf(List<Baby> babies, int? babyId) {
  for (final baby in babies) {
    if (baby.id == babyId) return baby.birthDate;
  }
  return DateTime(1990);
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.hint});

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

/// 常驻槽位：这一行夹在输入框中间，若在文案出现与消失时把它整段加进、移出 `ListView`
/// 的子项表，它后面的输入框会跟着位移，`FormFieldState` 连校验文案一起被重建。
class _ErrorLine extends StatelessWidget {
  const _ErrorLine({this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final text = this.text;
    if (text == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
