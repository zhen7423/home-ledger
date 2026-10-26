import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/cat_repository.dart';
import '../../../../data/services/network_status.dart';
import '../../../core/app_widgets.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../../../core/photo_picker.dart';
import '../../../core/profile_photo_field.dart';
import '../../../core/validators.dart';
import '../view_models/cat_view_model.dart';

/// §4.3.1 的建档与编辑，同一页靠 `id` 有没有值区分——照周期规则那页的做法。
///
/// 生日这一栏有三种给法（精确日 / 只到月 / 不填），它们交上去的是 `birthday` 与
/// `birthdayEstimated` 两个字段，而不是一个「生日类型」枚举：服务端存的就是那两列。
class CatEditPage extends ConsumerStatefulWidget {
  const CatEditPage({super.key, this.id});

  final int? id;

  bool get isEdit => id != null;

  @override
  ConsumerState<CatEditPage> createState() => _CatEditPageState();
}

class _CatEditPageState extends ConsumerState<CatEditPage> {
  static const List<(String, String)> _genders = [
    ('MALE', '公'),
    ('FEMALE', '母'),
    ('UNKNOWN', '未知'),
  ];

  static const List<(String, String)> _neuteredStates = [
    ('YES', '已绝育'),
    ('NO', '未绝育'),
    ('UNKNOWN', '未知'),
  ];

  /// 下拉候选六条（§4.3.1 品种那行只给了三个示例）。纯前端常量：不落库、不进接口。
  static const List<String> _breeds = [
    '中华田园猫',
    '英国短毛猫',
    '美国短毛猫',
    '布偶猫',
    '暹罗猫',
    '缅因猫',
  ];

  /// 生日的三种给法。不填那一支交上去的是 `birthday: null`，服务端那一列本来就允许空。
  static const String _birthdayExact = 'EXACT';
  static const String _birthdayEstimated = 'ESTIMATED';
  static const String _birthdayUnknown = 'UNKNOWN';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _remark = TextEditingController();

  String _gender = 'UNKNOWN';
  String _neutered = 'UNKNOWN';
  String _birthdayScope = _birthdayUnknown;
  DateTime? _birthday;
  String? _breed;
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
    _weight.dispose();
    _remark.dispose();
    super.dispose();
  }

  Future<void> _loadOriginal() async {
    // 必须先 future 再 byId：`CatViewModel.byId` 读的是已经加载好的那份列表（服务端没有单只猫的详情端点），
    // 冷启动直接 push 进编辑页时那份列表还在飞，少了这一行 await 会把它读成「没有这只猫」，
    // 症状是从倒计时点进一只没看过的猫立刻被弹回来。
    await ref.read(catViewModelProvider.future);
    if (!mounted) return;

    final cat = ref.read(catViewModelProvider.notifier).byId(widget.id!);
    if (cat == null) {
      showSnackBar(context, '没有找到这只猫咪，它可能已经被删除了');
      context.pop();
      return;
    }

    _name.text = cat.name;
    _gender = cat.gender;
    _neutered = cat.neutered;
    _breed = cat.breed;
    _weight.text = cat.weightKg ?? '';
    _remark.text = cat.remark ?? '';
    final birthday = cat.birthday;
    setState(() {
      _photoUrl = cat.photoUrl;
      _birthday = birthday;
      _birthdayScope = birthday == null
          ? _birthdayUnknown
          : cat.birthdayEstimated
          ? _birthdayEstimated
          : _birthdayExact;
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
      final notifier = ref.read(catViewModelProvider.notifier);
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
      final notifier = ref.read(catViewModelProvider.notifier);
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

  /// 选填，所以空串直接放过；填了才判形与界。三句文案与服务端那三条注解逐字对齐，
  /// 用户在客户端被拦下的那句与服务端那句要一样。
  String? _weightError(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'\d+(?:\.\d{1,2})?$').hasMatch(text)) return '体重最多两位小数';
    final weight = double.tryParse(text);
    if (weight == null || weight < 0.01) return '体重要大于 0';
    if (weight > 999.99) return '体重最大 999.99 kg';
    return null;
  }

  /// 估算态存该月 1 日（§4.3.1 只填年月那一支）。日在这一支没有含义，
  /// 但那一列要有值才能参与后端的年龄与体重区间运算。
  void _setEstimatedBirthday(int year, int month) =>
      setState(() => _birthday = DateTime(year, month));

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = CatDraft(
      name: _name.text.trim(),
      gender: _gender,
      birthday: _birthdayScope == _birthdayUnknown ? null : _birthday,
      birthdayEstimated: _birthdayScope == _birthdayEstimated,
      breed: _breed,
      weightKg: _weight.text.trim().isEmpty ? null : _weight.text.trim(),
      neutered: _neutered,
      remark: _remark.text.trim().isEmpty ? null : _remark.text.trim(),
    );
    setState(() => _saving = true);

    final notifier = ref.read(catViewModelProvider.notifier);
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

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? '编辑猫咪' : '猫咪建档')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // 只对「已存在的猫」出现：照片挂在 cat id 上（POST /cats/{id}/photo），
            // 建档态没有 id，渲染出来只会把 widget.id! 撞爆（S10 审查 C1）。先建档、再进编辑页加照片。
            if (widget.isEdit) ...[
              ProfilePhotoField(
                photoUrl: _photoUrl,
                enabled: canSubmit,
                uploading: _uploading,
                onPick: _pickPhoto,
                onClear: _clearPhoto,
                placeholderIcon: Icons.pets_outlined,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _name,
              maxLength: 12,
              decoration: const InputDecoration(
                labelText: '昵称',
                hintText: '咪咪',
                counterText: '',
              ),
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
            _Segmented(
              options: const [
                (_birthdayExact, '精确到日'),
                (_birthdayEstimated, '只到月份'),
                (_birthdayUnknown, '不填'),
              ],
              selected: _birthdayScope,
              onChanged: (value) => setState(() {
                _birthdayScope = value;
                if (value == _birthdayUnknown) _birthday = null;
              }),
            ),
            if (_birthdayScope == _birthdayExact) _birthdayDateTile(),
            if (_birthdayScope == _birthdayEstimated) _birthdayMonthPickers(),
            const SizedBox(height: 16),
            const _FieldLabel('品种'),
            _breedChips(),
            const SizedBox(height: 16),
            const _FieldLabel('是否绝育'),
            _Segmented(
              options: _neuteredStates,
              selected: _neutered,
              onChanged: (value) => setState(() => _neutered = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: '体重（kg，选填）',
                hintText: '4.25',
              ),
              validator: _weightError,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _remark,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: '备注（选填）',
                hintText: '绝育医院、性格',
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

  /// 上界就是今天：一个还没出生的生日没有意义，服务端的「生日不能晚于今天」由这一格挡住。
  Widget _birthdayDateTile() {
    final today = DateTime.now();
    final birthday = _birthday;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.cake_outlined),
      title: const Text('出生日期'),
      trailing: Text(
        birthday == null ? '请选择' : formatDate(birthday),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: birthday == null || birthday.isAfter(today)
              ? today
              : birthday,
          firstDate: DateTime(1990),
          lastDate: today,
        );
        if (picked != null) setState(() => _birthday = picked);
      },
    );
  }

  /// 「只填年月」不能用 `showDatePicker`：那个选择器最后仍然要挑一个日，用户取消不了那一步，
  /// 交上来的仍是一个精确日期，而「这是估算」就成了猜的。两个下拉是唯一的写法。
  Widget _birthdayMonthPickers() {
    final thisYear = DateTime.now().year;
    final years = [for (var year = 1990; year <= thisYear; year++) year];
    final selectedYear = _birthday?.year;
    final lastMonth = selectedYear == thisYear ? DateTime.now().month : 12;
    final months = [for (var month = 1; month <= lastMonth; month++) month];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: selectedYear,
              decoration: const InputDecoration(labelText: '出生年'),
              items: [
                for (final year in years)
                  DropdownMenuItem(value: year, child: Text('$year 年')),
              ],
              onChanged: (year) {
                if (year == null) return;
                // 换了年，原来那个月可能落到今年不存在的那几个月里，一起清掉重挑。
                final month = _birthday?.month;
                _setEstimatedBirthday(
                  year,
                  year == thisYear && month != null && month <= lastMonth
                      ? month
                      : 1,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: selectedYear == null ? null : _birthday?.month,
              decoration: const InputDecoration(labelText: '出生月'),
              items: [
                for (final month in months)
                  DropdownMenuItem(value: month, child: Text('$month 月')),
              ],
              onChanged: (month) {
                final year = selectedYear;
                if (month == null || year == null) return;
                _setEstimatedBirthday(year, month);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _breedChips() {
    // 自定义过的品种不在候选里，也要渲染一枚选中态的芯片，否则用户改完回来看到的是一排都没选中。
    final chips = {
      for (final breed in _breeds) breed,
      if (_breed != null && !_breeds.contains(_breed)) _breed!,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final breed in chips)
          ChoiceChip(
            label: Text(breed),
            selected: _breed == breed,
            onSelected: (selected) =>
                setState(() => _breed = selected ? breed : null),
          ),
        ActionChip(
          avatar: const Icon(Icons.edit_outlined, size: 18),
          label: Text(chips.contains(_breed) ? '其他' : '自定义'),
          onPressed: () async {
            final value = await promptForText(
              context,
              title: '品种',
              label: '猫咪品种',
              initialValue: chips.contains(_breed) ? null : _breed,
              validator: (v) => (v ?? '').length > 20 ? '品种最多 20 个字符' : null,
            );
            if (value != null && value.isNotEmpty) {
              setState(() => _breed = value);
            }
          },
        ),
      ],
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

/// 三处单选（性别 / 生日给法 / 是否绝育）同一形状，段数不同而已，所以抽一个私有件。
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
