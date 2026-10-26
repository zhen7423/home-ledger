import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/baby.dart';
import '../../../../data/models/baby_vaccine.dart';
import '../../../../data/repositories/baby_vaccine_plan_repository.dart';
import '../../../../data/repositories/baby_vaccine_record_repository.dart';
import '../../../../data/services/network_status.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../baby_badges.dart';
import '../baby_copy.dart';
import '../paid_vaccine_presets.dart';
import '../view_models/baby_list_view_model.dart';
import '../view_models/baby_vaccine_record_view_model.dart';
import '../view_models/baby_vaccine_view_model.dart';

/// 两个分段的段值。`SegmentedButton` 的段值不能为空（要跟 `selected` 那个非空集合比），
/// 所以用 'PLANS' / 'RECORDS'，而不是把 null 当成「应种清单」。
const String _plansSegment = 'PLANS';
const String _recordsSegment = 'RECORDS';

/// 标记原因的校验：服务端是「必填 + 最多 50 字」（§4.3③：空原因不发请求，直接提示）。
/// 放在弹层的校验器里，请求就发不出去，用户也当场看见是哪一格不对。
String? _reasonError(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return '请填写原因';
  return text.length > 50 ? '原因最多 50 个字' : null;
}

String? _nameOf(List<Baby> babies, int id) {
  for (final baby in babies) {
    if (baby.id == id) return baby.name;
  }
  return null;
}

/// `DONE` 行的实际接种日期：`record_id` 指向那条记录（§4.4.4 的展示列要求显示它）。
/// 记录列表还没回来时退回 null——那一行仍然是「已接种」，只是少一个日期。
DateTime? _vaccinatedOn(List<BabyVaccineRecord> records, BabyVaccinePlan row) {
  final recordId = row.recordId;
  if (recordId == null) return null;
  for (final record in records) {
    if (record.id == recordId) return record.givenDate;
  }
  return null;
}

/// §4.4.4 的疫苗页：应种清单与接种记录两个分段。`?babyId=` 有值就是这一个宝宝的，
/// 缺省是整个家庭（每行带宝宝名）。**不做离线快照**（§5.4），离线时挂横幅。
///
/// 两个分段各读一组 provider，切换**不 invalidate 另一个**：真正的联动在写的那一侧——
/// 接种记录一落库就把对应应种项置 `DONE`，所以录完一条回来，清单那一段要立刻看得见。
class BabyVaccinePage extends ConsumerStatefulWidget {
  const BabyVaccinePage({this.babyId, super.key});

  /// null = 全部。由路由从 `?babyId=` 解出来。
  final int? babyId;

  @override
  ConsumerState<BabyVaccinePage> createState() => _BabyVaccinePageState();
}

class _BabyVaccinePageState extends ConsumerState<BabyVaccinePage> {
  String _segment = _plansSegment;

  @override
  Widget build(BuildContext context) {
    final babies = ref.watch(babyListViewModelProvider).value ?? const <Baby>[];
    final offline = ref.watch(networkStatusProvider) == NetworkStatus.offline;

    final subject = widget.babyId == null
        ? null
        : _nameOf(babies, widget.babyId!);

    return Scaffold(
      appBar: AppBar(
        title: Text(subject == null ? '疫苗' : '$subject 的疫苗'),
        actions: [
          IconButton(
            tooltip: _segment == _plansSegment ? '添加自费疫苗' : '记一次接种',
            icon: const Icon(Icons.add),
            // 两个分段的「+」不是同一件事：清单侧建的是应种项（弹层），记录侧进 ⑧。
            onPressed: _segment == _plansSegment
                ? () => _addManual(babies)
                : () => context.push(RoutePath.babyVaccineRecordEdit),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: _plansSegment, label: Text('应种清单')),
                  ButtonSegment(value: _recordsSegment, label: Text('接种记录')),
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
            child: _segment == _plansSegment
                ? _PlanSegment(babyId: widget.babyId)
                : _RecordSegment(babyId: widget.babyId),
          ),
        ],
      ),
    );
  }

  /// 自费项手动新增（§4.4.4）：疫苗名称 + 剂次 + 应种日期，落 `manual = 1`。
  /// 默认宝宝取当前筛选的那个——用户正看着 A 的清单却把新行建到 B 名下，回来看不见它；
  /// 不带 `?babyId=` 进来（总览待办卡的「全部」）就是一格未选的选择器。
  Future<void> _addManual(List<Baby> babies) async {
    if (babies.isEmpty) {
      showSnackBar(context, '还没有在册的宝宝，先建档再添加自费疫苗');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          _ManualPlanDialog(babies: babies, initialBabyId: widget.babyId),
    );
  }
}

/// 分段一：应种清单。排序沿用服务端的 `dueDate, id`，前端不重排。
class _PlanSegment extends ConsumerWidget {
  const _PlanSegment({required this.babyId});

  final int? babyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(babyVaccineViewModelProvider);
    // 已接种的行要显示那条接种记录的日期（§4.4.4 的展示列），`record_id` 指向它。
    final records =
        ref.watch(babyVaccineRecordViewModelProvider).value ??
        const <BabyVaccineRecord>[];
    final babies = ref.watch(babyListViewModelProvider).value ?? const <Baby>[];

    final rows = [
      for (final row in plans.value ?? const <BabyVaccinePlan>[])
        if (babyId == null || row.babyId == babyId) row,
    ];

    return plans.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Failure(
        message: errorCopy(error),
        onRetry: () => ref.invalidate(babyVaccineViewModelProvider),
      ),
      data: (_) => rows.isEmpty
          ? const _Empty(
              icon: Icons.vaccines_outlined,
              title: '没有应种项',
              hint: '建档后系统会按国家免疫规划程序表自动生成应种清单',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // 应种清单每行一张独立小卡（问题单：卡片间有间距）。
                for (final row in rows)
                  RowCard(
                    child: _PlanTile(
                      row: row,
                      // 「全部宝宝」那一份才逐行重复宝宝名（同 ④）。
                      babyName: babyId == null
                          ? _nameOf(babies, row.babyId)
                          : null,
                      vaccinatedOn: _vaccinatedOn(records, row),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PlanTile extends ConsumerWidget {
  const _PlanTile({required this.row, this.babyName, this.vaccinatedOn});

  final BabyVaccinePlan row;

  /// 只在「全部宝宝」那一份里显示。
  final String? babyName;

  /// 已接种行那条记录的接种日期，取不到时为 null（那一行只少这一个日期）。
  final DateTime? vaccinatedOn;

  /// `DONE` 只由接种记录回写、手工改不了（§4.4.4），所以这一行一个动作都不给。
  bool get _canMark => row.status != 'DONE';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canSubmit = ref.watch(canSubmitProvider);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final vaccinatedOn = this.vaccinatedOn;

    // 不用 `ListTile`：副标题是二到三行可变高度，`ListTile` 按行数预留空间，
    // 多一行就报 RenderFlex overflow（同 ④）。
    return Padding(
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
                      ? row.vaccineName
                      : '$babyName · ${row.vaccineName}',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    VaccineStatusBadge(displayStatus: row.displayStatus),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        // 展示与排序都取生效日期：改过计划日期的行按用户定的日子走
                        '${doseLabel(row.doseNo)} · ${formatDate(row.effectiveDate)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (row.plannedDate != null)
                  Text('已改期 · 原定 ${formatDate(row.dueDate)}', style: muted),
                if (vaccinatedOn != null)
                  Text('接种 ${formatDate(vaccinatedOn)}', style: muted),
                if (row.skipReason != null)
                  Text('原因：${row.skipReason}', style: muted),
              ],
            ),
          ),
          if (_canMark) _menu(context, ref, canSubmit),
        ],
      ),
    );
  }

  /// 动作按 `manual` 与落库态分岔：字典行只有「标记跳过 / 标记不适用」，标过了就换成「撤销」；
  /// 手动行多一个「删除」——字典生成的行删了，下次改生日重算又会补回来（§4.4.4）。
  /// 三种未标记的行（含手动行）都先给「标记已接种」（问题单 3）：打完针直接在清单里回填，
  /// 不用再切到接种记录那一段补录。
  /// 未接种的行另给「设置计划日期」（2026-10-26 需求②）：改过期的行多一条「恢复程序表日期」。
  Widget _menu(BuildContext context, WidgetRef ref, bool canSubmit) {
    final marked = row.status != 'PENDING';
    // 与服务端同一条守卫：已接种（recordId 回写）的行不再接受计划日期
    final canPlan = row.status != 'DONE' && row.recordId == null;

    return PopupMenuButton<String>(
      onSelected: (value) => switch (value) {
        'vaccinate' => _vaccinate(context, ref),
        'skip' => _mark(context, ref, 'SKIPPED', '标记跳过'),
        'na' => _mark(context, ref, 'NA', '标记不适用'),
        'undo' => _undo(context, ref),
        'planned' => _pickPlannedDate(context, ref),
        'clear-planned' => _clearPlannedDate(context, ref),
        _ => _delete(context, ref),
      },
      itemBuilder: (context) => [
        if (!marked) ...[
          const PopupMenuItem(value: 'vaccinate', child: Text('标记已接种')),
          const PopupMenuItem(value: 'skip', child: Text('标记跳过')),
          const PopupMenuItem(value: 'na', child: Text('标记不适用')),
        ] else
          PopupMenuItem(
            value: 'undo',
            // 离线时禁用并把原因写进文案：灰掉的菜单项说不清「为什么点不动」（§5.4）。
            enabled: canSubmit,
            child: Text(canSubmit ? '撤销标记' : '撤销标记（$offlineSubmitHint）'),
          ),
        if (canPlan) ...[
          PopupMenuItem(
            value: 'planned',
            enabled: canSubmit,
            child: Text(
              canSubmit
                  ? (row.plannedDate == null ? '设置计划日期' : '改计划日期')
                  : '计划日期（$offlineSubmitHint）',
            ),
          ),
          if (row.plannedDate != null)
            const PopupMenuItem(value: 'clear-planned', child: Text('恢复程序表日期')),
        ],
        if (row.manual) const PopupMenuItem(value: 'delete', child: Text('删除')),
      ],
    );
  }

  /// 设置计划接种日期（2026-10-26 需求②）：约好哪天去打就填哪天，清单的排序与
  /// 逾期判定跟着它走；改出生日期重算不会把它平移掉。下界取出生日期（与服务端同口径），
  /// 上界放 10 年（与手动新增应种项同一口径）。
  Future<void> _pickPlannedDate(BuildContext context, WidgetRef ref) async {
    final today = DateTime.now();
    final earliest = _birthDateOf(ref, row.babyId);
    final first = earliest.isAfter(today) ? today : earliest;
    // 上界只用这一个变量：钳制与 lastDate 必须同一天，否则 effectiveDate 落在两者之间时
    // initial > lastDate，showDatePicker 直接断言（复扫 P2——两个「10 年」差着闰年天数的窗口）
    final last = DateTime(today.year + 10);
    var initial = row.effectiveDate.isBefore(first) ? first : row.effectiveDate;
    if (initial.isAfter(last)) initial = today;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: '计划接种日期',
    );
    if (picked == null) return;

    final error = await ref
        .read(babyVaccineViewModelProvider.notifier)
        .setPlannedDate(row.id, picked);
    if (error != null && context.mounted) showSnackBar(context, error);
  }

  Future<void> _clearPlannedDate(BuildContext context, WidgetRef ref) async {
    final error = await ref
        .read(babyVaccineViewModelProvider.notifier)
        .setPlannedDate(row.id, null);
    if (error != null && context.mounted) showSnackBar(context, error);
  }

  /// 计划日期的下界：出生日期；档案还没加载出来时退成 1990（与 _VaccinateDialog 同一口径）。
  DateTime _birthDateOf(WidgetRef ref, int babyId) {
    for (final baby
        in ref.read(babyListViewModelProvider).value ?? const <Baby>[]) {
      if (baby.id == babyId) return baby.birthDate;
    }
    return DateTime(1990);
  }

  /// 在清单这一行就地标记已接种（问题单 3）：弹层里选接种日期（+ 可选的接种机构），
  /// 以 `planId` 指名回写这一行——服务端同一事务里把应种项置 `DONE` 并记 `record_id`，
  /// 与「接种记录 → 新增」走的是同一条写路径，所以不需要先切到记录那一段。
  Future<void> _vaccinate(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => _VaccinateDialog(row: row),
    );
  }

  /// 标记跳过 / 不适用：原因必填（§4.3③），弹层的校验器挡住空提交；撤销不问原因，
  /// 服务端会清掉上一次那条（留着的话下次标记会带着上一次的字）。
  Future<void> _mark(
    BuildContext context,
    WidgetRef ref,
    String status,
    String title,
  ) async {
    final reason = await promptForText(
      context,
      title: title,
      label: '原因（最多 50 个字）',
      validator: _reasonError,
      confirmDisabledHint: ref.read(canSubmitProvider)
          ? null
          : offlineSubmitHint,
    );
    if (reason == null) return;

    final error = await ref
        .read(babyVaccineViewModelProvider.notifier)
        .mark(row.id, status, reason);
    if (error != null && context.mounted) showSnackBar(context, error);
  }

  Future<void> _undo(BuildContext context, WidgetRef ref) async {
    final error = await ref
        .read(babyVaccineViewModelProvider.notifier)
        .mark(row.id, 'PENDING', null);
    if (error != null && context.mounted) showSnackBar(context, error);
  }

  /// 只有 `manual = 1` 的行有这个入口，服务端对字典生成的行也会再拒一次，文案原样弹出。
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: '删除「${row.vaccineName} ${doseLabel(row.doseNo)}」？',
      message: '这是手动添加的自费项，删除后不再出现在应种清单里，也无法恢复。',
      confirmLabel: '删除',
    );
    if (!confirmed) return;

    final error = await ref
        .read(babyVaccineViewModelProvider.notifier)
        .remove(row.id);
    if (error != null && context.mounted) showSnackBar(context, error);
  }
}

/// 应种清单一行上的「标记已接种」弹层（问题单 3）。接种日期必填、机构选填，
/// 提交时 `planId` 指名回写这一行，与「接种记录 → 新增」走同一条写路径。
class _VaccinateDialog extends ConsumerStatefulWidget {
  const _VaccinateDialog({required this.row});

  final BabyVaccinePlan row;

  @override
  ConsumerState<_VaccinateDialog> createState() => _VaccinateDialogState();
}

class _VaccinateDialogState extends ConsumerState<_VaccinateDialog> {
  final TextEditingController _clinic = TextEditingController();

  DateTime? _givenDate;
  String? _dateError;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _clinic.dispose();
    super.dispose();
  }

  /// 接种日期不可能早于出生日期，下界就取它；档案还没加载出来时退成 1990。
  DateTime _earliestDate() {
    final babyId = widget.row.babyId;
    for (final baby
        in ref.read(babyListViewModelProvider).value ?? const <Baby>[]) {
      if (baby.id == babyId) return baby.birthDate;
    }
    return DateTime(1990);
  }

  Future<void> _pickGivenDate() async {
    final today = DateTime.now();
    final earliest = _earliestDate();
    final current = _givenDate;

    // 上界是今天（§4.4.4：接种日期不可晚于今天）。时钟回拨/异常数据会让 earliest 晚于今天，
    // 那时下界钳完又越过上界——先收窄 firstDate 再按 [first, today] 夹 initial，
    // 两个参数越界都会让 showDatePicker 断言失败。
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
      _givenDate = picked;
      _dateError = null;
    });
  }

  Future<void> _submit() async {
    final givenDate = _givenDate;
    setState(() => _dateError = givenDate == null ? '请选择接种日期' : null);
    if (givenDate == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    String? error;
    try {
      error = await ref
          .read(babyVaccineRecordViewModelProvider.notifier)
          .create(
            VaccineRecordDraft(
              babyId: widget.row.babyId,
              vaccineName: widget.row.vaccineName,
              doseNo: widget.row.doseNo,
              givenDate: givenDate,
              // 指名回写这一行：服务端同一事务置 DONE + 记 record_id（§4.4.4）。
              planId: widget.row.id,
              clinic: _clinic.text.trim().isEmpty ? null : _clinic.text.trim(),
            ),
          );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context);
      return;
    }
    setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = ref.watch(canSubmitProvider);

    return AlertDialog(
      title: const Text('标记已接种'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${widget.row.vaccineName} ${doseLabel(widget.row.doseNo)}'
                ' · 应种 ${formatDate(widget.row.effectiveDate)}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _FieldLabel('接种日期'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                trailing: Text(
                  _givenDate == null ? '请选择' : formatDate(_givenDate!),
                  style: theme.textTheme.titleMedium,
                ),
                onTap: _pickGivenDate,
              ),
              _ErrorLine(text: _dateError),
              const SizedBox(height: 8),
              TextFormField(
                controller: _clinic,
                maxLength: 50,
                decoration: const InputDecoration(labelText: '接种机构（选填）'),
              ),
              if (_error != null) _ErrorLine(text: _error!),
              if (!canSubmit) const OfflineSubmitHint(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: (_saving || !canSubmit) ? null : _submit,
          child: submitButtonText(saving: _saving),
        ),
      ],
    );
  }
}

/// 分段二：接种记录。接种日期倒序、同日按 id 倒序，沿用服务端的顺序。
class _RecordSegment extends ConsumerWidget {
  const _RecordSegment({required this.babyId});

  final int? babyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(babyVaccineRecordViewModelProvider);
    final babies = ref.watch(babyListViewModelProvider).value ?? const <Baby>[];

    final rows = [
      for (final row in records.value ?? const <BabyVaccineRecord>[])
        if (babyId == null || row.babyId == babyId) row,
    ];

    return records.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Failure(
        message: errorCopy(error),
        onRetry: () => ref.invalidate(babyVaccineRecordViewModelProvider),
      ),
      data: (_) => rows.isEmpty
          ? const _Empty(
              icon: Icons.vaccines_outlined,
              title: '还没有接种记录',
              hint: '打完针记一笔，对应的应种项会跟着变成「已接种」',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                // 接种记录每行一张独立小卡（问题单：卡片间有间距）。
                for (final row in rows)
                  RowCard(
                    child: _RecordTile(
                      row: row,
                      babyName: babyId == null
                          ? _nameOf(babies, row.babyId)
                          : null,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _RecordTile extends ConsumerWidget {
  const _RecordTile({required this.row, this.babyName});

  final BabyVaccineRecord row;

  /// 只在「全部宝宝」那一份里显示。
  final String? babyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final nextDate = row.nextDate;

    return InkWell(
      onTap: () => context.push(RoutePath.babyVaccineRecordEditOf(row.id)),
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
                        ? formatDate(row.givenDate)
                        : '$babyName · ${formatDate(row.givenDate)}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${row.vaccineName} · ${doseLabel(row.doseNo)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (row.clinic != null) Text(row.clinic!, style: muted),
                  // 下一针日期由服务端按该疫苗下一个未完成剂次推算，这里只读展示（§4.4.4）。
                  if (nextDate != null)
                    Text('下一针 ${formatDate(nextDate)}', style: muted),
                  if (row.remark != null) Text(row.remark!, style: muted),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit'
                  ? context.push(RoutePath.babyVaccineRecordEditOf(row.id))
                  : _delete(context, ref),
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

  /// 删一条接种记录会把对应应种项退回「待接种」（§4.4.4：录错了要能改回来），所以确认框
  /// 把这件事说出来——它是这一屏唯一一个会改到**另一个分段**的动作。
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: '删除 ${formatDate(row.givenDate)} 这条接种记录？',
      message: '对应的应种项会退回「待接种」。删除后无法恢复。',
      confirmLabel: '删除',
    );
    if (!confirmed) return;

    final error = await ref
        .read(babyVaccineRecordViewModelProvider.notifier)
        .remove(row.id);
    if (error != null && context.mounted) showSnackBar(context, error);
  }
}

/// 自费项新增的弹层（第 30 轮起带预置）。两种模式：
///  - 预置模式：点一个常用自费疫苗（默认选中五联），展示它的通盘剂次与按出生日期算好的
///    建议应种日期，一次确认整串入清单；已在该宝宝清单里的剂次就地标「已在清单」、跳过发送。
///  - 自定义模式：保留原有「疫苗名称 + 剂次 + 应种日期」手工录入（预置没有的苗走这里）。
///
/// **请求发在弹层里**而不是把草稿弹回页面：撞键（「该疫苗第 n 剂已在应种清单里」）与
/// 应种日期早于出生日期都由服务端拒，就地显示错误才能保住用户已经选的预置与宝宝。
class _ManualPlanDialog extends ConsumerStatefulWidget {
  const _ManualPlanDialog({required this.babies, this.initialBabyId});

  final List<Baby> babies;
  final int? initialBabyId;

  @override
  ConsumerState<_ManualPlanDialog> createState() => _ManualPlanDialogState();
}

class _ManualPlanDialogState extends ConsumerState<_ManualPlanDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _dose = TextEditingController();

  int? _babyId;
  DateTime? _dueDate;

  /// 应种日期是必填，但它是 `ListTile` 不是 `TextFormField`，`Form.validate()` 管不到它。
  String? _dateError;

  /// 选中预置的下标；`null` = 自定义模式。用下标而非名字：哨兵与预置名同命名空间的话，
  /// 将来加一个恰好叫哨兵名的预置会静默弄坏「自定义」chip 的选中态。
  int? _presetIndex = 0; // 默认选中第一个预置（五联）：这扇门就是为「几个常用自费苗一点即加」开的。

  /// 服务端拒了的那句话，就地显示在按钮上方。
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // 多个在册宝宝时直接选中第一个（问题单 5）：从总览待办卡进来不带 `?babyId=`，
    // 若还要先手选一次，预置区四行剂次全成「请选择宝宝」，恰恰看不到这一屏的卖点。
    _babyId =
        widget.initialBabyId ??
        (widget.babies.isEmpty ? null : widget.babies.first.id);
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    super.dispose();
  }

  Baby? get _selectedBaby {
    final babyId = _babyId;
    if (babyId == null) return null;
    for (final baby in widget.babies) {
      if (baby.id == babyId) return baby;
    }
    return null;
  }

  PaidVaccinePreset? get _preset {
    final index = _presetIndex;
    return index == null ? null : paidVaccinePresets[index];
  }

  /// 已在这个宝宝清单里的剂次集合（按疫苗名过滤），预置模式用它标「已在清单」并过滤提交。
  /// 注意名称是逐字匹配：服务端 `assertKeyFree` 同口径，写法不同的同名苗会被当成不同疫苗。
  Set<String> _existingDoseNos(String vaccineName) {
    final babyId = _babyId;
    if (babyId == null) return const {};
    final plans = ref.read(babyVaccineViewModelProvider).value ?? const [];
    return {
      for (final plan in plans)
        if (plan.babyId == babyId && plan.vaccineName == vaccineName)
          plan.doseNo,
    };
  }

  Future<void> _submit() async {
    final preset = _preset;
    if (preset == null) {
      await _submitCustom();
      return;
    }
    final baby = _selectedBaby;
    if (baby == null) {
      setState(() => _error = '请选择宝宝');
      return;
    }
    final existing = _existingDoseNos(preset.name);
    final drafts = [
      for (final dose in preset.doses)
        if (!existing.contains(dose.doseNo))
          ManualPlanDraft(
            babyId: baby.id,
            vaccineName: preset.name,
            doseNo: dose.doseNo,
            dueDate: paidVaccineDueDate(baby.birthDate, dose.ageMonths),
          ),
    ];
    if (drafts.isEmpty) {
      setState(() => _error = '这个宝宝的${preset.name}剂次都已在应种清单里');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    String? error;
    try {
      error = await ref
          .read(babyVaccineViewModelProvider.notifier)
          .createManualSeries(drafts);
    } finally {
      // 非 ApiException 的意外异常（解析崩、StateError）也得把按钮还给用户，
      // 否则弹层永久钉在「保存中…」（S5/S9 的卡死教训）。
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context);
      return;
    }
    setState(() => _error = error);
  }

  /// 自定义分支（第 30 轮前原样保留）：偏门疫苗用手工填。
  Future<void> _submitCustom() async {
    final dueDate = _dueDate;
    setState(() => _dateError = dueDate == null ? '请选择应种日期' : null);

    final valid = _formKey.currentState?.validate() ?? false;
    final babyId = _babyId;
    if (!valid || dueDate == null || babyId == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    String? error;
    try {
      error = await ref
          .read(babyVaccineViewModelProvider.notifier)
          .createManual(
            ManualPlanDraft(
              babyId: babyId,
              vaccineName: _name.text.trim(),
              doseNo: _dose.text.trim(),
              dueDate: dueDate,
            ),
          );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context);
      return;
    }
    setState(() => _error = error);
  }

  /// 不夹出生日期那道下界：它是服务端唯一的判定（`assertDueDateNotBeforeBirth`），
  /// 这里再夹一次就多一处会漂移的口径；而宝宝选择器随时可改，夹了还得跟着重算。
  Future<void> _pickDueDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today,
      firstDate: DateTime(today.year - 5),
      lastDate: DateTime(today.year + 10),
    );
    if (picked == null) return;
    setState(() {
      _dueDate = picked;
      _dateError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = ref.watch(canSubmitProvider);
    final preset = _preset;

    return AlertDialog(
      title: const Text('添加自费疫苗'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _babyId,
                  decoration: const InputDecoration(labelText: '宝宝'),
                  items: [
                    for (final baby in widget.babies)
                      DropdownMenuItem(value: baby.id, child: Text(baby.name)),
                  ],
                  onChanged: (value) => setState(() => _babyId = value),
                  validator: (value) => value == null ? '请选择宝宝' : null,
                ),
                const SizedBox(height: 12),
                const _FieldLabel('自费疫苗'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (index, item) in paidVaccinePresets.indexed)
                      ChoiceChip(
                        label: Text(item.name),
                        selected: _presetIndex == index,
                        onSelected: (_) => setState(() => _presetIndex = index),
                      ),
                    ChoiceChip(
                      label: const Text('自定义'),
                      selected: _presetIndex == null,
                      onSelected: (_) => setState(() => _presetIndex = null),
                    ),
                  ],
                ),
                if (preset != null) ...[
                  const SizedBox(height: 12),
                  if (preset.note != null) _PresetNote(text: preset.note!),
                  const SizedBox(height: 4),
                  for (final dose in preset.doses)
                    _PresetDoseTile(
                      baby: _selectedBaby,
                      dose: dose,
                      alreadyInPlan: _existingDoseNos(
                        preset.name,
                      ).contains(dose.doseNo),
                    ),
                ] else ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    maxLength: 30,
                    decoration: const InputDecoration(
                      labelText: '疫苗名称',
                      // 故意避开预置名（如「水痘疫苗」与预置「水痘减毒活疫苗」）：
                      // 清单去重按名称逐字匹配，照 hint 填会让同一种苗在清单里分裂成两套名字。
                      hintText: '如 23 价肺炎疫苗',
                    ),
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? '请填写疫苗名称' : null,
                  ),
                  TextFormField(
                    controller: _dose,
                    maxLength: 8,
                    decoration: const InputDecoration(
                      labelText: '剂次',
                      hintText: '如 1、加强针',
                    ),
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? '请填写剂次' : null,
                  ),
                  const SizedBox(height: 8),
                  const _FieldLabel('应种日期'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    trailing: Text(
                      _dueDate == null ? '请选择' : formatDate(_dueDate!),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: _pickDueDate,
                  ),
                  _ErrorLine(text: _dateError),
                ],
                if (_error != null) _ErrorLine(text: _error!),
                if (!canSubmit) const OfflineSubmitHint(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: (_saving || !canSubmit) ? null : _submit,
          child: submitButtonText(saving: _saving),
        ),
      ],
    );
  }
}

/// 预置接种说明的小字块：五联的重叠关系、各苗的接种窗口都写在预置数据里。
class _PresetNote extends StatelessWidget {
  const _PresetNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: theme.textTheme.bodySmall),
    );
  }
}

/// 预置模式下的一剂：剂次 + 建议应种日期；已在清单的标「已在清单」且不参与提交。
class _PresetDoseTile extends StatelessWidget {
  const _PresetDoseTile({
    required this.baby,
    required this.dose,
    required this.alreadyInPlan,
  });

  final Baby? baby;
  final PaidVaccineDose dose;
  final bool alreadyInPlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = baby == null
        ? '请选择宝宝'
        : formatDate(paidVaccineDueDate(baby!.birthDate, dose.ageMonths));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            alreadyInPlan ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: alreadyInPlan
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${doseLabel(dose.doseNo)} · $date',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (alreadyInPlan) Text('已在清单', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
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
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
