import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/cat_food_bag.dart';
import '../../../../data/repositories/cat_food_bag_repository.dart';
import '../../../../data/services/network_status.dart';
import '../../../core/app_widgets.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../view_models/cat_food_bag_view_model.dart';

/// §4.3.2 的记一袋与改一袋，同一页靠 `id` 有没有值区分。
///
/// 表单里没有「什么时候吃完」这一栏：那是下一袋的开始日推出来的，写进来就成了第二个真相。
class CatFoodBagEditPage extends ConsumerStatefulWidget {
  const CatFoodBagEditPage({this.id, super.key});

  /// null = 新开一袋。非空是改那一袋，走 `byId` 回填（服务端没有单袋的详情端点）。
  final int? id;

  bool get isEdit => id != null;

  @override
  ConsumerState<CatFoodBagEditPage> createState() =>
      _CatFoodBagEditPageState();
}

class _CatFoodBagEditPageState extends ConsumerState<CatFoodBagEditPage> {
  /// 与服务端那条 `@Max(100000)` 同一个数。这一份上限不是「够用就行」：
  /// 它是「预计耗尽日」那步加法不溢出的前提，上界由服务端那一注解挡着。
  static const int _maxPackGrams = 100000;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _packGrams = TextEditingController();
  final TextEditingController _remark = TextEditingController();

  String? _brand;

  /// 默认今天：这一屏绝大多数时候是「刚拆一袋，顺手记上」。
  DateTime _startedDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) _loadOriginal();
  }

  @override
  void dispose() {
    _packGrams.dispose();
    _remark.dispose();
    super.dispose();
  }

  Future<void> _loadOriginal() async {
    // 先 future 再 byId：没有 `GET /cat-food-bags/{id}`，编辑页读的是那份已经加载好的列表。
    await ref.read(catFoodBagViewModelProvider.future);
    if (!mounted) return;

    final bag = ref.read(catFoodBagViewModelProvider.notifier).byId(widget.id!);
    if (bag == null) {
      showSnackBar(context, '没有找到这一袋猫粮，它可能已经被删除了');
      context.pop();
      return;
    }

    // 规格直接写控制器，不走 _selectBrand：那条是「换品牌时带出上次规格」的便利，
    // 回填时品牌没换过，走它会把这一袋自己的 packGrams 换成同品牌最近一袋的值。
    _brand = bag.brand;
    _packGrams.text = '${bag.packGrams}';
    _remark.text = bag.remark ?? '';
    setState(() => _startedDate = bag.startedDate);
  }

  /// 出现过的品牌，最近开过的那一袋排第一。
  ///
  /// 与时间线那一屏的排序不矛盾：那一屏显示的是派生值、顺序由服务端定；这一排是一列**候选芯片**，
  /// 顺序只影响眼睛先扫到哪个，不改变任何数字。
  List<String> _brandChoices(List<CatFoodBag> bags) {
    final seen = <String>[];
    for (final bag in bags) {
      if (!seen.contains(bag.brand)) seen.add(bag.brand);
    }
    return seen.reversed.toList();
  }

  /// 这个品牌最近一袋的包装规格。`bags` 是 `startedDate` 升序，所以最后一个匹配就是最近那袋。
  int? _lastPackOf(List<CatFoodBag> bags, String brand) {
    int? grams;
    for (final bag in bags) {
      if (bag.brand == brand) grams = bag.packGrams;
    }
    return grams;
  }

  /// §4.3.2 的便利：换一个品牌就把它上次的规格带上来，省一次重复输入。
  ///
  /// 只在品牌**真的变了**时覆盖：点已选中的那枚也覆盖的话，用户刚手改的 1800 会被
  /// 悄悄换回历史里的 2000，而输入框看起来什么都没发生。
  void _selectBrand(String brand) {
    if (brand == _brand) return;
    final bags =
        ref.read(catFoodBagViewModelProvider).value ?? const <CatFoodBag>[];
    final grams = _lastPackOf(bags, brand);
    setState(() {
      _brand = brand;
      if (grams != null) _packGrams.text = '$grams';
    });
  }

  /// 与服务端的 `@NotBlank` / `@Size(max = 20)` 逐字对齐。品牌是一排芯片，
  /// 但这个对话框里是一个输入框，所以要带校验器。
  String? _brandFieldError(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '请填写猫粮品牌';
    if (text.length > 20) return '猫粮品牌最多 20 个字符';
    return null;
  }

  /// 自定义品牌**不走** `_selectBrand`：这个品牌服务端从没见过，`_lastPackOf` 必然回 null，
  /// 走一圈的结果一样但多一次遍历；更重要的是 `_selectBrand` 的语义是「换品牌时带出上次规格」，
  /// 而这里用户已经填好的规格不该被一次品牌输入改动。
  Future<void> _pickOtherBrand() async {
    final brand = await promptForText(
      context,
      title: '猫粮品牌',
      label: '品牌名称',
      initialValue: _brand,
      validator: _brandFieldError,
    );
    if (brand == null || !mounted) return;
    setState(() => _brand = brand);
  }

  /// 四句文案与服务端的 `@NotNull` / `@Min` / `@Max` 逐字对齐。
  /// 「要填整数克」这一句 `digitsOnly` 挡不住——它是给粘贴进来的 `1,2` 或空值绕过表单时兜底的。
  String? _packError(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '请填写包装规格';
    final grams = int.tryParse(text);
    if (grams == null) return '包装规格要填整数克';
    if (grams < 1) return '包装规格至少 1 克';
    if (grams > _maxPackGrams) return '包装规格最大 $_maxPackGrams 克';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final brand = _brand?.trim();
    if (brand == null || brand.isEmpty) {
      // 品牌是一排芯片，不在 `Form` 里，`validate()` 拦不到它。
      showSnackBar(context, '请填写猫粮品牌');
      return;
    }

    final draft = CatFoodBagDraft(
      brand: brand,
      // 到这里 `_packError` 已经放行，`int.parse` 不会抛。
      packGrams: int.parse(_packGrams.text.trim()),
      startedDate: _startedDate,
      remark: _remark.text.trim().isEmpty ? null : _remark.text.trim(),
    );
    setState(() => _saving = true);

    final notifier = ref.read(catFoodBagViewModelProvider.notifier);
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
        ref.watch(catFoodBagViewModelProvider).value ?? const <CatFoodBag>[];

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? '编辑猫粮袋' : '记一袋猫粮')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _chipField(
              label: '猫粮品牌',
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
                hintText: '2000',
                suffixText: 'g',
              ),
              validator: _packError,
            ),
            const SizedBox(height: 8),
            _dateTile(
              label: '开始喂养日期',
              value: formatDate(_startedDate),
              initial: _startedDate,
              // 可回溯补录（§4.3.2 那句「忘了记也要能补」），但未来的那一天还没有粮可吃。
              firstDate: DateTime(DateTime.now().year - 5),
              lastDate: DateTime.now(),
              onPicked: (picked) => setState(() => _startedDate = picked),
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

  Widget _chipField({
    required String label,
    required List<Widget> children,
  }) {
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
              tooltip: '改为不限',
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
