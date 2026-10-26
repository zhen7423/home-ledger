import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/cat.dart';
import '../../../../data/models/cat_deworming.dart';
import '../../../../data/models/cat_setting.dart';
import '../../../../data/repositories/cat_deworming_repository.dart';
import '../../../../data/services/network_status.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../view_models/cat_deworming_view_model.dart';
import '../view_models/cat_setting_view_model.dart';
import '../view_models/cat_view_model.dart';

/// §4.3.3 的记一次驱虫。`catId` 只在新增时用，是从到期倒计时那一行「给这只猫记一次」带过来的预选。
///
/// 下次日期可以留空：留空交上去的是 `nextDate: null`，由服务端按设置里的周期回算。
/// 那一格显示「按周期算」四个字而不是一个前端算出来的日期，算的是服务端。
class CatDewormingEditPage extends ConsumerStatefulWidget {
  const CatDewormingEditPage({this.id, this.catId, super.key});

  /// null = 新记一次。
  final int? id;

  /// 新增时预选的那只猫。编辑时忽略。
  final int? catId;

  bool get isEdit => id != null;

  @override
  ConsumerState<CatDewormingEditPage> createState() =>
      _CatDewormingEditPageState();
}

class _CatDewormingEditPageState extends ConsumerState<CatDewormingEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _medicine = TextEditingController();
  final TextEditingController _dosage = TextEditingController();
  final TextEditingController _remark = TextEditingController();

  int? _catId;
  String _type = 'INTERNAL';
  DateTime _doneDate = DateTime.now();

  /// null = 交服务端按周期回算。
  DateTime? _nextDate;
  bool _saving = false;

  /// 多个在册猫咪时默认选中第一只：没有猫可归时回 null，由提交前的
  /// `_effectiveCatId` 继续兜底。
  int? _firstActiveCatId() {
    final active = ref.read(catViewModelProvider.notifier).active();
    return active.isEmpty ? null : active.first.id;
  }

  /// 用户点过（或从倒计时带进来、编辑回填）的用那份；没点且档案已加载时就落在第一只。
  /// 芯片不是 FormField，每帧都按这份值重建，所以数据晚到也能自动亮起第一只。
  int? get _effectiveCatId {
    final picked = _catId;
    if (picked != null) return picked;
    final active = ref.read(catViewModelProvider.notifier).active();
    return active.isEmpty ? null : active.first.id;
  }

  @override
  void initState() {
    super.initState();
    _catId = widget.catId ?? _firstActiveCatId();
    if (widget.isEdit) _loadOriginal();
  }

  @override
  void dispose() {
    _medicine.dispose();
    _dosage.dispose();
    _remark.dispose();
    super.dispose();
  }

  Future<void> _loadOriginal() async {
    // 先 future 再 byId：服务端也没有单条记录的详情端点。列表是全量的，所以哪怕用户是从
    // 「只看这只猫」的筛选页点进来，那条记录也在这份列表里。
    await ref.read(catDewormingViewModelProvider.future);
    if (!mounted) return;

    final row = ref
        .read(catDewormingViewModelProvider.notifier)
        .byId(widget.id!);
    if (row == null) {
      showSnackBar(context, '没有找到这条驱虫记录，它可能已经被删除了');
      context.pop();
      return;
    }

    _catId = row.catId;
    _type = row.type;
    _medicine.text = row.medicine;
    _dosage.text = row.dosage ?? '';
    _remark.text = row.remark ?? '';
    setState(() {
      _doneDate = row.doneDate;
      _nextDate = row.nextDate;
    });
  }

  /// 可选项 = 在册的猫，外加「编辑的那只猫即使已归档也要能显示」。
  ///
  /// 服务端改一条记录时刻意不重校验猫是否在册（改一条历史记录不该被猫后来的归档挡住），
  /// 所以这一处不补那枚芯片的话，编辑一只归档猫的记录时整排芯片一个都不亮，
  /// 界面读起来像「还没选猫」，而提交时 `catId` 明明是有的。
  List<Cat> _catOptions() {
    final vm = ref.read(catViewModelProvider.notifier);
    final options = vm.active();
    final picked = _effectiveCatId;
    if (picked == null || options.any((cat) => cat.id == picked)) {
      return options;
    }
    final archived = vm.byId(picked);
    return archived == null ? options : [...options, archived];
  }

  /// 按 `doneDate` 从新到旧去重取前六个药品名。
  /// 只读已经拿到的那份列表，不为此加端点：一屏六枚已经够点，第七种多半是要自己填。
  List<String> _medicineCandidates() {
    final names = <String>{};
    for (final row
        in ref.watch(catDewormingViewModelProvider).value ??
            const <CatDeworming>[]) {
      if (names.length == 6) break;
      names.add(row.medicine.trim());
    }
    return names.toList();
  }

  /// 与服务端那句 `BAD_REQUEST` 同字。判 `isAfter` 而不是 `!isBefore`：
  /// 选了跟本次同一天的那次驱虫，服务端也要拒（同一天驱两次不是这条记录要说的事）。
  String? _nextError() {
    final next = _nextDate;
    if (next != null && !next.isAfter(_doneDate)) {
      return '下次驱虫日期要晚于本次驱虫日期';
    }
    return null;
  }

  /// 与服务端的 `@NotBlank` / `@Size(max = 30)` 逐字同。**不进 `ui/core/validators.dart`**：
  /// 那一份是全项目共用的校验器，只有会被两处以上用到的规则才进去（`validateAmount` 五个调用方，
  /// 本模块的 `_packError` / 这一份各只有一个）。`maxLength: 30` 已经挡在输入框上，
  /// 这一句是给粘贴与回填兜底的。
  String? _medicineError(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '请填写药品名称';
    if (text.length > 30) return '药品名称最多 30 个字符';
    return null;
  }

  /// 那句 helper 文案。`setting` 由 build 传进来而不是在这里 `ref.watch`：
  /// 这个方法也要在 `setState` 之后的重建里被调，而 `ref.watch` 只允许出现在 build 路径上。
  String _monthsHint(CatSetting setting) =>
      '留空 = 按周期算：本次日期 + '
      '${_type == 'INTERNAL' ? setting.internalMonths : setting.externalMonths} 个月';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final catId = _effectiveCatId;
    if (catId == null) {
      showSnackBar(context, '请选择猫咪');
      return;
    }
    final nextError = _nextError();
    if (nextError != null) {
      showSnackBar(context, nextError);
      return;
    }

    final dosage = _dosage.text.trim();
    final remark = _remark.text.trim();
    final draft = CatDewormingDraft(
      catId: catId,
      type: _type,
      doneDate: _doneDate,
      medicine: _medicine.text.trim(),
      dosage: dosage.isEmpty ? null : dosage,
      nextDate: _nextDate,
      remark: remark.isEmpty ? null : remark,
    );
    setState(() => _saving = true);

    final notifier = ref.read(catDewormingViewModelProvider.notifier);
    final error = widget.isEdit
        ? await notifier.save(widget.id!, draft)
        : await notifier.create(draft);
    if (!mounted) return;
    setState(() => _saving = false);

    if (error == null) {
      context.pop();
    } else {
      showSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = ref.watch(canSubmitProvider);
    ref.watch(catViewModelProvider);
    final cats = _catOptions();
    final setting =
        ref.watch(catSettingViewModelProvider).value ?? const CatSetting();
    final medicineCandidates = _medicineCandidates();

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? '编辑驱虫记录' : '记一次驱虫')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (cats.isEmpty)
              OutlinedButton.icon(
                icon: const Icon(Icons.pets_outlined),
                label: const Text('还没有猫咪档案，先去建档'),
                // 建档页回来时这一页还在栈里，`initState` 不会再跑一次，
                // 但 `catViewModelProvider` 已被档案的写操作失效过，芯片会自己长出来。
                onPressed: () => context.push(RoutePath.catCats),
              )
            else
              _chipField(
                label: '哪只猫',
                children: [
                  for (final cat in cats)
                    ChoiceChip(
                      label: Text(cat.name),
                      selected: _effectiveCatId == cat.id,
                      onSelected: (_) => setState(() => _catId = cat.id),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'INTERNAL', label: Text('内驱')),
                ButtonSegment(value: 'EXTERNAL', label: Text('外驱')),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
            const SizedBox(height: 8),
            _dateTile(
              label: '本次驱虫日期',
              value: formatDate(_doneDate),
              initial: _doneDate,
              firstDate: DateTime(DateTime.now().year - 5),
              // 服务端挡「驱虫日期不能晚于今天」，界面上直接把那一天挡在选择器外面。
              lastDate: DateTime.now(),
              onPicked: (picked) => setState(() {
                _doneDate = picked;
                // 原来那份下次日期会落到本次之前，留着它就是一条服务端会拒的值
                final next = _nextDate;
                if (next != null && !next.isAfter(picked)) _nextDate = null;
              }),
            ),
            _dateTile(
              label: '下次驱虫日期',
              value: _nextDate == null ? '按周期算' : formatDate(_nextDate!),
              initial: _nextDate ?? _doneDate,
              firstDate: _doneDate,
              lastDate: DateTime(DateTime.now().year + 10),
              onPicked: (picked) => setState(() => _nextDate = picked),
              onClear: _nextDate == null
                  ? null
                  : () => setState(() => _nextDate = null),
            ),
            Text(
              _monthsHint(setting),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _medicine,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: '药品名称',
                hintText: '拜宠清、大宠爱',
              ),
              validator: _medicineError,
            ),
            if (medicineCandidates.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final name in medicineCandidates)
                    ActionChip(
                      label: Text(name),
                      onPressed: () {
                        _medicine.text = name;
                        // 这一屏没有 autovalidateMode，改 text 不重跑 validator，
                        // 先前撞出来的那行红字要在这里收掉
                        _formKey.currentState?.validate();
                      },
                    ),
                ],
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _dosage,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: '规格 / 剂量（选填）',
                hintText: '半片、1 支',
              ),
            ),
            TextFormField(
              controller: _remark,
              maxLength: 200,
              decoration: const InputDecoration(labelText: '备注'),
            ),
            const SizedBox(height: 24),
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
              tooltip: '改为按周期算',
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
}

DateTime _clamp(DateTime value, DateTime first, DateTime last) {
  if (value.isBefore(first)) return first;
  if (value.isAfter(last)) return last;
  return value;
}
