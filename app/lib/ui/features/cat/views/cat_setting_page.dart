import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/cat_setting_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../../data/services/network_status.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../view_models/cat_setting_view_model.dart';

/// §4.3.3 的驱虫周期与 §4.3.4 的预估日均克数，三项都在这一屏。
///
/// 这是猫模块唯一一张「配置」而不是「记录」的表单（那张表每家庭一行），所以骨架比另外
/// 四个表单页少一半：没有 `byId` 回填、没有 `isEdit`、没有删除入口。
class CatSettingPage extends ConsumerStatefulWidget {
  const CatSettingPage({super.key});

  @override
  ConsumerState<CatSettingPage> createState() => _CatSettingPageState();
}

class _CatSettingPageState extends ConsumerState<CatSettingPage> {
  static const int _maxMonths = 12;

  /// 与服务端那条 `@Max(2000)` 同一个数。
  static const int _maxEstimatedGrams = 2000;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _internalMonths = TextEditingController();
  final TextEditingController _externalMonths = TextEditingController();
  final TextEditingController _estimatedDailyGrams = TextEditingController();

  bool _saving = false;

  /// `_fill()` 只在 `initState` 跑一次；如果那次失败（网络断了、服务端 500），
  /// 控制器是空的。后来 provider 恢复成 data 时（别的操作 invalidate 了它、或网络回来），
  /// 这一面会重建到 data 分支，但 `_fill()` 不会再跑——三个输入框就停在空白。
  /// 检测「数据已到、控制器还空」补一次回填，用 `addPostFrameCallback` 避开 build 里 setState。
  bool _controllersFilled = false;

  @override
  void initState() {
    super.initState();
    _fill();
  }

  @override
  void dispose() {
    _internalMonths.dispose();
    _externalMonths.dispose();
    _estimatedDailyGrams.dispose();
    super.dispose();
  }

  /// 回填当前设置。这一处**真的在发请求**（首次读那个 provider 就是那次 `GET /cat-settings`），
  /// 所以要接住 `ApiException`：它会从 `await` 里抛出来，不接就是一条未处理的异步异常。
  /// 与另外四个表单页的 `_loadOriginal()` 不 catch 不矛盾——那两处 await 的是已经加载好的列表，
  /// 失败早被页面的错误态接住了；这一屏的错误态正是由这一次抛出来的。
  Future<void> _fill() async {
    try {
      final setting = await ref.read(catSettingViewModelProvider.future);
      if (!mounted) return;
      setState(() {
        _internalMonths.text = '${setting.internalMonths}';
        _externalMonths.text = '${setting.externalMonths}';
        _estimatedDailyGrams.text = setting.estimatedDailyGrams == null
            ? ''
            : '${setting.estimatedDailyGrams}';
      });
      _controllersFilled = true;
    } on ApiException {
      // 不弹 snackbar：下面 `when` 的 error 分支会把同一句 `errorCopy` 铺成整屏错误态。
    }
  }

  /// 两个周期共用一份，六个字段的差别只在字段名——`label` 就是服务端注解里那个名字，
  /// 于是三句文案与 `@NotNull` / `@Min(1)` / `@Max(12)` 逐字对齐只写一次。
  /// `int.tryParse('') == null`，所以「没填」与「不是整数」是同一格的上一句，不必先判空。
  String? _monthsError(String label, String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '请填写$label';
    final months = int.tryParse(text);
    if (months == null) return '$label要填整数月';
    if (months < 1) return '$label至少 1 个月';
    if (months > _maxMonths) return '$label最多 $_maxMonths 个月';
    return null;
  }

  /// 选填，所以空串放过；三句文案对齐服务端的 `@Min(1)` / `@Max(2000)`。
  String? _estimateError(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final grams = int.tryParse(text);
    if (grams == null) return '预估日均要填整数克';
    if (grams < 1) return '预估日均克数至少 1 克';
    if (grams > _maxEstimatedGrams) {
      return '预估日均克数最多 $_maxEstimatedGrams 克';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final draft = CatSettingDraft(
      internalMonths: int.parse(_internalMonths.text.trim()),
      externalMonths: int.parse(_externalMonths.text.trim()),
      // 接管态也照格子里的原值回传：那次 PUT 是整份 upsert，漏传等于把用户以前填的兜底值抹掉，
      // 而哪天最后一袋被删回「没有已完成袋」时它还得再生效。
      estimatedDailyGrams: _estimatedDailyGrams.text.trim().isEmpty
          ? null
          : int.parse(_estimatedDailyGrams.text.trim()),
    );
    setState(() => _saving = true);

    final error = await ref
        .read(catSettingViewModelProvider.notifier)
        .save(draft);
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
    final theme = Theme.of(context);
    final setting = ref.watch(catSettingViewModelProvider);
    final canSubmit = ref.watch(canSubmitProvider);

    // 首次 _fill() 失败后 provider 恢复成 data 的那一次重建：控制器还空，补一次回填。
    if (setting.hasValue && !_controllersFilled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_controllersFilled) _fill();
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('猫咪设置')),
      body: setting.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorCopy(error), textAlign: TextAlign.center),
          ),
        ),
        data: (current) => Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text('驱虫周期', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _internalMonths,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '内驱周期',
                  suffixText: '个月',
                  helperText: '默认 3 个月',
                ),
                validator: (value) => _monthsError('内驱周期', value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _externalMonths,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '外驱周期',
                  suffixText: '个月',
                  helperText: '默认 1 个月',
                ),
                validator: (value) => _monthsError('外驱周期', value),
              ),
              const SizedBox(height: 8),
              Text(
                '改周期只影响之后新建的记录，已有驱虫记录的下次日期不重算。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text('猫粮余量估算', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _estimatedDailyGrams,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !current.estimateTakenOverByHistory,
                decoration: InputDecoration(
                  labelText: '预估日均克数（选填）',
                  hintText: '50',
                  suffixText: 'g',
                  helperText: current.estimateTakenOverByHistory
                      ? '已由历史数据接管'
                      : '只在还没有已用完的袋时用来估算余量',
                ),
                validator: _estimateError,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: (_saving || !canSubmit) ? null : _submit,
                child: const Text('保存'),
              ),
              if (!canSubmit) const OfflineSubmitHint(),
            ],
          ),
        ),
      ),
    );
  }
}
