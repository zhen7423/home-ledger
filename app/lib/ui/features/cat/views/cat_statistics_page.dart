import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/cat_food_bag.dart';
import '../../../../data/models/cat_statistics.dart';
import '../../../../data/models/finance_statistics.dart';
import '../../../../router/app_router.dart';
import '../../../core/category_palette.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';
import '../../../core/range_copy.dart';
import '../cat_badges.dart';
import '../cat_copy.dart';
import '../view_models/cat_food_bag_view_model.dart';
import '../view_models/cat_statistics_view_model.dart';

/// §4.3.5 的猫咪统计。一屏七块，由两条端点喂：消耗四块读 `food-consumption`（带区间），
/// 驱虫三块读 `deworming`（无入参、固定近 12 个月）。
///
/// 与财务统计页同一条加载规矩：换区间时**两条一起重取**，于是不会出现
/// 「饼图换到上月、时间轴还是本月」那种半屏旧数据。
class CatStatisticsPage extends ConsumerStatefulWidget {
  const CatStatisticsPage({super.key});

  @override
  ConsumerState<CatStatisticsPage> createState() => _CatStatisticsPageState();
}

class _CatStatisticsPageState extends ConsumerState<CatStatisticsPage> {
  /// 最近一次拿到的完整状态，理由与财务统计页那一条相同：`AsyncError` 装不下 value，
  /// 而区间那一排必须在错误页上也留在原位——这一屏没有快照，芯片是唯一的重试入口。
  CatStatisticsState _last = const CatStatisticsState();

  @override
  Widget build(BuildContext context) {
    final statistics = ref.watch(catStatisticsViewModelProvider);
    final current = statistics.value;
    if (current != null) {
      _last = current;
    }
    final state = _last;
    final notifier = ref.read(catStatisticsViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('猫咪统计')),
      body: Column(
        children: [
          _RangeBar(
            state: state,
            onRange: (range) => notifier.selectRange(range),
            onCustom: _pickCustom,
          ),
          Expanded(
            child: statistics.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Failure(
                message: errorCopy(error),
                onRetry: notifier.retry,
              ),
              data: (loaded) => _content(context, ref, loaded),
            ),
          ),
        ],
      ),
    );
  }

  /// 自定义区间两个日期连着挑，整段照财务统计页。第二个选择器的
  /// `firstDate` 就是第一个的结果，于是「起始晚于结束」在选择器层面就不可能发生
  /// （`catFoodQueryFor` 那一句 `from.isAfter(to)` 因此是服务端的兜底，不是界面规矩）。
  Future<void> _pickCustom() async {
    final today = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: _last.customStart ?? DateTime(today.year, today.month),
      firstDate: DateTime(today.year - 5),
      lastDate: today,
    );
    if (start == null || !mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: _last.customEnd ?? today,
      firstDate: start,
      lastDate: today,
    );
    if (end == null || !mounted) return;
    await ref
        .read(catStatisticsViewModelProvider.notifier)
        .applyCustom(start, end);
  }

  /// 品牌 → 取色下标，按「该品牌在**全量**袋列表里第一次出现的位置」取号。
  ///
  /// 不能用响应里的 `bagUsages`：那是与区间有交集的子集，按它取号会让同一品牌在「本月」和「本年」
  /// 下换个颜色，饼图看起来像换了数据。列表还没到或加载失败时回空表，下面退成按 `brandBreakdown`
  /// 自身顺序取号——颜色不是数据，不该让一整屏数字等一次列表请求，更不该在列表失败时画成空白。
  Map<String, int> _brandIndexByFirstUse(WidgetRef ref) {
    final bags =
        ref.watch(catFoodBagViewModelProvider).value ?? const <CatFoodBag>[];
    final indexOf = <String, int>{};
    for (final bag in bags) {
      indexOf.putIfAbsent(bag.brand, () => indexOf.length);
    }
    return indexOf;
  }

  /// 完成度按猫归堆：一只猫一个名字头 + 内驱/外驱两行。
  ///
  /// 分组在**前端**做，因为服务端明写不承诺同一只猫的两行相邻。Dart 的 Map 字面量是
  /// `LinkedHashMap`，于是组序 = 该猫第一行在响应里的位置，一次遍历且不重排任何行。
  Map<int, List<CatDewormingCompletion>> _groupByCat(
    List<CatDewormingCompletion> rows,
  ) {
    final grouped = <int, List<CatDewormingCompletion>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.catId, () => <CatDewormingCompletion>[]).add(row);
    }
    return grouped;
  }

  /// 只做取数与摆块，每块怎么画都在自己的私有类里。
  Widget _content(
    BuildContext context,
    WidgetRef ref,
    CatStatisticsState state,
  ) {
    final food = state.food;
    final deworming = state.deworming;
    if (food == null || deworming == null) {
      // `_apply` 会先把两个数据字段清空再发请求，于是 data 分支上存在一个
      // 「条件完整、数据还在路上」的短暂帧。财务页在这一格写的是「挑一个完整的自定义区间」，
      // 抄过来会是错的：这一屏的 `_pickCustom` 在日期没挑完时根本不调 `applyCustom`，
      // 用户看不到那半份状态，看得到的只有这个加载中的瞬间。
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final brandIndexOf = _brandIndexByFirstUse(ref);
    final brandColors = [
      for (var i = 0; i < food.brandBreakdown.length; i++)
        categoryColor(brandIndexOf[food.brandBreakdown[i].brand] ?? i),
    ];
    final usageColors = [
      for (var i = 0; i < food.bagUsages.length; i++)
        categoryColor(brandIndexOf[food.bagUsages[i].brand] ?? i),
    ];

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _SummaryCard(food: food),
        _Block(
          title: '品牌占比',
          subtitle: '按消耗克数占比，不是按袋数',
          child: food.brandBreakdown.isEmpty
              ? const _NothingHere('这个区间还没有猫粮消耗')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Pie(slices: food.brandBreakdown, colors: brandColors),
                    const SizedBox(height: 12),
                    for (var i = 0; i < food.brandBreakdown.length; i++)
                      _BrandRow(
                        slice: food.brandBreakdown[i],
                        color: brandColors[i],
                      ),
                  ],
                ),
        ),
        _Block(
          title: '逐月消耗趋势',
          subtitle:
              '固定最近 12 个自然月，不随上面的时间范围变化；'
              '每袋的克数按使用天数均摊到它所跨的每个月，是近似值',
          child: _MonthBars(items: food.monthlyTrend),
        ),
        _Block(
          title: '每袋用时',
          subtitle: '与区间有交集的袋，含还在用的那一袋',
          child: food.bagUsages.isEmpty
              ? const _NothingHere('这个区间没有猫粮袋在用')
              : Column(
                  children: [
                    for (var i = 0; i < food.bagUsages.length; i++)
                      _BagRow(bag: food.bagUsages[i], color: usageColors[i]),
                  ],
                ),
        ),
        _Block(
          title: '驱虫完成度',
          subtitle:
              '固定近 12 个月（${formatDate(deworming.windowStart)} ~ '
              '${formatDate(deworming.windowEnd)}）',
          child: deworming.completion.isEmpty
              ? const _NothingHere('还没有建档的猫。添加一只猫，这里就开始计次。')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final group in _groupByCat(
                      deworming.completion,
                    ).entries)
                      _CompletionGroup(
                        catName: group.value.first.catName,
                        rows: group.value,
                      ),
                  ],
                ),
        ),
        _Block(
          title: '驱虫时间轴',
          subtitle: '固定近 12 个月，最近一次在最上面',
          child: deworming.timeline.isEmpty
              ? const _NothingHere('近 12 个月没有驱虫记录')
              : _Timeline(items: deworming.timeline),
        ),
        _Block(
          title: '到期倒计时',
          subtitle: '全部在册的猫，按下次日期升序',
          child: deworming.dueCountdown.isEmpty
              ? const _NothingHere(catCountdownEmptyHint)
              : _CountdownRows(items: deworming.dueCountdown),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            '猫粮相关的这四块都是家庭整体口径，不区分是哪只猫吃的。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
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

/// 与财务统计页那一份同形，只是**没有 `trailing` 字段**：这一屏没有任何区块带右上角控件
/// （财务那一处是饼图下钻的「返回大类」按钮），留着一个永远传 null 的入参是负担。
/// 问题单（卡片化）：区块整体是一张纸白浮层卡，浮在浅灰底上。
class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

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
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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

/// 品牌饼图的图例行与「每袋用时」那一列都用它，同一个品牌在两处同色——
/// 那正是取号要钉死的原因（见 `_brandIndexByFirstUse`）。
Widget _swatch(Color color) => Container(
  width: 10,
  height: 10,
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(2),
  ),
);

/// 区间那一排 + 下面那句固定窗口的说明。**不带 `offline` 入参**：这一屏没有快照，
/// 断网时整页已经是错误态，芯片是唯一的重试入口。财务页那一排离线时禁用，是因为它有一份
/// 月度快照可看——两张表形状相似而规矩相反，这正是不能共用一个控件的原因。
class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.state,
    required this.onRange,
    required this.onCustom,
  });

  final CatStatisticsState state;
  final ValueChanged<StatisticsRange> onRange;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final range in StatisticsRange.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(rangeLabel(range)),
                      selected: state.range == range,
                      onSelected:
                          (_) => range == StatisticsRange.custom
                              ? onCustom()
                              : onRange(range),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '驱虫统计固定近 12 个月，不随这个区间变化',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.food});

  final CatFoodConsumption food;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                '${formatDate(food.startDate)} ~ ${formatDate(food.endDate)}'
                ' · ${food.days} 天',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                gramsText(food.totalGrams),
                style: theme.textTheme.headlineSmall,
              ),
              Text(
                '消耗',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  // days 为 0 只可能是区间里一天消耗都没有。写「0 g」会被读成
                  // 「这段时间一克都没吃」，画一个破折号更诚实。
                  _cell(
                    theme,
                    '区间日均',
                    food.days == 0 ? '—' : gramsText(food.dailyAverage),
                  ),
                  // 「区间日均」四个字不能省成「日均」：余量卡上那句「日均 50 g」是推算输入，
                  // 两个「日均」在同一屏里以同一个词出现就是走偏。
                  _cell(theme, '已完成袋数', '${food.finishedBags} 袋'),
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

class _Pie extends StatelessWidget {
  const _Pie({required this.slices, required this.colors});

  final List<CatBrandSlice> slices;
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
          for (var i = 0; i < slices.length; i++)
            PieChartSectionData(
              value: slices[i].grams.toDouble(),
              color: colors[i],
              radius: 52,
              showTitle: false,
            ),
        ],
      ),
    ),
  );
}

/// 饼图的一行图例。没有下钻：猫粮这一侧没有「小类」那一层，
/// 所以外壳是不带响应的 `Padding`——留着 `InkWell` 会点出水波纹，那是一个假的可点提示。
class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.slice, required this.color});

  final CatBrandSlice slice;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _swatch(color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              slice.brand,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(gramsText(slice.grams), style: theme.textTheme.bodyMedium),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${slice.percent}%',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BagRow extends StatelessWidget {
  const _BagRow({required this.bag, required this.color});

  final CatFoodBag bag;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usageDays = bag.usageDays;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _swatch(color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bag.brand,
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 当前袋那两栏是 null，而这一行恰恰是唯一一条**还在增长**的数据：
              // 写「—」会被读成这条数据缺失，写「还在用」才说清了它在等什么。
              Text(
                usageDays == null ? '还在用' : '$usageDays 天',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            bagSummaryLine(bag),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthBars extends StatelessWidget {
  const _MonthBars({required this.items});

  final List<CatMonthGrams> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var high = 0.0;
    for (final month in items) {
      high = math.max(high, month.grams.toDouble());
    }
    // 空态判据是「全是零柱」而不是「一项都没有」：`monthlyTrend` 恒为 12 项、缺月补 0，
    // 照 items.isEmpty 判会得到一张 12 根零柱的空轴。
    if (high == 0) {
      return const _NothingHere('这个区间还没有猫粮消耗');
    }
    final maxY = _axisMax(high);
    final interval = _axisInterval(0, maxY);

    // 不套横向滚动：那套「内容宽度按柱子数撑」是为几十根柱子准备的，
    // 12 根在一屏放得下，把一张 12 格的图做成横向滚动等于让它看不见开头。
    return SizedBox(
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
                  child: Text(_axisLabel(value), style: theme.textTheme.labelSmall),
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
                  if (index < 0 || index >= items.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      _monthTick(items[index].month),
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
            for (var i = 0; i < items.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: items[i].grams.toDouble(),
                    width: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 一只猫一组：名字一行，下面内驱 / 外驱各一行。
///
/// `rows` 恒为两条（后端的 VO 明写「一只猫两行」），所以这里不判长度、不补位、不按 type 重排：
/// 补位等于在前端造一份后端没说过的数据，重排等于把「顺序只影响哪只猫在上面」又算一遍。
class _CompletionGroup extends StatelessWidget {
  const _CompletionGroup({required this.catName, required this.rows});

  final String catName;
  final List<CatDewormingCompletion> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(catName, style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          for (final row in rows) _CompletionRow(row: row),
        ],
      ),
    );
  }
}

/// 「内驱 3/4 次 · 75% · 逾期 6 天」一行。
///
/// 完成度用文字不用进度条：`due` 在一只刚建档的猫上可能是 1，那时「1/1 · 100%」的条子
/// 铺满是 8 像素的一整根绿，读者分不清「做得很好」与「还没来得及考」。
/// `rate` 与 `overdueDays` 都是后端算好的，这一格里不重算第二遍口径。
class _CompletionRow extends StatelessWidget {
  const _CompletionRow({required this.row});

  final CatDewormingCompletion row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdueDays = row.overdueDays;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          CatTypeBadge(type: row.type),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${row.done}/${row.due} 次',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text('${row.rate}%', style: theme.textTheme.bodyMedium),
          const SizedBox(width: 8),
          SizedBox(
            // 定宽是给「逾期 365 天」留的：不给宽度，这两行会在逾期与否之间横向跳动。
            // 不逾期那一格写空串而不是 `_NothingHere`：它是「这一行不逾期」，不是「这块没数据」。
            width: 68,
            child: Text(
              overdueDays == null ? '' : '逾期 $overdueDays 天',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 驱虫时间轴。一条竖线串起若干节点，最近一次在最上面（服务端定的倒序，前端不重排）。
///
/// 不用 `Stepper`：它的 label/content 是折叠区，一屏放三条就把屏占满了，而这一块要的密度是
/// 十二个月一眼看完。
class _Timeline extends StatelessWidget {
  const _Timeline({required this.items});

  final List<CatDewormingTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          _TimelineRow(
            item: items[i],
            // 最后一行不画下半截竖线，否则这一块下面吊着一段没有终点的尾巴
            isLast: i == items.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.isLast});

  final CatDewormingTimelineItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // `IntrinsicHeight` + `stretch` 是必需的：`Column` 里的 `Expanded` 要一个有界高度才存在，
    // 而 `Row` 的自然高度由右边那块文字决定。换成固定高度会在中文长药品名换行时挤掉一行。
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            // 圆点与竖线都不靠 margin 对齐：`Column` 默认 `center`，16 宽盒子里 8 的点
            // 和 2 的线各自居中，中心都在 x=8。
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.catName} · ${dewormingLabel(item.type)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '${formatDate(item.doneDate)} · ${item.medicine}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 与总览页那块倒计时同形，只是空态那一支不在这里（由 `_content` 里的 `_NothingHere` 负责，
/// 两处各画一次会在屏上上下重复同一句话），且不再横向缩进：`_Block` 自己带 16 的边距。
class _CountdownRows extends StatelessWidget {
  const _CountdownRows({required this.items});

  final List<CatDueCountdownItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (final item in items)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: CatTypeBadge(type: item.type),
            title: Text(item.catName),
            subtitle: Text(formatDate(item.nextDate)),
            trailing: Text(
              dueLabel(daysToDue: item.daysToDue, overdueDays: item.overdueDays),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: item.overdueDays != null
                    ? theme.colorScheme.error
                    : null,
              ),
            ),
            onTap: () => context.push(RoutePath.catDewormingsOf(item.catId)),
          ),
      ],
    );
  }
}

/// 坐标轴上限：向上取到 1 / 2 / 5 × 10ⁿ。
///
/// 直接拿最大值当上限，最高那根柱子的圆角会被边框裁掉一半；取到「好看的数」还顺带让刻度是整数。
/// `maxValue <= 0` 时回 1：区间内一克消耗都没有，而 fl_chart 的 maxY 不能等于 minY。
double _axisMax(double maxValue) {
  if (maxValue <= 0) {
    return 1;
  }
  final magnitude = math
      .pow(10, (math.log(maxValue) / math.ln10).floor())
      .toDouble();
  for (final step in const [1, 2, 5, 10]) {
    if (step * magnitude >= maxValue) {
      return step * magnitude;
    }
  }
  return 10 * magnitude;
}

/// 左侧刻度的步长。取跨度的四分之一再向上取整到「好看的数」，于是刻度值总是整数克。
double _axisInterval(double minY, double maxY) {
  final span = maxY - minY;
  return span <= 0 ? 1 : _axisMax(span / 4);
}

/// 「2026-09」→「9月」。年份不进轴：一根柱子的位置只有二十几逻辑像素，放不下「2026年9月」，
/// 而这张图的读数靠左右顺序（服务端定的是升序 12 个月），不靠标签里的年份。
String _monthTick(String month) {
  final parts = month.split('-');
  return '${int.parse(parts.last)}月';
}

/// 克数刻度。这里**不抄财务页的 `axisLabel`**（那是「分 → 元 → 1.2万」的一套）：
/// 「1.2万」在金额轴上读得通，是因为「万元」是中文里的一个量词，而「1.2万克」不是任何人会说的话。
/// 包装规格的上界是后端的 100000 克，六位数字在 `labelSmall` 下约 36 像素，`reservedSize: 44` 装得下。
String _axisLabel(double grams) => grams.round().toString();
