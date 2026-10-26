import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/baby_formula_bag.dart';
import '../../../../data/repositories/baby_formula_bag_repository.dart';
import '../../../../data/services/network_status.dart';
import '../../../core/app_widgets.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../view_models/baby_formula_view_model.dart';

/// §4.5.3 的记一罐与改一罐，同一页靠 `id` 有没有值区分。
///
/// 表单里没有「什么时候喝完」这一栏：那是下一罐的开罐日推出来的，写进来就成了第二个真相。
/// 表单里多一个「预计每天克数（选填）」，只在没有可用历史罐时兜底——首次开罐顺手填一个，
/// 之后有历史了它就退居二线（推算规则在服务端 ConsumptionEstimate，本页只负责收数）。
class BabyFormulaBagEditPage extends ConsumerStatefulWidget {
  const BabyFormulaBagEditPage({this.id, super.key});

  /// null = 新开一罐。非空是改那一罐，走 `byId` 回填（服务端没有单罐的详情端点）。
  final int? id;

  bool get isEdit => id != null;

  @override
  ConsumerState<BabyFormulaBagEditPage> createState() =>
      _BabyFormulaBagEditPageState();
}

class _BabyFormulaBagEditPageState extends ConsumerState<BabyFormulaBagEditPage> {
  static const int _maxPackGrams = 100000;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _packGrams = TextEditingController();
  final TextEditingController _dailyGrams = TextEditingController();
  final TextEditingController _remark = TextEditingController();

  String? _brand;

  /// 默认今天：这一屏绝大多数时候是「刚拆一罐，顺手记上」。
  DateTime _startedDate = DateTime.now();

  /// 开罐具体时刻，选填（2026-10-26 需求①）。新建默认当前时刻——「顺手记上」的场景里
  /// 现在就是开罐那一刻；编辑老罐（历史上没存过时刻）时保持 null，不替用户编一个。
  TimeOfDay? _startedTime = TimeOfDay.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadOriginal();
  }

  @override
  void dispose() {
    _packGrams.dispose();
    _dailyGrams.dispose();
    _remark.dispose();
    super.dispose();
  }

  Future<void> _loadOriginal() async {
    await ref.read(babyFormulaViewModelProvider.future);
    if (!mounted) return;

    final bag =
        ref.read(babyFormulaViewModelProvider.notifier).byId(widget.id!);
    if (bag == null) {
      showSnackBar(context, '没有找到这一罐奶粉，它可能已经被删除了');
      context.pop();
      return;
    }

    _brand = bag.brand;
    _packGrams.text = '${bag.packGrams}';
    _dailyGrams.text = bag.estimatedDailyGrams?.toString() ?? '';
    _remark.text = bag.remark ?? '';
    setState(() {
      _startedDate = bag.startedDate;
      _startedTime = _timeOf(bag.startedTime);
    });
  }

  /// 出现过的品牌，最近开过的那一罐排第一。
  List<String> _brandChoices(List<BabyFormulaBag> bags) {
    final seen = <String>[];
    for (final bag in bags) {
      if (!seen.contains(bag.brand)) seen.add(bag.brand);
    }
    return seen.reversed.toList();
  }

  /// 这个品牌最近一罐的包装规格。`bags` 是 `startedDate` 升序，最后一个匹配就是最近那罐。
  int? _lastPackOf(List<BabyFormulaBag> bags, String brand) {
    int? grams;
    for (final bag in bags) {
      if (bag.brand == brand) grams = bag.packGrams;
    }
    return grams;
  }

  /// §4.5.3 的便利：换一个品牌就把它上次的规格带上来，省一次重复输入。
  /// 只在品牌**真的变了**时覆盖。
  void _selectBrand(String brand) {
    if (brand == _brand) return;
    final bags =
        ref.read(babyFormulaViewModelProvider).value ?? const <BabyFormulaBag>[];
    final grams = _lastPackOf(bags, brand);
    setState(() {
      _brand = brand;
      if (grams != null) _packGrams.text = '$grams';
    });
  }

  String? _brandFieldError(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '请填写奶粉品牌';
    if (text.length > 20) return '奶粉品牌最多 20 个字符';
    return null;
  }

  Future<void> _pickOtherBrand() async {
    final brand = await promptForText(
      context,
      title: '奶粉品牌',
      label: '品牌名称',
      initialValue: _brand,
      validator: _brandFieldError,
    );
    if (brand == null || !mounted) return;
    setState(() => _brand = brand);
  }

  String? _packError(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '请填写包装规格';
    final grams = int.tryParse(text);
    if (grams == null) return '包装规格要填整数克';
    if (grams < 1) return '包装规格至少 1 克';
    if (grams > _maxPackGrams) return '包装规格最大 $_maxPackGrams 克';
    return null;
  }

  /// 与服务端的 `@Min(1)` / `@Max(2000)` 逐字对齐；空串 = 不填这一栏，发给服务端的是 null。
  String? _dailyGramsError(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final grams = int.tryParse(text);
    if (grams == null) return '预计每天克数要填整数';
    if (grams < 1) return '预计每天克数至少 1 克';
    if (grams > 2000) return '预计每天克数最大 2000 克';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final brand = _brand?.trim();
    if (brand == null || brand.isEmpty) {
      showSnackBar(context, '请填写奶粉品牌');
      return;
    }
    final daily = _dailyGrams.text.trim();
    final draft = BabyFormulaBagDraft(
      brand: brand,
      packGrams: int.parse(_packGrams.text.trim()),
      startedDate: _startedDate,
      startedTime: _startedTime == null ? null : _formatTime(_startedTime!),
      estimatedDailyGrams: daily.isEmpty ? null : int.parse(daily),
      remark: _remark.text.trim().isEmpty ? null : _remark.text.trim(),
    );
    setState(() => _saving = true);

    final notifier = ref.read(babyFormulaViewModelProvider.notifier);
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
    final bags =
        ref.watch(babyFormulaViewModelProvider).value ?? const <BabyFormulaBag>[];

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? '编辑奶粉罐' : '记一罐奶粉')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _chipField(
              label: '奶粉品牌',
              children: [
                for (final brand in _brandChoices(bags))
                  ChoiceChip(
                    label: Text(brand),
                    selected: _brand == brand,
                    onSelected: (_) => _selectBrand(brand),
                  ),
                if (_brand != null &&
                    !bags.any((bag) => bag.brand == _brand))
                  ChoiceChip(
                    label: Text(_brand!),
                    selected: true,
                    onSelected: (_) {},
                  ),
                ActionChip(
                  avatar: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(_brand == null ? '其他品牌' : '换一个'),
                  onPressed: _pickOtherBrand,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _packGrams,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '包装规格（克）',
                hintText: '800',
                suffixText: 'g',
              ),
              validator: _packError,
            ),
            const SizedBox(height: 8),
            _dateTile(
              label: '开罐日期',
              value: formatDate(_startedDate),
              initial: _startedDate,
              // 可回溯补录（§4.5.3 那句「忘了记也要能补」），但未来的那一天还没有奶粉可喝。
              firstDate: DateTime(DateTime.now().year - 5),
              lastDate: DateTime.now(),
              onPicked: (picked) => setState(() => _startedDate = picked),
            ),
            _timeTile(
              label: '开罐时间',
              value: _startedTime,
              // 与日期同一句「未来的那一刻还没有奶粉可喝」：选今天时时刻不许晚于现在（服务端也会再挡一次）。
              onChanged: (picked) => setState(() => _startedTime = picked),
            ),
            TextFormField(
              controller: _dailyGrams,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '预计每天克数（选填）',
                hintText: '如 120',
                helperText: '只在还没有历史罐时兜底，有历史后按实际消耗折算',
                suffixText: 'g',
              ),
              validator: _dailyGramsError,
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
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
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

  /// 开罐时间行（2026-10-26 需求①）。选填：`value` 为 null 显示「不填」，
  /// trailing 是「清除」而不是值本身，一眼能看出这栏可以留空。
  Widget _timeTile({
    required String label,
    required TimeOfDay? value,
    required ValueChanged<TimeOfDay?> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule_outlined),
      title: Text(value == null ? '$label（选填）' : label),
      trailing: value == null
          ? Text('不填', style: Theme.of(context).textTheme.titleMedium)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(value),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: '清除时间，只记日期',
                  onPressed: () => onChanged(null),
                ),
              ],
            ),
      onTap: () async {
        final now = TimeOfDay.now();
        // 开罐日期是今天时初始值钳到当前时刻之前（选择器没有上限参数，选了更晚的时刻
        // 由服务端 assertTimeNotFuture 挡回「开罐时间不能晚于当前时刻」）；补录历史日期不受限。
        var initial = value ?? now;
        if (_isToday(_startedDate) && _after(initial, now)) initial = now;
        final picked = await showTimePicker(context: context, initialTime: initial);
        if (picked != null) onChanged(picked);
      },
    );
  }

  static String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  /// "08:30" / "08:30:45" → TimeOfDay；坏值当 null（只显示日期，不让一条脏数据堵住编辑页）。
  static TimeOfDay? _timeOf(String? text) {
    if (text == null) return null;
    final parts = text.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool _after(TimeOfDay a, TimeOfDay b) =>
      a.hour != b.hour ? a.hour > b.hour : a.minute > b.minute;
}

DateTime _clamp(DateTime value, DateTime first, DateTime last) {
  if (value.isBefore(first)) return first;
  if (value.isAfter(last)) return last;
  return value;
}