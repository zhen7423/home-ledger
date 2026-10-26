import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/baby.dart';
import '../../../../data/models/baby_growth.dart';
import '../../../../data/services/network_status.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../baby_badges.dart';
import '../baby_copy.dart';
import '../view_models/baby_curve_view_model.dart';
import '../view_models/baby_list_view_model.dart';

/// §4.4.3 的生长曲线。**本页一个百分位都不算**：实测点、每点的档位与整张标准表都由服务端
/// 算好送来，前端只负责把「带 + 中位线 + 实测折线」叠到一张图上（§3.10 第 7 条）。
///
/// 七个百分位列在图上各有各的画法，靠 `lineBarsData` 的下标成带：P3 与 P97 画外边界线、
/// P50 画虚线中位线，中间四条（P10 / P25 / P75 / P90）只作画带的骨架、自己不描线，
/// 六段相邻的 `betweenBarsData` 分三档深浅由外向内加深——§4.4.3 要的「三层深浅」就是这个效果，
/// 而相邻六段没有嵌套带的叠色次序问题（谁压谁不必猜）。
class BabyGrowthCurvePage extends ConsumerStatefulWidget {
  const BabyGrowthCurvePage({required this.babyId, this.metric, super.key});

  final int babyId;

  /// 路由不带 `?metric=` 时用 `growthMetrics` 的缺省（身高），与后端的缺省一致。
  final String? metric;

  @override
  ConsumerState<BabyGrowthCurvePage> createState() =>
      _BabyGrowthCurvePageState();
}

class _BabyGrowthCurvePageState extends ConsumerState<BabyGrowthCurvePage> {
  /// 换指标只换这一个键：视图模型是 `family` 的，新键就是一个新的 provider，
  /// 页面本身不重建，那排 chips 也不会跟着闪一下加载态。
  late String _metric = widget.metric ?? defaultGrowthMetric;

  @override
  Widget build(BuildContext context) {
    final query = curveQueryFor(widget.babyId, _metric);
    final curve = ref.watch(babyCurveViewModelProvider(query));
    final offline = ref.watch(networkStatusProvider) == NetworkStatus.offline;
    final name = _nameOf();
    final notifier = ref.read(babyCurveViewModelProvider(query).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(name == null ? '生长曲线' : '$name 的生长曲线')),
      body: Column(
        children: [
          if (offline) const OfflineBanner(),
          _MetricChips(
            selected: _metric,
            onChanged: (metric) => setState(() => _metric = metric),
          ),
          Expanded(
            child: curve.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Failure(
                message: errorCopy(error),
                onRetry: notifier.refresh,
              ),
              // `null` 是「还没登录」那一支：路由把未登录挡在外面，这里等它转完就行。
              data: (value) => value == null
                  ? const Center(child: CircularProgressIndicator())
                  : _CurveBody(
                      // 换指标 = 新的一份数据，缩放态也要归零。
                      key: ValueKey(query),
                      curve: value,
                      onTapPoint: _showPoint,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String? _nameOf() {
    for (final baby
        in ref.watch(babyListViewModelProvider).value ?? const <Baby>[]) {
      if (baby.id == widget.babyId) return baby.name;
    }
    return null;
  }

  /// 点详情的月龄取 `points[].ageMonths`，**不能拿 `xValue` 当年龄**：`WEIGHT_HEIGHT`
  /// 那条指标的横轴是身长/身高 cm，当年龄显示会写出「月龄 95」（§4.4.3、第 24 轮 (c)）。
  Future<void> _showPoint(BabyCurve curve, BabyCurvePoint point) {
    final theme = Theme.of(context);
    final metric = growthMetricLabels[curve.metric] ?? curve.metric;

    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$metric · ${formatDate(point.measureDate)} · 月龄 ${point.ageMonths}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('实测', style: theme.textTheme.labelMedium),
                  const SizedBox(width: 12),
                  Text(
                    _measuredText(point, curve.metric),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('所处区间', style: theme.textTheme.labelMedium),
                  const SizedBox(width: 12),
                  // `null` 是「超出标准表覆盖范围」这个有含义的空值：点照常画，
                  // 小部件自己会写清那句话，这里不另给一套文案。
                  PercentileBand(band: point.percentileBand),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 实测值的显示位数按该指标的列宽定：体重 `DECIMAL(5,2)`、BMI 两位、身高与头围一位。
/// `measured` 是全 App 仅有的两个 `double` 之一，直接 `toString` 会印出 `6.250000000000001`。
String _measuredText(BabyCurvePoint point, String metric) {
  final text = point.measured.toStringAsFixed(
    metric == 'WEIGHT' || metric == 'BMI' ? 2 : 1,
  );
  return switch (metric) {
    'WEIGHT' => '$text kg',
    'BMI' => text,
    _ => '$text cm',
  };
}

/// 横轴是什么：三个年龄别指标是月龄，体重别身高的那张表横轴是身长/身高 cm。
/// 以响应里的 `standardMetric` 为准（它是服务端实际选中的表），不看用户选的那个。
String _xAxisNote(BabyCurve curve) =>
    curve.standardMetric == 'WEIGHT_LENGTH' ||
        curve.standardMetric == 'WEIGHT_HEIGHT'
    ? '横轴：身长 / 身高（cm）'
    : '横轴：月龄（月）';

/// 轴刻度取 1 / 2 / 5 / 10 的整数倍，免得轴上出现 48.63 这种读数。
double _niceInterval(double span) {
  if (span <= 0) return 1;
  final raw = span / 5;
  final magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  for (final step in const <double>[1, 2, 5]) {
    if (raw <= step * magnitude) return step * magnitude;
  }
  return 10 * magnitude;
}

/// 图的坐标范围：横向取标准表与实测点的并集（实测点可以落在表外，点照常要看得见），
/// 纵向取 P3 / P97 与实测值，上下各留一成余量免得贴着边框。
class _CurveScale {
  const _CurveScale({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.xInterval,
    required this.yInterval,
  });

  factory _CurveScale.of(BabyCurve curve) {
    final xs = [
      for (final row in curve.standard) row.xValue,
      for (final point in curve.points) point.xValue,
    ];
    final ys = [
      for (final row in curve.standard) ...[row.p3, row.p97],
      for (final point in curve.points) point.measured,
    ];
    if (xs.isEmpty || ys.isEmpty) {
      return const _CurveScale(
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        xInterval: 1,
        yInterval: 1,
      );
    }

    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final low = ys.reduce(math.min);
    final high = ys.reduce(math.max);
    // 只有一个值时（一个点、或一张退化的表）给一个真实存在的跨度，零跨度画不出轴。
    final padding = high > low ? (high - low) * 0.1 : 1.0;
    final spanX = maxX > minX ? maxX - minX : 1.0;
    final spanY = high + padding - (low - padding);

    return _CurveScale(
      minX: minX,
      maxX: maxX,
      minY: low - padding,
      maxY: high + padding,
      xInterval: _niceInterval(spanX),
      yInterval: _niceInterval(spanY),
    );
  }

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double xInterval;
  final double yInterval;
}

class _CurveBody extends StatefulWidget {
  const _CurveBody({required this.curve, required this.onTapPoint, super.key});

  final BabyCurve curve;
  final void Function(BabyCurve curve, BabyCurvePoint point) onTapPoint;

  @override
  State<_CurveBody> createState() => _CurveBodyState();
}

class _CurveBodyState extends State<_CurveBody> {
  /// 实测折线在 `lineBarsData` 里的下标：前七个是 P3 / P10 / P25 / P50 / P75 / P90 / P97。
  static const int _measuredIndex = 7;

  static const int _p3 = 0;
  static const int _p10 = 1;
  static const int _p25 = 2;
  static const int _p50 = 3;
  static const int _p75 = 4;
  static const int _p90 = 5;
  static const int _p97 = 6;

  /// 横向缩放的控制器：前几个月的点挤在横轴左侧，双指放大 + 左右拖动
  /// 才能看清每一点的档位；`setState` 只是为了让「重置缩放」按钮随之现身/隐身。
  final TransformationController _transformation = TransformationController();

  @override
  void initState() {
    super.initState();
    _transformation.addListener(_onTransformed);
  }

  @override
  void dispose() {
    _transformation.removeListener(_onTransformed);
    _transformation.dispose();
    super.dispose();
  }

  void _onTransformed() => setState(() {});

  bool get _zoomed => !_transformation.value.isIdentity();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final curve = widget.curve;
    final standard = curve.standard;
    final points = curve.points;

    if (standard.isEmpty && points.isEmpty) {
      return const _Failure(message: '这个指标既没有实测记录，也超出了标准表的覆盖范围');
    }

    final scale = _CurveScale.of(curve);
    final note = standardMetricNotes[curve.standardMetric];
    final subtitle = [note, _xAxisNote(curve)].whereType<String>().join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text(
          '${growthMetricLabels[curve.metric] ?? curve.metric} 的百分位曲线',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: LineChart(
            transformationConfig: FlTransformationConfig(
              // 只缩放横轴：月龄方向的数据会密起来，纵向始终是
              // 「值域」不该被拉变形，而且纵向缩放会跟外层 ListView 抢手势。
              scaleAxis: FlScaleAxis.horizontal,
              minScale: 1,
              maxScale: 10,
              panEnabled: true,
              scaleEnabled: true,
              transformationController: _transformation,
            ),
            LineChartData(
              minX: scale.minX,
              maxX: scale.maxX,
              minY: scale.minY,
              maxY: scale.maxY,
              // 带与点都由 min/max 框住，但折线的圆头会溢出半格线宽，裁掉最省心。
              clipData: const FlClipData.all(),
              lineTouchData: LineTouchData(
                // 自带的 tooltip 不用：点一个散点要弹详情表。
                handleBuiltInTouches: false,
                touchSpotThreshold: 16,
                touchCallback: (event, response) {
                  if (event is! FlTapUpEvent) return;
                  final spot = response?.lineBarSpots?.firstOrNull;
                  if (spot == null || spot.barIndex != _measuredIndex) return;
                  widget.onTapPoint(curve, points[spot.spotIndex]);
                },
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: scale.yInterval,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.outlineVariant,
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: scale.yInterval,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        value.toStringAsFixed(1),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: scale.xInterval,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        value.round().toString(),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
              ),
              betweenBarsData: _bands(theme),
              lineBarsData: _bars(theme),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                '双指缩放、左右拖动可放大查看早期的密集数据点',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (_zoomed)
              TextButton.icon(
                onPressed: () => _transformation.value = Matrix4.identity(),
                icon: const Icon(Icons.zoom_out_map, size: 18),
                label: const Text('重置缩放'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const _Legend(),
        _GrowthSummary(curve: curve),
        if (points.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '这个宝宝还没有身高体重记录，先记一次测量',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: 8),
        _Disclaimer(text: curve.disclaimer),
      ],
    );
  }

  /// 六段相邻的带，三档深浅由外向内加深：外两段最浅（P3–P97 的外缘）、
  /// 中两段一档、靠中位线的两段最深——合起来就是 §4.4.3 要的三层深浅。
  List<BetweenBarsData> _bands(ThemeData theme) {
    // 表是空的话七条骨架线都没有点，带也画不出来。
    if (widget.curve.standard.isEmpty) return const [];

    final primary = theme.colorScheme.primary;
    final shades = <double>[0.06, 0.14, 0.24];

    return [
      for (final (from, to, shade) in <(int, int, double)>[
        (_p3, _p10, shades[0]),
        (_p90, _p97, shades[0]),
        (_p10, _p25, shades[1]),
        (_p75, _p90, shades[1]),
        (_p25, _p50, shades[2]),
        (_p50, _p75, shades[2]),
      ])
        BetweenBarsData(
          fromIndex: from,
          toIndex: to,
          color: primary.withValues(alpha: shade),
        ),
    ];
  }

  List<LineChartBarData> _bars(ThemeData theme) {
    final standard = widget.curve.standard;
    final points = widget.curve.points;
    final outline = theme.colorScheme.outline;
    final median = theme.colorScheme.primary;
    final measured = theme.colorScheme.tertiary;

    List<FlSpot> column(double Function(GrowthStandardRow row) pick) => [
      for (final row in standard) FlSpot(row.xValue, pick(row)),
    ];

    // 只作骨架的四条：颜色透明、不描点，只为让 `betweenBarsData` 有的可指。
    LineChartBarData skeleton(List<FlSpot> spots, {bool show = false}) =>
        LineChartBarData(
          spots: spots,
          color: show ? outline : Colors.transparent,
          barWidth: show ? 1 : 0,
          isCurved: false,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        );

    return [
      skeleton(column((row) => row.p3), show: true),
      skeleton(column((row) => row.p10)),
      skeleton(column((row) => row.p25)),
      // P50 是虚线中位线：`dashArray` 之后它才与两条实线的边界区分得开。
      LineChartBarData(
        spots: column((row) => row.p50),
        color: median,
        barWidth: 1.5,
        dashArray: [6, 4],
        isCurved: false,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ),
      skeleton(column((row) => row.p75)),
      skeleton(column((row) => row.p90)),
      skeleton(column((row) => row.p97), show: true),
      // 实测折线：**点数少于 2 时不画折线只留散点**（§4.4.3 末条）——一个点连不成线，
      // 硬画会得到一条零长度的线，看着像是数据缺了一段。
      LineChartBarData(
        spots: [
          for (final point in points) FlSpot(point.xValue, point.measured),
        ],
        color: points.length < 2 ? Colors.transparent : measured,
        barWidth: 2,
        isCurved: false,
        dotData: FlDotData(
          show: points.isNotEmpty,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 4,
            color: measured,
            strokeColor: theme.colorScheme.surface,
            strokeWidth: 1.5,
          ),
        ),
        belowBarData: BarAreaData(show: false),
      ),
    ];
  }
}

class _MetricChips extends StatelessWidget {
  const _MetricChips({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Row(
      children: [
        // **`WEIGHT_LENGTH` 不在其中**（§1.4 第 23 条）：它是服务端按年龄选的那张表
        // （2 岁以下用身长），不是用户能选的指标，选错了会得到一段与表无关的百分位。
        for (final metric in growthMetrics) ...[
          ChoiceChip(
            label: Text(growthMetricLabels[metric] ?? metric),
            selected: metric == selected,
            onSelected: (_) => onChanged(metric),
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendItem(
          swatch: _Square(color: primary.withValues(alpha: 0.24)),
          label: 'P25–P75',
        ),
        _LegendItem(
          swatch: _Square(color: primary.withValues(alpha: 0.14)),
          label: 'P10–P90',
        ),
        _LegendItem(
          swatch: _Square(color: primary.withValues(alpha: 0.06)),
          label: 'P3–P97',
        ),
        _LegendItem(
          swatch: _Square(color: primary, height: 2),
          label: 'P50 中位线',
        ),
        _LegendItem(
          swatch: _Square(color: theme.colorScheme.tertiary),
          label: '实测',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.swatch, required this.label});

  final Widget swatch;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch,
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({required this.color, this.height = 12});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) =>
      Container(width: 12, height: height, color: color);
}

/// 成长小结：把「最近一次测量落在哪个百分位区间」讲成人话，
/// 并给出「当前发育是否正常」的参考口径。百分位是服务端算好下发的（§4.4.3），
/// 这里只读 `points.last` 那一点的 `percentileBand` 拼句子，不自己算任何东西。
class _GrowthSummary extends StatelessWidget {
  const _GrowthSummary({required this.curve});

  final BabyCurve curve;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = curve.points;
    if (points.isEmpty) return const SizedBox.shrink();

    final point = points.last;
    final metric = growthMetricLabels[curve.metric] ?? curve.metric;
    final band = point.percentileBand;
    final value = _measuredText(point, curve.metric);
    final when =
        '最近一次（${formatDate(point.measureDate)} · 月龄 ${point.ageMonths}）';

    final body = band == null
        ? '$metric $when 为 $value，该点已超出标准表的覆盖范围，未能给出百分位区间；'
              '实际发育情况请结合医生判断。'
        : '$metric $when 为 $value，处于 $band 区间。'
              '百分位在 P3–P97 之间均属常见参考范围，低于 P3 或高于 P97 时建议咨询儿保医生。';

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text('成长小结', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 6),
            Text(body, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// §4.4.3 的免责声明。文案由服务端随响应下发（`BabyDisclaimers`），
/// 与疫苗清单页那一份逐字相同——这里读响应、不读本地常量，两页各读一处不会漂。
class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: EdgeInsets.zero,
    title: Text('数据来源与免责声明', style: Theme.of(context).textTheme.labelMedium),
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
          ],
        ],
      ),
    ),
  );
}
