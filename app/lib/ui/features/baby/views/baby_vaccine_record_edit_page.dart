import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/baby.dart';
import '../../../../data/models/baby_vaccine.dart';
import '../../../../data/repositories/baby_vaccine_record_repository.dart';
import '../../../../data/services/network_status.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../baby_copy.dart';
import '../view_models/baby_list_view_model.dart';
import '../view_models/baby_vaccine_record_view_model.dart';
import '../view_models/baby_vaccine_view_model.dart';

/// §4.4.4 的接种记录录入，同一页靠 `?id=` 有没有值区分新增与编辑（同 ⑤）。
///
/// 宝宝一栏：新增时是在册宝宝的选择器，编辑时只读——既有记录挂的宝宝可能已经归档，
/// 归档的宝宝不在选择器里，做成可改就等于「把这条记录挂到一个选不出来的宝宝身上」。
///
/// **`planId` 不在表单里**：新增时按「疫苗名称 + 剂次」自动匹配应种项、匹配到就回写 `DONE`
/// 是服务端的默认路径；只有从清单某一行点「补种」进来时才带 `planId`，而那个入口 S7 不开，
/// 所以它一直是 null。
class BabyVaccineRecordEditPage extends ConsumerStatefulWidget {
  const BabyVaccineRecordEditPage({super.key, this.id});

  final int? id;

  bool get isEdit => id != null;

  @override
  ConsumerState<BabyVaccineRecordEditPage> createState() =>
      _BabyVaccineRecordEditPageState();
}

class _BabyVaccineRecordEditPageState
    extends ConsumerState<BabyVaccineRecordEditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _dose = TextEditingController();
  final TextEditingController _clinic = TextEditingController();
  final TextEditingController _remark = TextEditingController();

  int? _babyId;
  DateTime? _givenDate;

  /// 从应种清单选中的那一行（问题单 4）。指名回写：服务端按 `planId` 绑定，不再按
  /// 「疫苗名称 + 剂次」自动匹配——用户改过名称或剂次、或换了宝宝时要把这一格清掉，
  /// 否则会把一条属于别的宝宝的应种项带进提交（服务端 `requirePlan` 会拒）。
  int? _planId;

  /// 接种日期是必填，但它是 `ListTile` 不是 `TextFormField`，`Form.validate()` 管不到它。
  String? _dateError;

  BabyVaccineRecord? _original;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadOriginal();
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _clinic.dispose();
    _remark.dispose();
    super.dispose();
  }

  Future<void> _loadOriginal() async {
    // 没有 `GET /baby-vaccine-records/{id}`：编辑表单要回填的那一行只能从整份列表里找，
    // 冷启动直接 push 进来时得先 await 它，否则会读成「没有这条记录」而弹回。
    await ref.read(babyVaccineRecordViewModelProvider.future);
    if (!mounted) return;

    final row = ref
        .read(babyVaccineRecordViewModelProvider.notifier)
        .byId(widget.id!);
    if (row == null) {
      showSnackBar(context, '没有找到这条接种记录，它可能已经被删除了');
      context.pop();
      return;
    }

    _name.text = row.vaccineName;
    _dose.text = row.doseNo;
    _clinic.text = row.clinic ?? '';
    _remark.text = row.remark ?? '';
    setState(() {
      _original = row;
      _babyId = row.babyId;
      _givenDate = row.givenDate;
      _dateError = null;
    });
  }

  /// 接种日期不可能早于出生日期，下界就取它；档案还没加载出来时退成 1990——与建档页同一个下界。
  DateTime _earliestDate() {
    final babyId = _babyId ?? _defaultBabyId();
    if (babyId == null) return DateTime(1990);
    for (final baby
        in ref.read(babyListViewModelProvider).value ?? const <Baby>[]) {
      if (baby.id == babyId) return baby.birthDate;
    }
    return DateTime(1990);
  }

  /// 多个在册宝宝时默认选中第一个（问题单 5）。只读 provider 的当前值：
  /// 在 initState 里读它时可能还没加载完，所以「喂给下拉框 + 提交」两处都用这一份兜底，
  /// 下拉框再配一个随值变化的 `key` 让它重建，数据一到就自动落在第一个宝宝上。
  int? _defaultBabyId() {
    for (final baby
        in ref.read(babyListViewModelProvider).value ?? const <Baby>[]) {
      if (!baby.archived) return baby.id;
    }
    return null;
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
    final valid = _formKey.currentState?.validate() ?? false;

    final givenDate = _givenDate;
    final babyId = _babyId ?? _defaultBabyId();
    setState(() {
      _dateError = givenDate == null ? '请选择接种日期' : null;
    });
    if (!valid || givenDate == null || babyId == null) return;

    final draft = VaccineRecordDraft(
      babyId: babyId,
      vaccineName: _name.text.trim(),
      doseNo: _dose.text.trim(),
      givenDate: givenDate,
      // 从清单选过就指名回写那一行；没选则交给服务端按键自动匹配（§4.4.4）。
      planId: _planId,
      clinic: _optional(_clinic.text),
      remark: _optional(_remark.text),
    );
    setState(() => _saving = true);

    final notifier = ref.read(babyVaccineRecordViewModelProvider.notifier);
    final error = widget.isEdit
        ? await notifier.save(widget.id!, draft)
        : await notifier.create(draft);
    if (!mounted) return;
    setState(() => _saving = false);

    // 保存成功回列表：清单那一段的对应行已经由服务端回写成「已接种」，退回「待接种」同理。
    if (error == null) {
      context.pop();
    } else {
      showSnackBar(context, error);
    }
  }

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  /// 从应种清单选的入口（问题单 4）：列出当前宝宝仍未接种（`PENDING`）的行，
  /// 点一枚就把名称与剂次填进下面两个输入框，同时记住 `planId` 指名回写。
  /// 没有任何待种行时不占位置——手动录入本来就是那几行的退路。
  /// `babyId` 可空：为空时（一个在册宝宝都没有）整页已换成建档引导，这里不渲染东西。
  Widget _planPicker(int? babyId, ThemeData theme) {
    if (babyId == null) return const SizedBox.shrink();
    final plans =
        ref.watch(babyVaccineViewModelProvider).value ?? const <BabyVaccinePlan>[];
    final candidates = [
      for (final plan in plans)
        if (plan.babyId == babyId && plan.status == 'PENDING') plan,
    ];
    if (candidates.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel('从应种清单选择（选填）'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final plan in candidates)
                ChoiceChip(
                  label: Text('${plan.vaccineName} ${doseLabel(plan.doseNo)}'),
                  selected: _planId == plan.id,
                  onSelected: (_) => _pickPlan(plan),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '选中的那一针会把对应应种项置为「已接种」；不选则按名称与剂次自动匹配。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 点一枚应种项：名称与剂次照抄进表单，`planId` 记下来指名回写。
  /// 手动改过名称或剂次后 `_planId` 会被清掉，交回服务端按新键重新匹配。
  void _pickPlan(BabyVaccinePlan plan) {
    setState(() {
      _planId = plan.id;
      _name.text = plan.vaccineName;
      _dose.text = plan.doseNo;
    });
    // 这一屏没有 autovalidateMode，改 text 不会重跑 validator，先前撞出来的红字要在这里收掉。
    _formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = ref.watch(canSubmitProvider);
    final babyList = ref.watch(babyListViewModelProvider);
    final babies = [
      for (final baby in babyList.value ?? const <Baby>[])
        if (!baby.archived) baby,
    ];
    // 默认选中第一个在册宝宝（问题单 5）。`null` 只可能是「一个都没有」——
    // 那一支整页已换成建档引导，不会带着空选择器渲染。
    final effectiveBabyId = _babyId ?? (babies.isEmpty ? null : babies.first.id);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? '编辑接种记录' : '记一次接种')),
      body: !widget.isEdit && babyList.hasValue && babies.isEmpty
          ? const _NoBabies()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (widget.isEdit)
                    ..._readOnlyBaby(context)
                  else ...[
                    DropdownButtonFormField<int>(
                      // 数据异步到达后要自动落在第一个宝宝上：`initialValue` 只在 FormField
                      // 首次挂载时读一次，这里用随值变化的 key 让它在兜底值改变时重建。
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
                      onChanged: (value) => setState(() {
                        _babyId = value;
                        // 换了宝宝，之前从清单选的那一行就不再属于当前宝宝（§4.4.4 的
                        // requirePlan 会拒跨宝宝回写），连名字一起清掉避免误提交。
                        _planId = null;
                      }),
                      validator: (value) => value == null ? '请选择宝宝' : null,
                    ),
                    _planPicker(effectiveBabyId, theme),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _name,
                    maxLength: 30,
                    // 手动改动名称就让「从清单选的那一行」失效：交回服务端按新键重新匹配。
                    onChanged: (_) => setState(() => _planId = null),
                    decoration: const InputDecoration(
                      labelText: '疫苗名称',
                      hintText: '如 乙肝疫苗',
                    ),
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? '请填写疫苗名称' : null,
                  ),
                  TextFormField(
                    controller: _dose,
                    maxLength: 8,
                    onChanged: (_) => setState(() => _planId = null),
                    decoration: const InputDecoration(
                      labelText: '剂次',
                      hintText: '如 1、加强针',
                    ),
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? '请填写剂次' : null,
                  ),
                  if (widget.isEdit)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '改疫苗名称或剂次会重新匹配应种清单',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const _FieldLabel('接种日期'),
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _clinic,
                    maxLength: 50,
                    decoration: const InputDecoration(labelText: '接种机构（选填）'),
                  ),
                  const SizedBox(height: 8),
                  const _FieldLabel('下一针日期'),
                  _nextDateNote(theme),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _remark,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: const InputDecoration(labelText: '备注（选填）'),
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

  /// §4.4.4：`nextDate` 不在 `VaccineRecordDraft` 里，服务端把「没给」与「给了 null」
  /// 当同一件事，一律按该疫苗下一个未完成剂次推算。**渲染成一个填了不生效的输入框，比不显示
  /// 更糟**——所以这里只有一行小字，编辑态顺手把服务端上次算出来的那个日期报出来。
  Widget _nextDateNote(ThemeData theme) {
    final nextDate = _original?.nextDate;
    return Text(
      nextDate == null
          ? '由服务端按该疫苗下一个未完成剂次推算，这里不能手填'
          : '由服务端推算，当前为 ${formatDate(nextDate)}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
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
              '接种记录要挂在宝宝名下，先建一个宝宝档案',
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
