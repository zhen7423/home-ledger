import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/baby.dart';
import '../../../../data/models/baby_growth.dart';
import '../../../../data/repositories/baby_growth_repository.dart';
import '../../../../data/services/network_status.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../baby_copy.dart';
import '../view_models/baby_growth_view_model.dart';
import '../view_models/baby_list_view_model.dart';

/// 小数位数按列宽卡的两个输入格式器与对应的校验正则：身高与头围 `DECIMAL(5,1)`、
/// 体重 `DECIMAL(5,2)`。**只判形态不判范围**：20–200 / 1–100 / 30–60 三对范围由服务端的
/// `@DecimalMin/@DecimalMax` 出文案，前端复制一份迟早与服务端漂移，而漂移的表现是
/// 「前端放行、服务端拒绝」。多出来的小数位必须在这里挡：MySQL 会把它悄悄四舍五入，
/// 界面上看到的与库里存的对不上。
final RegExp _oneDecimal = RegExp(r'^\d+(?:\.\d)?$');
final RegExp _twoDecimals = RegExp(r'^\d+(?:\.\d{1,2})?$');

final List<TextInputFormatter> _oneDecimalInput = [
  FilteringTextInputFormatter.allow(RegExp(r'\d*\.?\d{0,1}')),
];
final List<TextInputFormatter> _twoDecimalsInput = [
  FilteringTextInputFormatter.allow(RegExp(r'\d*\.?\d{0,2}')),
];

String? _decimalError(String? value, RegExp pattern, String message) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return pattern.hasMatch(text) ? null : message;
}

/// §4.4.2 的身高体重录入，同一页靠 `?id=` 有没有值区分（常态是新增，§1.3 第 1 条）。
///
/// 宝宝一栏：新增时是在册宝宝的选择器，编辑时只读——既有记录挂的宝宝可能已经归档，
/// 归档的宝宝不在选择器里，做成可改就等于「把这条记录挂到一个选不出来的宝宝身上」。
class BabyGrowthEditPage extends ConsumerStatefulWidget {
  const BabyGrowthEditPage({super.key, this.id});

  final int? id;

  bool get isEdit => id != null;

  @override
  ConsumerState<BabyGrowthEditPage> createState() => _BabyGrowthEditPageState();
}

class _BabyGrowthEditPageState extends ConsumerState<BabyGrowthEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _head = TextEditingController();
  final TextEditingController _remark = TextEditingController();

  int? _babyId;
  DateTime? _measureDate;

  /// 测量日期是必填，但它是 `ListTile` 不是 `TextFormField`，`Form.validate()` 管不到它。
  String? _dateError;

  BabyGrowth? _original;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // 保存按钮的可用性挂在「身高与体重至少填一项」上，字一改就得重算。
    _height.addListener(_onMeasureChanged);
    _weight.addListener(_onMeasureChanged);
    if (widget.isEdit) _loadOriginal();
  }

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _head.dispose();
    _remark.dispose();
    super.dispose();
  }

  void _onMeasureChanged() => setState(() {});

  Future<void> _loadOriginal() async {
    // 没有 `GET /baby-growths/{id}`：编辑表单要回填的那一行只能从整份列表里找，而列表是全量、
    // 按日期倒序的，所以冷启动直接 push 进来时得先 await 它，否则会读成「没有这条记录」而弹回。
    await ref.read(babyGrowthViewModelProvider.future);
    if (!mounted) return;

    final row = ref.read(babyGrowthViewModelProvider.notifier).byId(widget.id!);
    if (row == null) {
      showSnackBar(context, '没有找到这条身高体重记录，它可能已经被删除了');
      context.pop();
      return;
    }

    _height.text = row.heightCm ?? '';
    _weight.text = row.weightKg ?? '';
    _head.text = row.headCm ?? '';
    _remark.text = row.remark ?? '';
    setState(() {
      _original = row;
      _babyId = row.babyId;
      _measureDate = row.measureDate;
      _dateError = null;
    });
  }

  /// 测量日期不可能早于出生日期，下界就取它；档案还没加载出来时退成 1990——与建档页同一个下界。
  DateTime _earliestDate() {
    final babyId = _babyId ?? _defaultBabyId();
    if (babyId == null) return DateTime(1990);
    for (final baby
        in ref.read(babyListViewModelProvider).value ?? const <Baby>[]) {
      if (baby.id == babyId) return baby.birthDate;
    }
    return DateTime(1990);
  }

  /// 多个在册宝宝时默认选中第一个。在 initState 里读 provider 可能还没加载完，
  /// 所以「喂给下拉框 + 提交」两处都用这一份兜底，下拉框再配随机值变化的 `key` 让它重建。
  int? _defaultBabyId() {
    for (final baby
        in ref.read(babyListViewModelProvider).value ?? const <Baby>[]) {
      if (!baby.archived) return baby.id;
    }
    return null;
  }

  Future<void> _pickMeasureDate() async {
    final today = DateTime.now();
    final earliest = _earliestDate();
    final current = _measureDate;

    // 上界是今天（§4.4.2：不可晚于今天），服务端也会拒，这一格是让它更好点。
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
      _measureDate = picked;
      _dateError = null;
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;

    final measureDate = _measureDate;
    final babyId = _babyId ?? _defaultBabyId();
    setState(() {
      _dateError = measureDate == null ? '请选择测量日期' : null;
    });
    if (!valid || measureDate == null || babyId == null) return;

    final draft = BabyGrowthDraft(
      babyId: babyId,
      measureDate: measureDate,
      heightCm: _optional(_height.text),
      weightKg: _optional(_weight.text),
      headCm: _optional(_head.text),
      remark: _optional(_remark.text),
    );
    setState(() => _saving = true);

    final notifier = ref.read(babyGrowthViewModelProvider.notifier);
    final error = widget.isEdit
        ? await notifier.save(widget.id!, draft)
        : await notifier.create(draft);
    if (!mounted) return;
    setState(() => _saving = false);

    // 保存成功回列表：新记的那一条就在顶上，「较上次」也随服务端重算过。
    if (error == null) {
      context.pop();
    } else {
      showSnackBar(context, error);
    }
  }

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  /// 「身高与体重至少填一项」（§4.4.2）。服务端也会拒，两边都要有：这一句让用户在页面上
  /// 当场看见，而不是等一次往返。
  bool get _hasAnyMeasure =>
      _height.text.trim().isNotEmpty || _weight.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final canSubmit = ref.watch(canSubmitProvider);
    final babyList = ref.watch(babyListViewModelProvider);
    final babies = [
      for (final baby in babyList.value ?? const <Baby>[])
        if (!baby.archived) baby,
    ];
    final rows =
        ref.watch(babyGrowthViewModelProvider).value ?? const <BabyGrowth>[];
    // 默认选中第一个在册宝宝。`null` 只可能是「一个都没有」——
    // 那一支整页已换成建档引导，不会带着空选择器渲染。
    final effectiveBabyId =
        _babyId ?? (babies.isEmpty ? null : babies.first.id);

    final reference = _reference(rows);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? '编辑身高体重' : '记一次身高体重')),
      body: !widget.isEdit && babyList.hasValue && babies.isEmpty
          ? const _NoBabies()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (widget.isEdit)
                    ..._readOnlyBaby(context)
                  else
                    DropdownButtonFormField<int>(
                      key: ValueKey('baby-$effectiveBabyId'),
                      initialValue: effectiveBabyId,
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
                  if (reference != null) ...[
                    _ReferenceCard(
                      title: reference.title,
                      row: reference.row,
                      delta: reference.delta,
                    ),
                    const SizedBox(height: 16),
                  ],
                  const _FieldLabel('测量日期'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    trailing: Text(
                      _measureDate == null ? '请选择' : formatDate(_measureDate!),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: _pickMeasureDate,
                  ),
                  _ErrorLine(text: _dateError),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _height,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _oneDecimalInput,
                    decoration: const InputDecoration(
                      labelText: '身高（cm，选填）',
                      hintText: '62.5',
                    ),
                    validator: (value) =>
                        _decimalError(value, _oneDecimal, '身高最多一位小数'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _twoDecimalsInput,
                    decoration: const InputDecoration(
                      labelText: '体重（kg，选填）',
                      hintText: '6.25',
                    ),
                    validator: (value) =>
                        _decimalError(value, _twoDecimals, '体重最多两位小数'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _head,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: _oneDecimalInput,
                    decoration: const InputDecoration(
                      labelText: '头围（cm，选填）',
                      hintText: '42.0',
                    ),
                    validator: (value) =>
                        _decimalError(value, _oneDecimal, '头围最多一位小数'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _remark,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: '备注（选填）',
                      hintText: '体检、疫苗当天的数据',
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_hasAnyMeasure) const _ErrorLine(text: '身高与体重至少填一项'),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: (_saving || !canSubmit || !_hasAnyMeasure)
                        ? null
                        : _submit,
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

  /// 编辑态的宝宝只读：既有记录挂的宝宝可能已归档，归档的宝宝不在上面的选择器里。
  List<Widget> _readOnlyBaby(BuildContext context) {
    final babyId = _original?.babyId;
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

  /// 上一次那一行。新增时给该宝宝最近一次的值（手里还没有新值，就没有「差」可算），
  /// 编辑时给这条记录自己那一行差值——`deltaFromPrevious` 是服务端派生好的，前端只读不重算。
  ({String title, BabyGrowth row, BabyGrowthDelta? delta})? _reference(
    List<BabyGrowth> rows,
  ) {
    final original = _original;
    if (original != null) {
      final previous = _previousOf(rows, original);
      if (previous == null) return null;
      return (
        title: '上一次 · ${formatDate(previous.measureDate)}',
        row: previous,
        delta: original.deltaFromPrevious,
      );
    }

    final babyId = _babyId ?? _defaultBabyId();
    if (babyId == null) return null;
    for (final row in rows) {
      if (row.babyId == babyId) {
        return (
          title: '该宝宝最近一次 · ${formatDate(row.measureDate)}',
          row: row,
          delta: null,
        );
      }
    }
    return null;
  }
}

/// 编辑时这条记录的「上一次」＝同一宝宝里日期比它早的最近一条**代表行**（同日取 id 最大的那条，
/// 也就是列表里同一天的第一条）。列表已经是服务端的「日期降序、同日 id 降序」，往后扫到第一条
/// 日期不同的行就是它——这里的差值仍由服务端算，这趟扫只把「上一次是谁」读出来。
BabyGrowth? _previousOf(List<BabyGrowth> rows, BabyGrowth row) {
  var reached = false;
  for (final candidate in rows) {
    if (!reached) {
      reached = candidate.id == row.id;
      continue;
    }
    if (candidate.babyId == row.babyId &&
        formatDate(candidate.measureDate) != formatDate(row.measureDate)) {
      return candidate;
    }
  }
  return null;
}

String? _deltaLine(BabyGrowthDelta? delta) {
  final days = delta?.days;
  if (delta == null || days == null) return null;

  final parts = [
    if (delta.heightCm != null) '身高 ${signedDelta(delta.heightCm!)} cm',
    if (delta.weightKg != null) '体重 ${signedDelta(delta.weightKg!)} kg',
    if (delta.headCm != null) '头围 ${signedDelta(delta.headCm!)} cm',
  ];
  if (parts.isEmpty) return null;
  return '较上次 ${[...parts, '$days 天'].join(' · ')}';
}

class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.title, required this.row, this.delta});

  final String title;
  final BabyGrowth row;
  final BabyGrowthDelta? delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final measures = [
      if (row.heightCm != null) '身高 ${row.heightCm} cm',
      if (row.weightKg != null) '体重 ${row.weightKg} kg',
      if (row.headCm != null) '头围 ${row.headCm} cm',
    ];
    final deltaLine = _deltaLine(delta);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(measures.join(' · '), style: theme.textTheme.bodyMedium),
          if (deltaLine != null)
            Text(
              deltaLine,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _NoBabies extends StatelessWidget {
  const _NoBabies();

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
              Icons.child_care_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('还没有在册的宝宝', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '身高体重记录要挂在宝宝名下，先建一个宝宝档案',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push(RoutePath.babyEdit),
              icon: const Icon(Icons.add),
              label: const Text('宝宝建档'),
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
