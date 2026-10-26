import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/budget_progress.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/finance_statistics.dart';
import '../../../../data/models/member.dart';
import '../../../../data/models/transaction_summary.dart';
import '../../../../data/services/network_status.dart';
import '../../../../router/app_router.dart';
import '../../../core/budget_copy.dart';
import '../../../core/category_palette.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';
import '../../../core/money.dart';
import '../../../core/offline_banner.dart';
import '../../../core/range_copy.dart';
import '../../family/view_models/family_view_model.dart';
import '../view_models/budget_view_model.dart';
import '../view_models/category_view_model.dart';
import '../view_models/statistics_series.dart';
import '../view_models/statistics_view_model.dart';

/// §4.2.6 的统计页。
///
/// 页面上只暴露时间范围与记录人两项，虽然接口能收的筛选条件与流水列表一样多——留全量入参
/// 是为了导出页复用同一份条件，页面不做没被确认过的交互（§4.2.6 末段）。
class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  /// 饼图下钻到的大类 id，null 是顶层。纯视图状态，不进 ViewModel：
  /// 换条件、退出去再进来都该回到顶层，把它存进状态里就得再写一处清理。
  int? _drilled;

  /// 成员对比图是「按大类」还是「按成员」。同上。
  bool _memberByCategory = false;

  /// 最近一次拿到的完整状态。
  ///
  /// `AsyncError` 会把 value 一起丢掉，而条件那一排必须在错误页上也留在原位——否则一次加载
  /// 失败就再也换不了区间，只能退出去重进。在 build 里赋值不调 setState：这一帧本来就要用它，
  /// 也没有别的地方要通知。
  StatisticsState _last = const StatisticsState();

  @override
  void initState() {
    super.initState();
    // 预算那块恒显示当月（§4.2.6）。`budgetProgressViewModelProvider` 是全局共享的，
    // 用户可能刚在预算页里把它切到了别的月份，进这一页时拨回当月。
    ref.read(budgetProgressViewModelProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final statistics = ref.watch(statisticsViewModelProvider);
    final current = statistics.value;
    if (current != null) {
      _last = current;
    }
    final state = _last;
    final offline = ref.watch(networkStatusProvider) == NetworkStatus.offline;
    final notifier = ref.read(statisticsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        actions: [
          IconButton(
            tooltip: '导出',
            icon: const Icon(Icons.file_download_outlined),
            // 自定义区间还没挑完时 queryFor 回 null，这时带一份空条件过去（等于「导出全部」）：
            // 这一页本来也还没有数据可继承。
            onPressed: () => context.push(
              RoutePath.exportWith(queryFor(state) ?? const StatisticsQuery()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.fromCache) OfflineBanner(savedAt: state.savedAt),
          _ConditionBar(
            state: state,
            offline: offline,
            onRange: (range) {
              setState(() => _drilled = null);
              notifier.selectRange(range);
            },
            onCustom: _pickCustom,
            onRecorder: (userId) {
              setState(() => _drilled = null);
              notifier.selectRecorder(userId);
            },
          ),
          Expanded(
            child: statistics.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  _Failure(message: errorCopy(error), onRetry: notifier.retry),
              data: (loaded) => _content(context, ref, loaded),
            ),
          ),
        ],
      ),
    );
  }

  /// 自定义区间的两个日期连着挑。第二个选择器的 `firstDate` 就是第一个的结果，
  /// 于是「起始不得晚于结束」（§4.2.6）在选择器层面就不可能发生，不必再校验一次。
  /// initialDate 是从上一次的选择记忆里来的（跨夜/深链可能越界），进选择器前双向钳。
  Future<void> _pickCustom() async {
    final today = DateTime.now();
    final firstDate = DateTime(today.year - 5);
    var startInitial = _last.customStart ?? DateTime(today.year, today.month);
    if (startInitial.isBefore(firstDate)) startInitial = firstDate;
    if (startInitial.isAfter(today)) startInitial = today;
    final start = await showDatePicker(
      context: context,
      initialDate: startInitial,
      firstDate: firstDate,
      lastDate: today,
    );
    if (start == null || !mounted) return;
    // 上次的自定义结束日可能早于这次新选的起始日（initialDate < firstDate 会让
    // showDatePicker 断言失败/日历落在非法位置），先钳到今天再进选择器。
    var endInitial = _last.customEnd ?? today;
    if (endInitial.isBefore(start)) endInitial = today;
    if (endInitial.isAfter(today)) endInitial = today;
    final end = await showDatePicker(
      context: context,
      initialDate: endInitial,
      firstDate: start,
      lastDate: today,
    );
    if (end == null || !mounted) return;
    setState(() => _drilled = null);
    await ref
        .read(statisticsViewModelProvider.notifier)
        .applyCustom(start, end);
  }

  Widget _content(BuildContext context, WidgetRef ref, StatisticsState state) {
    final summary = state.summary;
    final overview = state.overview;
    if (summary == null || overview == null) {
      // 只可能是自定义区间挑了一半（或起始晚于结束），`queryFor` 回了 null、这一趟没发请求。
      return const Center(
        child: Padding(padding: EdgeInsets.all(24), child: Text('挑一个完整的自定义区间')),
      );
    }

    final theme = Theme.of(context);
    final colorIndexOf = _colorIndexOf(ref);
    final slices = visibleSlices(overview, _drilled);
    final data = sliceData(slices);
    final sliceColors = [
      for (var i = 0; i < slices.length; i++)
        _drilled == null
            ? _majorColor(theme, slices[i].categoryId, colorIndexOf)
            // §4.2.2：下钻沿用大类的色相，按小类序号调明度
            : categoryShade(_majorColor(theme, _drilled, colorIndexOf), i),
    ];
    // 「其他」（categoryId 为 null）不是一片真的类别，点进去只会得到一张空饼图，
    // 没有小类的大类同理。两种都在这里一次挡掉。
    final drillable = {
      for (final slice in slices)
        if (slice.categoryId != null && slice.subCategories.isNotEmpty)
          slice.categoryId!,
    };

    String? drilledName;
    for (final slice in overview.categoryBreakdown) {
      if (slice.categoryId == _drilled) drilledName = slice.name;
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _SummaryBlock(summary: summary),
        _Block(
          title: _drilled == null ? '类别占比' : '$drilledName 的小类',
          subtitle: _drilled == null
              ? '只统计支出，Top 8 之外合并为「其他」'
              : '百分比相对「$drilledName」的合计，未细分的部分单列一行',
          trailing: _drilled == null
              ? null
              : [
                  TextButton(
                    onPressed: () => setState(() => _drilled = null),
                    child: const Text('返回大类'),
                  ),
                ],
          child: slices.isEmpty || _totalOf(slices) == 0
              ? const _NothingHere('这个区间还没有支出')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Pie(data: data, colors: sliceColors),
                    const SizedBox(height: 12),
                    for (var i = 0; i < slices.length; i++)
                      _LegendRow(
                        datum: data[i],
                        color: sliceColors[i],
                        onTap: drillable.contains(slices[i].categoryId)
                            ? () => setState(
                                () => _drilled = slices[i].categoryId,
                              )
                            : null,
                      ),
                  ],
                ),
        ),
        _Block(
          title: '月度收支趋势',
          subtitle: '固定最近 12 个自然月，不随上面的时间范围变化',
          child: _TrendChart(data: monthlyData(overview.monthlyTrend)),
        ),
        _Block(
          title: '区间内每日支出',
          subtitle: _peakLine(dailyPeak(overview.dailyTrend)),
          child: overview.dailyTrend.isEmpty
              ? const _NothingHere('这个区间还没有支出')
              : _DailyChart(data: dailyData(overview.dailyTrend)),
        ),
        _Block(
          title: '支付方式占比',
          subtitle: '只统计支出，按当前账户字典汇总',
          child: overview.accountBreakdown.isEmpty
              ? const _NothingHere('这个区间还没有支出')
              : Column(
                  children: [
                    for (final slice in overview.accountBreakdown)
                      _AccountRow(slice: slice),
                  ],
                ),
        ),
        const _BudgetBlock(),
        _Block(
          title: '成员支出对比',
          subtitle: '含已退出的成员——他们记的流水还在家庭账上',
          trailing: [
            _modeChip(
              '按成员',
              !_memberByCategory,
              () => setState(() => _memberByCategory = false),
            ),
            _modeChip(
              '按大类',
              _memberByCategory,
              () => setState(() => _memberByCategory = true),
            ),
          ],
          child: overview.memberComparison.isEmpty
              ? const _NothingHere('这个区间还没有支出')
              : _memberContent(theme, overview, colorIndexOf),
        ),
      ],
    );
  }

  Widget _memberContent(
    ThemeData theme,
    FinanceStatistics overview,
    Map<int, int> colorIndexOf,
  ) {
    final members = memberData(overview.memberComparison);
    final labels = memberBarLabels(overview.categoryBreakdown);
    final colors = [
      for (final slice in overview.categoryBreakdown)
        _majorColor(theme, slice.categoryId, colorIndexOf),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MemberChart(
          data: members,
          byCategory: _memberByCategory,
          barColors: colors,
        ),
        if (_memberByCategory) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (var i = 0; i < labels.length; i++)
                _LegendChip(label: labels[i], color: colors[i]),
            ],
          ),
        ],
        const SizedBox(height: 12),
        // 柱子上不写数字（触摸关掉了），每个人的合计在这里逐行列出来
        for (final member in members)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(member.label, style: theme.textTheme.bodyMedium),
                ),
                Text(
                  formatYuan(fromCents(member.total.round())),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _modeChip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );

  /// 大类 id → colorIndex。取**当前字典**而不是流水上的快照（§4.2.6）。
  Map<int, int> _colorIndexOf(WidgetRef ref) {
    final tree = ref.watch(categoryViewModelProvider).value?.categories;
    return {
      for (final major in tree ?? const <Category>[])
        major.id: major.colorIndex ?? 0,
    };
  }

  /// 一片类别的基色。`categoryId` 为 null 是 Top 8 之外合并出来的「其他」，字典里没有它；
  /// 查不到某个 id 同样退成中性色——B5 论证过这种情况不可达，这里只是不让一个 null 漏进 HSL。
  Color _majorColor(
    ThemeData theme,
    int? categoryId,
    Map<int, int> colorIndexOf,
  ) => categoryId == null
      ? theme.colorScheme.outline
      : categoryColor(colorIndexOf[categoryId] ?? 0);

  String _peakLine(ChartDatum? peak) => peak == null
      ? '只统计支出，横向滚动看整个区间'
      : '最高：${peak.label} ${peak.caption}　横向滚动看整个区间';

  int _totalOf(List<CategorySlice> slices) {
    var total = 0;
    for (final slice in slices) {
      total += toCents(slice.amount);
    }
    return total;
  }
}

/// 时间范围与记录人两排 chips。离线时整排禁用（用例 33②）。
class _ConditionBar extends ConsumerWidget {
  const _ConditionBar({
    required this.state,
    required this.offline,
    required this.onRange,
    required this.onCustom,
    required this.onRecorder,
  });

  final StatisticsState state;
  final bool offline;
  final ValueChanged<StatisticsRange> onRange;
  final VoidCallback onCustom;
  final ValueChanged<int?> onRecorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final members =
        ref.watch(familyViewModelProvider).value?.members ?? const <Member>[];

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row([
            for (final range in StatisticsRange.values)
              ChoiceChip(
                label: Text(rangeLabel(range)),
                selected: state.range == range,
                // 离线时只看已缓存的那一个区间：换条件必然要发请求，而请求必然失败
                onSelected: offline
                    ? null
                    : (_) => range == StatisticsRange.custom
                          ? onCustom()
                          : onRange(range),
              ),
          ]),
          const SizedBox(height: 8),
          _row([
            ChoiceChip(
              label: const Text('全部成员'),
              selected: state.createdBy == null,
              onSelected: offline ? null : (_) => onRecorder(null),
            ),
            for (final member in members)
              ChoiceChip(
                label: Text(member.nickname),
                selected: state.createdBy == member.userId,
                onSelected: offline ? null : (_) => onRecorder(member.userId),
              ),
          ]),
          if (offline)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 16),
              child: Text(
                '离线时只看已缓存的区间',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 横向滚动：五个区间 chip 加上「自定义」在 360dp 的屏上是紧的，成员再多一个就溢出。
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

/// 区块外壳：标题、副标题、右上角的零碎控件、图。七个区块共用一套间距。
/// 问题单（卡片化）：区块整体是一张纸白浮层卡，浮在浅灰底上；标题不放强调条。
class _Block extends StatelessWidget {
  const _Block({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // 统计区块卡间距（统一标准）：左右 16、上 4、下 8
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...?trailing,
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _NothingHere extends StatelessWidget {
  const _NothingHere(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

/// 概览卡片。`days` 与两个日期都是后端解析之后的**实际区间**，界面上原样摆出来，
/// 用户才知道「本月」到底是哪一段。
class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.summary});

  final TransactionSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final negative = toCents(summary.balance) < 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${formatDate(summary.startDate)} ~ ${formatDate(summary.endDate)}'
                ' · ${summary.days} 天',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatYuan(summary.balance),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: negative
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '结余',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  _cell(theme, '收入', formatYuan(summary.income)),
                  _cell(theme, '支出', formatYuan(summary.expense)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // days 为 0 只可能是区间里一条流水都没有（§4.2.6）。写 ¥0.00 会被读成
                  // 「这段时间一分没花」，画一个破折号更诚实。
                  _cell(
                    theme,
                    '日均支出',
                    summary.days == 0
                        ? '—'
                        : formatYuan(summary.dailyAverageExpense),
                  ),
                  _cell(theme, '笔数', '${summary.count}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(ThemeData theme, String label, String value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.titleSmall),
      ],
    ),
  );
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _swatch(color),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

Widget _swatch(Color color) => Container(
  width: 10,
  height: 10,
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(2),
  ),
);

/// 饼图的一行图例，同时是下钻的触发处。
///
/// 数字放这里而不是扇区上：扇区上写「32%」在小扇区里会溢出到邻片上，而图例行有的是横向空间，
/// 金额与百分比能一起摆出来（§4.2.6 要求两者都显示）。
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.datum,
    required this.color,
    required this.onTap,
  });

  final ChartDatum datum;
  final Color color;

  /// null 表示这一片不可下钻（「其他」或没有小类的大类）。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            _swatch(color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                datum.label,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(datum.caption, style: theme.textTheme.bodyMedium),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                '${datum.percent}%',
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _Pie extends StatelessWidget {
  const _Pie({required this.data, required this.colors});

  final List<ChartDatum> data;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 200,
    child: PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 44,
        // 从正上方开始顺时针，与「第一片在 12 点钟方向」的直觉一致
        startDegreeOffset: -90,
        pieTouchData: PieTouchData(enabled: false),
        sections: [
          for (var i = 0; i < data.length; i++)
            PieChartSectionData(
              value: data[i].value,
              color: colors[i],
              radius: 52,
              showTitle: false,
            ),
        ],
      ),
    ),
  );
}

/// 双柱（收入 / 支出）叠一条折线（结余）。
///
/// 两张图叠在一个 `Stack` 里，所以**左轴预留宽度与底部预留高度必须完全一致**，而折线那张
/// 用 `Padding` 把同样的两条边空出来——`FlTitlesData(show: false)` 是不留空间的，
/// 直接叠会让折线相对柱子整体往左下偏移。
class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.data});

  final List<MonthDatum> data;

  static const double _leftSize = 44;
  static const double _bottomSize = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return const _NothingHere('还没有流水');
    }
    var low = 0.0;
    var high = 0.0;
    for (final month in data) {
      low = math.min(low, month.balance);
      high = math.max(high, math.max(month.income, month.expense));
    }
    if (high == 0 && low == 0) {
      return const _NothingHere('最近 12 个月还没有流水');
    }
    final maxY = axisMax(high);
    // 结余可能是负的，下界也要落到一个「好看的数」上，否则零线会贴在图框边上
    final minY = low < 0 ? -axisMax(-low) : 0.0;
    final interval = axisInterval(minY, maxY);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          children: [
            _LegendChip(label: '收入', color: theme.colorScheme.primary),
            _LegendChip(label: '支出', color: theme.colorScheme.tertiary),
            _LegendChip(label: '结余', color: theme.colorScheme.secondary),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: Stack(
            children: [
              BarChart(
                BarChartData(
                  minY: minY,
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: const BarTouchData(enabled: false),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: _leftSize,
                        interval: interval,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            axisLabel(value),
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: _bottomSize,
                        interval: 1,
                        getTitlesWidget: (value, meta) =>
                            _bottomLabel(value, meta, theme),
                      ),
                    ),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                  ),
                  barGroups: [
                    for (var i = 0; i < data.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 2,
                        barRods: [
                          BarChartRodData(
                            toY: data[i].income,
                            fromY: 0,
                            width: 6,
                            color: theme.colorScheme.primary,
                          ),
                          BarChartRodData(
                            toY: data[i].expense,
                            fromY: 0,
                            width: 6,
                            color: theme.colorScheme.tertiary,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: _leftSize,
                  bottom: _bottomSize,
                ),
                child: LineChart(
                  LineChartData(
                    // 与 BarChartAlignment.spaceAround 的分组中心对齐：第 i 组落在 (i+0.5)/n
                    minX: -0.5,
                    maxX: data.length - 0.5,
                    minY: minY,
                    maxY: maxY,
                    lineTouchData: const LineTouchData(enabled: false),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < data.length; i++)
                            FlSpot(i.toDouble(), data[i].balance),
                        ],
                        color: theme.colorScheme.secondary,
                        barWidth: 2,
                        isCurved: false,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomLabel(double value, TitleMeta meta, ThemeData theme) {
    final index = value.round();
    if (index < 0 || index >= data.length) {
      return const SizedBox.shrink();
    }
    return SideTitleWidget(
      meta: meta,
      child: Text(data[index].label, style: theme.textTheme.labelSmall),
    );
  }
}

/// 区间内逐日支出，横向滚动（§4.2.6）。
///
/// 左轴会跟着内容一起滚走，这是横向滚动图表的固有代价；关键的数字由区块副标题那句
/// 「最高：9月8日 ¥320」兜住，用户不必对着轴读数。
class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.data});

  final List<ChartDatum> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var high = 0.0;
    for (final day in data) {
      high = math.max(high, day.value);
    }
    if (high == 0) {
      return const _NothingHere('这个区间每天都没有支出');
    }
    final maxY = axisMax(high);
    final interval = axisInterval(0, maxY);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: dailyChartWidth(data.length, constraints.maxWidth),
          height: 200,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: const BarTouchData(enabled: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: interval,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        axisLabel(value),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: dailyLabelInterval(data.length).toDouble(),
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          data[index].label,
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
              ),
              barGroups: [
                for (var i = 0; i < data.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i].value,
                        width: dailyBarWidth * 0.6,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 支付方式占比的一行。用 `LinearProgressIndicator` 而不是 fl_chart 的横向柱状图：
/// fl_chart 没有原生的横向条形图，要把 `BarChart` 转 90° 再自己处理刻度方向，
/// 而这张图要表达的只有「谁多谁少」，进度条行做得更清楚，形状也与预算页一致。
class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.slice});

  final AccountSlice slice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(slice.name, style: theme.textTheme.titleSmall),
              ),
              Text(
                '${slice.percent}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatYuan(slice.amount),
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (slice.percent / 100).clamp(0.0, 1.0),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

/// 本月预算执行。直接复用 `GET /budgets/progress`（§4.2.6），统计接口不重复提供预算数据。
///
/// **这一块不进统计快照**：离线时它自己报错，上面五张图照常显示。把预算塞进快照意味着
/// 快照里混了一份恒为当月的数据，而其余部分是用户选的区间，两者过期时间不同步。
class _BudgetBlock extends ConsumerWidget {
  const _BudgetBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(budgetProgressViewModelProvider);
    return _Block(
      title: '本月预算执行',
      subtitle: '恒显示当月，不随上面的时间范围变化',
      child: progress.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(errorCopy(error)),
        ),
        data: (rows) => rows.isEmpty
            ? const _NothingHere('还没有设置预算')
            : Column(children: [for (final row in rows) _BudgetRow(row: row)]),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.row});

  final BudgetProgress row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 颜色与文案一律看 level，不拿 usedPercent 自己比阈值（budget_progress.dart 的注释）
    final color = budgetLevelColor(theme.colorScheme, row.level);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  budgetTitle(row.scope, row.categoryName ?? row.memberName),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                row.level == 'NORMAL'
                    ? formatYuan(row.used)
                    : budgetLevelLabel(row.level),
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (row.usedPercent / 100).clamp(0.0, 1.0),
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberChart extends StatelessWidget {
  const _MemberChart({
    required this.data,
    required this.byCategory,
    required this.barColors,
  });

  final List<MemberDatum> data;
  final bool byCategory;
  final List<Color> barColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var high = 0.0;
    for (final member in data) {
      if (byCategory) {
        for (final bar in member.bars) {
          high = math.max(high, bar.value);
        }
      } else {
        high = math.max(high, member.total);
      }
    }
    if (high == 0) {
      return const _NothingHere('这个区间还没有支出');
    }
    final maxY = axisMax(high);
    final interval = axisInterval(0, maxY);
    final barsPerMember = byCategory ? math.max(barColors.length, 1) : 1;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: math.max(
            memberChartWidth(data.length, barsPerMember),
            constraints.maxWidth,
          ),
          height: 220,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              barTouchData: const BarTouchData(enabled: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: interval,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        axisLabel(value),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          data[index].label,
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
              ),
              barGroups: [
                for (var i = 0; i < data.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 2,
                    barRods: byCategory
                        ? [
                            // 颜色与名字都按下标取：byCategory 与 categoryBreakdown 逐项对齐
                            // 是后端 B9 钉住的契约（见 statistics_series.dart 的 memberBarLabels）
                            for (var b = 0; b < data[i].bars.length; b++)
                              BarChartRodData(
                                toY: data[i].bars[b].value,
                                width: 6,
                                color: barColors[b % barColors.length],
                              ),
                          ]
                        : [
                            BarChartRodData(
                              toY: data[i].total,
                              width: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
