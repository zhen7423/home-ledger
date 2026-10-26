import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/baby.dart';
import '../../../../data/models/baby_statistics.dart';
import '../../../../data/services/network_status.dart';
import '../../../../router/app_router.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../baby_badges.dart';
import '../baby_copy.dart';
import '../view_models/baby_formula_statistics_view_model.dart';
import '../view_models/baby_list_view_model.dart';
import '../view_models/baby_statistics_view_model.dart';

/// §4.4.6 的宝宝统计。一屏两段——体格与疫苗——**同屏堆叠**，不藏在一对互斥的分段按钮后面：
/// §4.4.6 那张表是一屏要看的九行，切成两页会让「完成率」与「当前体格」永远没法对读。
///
/// 两条端点一起发（见 `BabyStatisticsViewModel`）：先回来哪段就先显示哪段，会出现半屏是上一轮的
/// 宝宝，所以整屏一起等。**不做离线快照**（§5.4）：离线时横幅 + 错误态里的「重试」。
class BabyStatisticsPage extends ConsumerWidget {
  const BabyStatisticsPage({this.babyId, super.key});

  /// null = 全家庭。由路由从 `?babyId=` 解出来——入口表上没有任何一处带它过来，那是留给手敲的。
  final int? babyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statistics = ref.watch(babyStatisticsViewModelProvider(babyId));
    final babies = ref.watch(babyListViewModelProvider).value ?? const <Baby>[];
    final offline = ref.watch(networkStatusProvider) == NetworkStatus.offline;

    String? subject;
    if (babyId != null) {
      for (final baby in babies) {
        if (baby.id == babyId) subject = baby.name;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(subject == null ? '宝宝统计' : '$subject 的统计')),
      body: Column(
        children: [
          if (offline) const OfflineBanner(),
          Expanded(
            child: statistics.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Failure(
                message: errorCopy(error),
                onRetry: () => ref
                    .read(babyStatisticsViewModelProvider(babyId).notifier)
                    .refresh(),
              ),
              // `_load` 拿两个字段一起填，理论上不会有半个状态；真出现也只当还在加载，
              // 不去画一张「体格有、疫苗空」的半截屏。
              data: (state) => state.growth == null || state.vaccine == null
                  ? const Center(child: CircularProgressIndicator())
                  : _content(state.growth!, state.vaccine!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BabyGrowthStatistics growth, BabyVaccineStatistics vaccine) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const _SectionHeader('体格成长'),
        if (growth.perBaby.isEmpty)
          const _NothingHere('还没有在册的宝宝')
        else
          for (final item in growth.perBaby) _GrowthCard(item: item),
        const _SectionHeader('疫苗'),
        if (vaccine.perBaby.isEmpty)
          const _NothingHere('还没有在册的宝宝')
        else
          for (final item in vaccine.perBaby) _VaccineCard(item: item),
        const _SectionHeader('奶粉消耗'),
        const _FormulaConsumptionCard(),
        const _SectionHeader('里程碑时间轴'),
        if (vaccine.milestoneTimeline.isEmpty)
          const _NothingHere('还没有里程碑')
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                for (var i = 0; i < vaccine.milestoneTimeline.length; i++)
                  _RailRow(
                    // 这一条是顶层、跨宝宝的一份，宝宝名不进上下文就没法分辨两个宝宝混在一起的行。
                    title:
                        '${vaccine.milestoneTimeline[i].babyName} · '
                        '${vaccine.milestoneTimeline[i].title}',
                    subtitle: formatDate(
                      vaccine.milestoneTimeline[i].occurDate,
                    ),
                    body: vaccine.milestoneTimeline[i].description,
                    isLast: i == vaccine.milestoneTimeline.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 一个宝宝的体格块。`perBaby` 含归档的宝宝（历史统计照旧算它），所以卡片不按在册与否分叉。
class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.item});

  final BabyGrowthItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = item.latest;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(item.ageText, style: muted),
            const SizedBox(height: 10),
            if (latest == null)
              Text('还没有身高体重记录', style: theme.textTheme.bodySmall)
            else ...[
              Text(
                '最新体格 · ${formatDate(latest.measureDate)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  // 没量那一项整段不出现：值为空与「超出标准表覆盖范围」是两回事，
                  // 后者有值，由 PercentileBand 自己出那句说明。
                  if (latest.heightCm != null)
                    _Metric(
                      label: '身高',
                      value: '${latest.heightCm} cm',
                      band: latest.bands.height,
                    ),
                  if (latest.weightKg != null)
                    _Metric(
                      label: '体重',
                      value: '${latest.weightKg} kg',
                      band: latest.bands.weight,
                    ),
                  if (latest.headCm != null)
                    _Metric(
                      label: '头围',
                      value: '${latest.headCm} cm',
                      band: latest.bands.headCircumference,
                    ),
                ],
              ),
              // 体重别身高与 BMI 是派生量，响应里只给档位、不给实测值。两个输入量齐了才算得出来，
              // 缺一个就整项不显示——否则「没量体重」会被下面那格说成「超出标准表覆盖范围」。
              if (latest.weightKg != null && latest.heightCm != null) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _Band(label: '体重别身高', band: latest.bands.weightHeight),
                    _Band(label: 'BMI', band: latest.bands.bmi),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 8),
            _GainRow(label: '较上次', gain: item.growth.sinceLast),
            _GainRow(label: '近 3 个月', gain: item.growth.last3Months),
            _GainRow(label: '近 12 个月', gain: item.growth.last12Months),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ⑥ 的第二个入口（§1.3）：统计页这一处与总览 AppBar 那处进的是同一页。
                TextButton(
                  onPressed: () =>
                      context.push(RoutePath.babyCurveOf(babyId: item.babyId)),
                  child: const Text('看曲线'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 三段增量的一行。整行为空时不显示（`null` 是「这一段窗口里不足两条代表行」），
/// 显示 `+0` 会把「没量」说成「没变」（§4.4.2）。
class _GainRow extends StatelessWidget {
  const _GainRow({required this.label, required this.gain});

  final String label;
  final BabyGrowthGain? gain;

  @override
  Widget build(BuildContext context) {
    final line = _gainLine(gain);
    if (line == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(line, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// 「身高 +1.2 cm · 体重 +0.30 kg · 30 天」。某一档为 null 时那一段不出现——「较上次没量身高」
/// 与「较上次身高没变」是两件事，后者是 `0`。三项差值全为空时整行不给：只剩「30 天」读不出
/// 是谁跟谁比。
String? _gainLine(BabyGrowthGain? gain) {
  final days = gain?.days;
  if (gain == null || days == null) return null;

  final parts = [
    if (gain.heightCm != null) '身高 ${signedDelta(gain.heightCm!)} cm',
    if (gain.weightKg != null) '体重 ${signedDelta(gain.weightKg!)} kg',
    if (gain.headCm != null) '头围 ${signedDelta(gain.headCm!)} cm',
  ];
  if (parts.isEmpty) return null;
  return [...parts, '$days 天'].join(' · ');
}

/// 一个宝宝的疫苗块：完成率、四态分布、两张待办清单、近 12 个月的接种时间轴。
class _VaccineCard extends StatelessWidget {
  const _VaccineCard({required this.item});

  final BabyVaccineItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                _CompletionRing(rate: item.completionRate),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('疫苗完成率', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 4),
                      // 分母只算已到期的应种项（§4.4.6 第 24 轮 (m)）：远期剂次不进分母，
                      // 否则出院那天就会被读成「进度落后」。这句是那张环的唯一读法说明。
                      Text('已接种 ÷ 已到期的应种项', style: muted),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _StatusBar(counts: item.statusCounts),
            // 逾期排在前（§4.4.6 的「红色置顶」），颜色由 vaccineStatusColor 那一处给。
            if (item.overdueList.isNotEmpty) ...[
              _ListTitle('逾期清单', color: theme.colorScheme.error),
              for (final row in item.overdueList)
                _TodoRow(item: row, status: 'OVERDUE'),
              const SizedBox(height: 12),
            ],
            if (item.upcoming.isNotEmpty) ...[
              _ListTitle('即将接种'),
              for (final row in item.upcoming)
                _TodoRow(item: row, status: 'DUE_SOON'),
              const SizedBox(height: 12),
            ],
            if (item.recordTimeline.isNotEmpty) ...[
              _ListTitle('接种时间轴'),
              for (var i = 0; i < item.recordTimeline.length; i++)
                _RailRow(
                  title: item.recordTimeline[i].vaccineName,
                  subtitle: [
                    formatDate(item.recordTimeline[i].givenDate),
                    if (item.recordTimeline[i].clinic != null)
                      item.recordTimeline[i].clinic!,
                  ].join(' · '),
                  isLast: i == item.recordTimeline.length - 1,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// §4.4.6 的「环形进度」。用环不用条：`due` 在一个刚建档的宝宝上可能是 1，那时铺满的条子
/// 与「做了很多」看着一样，而「1/1」与「25/25」是两件事；环中心的百分数是唯一读数。
class _CompletionRing extends StatelessWidget {
  const _CompletionRing({required this.rate});

  /// 服务端给的 0–100 整数（`rateOf` 已夹在区间内），这里只除一百给 `value`。
  final int rate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              value: rate / 100,
              strokeWidth: 8,
              backgroundColor: theme.colorScheme.outlineVariant,
            ),
          ),
          Text('$rate%', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// §4.4.6 的「疫苗状态分布 · 分段条」：一根按数量分段的横条 + 四段各自的数。
///
/// 四个数之和可以小于清单总行数——已标记（跳过 / 不适用）的行不进这四段（§4.4.6），
/// 所以条子的全长是**这四个数之和**，不是应种总数。
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.counts});

  final BabyVaccineCounts counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cells = <(String, int)>[
      ('VACCINATED', counts.vaccinated),
      ('UPCOMING', counts.upcoming),
      ('DUE_SOON', counts.dueSoon),
      ('OVERDUE', counts.overdue),
    ];
    final total = cells.fold(0, (sum, cell) => sum + cell.$2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 10,
            // 一条应种项都还没到期时四个数全是 0，此时画一根空槽——条子整根消失会让人
            // 以为这一块没加载出来。
            child: total == 0
                ? ColoredBox(color: scheme.outlineVariant)
                : Row(
                    children: [
                      for (final (status, count) in cells)
                        if (count > 0)
                          Expanded(
                            flex: count,
                            child: ColoredBox(
                              color: vaccineStatusColor(scheme, status),
                            ),
                          ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final (status, count) in cells)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: vaccineStatusColor(scheme, status),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    vaccineDisplayLabels[status] ?? status,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 4),
                  Text('$count', style: theme.textTheme.labelMedium),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// 待办清单的一行。两列互斥且总有一列非空（§4.4.6），所以 `vaccineDueLabel` 不需要
/// 「两个都拿不到」的分支。
class _TodoRow extends StatelessWidget {
  const _TodoRow({required this.item, required this.status});

  final BabyVaccinePlanItem item;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.vaccineName} · ${doseLabel(item.doseNo)}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            formatDate(item.dueDate),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            vaccineDueLabel(
              daysToDue: item.daysToDue,
              overdueDays: item.overdueDays,
            ),
            style: theme.textTheme.labelMedium?.copyWith(
              color: vaccineStatusColor(theme.colorScheme, status),
            ),
          ),
        ],
      ),
    );
  }
}

/// 垂直时间轴的一行。一条竖线串起节点，与应种清单页那一屏同形；接种与里程碑两处都用它，
/// 差别只在标题里要不要带宝宝名。
class _RailRow extends StatelessWidget {
  const _RailRow({
    required this.title,
    required this.subtitle,
    required this.isLast,
    this.body,
  });

  final String title;
  final String subtitle;
  final String? body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // `IntrinsicHeight` + `stretch` 是必需的：`Column` 里的 `Expanded` 要一个有界高度才存在，
    // 而 `Row` 的自然高度由右边那块文字决定。换成固定高度会在说明换行时挤掉一行。
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
                  Text(title, style: theme.textTheme.bodyMedium),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (body != null)
                    Text(body!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.band});

  final String label;
  final String value;

  /// 落在哪一档（§1.4 第 9 条）。为 null 时 `PercentileBand` 自己写「已超出标准表覆盖范围」。
  final String? band;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label $value', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(width: 6),
      PercentileBand(band: band),
    ],
  );
}

/// 派生指标那一格：响应里没有它的实测值，只有档位。
class _Band extends StatelessWidget {
  const _Band({required this.label, required this.band});

  final String label;
  final String? band;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(width: 6),
      PercentileBand(band: band),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
    child: Text(
      title,
      // 与卡片化后的 `SectionHeader` 同一个字重：不再加粗轰炸，标题只是「下一步看什么」的轻引子
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// 卡内小标题。
class _ListTitle extends StatelessWidget {
  const _ListTitle(this.title, {this.color});

  final String title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: color ?? theme.colorScheme.onSurfaceVariant,
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

/// 奶粉消耗卡（§4.5.3）：累计克数、累计天数、区间日均 + 近 6 个月逐月消耗。
/// 家庭整体口径（奶粉按家庭记录，不按宝宝分），因此不随 babyId 筛选变化。
class _FormulaConsumptionCard extends ConsumerWidget {
  const _FormulaConsumptionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statistics = ref.watch(babyFormulaStatisticsViewModelProvider);

    return statistics.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Card(child: LinearProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(errorCopy(error), style: theme.textTheme.bodySmall),
          ),
        ),
      ),
      data: (stats) {
        if (stats.totalGrams == 0) {
          return const _NothingHere('还没有奶粉记录');
        }
        int maxGrams = 0;
        for (final month in stats.monthlyTrend) {
          if (month.grams > maxGrams) maxGrams = month.grams;
        }
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '累计 ${stats.totalGrams} g · ${stats.totalDays} 天'
                  ' · 日均 ${stats.dailyAverage} g',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                // 近 6 个月逐月：一行「月份 · 克数」，量级到「一眼看出哪个月高」就够，
                // 不为这一张卡引图表库；柱长按本月/最大月归一，最大月满格
                for (final month in stats.monthlyTrend)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 64,
                          child: Text(
                            month.month,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: maxGrams == 0 ? 0 : month.grams / maxGrams,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 56,
                          child: Text(
                            '${month.grams} g',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
