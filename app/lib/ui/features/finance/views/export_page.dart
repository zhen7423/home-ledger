import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/export_format.dart';
import '../../../../data/models/finance_statistics.dart';
import '../../../../data/models/member.dart';
import '../../../../data/services/network_status.dart';
import '../../../core/date_format.dart';
import '../../../core/offline_banner.dart';
import '../../../core/range_copy.dart';
import '../../family/view_models/family_view_model.dart';
import '../view_models/export_view_model.dart';
import '../view_models/statistics_view_model.dart';

/// §4.2.7 的导出页。
///
/// 条件存在 `ExportState.query`（一个 `StatisticsQuery`）里，界面上那六格 chips 是它反推出来的，
/// 两边不各存一份——存两份就要写一处同步，而「chips 显示本月、实际导的是上月」正是同步漏掉的后果。
class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({required this.query, super.key});

  /// 入口带来的条件。统计页给的是它当前那一套（`RoutePath.exportWith`），
  /// 设置页给的是空条件，也就是「导出全部」。
  final StatisticsQuery query;

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  @override
  void initState() {
    super.initState();
    // 不能放 build：build 每帧都跑，会把概览接口打成筛子。
    // 也不能就在这儿直接调：`open()` 头一句是同步改状态，而 Riverpod 判断「build 期间」看的是
    // widget 树在不在构建、不是有没有听众——initState 恰好处在祖先的 build 之中，同步写入会被
    // 拦下来。等这一帧画完再改，代价只是「导出全部」那一格多亮一帧。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(exportViewModelProvider.notifier).open(widget.query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(exportViewModelProvider);
    final offline = ref.watch(networkStatusProvider) == NetworkStatus.offline;
    final query = state.query;
    // 两个日期都没有 = 「导出全部」（从设置页进来的默认态）。alignToQuery 认不出这一格，
    // 会把它归成 custom 加两个 null 日期，所以先自己判掉，别拿它的返回值当选中标签。
    final all = query.startDate == null && query.endDate == null;
    final resolved = all
        ? StatisticsState(createdBy: query.createdBy)
        : alignToQuery(StatisticsState(createdBy: query.createdBy), query);

    return Scaffold(
      appBar: AppBar(title: const Text('导出数据')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _label(theme, '格式'),
          // RadioListTile 的 groupValue / onChanged 在 Flutter 3.32 之后已废弃
          // （packages/flutter/lib/src/material/radio_list_tile.dart:164），照旧写会被
          // dart analyze 记一条 deprecated_member_use，而检查点要求 0 issue。
          // 值与回调都交给 RadioGroup 祖先；禁用走 RadioListTile.enabled，
          // 它在 false 时把 onTap 置成 null，RadioGroup.onChanged 根本不会被调到。
          RadioGroup<ExportFormat>(
            groupValue: state.format,
            onChanged: (format) {
              if (format != null) {
                ref.read(exportViewModelProvider.notifier).selectFormat(format);
              }
            },
            child: Column(
              children: [
                for (final format in ExportFormat.values)
                  RadioListTile<ExportFormat>(
                    value: format,
                    enabled: !offline,
                    contentPadding: EdgeInsets.zero,
                    title: Text(format.label),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _label(theme, '范围'),
          _Conditions(
            all: all,
            resolved: resolved,
            offline: offline,
            onRange: _pickRange,
            onCustom: _pickCustom,
            onRecorder: _pickRecorder,
          ),
          const SizedBox(height: 20),
          _label(theme, '规模'),
          _Scale(state: state),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: offline || state.exporting ? null : _export,
                  icon: state.exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_outlined),
                  label: Text(state.exporting ? '正在生成文件…' : '导出并分享'),
                ),
              ),
              // 按钮下面一次只给一句话。错误优先：它是要照着改条件的那一句
              // （比如「时间跨度不能超过 366 天」），而离线提示在错误为空时已经足够说明按钮为什么点不动。
              if (state.error != null)
                OfflineSubmitHint(text: state.error!)
              else if (offline)
                const OfflineSubmitHint(text: '离线时无法生成导出文件'),
            ],
          ),
        ),
      ),
    );
  }

  /// `null` 是「全部」那一格。
  Future<void> _pickRange(StatisticsRange? range) async {
    final state = ref.read(exportViewModelProvider);
    final notifier = ref.read(exportViewModelProvider.notifier);
    if (range == null) {
      await notifier.applyQuery(
        StatisticsQuery(createdBy: state.query.createdBy),
      );
      return;
    }
    if (range == StatisticsRange.custom) {
      await _pickCustom();
      return;
    }
    final query = queryFor(
      StatisticsState(range: range, createdBy: state.query.createdBy),
    );
    // 五个具名区间必然算得出条件，这个 null 分支只是把可空类型收窄掉
    if (query != null) {
      await notifier.applyQuery(query);
    }
  }

  Future<void> _pickRecorder(int? userId) => ref
      .read(exportViewModelProvider.notifier)
      .applyQuery(
        ref.read(exportViewModelProvider).query.copyWith(createdBy: userId),
      );

  /// 与统计页同一套：第二个选择器的 `firstDate` 就是第一个的结果，「起始晚于结束」在选择器
  /// 层面不可能发生。**366 天的跨度上限不在这里拦**——那是后端的口径（B5 校验、B7 给文案），
  /// 前端抄一份数字，运维改了配置就会前后矛盾；真超了，那句话会显示在按钮下面。
  Future<void> _pickCustom() async {
    final today = DateTime.now();
    final resolved = alignToQuery(
      const StatisticsState(),
      ref.read(exportViewModelProvider).query,
    );
    // 查询串深链带来的 customStart 可能是 5 年前或未来，双向钳后再进选择器（与统计页同一处口径）
    final firstDate = DateTime(today.year - 5);
    var startInitial = resolved.customStart ?? DateTime(today.year, today.month);
    if (startInitial.isBefore(firstDate)) startInitial = firstDate;
    if (startInitial.isAfter(today)) startInitial = today;
    final start = await showDatePicker(
      context: context,
      initialDate: startInitial,
      firstDate: firstDate,
      lastDate: today,
    );
    if (start == null || !mounted) return;
    // 上次的结束日可能早于这次新选的起始日或越过今天，钳到区间内（与统计页同一处修复）。
    var endInitial = resolved.customEnd ?? today;
    if (endInitial.isBefore(start)) endInitial = today;
    if (endInitial.isAfter(today)) endInitial = today;
    final end = await showDatePicker(
      context: context,
      initialDate: endInitial,
      firstDate: start,
      lastDate: today,
    );
    if (end == null || !mounted) return;
    final query = queryFor(
      StatisticsState(
        range: StatisticsRange.custom,
        customStart: start,
        customEnd: end,
        createdBy: ref.read(exportViewModelProvider).query.createdBy,
      ),
    );
    if (query != null) {
      await ref.read(exportViewModelProvider.notifier).applyQuery(query);
    }
  }

  /// 成功时系统分享面板自己会弹出来，不需要再补一句「导出成功」。
  /// 失败时 ViewModel 已经把 `errorCopy` 的结果放进 `state.error`，按钮下面那一行会显示；
  /// `export()` 的返回值是给测试断言用的（F8），页面不拿它再弹一次 SnackBar——
  /// 那句提示要照着改条件，两秒就消失的 SnackBar 不适合它。
  Future<void> _export() => ref.read(exportViewModelProvider.notifier).export();
}

Widget _label(ThemeData theme, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: Text(
    text,
    style: theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    ),
  ),
);

/// 范围那一排。**别去跟统计页的 `_ConditionBar` 合并成一个共用控件**：那边绑
/// `StatisticsState`、五格、离线时说「只看已缓存的区间」；这边绑 `StatisticsQuery`、
/// 六格（多一个「全部」）、离线时一句话挂在按钮下面。抽成一个要塞三个开关参数，
/// 比两份各六十行更难读。
class _Conditions extends ConsumerWidget {
  const _Conditions({
    required this.all,
    required this.resolved,
    required this.offline,
    required this.onRange,
    required this.onCustom,
    required this.onRecorder,
  });

  /// 「导出全部」：`StatisticsQuery` 两个日期都为 null。
  final bool all;

  /// `alignToQuery` 把 query 认回来的那一格，含自定义区间的两个日期与记录人。
  final StatisticsState resolved;
  final bool offline;
  final ValueChanged<StatisticsRange?> onRange;
  final VoidCallback onCustom;
  final ValueChanged<int?> onRecorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final members =
        ref.watch(familyViewModelProvider).value?.members ?? const <Member>[];
    final custom = !all && resolved.range == StatisticsRange.custom;
    final start = resolved.customStart;
    final end = resolved.customEnd;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row([
          ChoiceChip(
            label: const Text('全部'),
            selected: all,
            onSelected: offline ? null : (_) => onRange(null),
          ),
          for (final range in StatisticsRange.values)
            ChoiceChip(
              label: Text(rangeLabel(range)),
              selected: !all && resolved.range == range,
              onSelected: offline
                  ? null
                  : (_) => range == StatisticsRange.custom
                        ? onCustom()
                        : onRange(range),
            ),
        ]),
        // 「自定义」三个字说不出挑的是哪一段，把两个日期写在下面
        if (custom && start != null && end != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${formatDate(start)} ~ ${formatDate(end)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 8),
        _row([
          ChoiceChip(
            label: const Text('全部成员'),
            selected: resolved.createdBy == null,
            onSelected: offline ? null : (_) => onRecorder(null),
          ),
          for (final member in members)
            ChoiceChip(
              label: Text(member.nickname),
              selected: resolved.createdBy == member.userId,
              onSelected: offline ? null : (_) => onRecorder(member.userId),
            ),
        ]),
      ],
    );
  }

  /// 横向滚动：六格区间 chip 在 360dp 的屏上必然放不下，成员再来五个更是。
  Widget _row(List<Widget> chips) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final chip in chips)
          Padding(padding: const EdgeInsets.only(right: 8), child: chip),
      ],
    ),
  );
}

/// 「共 N 笔」与这份文件将覆盖的**实际**区间。
class _Scale extends StatelessWidget {
  const _Scale({required this.state});

  final ExportState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = state.summary;
    if (state.counting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('正在统计行数'),
          ],
        ),
      );
    }
    if (summary == null) {
      // 预查失败不拦导出（F5③），所以这里不写红字：红字会被读成「不能导」。
      // 失败的原因（离线 / 区间非法）出现在按钮下面那一行。
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '笔数没查到，不影响导出',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    // 区间取 summary 上那两个日期而不是 chips 上的选择：两个日期都不传时后端解析成
    // 「家里第一笔流水的日期 → 今天」（§4.2.6），只有解析后的那两个才对得上将要生成的文件。
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 计数不做千分位：上限 5 万行，最多五位数，而统计页概览卡里的「笔数」
          // 也是 '${summary.count}'，两处必须一个样。
          Text('共 ${summary.count} 笔', style: theme.textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            '${formatDate(summary.startDate)} ~ ${formatDate(summary.endDate)}'
            ' · ${summary.days} 天',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
