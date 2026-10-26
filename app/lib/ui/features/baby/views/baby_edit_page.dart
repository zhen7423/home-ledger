import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/baby.dart';
import '../../../../data/repositories/baby_repository.dart';
import '../../../../data/services/network_status.dart';
import '../../../core/app_widgets.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../../../core/photo_picker.dart';
import '../../../core/profile_photo_field.dart';
import '../../../core/validators.dart';
import '../baby_copy.dart';
import '../view_models/baby_list_view_model.dart';

/// 出生身高的小数位数与列 `DECIMAL(5,1)` 对齐，出生体重与 `DECIMAL(5,2)` 对齐。
/// **只判形态不判范围**：20–200 / 1–100 那两条由服务端的 `@DecimalMin/@DecimalMax` 出文案，
/// 前端复制一份迟早与服务端漂移，而漂移的表现是「前端放行、服务端拒绝」。
/// 多出来的小数位则必须在这里挡：MySQL 会把它悄悄四舍五入，界面上看到的与库里存的对不上。
final RegExp _oneDecimal = RegExp(r'^\d+(?:\.\d)?$');
final RegExp _twoDecimals = RegExp(r'^\d+(?:\.\d{1,2})?$');

String? _decimalError(String? value, RegExp pattern, String message) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  return pattern.hasMatch(text) ? null : message;
}

/// §4.4.1 的建档与编辑，同一页靠 `?id=` 有没有值区分（常态是新增，§1.3 第 1 条）。
///
/// 保存成功**不自动跳**：总览与统计由 `BabyListViewModel` 扇出刷新，用户按返回键回去看到的
/// 已经是新的那一份；这里直接 pop 会把「保存成功」这句反馈也一起吃掉——归档与删除才有
/// 明确的下一个落点。
class BabyEditPage extends ConsumerStatefulWidget {
  const BabyEditPage({super.key, this.id});

  final int? id;

  bool get isEdit => id != null;

  @override
  ConsumerState<BabyEditPage> createState() => _BabyEditPageState();
}

class _BabyEditPageState extends ConsumerState<BabyEditPage> {
  /// 顺序写死（男在前）、文案取自 `genderLabels`：两处各写一份的话，迟早一处改而另一处不改。
  static final List<(String, String)> _genders = [
    for (final entry in genderLabels.entries) (entry.key, entry.value),
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _remark = TextEditingController();

  String _gender = 'MALE';
  DateTime? _birthDate;

  /// 出生日期是必填，但它是 `ListTile` 不是 `TextFormField`，`Form.validate()` 管不到它。
  /// 所以这条错误自己拿一个字段装着，选到日期就清掉。
  String? _dateError;

  /// 编辑态下改生日要提示一句「清单会重算」，判据是「与原值不同」——与 ViewModel 扇出时所比的
  /// 是同一件事，两处都用 `formatDate` 比而不是 `==` 比（时分秒没有含义）。
  Baby? _original;

  bool _saving = false;

  /// S10 档案照片：独立端点上传/清除，不进整份表单；本地留一份展示用的相对路径。
  String? _photoUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadOriginal();
  }

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _weight.dispose();
    _remark.dispose();
    super.dispose();
  }

  Future<void> _loadOriginal() async {
    // 必须先 future 再 byId：`BabyListViewModel.byId` 读的是已经加载好的那份列表（服务端没有
    // 单宝宝的详情端点），冷启动直接 push 进编辑页时那份列表还在飞，少了这一行 await 会把它
    // 读成「没有这个宝宝」，症状是刚建档完从列表点进去立刻被弹回。
    await ref.read(babyListViewModelProvider.future);
    if (!mounted) return;

    final baby = ref.read(babyListViewModelProvider.notifier).byId(widget.id!);
    if (baby == null) {
      showSnackBar(context, '没有找到这个宝宝，它可能已经被删除了');
      context.pop();
      return;
    }

    _name.text = baby.name;
    _height.text = baby.birthHeight ?? '';
    _weight.text = baby.birthWeight ?? '';
    _remark.text = baby.remark ?? '';
    setState(() {
      _original = baby;
      _gender = baby.gender;
      _birthDate = baby.birthDate;
      _photoUrl = baby.photoUrl;
      _dateError = null;
    });
  }

  /// 选一张图、压缩到 5 MB 以内、上传，成功后用返还的 photoUrl 刷新本地预览。
  Future<void> _pickPhoto() async {
    if (_uploading) return;
    // 入口只在编辑态渲染（id 非空），理论不达；留一道同步守卫，
    // 既不让空断言以未处理异常逃逸，也不在 async gap 后拿 context（C1）。
    final id = widget.id;
    if (id == null) {
      showSnackBar(context, '请先保存档案，再上传照片');
      return;
    }
    setState(() => _uploading = true);
    try {
      final bytes = await pickAndCompressProfilePhoto();
      if (bytes == null) return; // 用户取消，不是失败
      final notifier = ref.read(babyListViewModelProvider.notifier);
      final error = await notifier.setPhoto(id, bytes, 'profile.jpg');
      if (!mounted) return;
      if (error == null) {
        setState(() => _photoUrl = notifier.byId(id)?.photoUrl);
      } else {
        showSnackBar(context, error);
      }
    } on PhotoSelectException catch (e) {
      if (mounted) showSnackBar(context, e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _clearPhoto() async {
    final id = widget.id;
    if (id == null) return; // 入口只在编辑态渲染，防御同 _pickPhoto
    final confirmed = await confirmAction(
      context,
      title: '删除这张照片？',
      message: '可以在编辑页重新上传一张。',
      confirmLabel: '删除',
    );
    if (!confirmed) return;
    setState(() => _uploading = true);
    try {
      final notifier = ref.read(babyListViewModelProvider.notifier);
      final error = await notifier.clearPhoto(id);
      if (!mounted) return;
      if (error == null) {
        setState(() => _photoUrl = null);
      } else {
        showSnackBar(context, error);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final birthDate = _birthDate;

    // 上界就是今天：出生的日子不可能在未来（§4.4.1）。服务端也会拒，这一格是让它更好点。
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate == null || birthDate.isAfter(today)
          ? today
          : birthDate,
      firstDate: DateTime(1990),
      lastDate: today,
    );
    if (picked == null) return;
    setState(() {
      _birthDate = picked;
      _dateError = null;
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    final birthDate = _birthDate;
    setState(() {
      _dateError = birthDate == null ? '请选择出生日期' : null;
    });
    if (!valid || birthDate == null) return;

    // 改生日会让服务端在同一事务里整份重算应种清单（§4.4.4），这比其它字段的改动重得多，
    // 所以编辑态下先问一句。新增态不弹：那一步本来就要生成清单。
    if (widget.isEdit && _birthDateChanged(birthDate)) {
      final confirmed = await confirmAction(
        context,
        title: '改了出生日期',
        message: '保存后会按新的出生日期重算应种清单，已接种与已跳过的记录不受影响。',
        confirmLabel: '继续保存',
      );
      if (!confirmed || !mounted) return;
    }

    final draft = BabyDraft(
      name: _name.text.trim(),
      gender: _gender,
      birthDate: birthDate,
      birthHeight: _optional(_height.text),
      birthWeight: _optional(_weight.text),
      remark: _optional(_remark.text),
    );
    setState(() => _saving = true);

    final notifier = ref.read(babyListViewModelProvider.notifier);
    final error = widget.isEdit
        ? await notifier.save(widget.id!, draft)
        : await notifier.create(draft);
    if (!mounted) return;
    setState(() {
      _saving = false;
      // 接着改第二次时「改没改生日」要拿刚存下的那一份比，否则同一个生日会被问第二次。
      if (error == null && widget.isEdit) {
        _original = notifier.byId(widget.id!);
      }
    });

    showSnackBar(context, error ?? (widget.isEdit ? '已保存' : '已建档'));
  }

  bool _birthDateChanged(DateTime birthDate) {
    final original = _original;
    return original == null ||
        formatDate(original.birthDate) != formatDate(birthDate);
  }

  /// 空串交 `null` 而不是 `'0'`：`'0'` 会在服务端撞 `@DecimalMin`，
  /// 而用户只是没填这一栏（选填的三个度量都走这里）。
  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) {
    final canSubmit = ref.watch(canSubmitProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? '编辑宝宝' : '宝宝建档')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // 只对「已存在的宝宝」出现：照片挂在 baby id 上（POST /babies/{id}/photo），
            // 建档态没有 id，渲染出来只会把 widget.id! 撞爆（S10 审查 C1）。先建档、再进编辑页加照片。
            if (widget.isEdit) ...[
              ProfilePhotoField(
                photoUrl: _photoUrl,
                enabled: canSubmit,
                uploading: _uploading,
                onPick: _pickPhoto,
                onClear: _clearPhoto,
                placeholderIcon: Icons.child_care_outlined,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _name,
              maxLength: 12,
              decoration: const InputDecoration(
                labelText: '姓名/小名',
                hintText: '朵朵',
                counterText: '',
              ),
              // 复用 `validateNickname`：长度上限（12 字符）与 §4.4.1 那一行一致，
              // 「昵称」与这一栏的「姓名/小名」是同一件事，`ui/core` 里也没有第二档名字校验器。
              validator: validateNickname,
            ),
            const SizedBox(height: 16),
            const _FieldLabel('性别'),
            _Segmented(
              options: _genders,
              selected: _gender,
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('出生日期'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake_outlined),
              trailing: Text(
                _birthDate == null ? '请选择' : formatDate(_birthDate!),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: _pickBirthDate,
            ),
            _ErrorLine(text: _dateError),
            const SizedBox(height: 16),
            TextFormField(
              controller: _height,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'\d*\.?\d{0,1}')),
              ],
              decoration: const InputDecoration(
                labelText: '出生身高（cm，选填）',
                hintText: '50.0',
              ),
              validator: (value) =>
                  _decimalError(value, _oneDecimal, '出生身高最多一位小数'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: '出生体重（kg，选填）',
                hintText: '3.25',
              ),
              validator: (value) =>
                  _decimalError(value, _twoDecimals, '出生体重最多两位小数'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _remark,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: '备注（选填）',
                hintText: '出生医院、过敏史',
              ),
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

/// 两选一（性别）。段数与 `cat_edit_page.dart` 那个同名件不同，形状一样，
/// 照抄一份而不是提成公共组件：二十行、两个入参、零逻辑，抽出去要在 `ui/core/` 新开文件。
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<String>(
    segments: [
      for (final (value, label) in options)
        ButtonSegment(value: value, label: Text(label)),
    ],
    selected: {selected},
    showSelectedIcon: false,
    onSelectionChanged: (selection) => onChanged(selection.first),
  );
}
