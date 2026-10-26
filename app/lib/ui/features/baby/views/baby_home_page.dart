import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/baby.dart';
import '../../../../data/models/baby_formula_bag.dart';
import '../../../../data/models/baby_formula_estimate.dart';
import '../../../../data/models/baby_statistics.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/auth_image.dart';
import '../../../core/category_palette.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';
import '../../../core/offline_banner.dart';
import '../baby_badges.dart';
import '../baby_copy.dart';
import '../view_models/baby_formula_view_model.dart';
import '../view_models/baby_home_view_model.dart';

/// 待办卡最多列几行。逾期与临近的加起来可能几十条（一个宝宝到 7 岁有二十来针），
/// 这一卡是「今天要留意什么」不是清单本身，清单在 ⑦，「全部」那一个入口把它接过去。
const int _todoLimit = 5;

/// §4.4 的宝宝总览，模块的唯一门面：从设置页 push 进来，其余九页都从这里分发。
///
/// 三段数据（档案、最新体格、疫苗待办）合并成一份状态（`BabyHomeViewModel`），
/// 所以要么整屏转圈、要么整屏出数，不会出现「卡片有宝宝、体格还在转」。也是本阶段
/// **唯一挂离线快照的页面**（§5.4）：`fromCache` 为真时顶部挂横幅，数据是上次成功那份。
class BabyHomePage extends ConsumerWidget {
  const BabyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(babyHomeViewModelProvider);
    final notifier = ref.read(babyHomeViewModelProvider.notifier);

    // 曲线要一个具体宝宝。`babyRepository.list()` 缺省不带归档的，所以这一份里的第一个
    // 就是在册的第一个；一个都没有（含加载与出错时）则曲线图标置灰。
    final babies = overview.value?.babies ?? const <Baby>[];
    final subject = babies.isEmpty ? null : babies.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('宝宝'),
        actions: [
          IconButton(
            tooltip: '档案管理',
            icon: const Icon(Icons.folder_outlined),
            onPressed: () => context.push(RoutePath.babyList),
          ),
          IconButton(
            // 置灰时 tooltip 换成原因：按钮自己变灰说明不了「为什么点不动」（§5.4 同一条规矩）。
            tooltip: subject == null ? '先建档一个宝宝' : '生长曲线',
            icon: const Icon(Icons.show_chart),
            onPressed: subject == null
                ? null
                : () => context.push(RoutePath.babyCurveOf(babyId: subject.id)),
          ),
          IconButton(
            tooltip: '统计',
            icon: const Icon(Icons.insert_chart_outlined),
            // 统计不带 `babyId` 就是全家庭那一份，所以它不要求先选中一个宝宝。
            onPressed: () => context.push(RoutePath.babyStatistics),
          ),
        ],
      ),
      body: RefreshIndicator(
        // 第 34 轮：下拉刷新把奶粉的两份数据也一起失效。此前这四份里只有宝宝总览的三段
        // 会重拉，奶粉区守着旧清单——「记录完回来看不到新罐，拉一下才好」就是这么来的。
        onRefresh: () async {
          ref.invalidate(babyFormulaViewModelProvider);
          ref.invalidate(babyFormulaCurrentProvider);
          await notifier.refresh();
        },
        child: overview.when(
          loading: () => _Centered(child: const CircularProgressIndicator()),
          error: (error, _) => _Centered(
            child: _Failure(
              message: errorCopy(error),
              onRetry: notifier.refresh,
            ),
          ),
          data: (state) => state.babies.isEmpty
              ? const _Centered(child: _EmptyBabies())
              : ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    if (state.fromCache) OfflineBanner(savedAt: state.savedAt),
                    // 档案在前、疫苗待办在后：宝宝是谁比今天要打哪一针更先被看到。
                    const SectionHeader(title: '宝宝档案'),
                    for (final (index, baby) in state.babies.indexed)
                      _BabyCard(
                        baby: baby,
                        latest: _latestOf(state, baby.id),
                        index: index,
                      ),
                    SectionHeader(
                      title: '疫苗待办',
                      trailing: TextButton(
                        onPressed: () => context.push(RoutePath.babyVaccines),
                        child: const Text('全部'),
                      ),
                    ),
                    _VaccineTodo(statistics: state.vaccineTodo),
                    // 奶粉节的标题行自带「记一罐」与「全部」两个入口，不套 SectionHeader
                    // （它只留一个 trailing 位，两个入口放不下）。
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '奶粉',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.push(RoutePath.babyFormulaEdit),
                            child: const Text('记一罐'),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.push(RoutePath.babyFormulas),
                            child: const Text('全部'),
                          ),
                        ],
                      ),
                    ),
                    // 第 34 轮：奶粉区从「当前一罐」改成「最近三罐」小列表（当前罐在最上，
                    // 口径确认），可一眼看到从哪罐喝到哪罐；记一罐入口放到节标题。
                    const _FormulaPreview(),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 总览上每张宝宝卡的最新体格取自统计端点那份 `perBaby`，不按 id 再打一次请求
/// ——三条请求要能合成一份快照，前提就是这一屏的数据全在这三条里（§5.4）。
BabyGrowthLatest? _latestOf(BabyHomeState state, int babyId) {
  for (final item in state.latestGrowth?.perBaby ?? const <BabyGrowthItem>[]) {
    if (item.babyId == babyId) {
      return item.latest;
    }
  }
  return null;
}

/// 待办一行：两张列表本身不带宝宝名（§4.4.6，它们挂在一个宝宝下面），
/// 总览上两栏摊平后「是谁的」只能在这里补上。
class _TodoRow {
  const _TodoRow({required this.babyName, required this.item});

  final String babyName;
  final BabyVaccinePlanItem item;
}

/// 逾期在前、逾期久者在前；未到期的按应种日期近者在前。两段分开排而不是合成一个比较器：
/// 逾期的「天数」越大越急，未到期的越小越急，方向相反。
List<_TodoRow> _todoRows(BabyVaccineStatistics? statistics) {
  final overdue = <_TodoRow>[];
  final upcoming = <_TodoRow>[];

  for (final perBaby in statistics?.perBaby ?? const <BabyVaccineItem>[]) {
    for (final item in perBaby.overdueList) {
      overdue.add(_TodoRow(babyName: perBaby.name, item: item));
    }
    for (final item in perBaby.upcoming) {
      upcoming.add(_TodoRow(babyName: perBaby.name, item: item));
    }
  }

  overdue.sort(
    (a, b) => (b.item.overdueDays ?? 0).compareTo(a.item.overdueDays ?? 0),
  );
  upcoming.sort(
    (a, b) => (a.item.daysToDue ?? 0).compareTo(b.item.daysToDue ?? 0),
  );
  return [...overdue, ...upcoming];
}

class _VaccineTodo extends StatelessWidget {
  const _VaccineTodo({required this.statistics});

  final BabyVaccineStatistics? statistics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _todoRows(statistics);

    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text('没有临近或逾期的疫苗。到了应种日会在这里提示。'),
      );
    }

    // 每条待办一张独立小卡（问题单：卡片间有间距）。
    return Column(
      children: [
        for (final row in rows.take(_todoLimit))
          RowCard(
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.vaccines_outlined),
              title: Text('${row.babyName} · ${row.item.vaccineName}'),
              subtitle: Text(
                '${doseLabel(row.item.doseNo)} · ${formatDate(row.item.dueDate)}',
              ),
              trailing: Text(
                vaccineDueLabel(
                  daysToDue: row.item.daysToDue,
                  overdueDays: row.item.overdueDays,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: row.item.overdueDays != null
                      ? theme.colorScheme.error
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 一个宝宝一张卡：头像、名字、服务端下发的 `ageText`、最新体格三项带百分位段，底部三个入口。
class _BabyCard extends StatelessWidget {
  const _BabyCard({
    required this.baby,
    required this.latest,
    required this.index,
  });

  final Baby baby;

  /// 一条身高体重记录都没有时为 null，此时那一行换成一句提示而不是六个「—」。
  final BabyGrowthLatest? latest;

  /// 只用于取头像色（一期无照片：颜色按列表下标取，不落库、不随属性变，同猫总览）。
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = this.latest;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 有档案照片就显示（S10）：带鉴权下载的 AuthImage，圆形裁切；没照片仍是色块+首字占位。
                ClipOval(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: AuthImage(
                      photoUrl: baby.photoUrl,
                      fit: BoxFit.cover,
                      // 40 逻辑 px × 2 高 DPI：小头像按 1200px 全解码白占内存
                      cacheWidth: 80,
                      placeholder: CircleAvatar(
                        backgroundColor: categoryTint(categoryColor(index)),
                        child: Text(
                          baby.name.characters.first,
                          style: TextStyle(
                            color: categoryColor(index),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(baby.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${genderLabels[baby.gender] ?? baby.gender} · '
                        '${formatDate(baby.birthDate)} · ${baby.ageText}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () =>
                      context.push(RoutePath.babyGrowthsOf(baby.id)),
                  child: const Text('身高体重'),
                ),
                TextButton(
                  onPressed: () =>
                      context.push(RoutePath.babyVaccinesOf(baby.id)),
                  child: const Text('疫苗'),
                ),
                TextButton(
                  onPressed: () =>
                      context.push(RoutePath.babyRecordsOf(baby.id)),
                  child: const Text('记录'),
                ),
              ],
            ),
          ],
        ),
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

/// loading 与 error 两支也要能被下拉。`RefreshIndicator` 挂在一个不可滚动的 `Center` 上时
/// 手势直接落空——症状是「转圈的时候反而刷新不了」。`minHeight` 那份约束让子项至少撑满一屏，
/// 于是 `Center` 仍然居中，而 `SingleChildScrollView` 永远可滚。
class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(child: child),
      ),
    ),
  );
}

/// 与 `cat_home_page.dart` 里那一份同形状，照抄而不是提成公共组件：十五行、两个入参、零逻辑，
/// 抽出去只有两条路——跨模块反向依赖，或在 `ui/core/` 新开一个文件（那要改需求文档 §6.1.1
/// 的目录树），为一个错误态开一次文档变更不值。
class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('重试')),
      ],
    ),
  );
}

/// 一个宝宝都没有时的整屏。AppBar 上那一排是「管理 / 曲线 / 统计」三个动作，没有建档，
/// 所以这里的按钮是这一屏唯一说得清下一步的地方。
class _EmptyBabies extends StatelessWidget {
  const _EmptyBabies();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.child_care_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('还没有宝宝档案', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '先建一个宝宝，身高体重、疫苗与就诊记录都挂在它名下',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push(RoutePath.babyEdit),
            icon: const Icon(Icons.add),
            label: const Text('建档'),
          ),
        ],
      ),
    );
  }
}

/// 奶粉区（§4.5.3，第 34 轮改为「最近三罐」小列表）：当前罐在最上，下面跟最近两罐。
///
/// 数据源是开罐清单 `babyFormulaViewModelProvider` 而不是 `/current`：清单的 state 在
/// 记/改/删成功后由 VM 的 `_write` 直接重写（同步落地），不依赖 invalidate 的时序——
/// 所以「记录完回宝宝页马上看到新罐」是结构上保证的，而不是碰巧赶上某次重建。
/// `/current` 只用来给当前罐那一行补余量推算（剩余克数 / 预计还能喝几天）。
class _FormulaPreview extends ConsumerWidget {
  const _FormulaPreview();

  /// 总览上最多列几行。完整时间线在「全部」那一页，这一卡只是「最近在喝什么」。
  static const int _previewLimit = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bags = ref.watch(babyFormulaViewModelProvider);
    // 当前罐的余量推算仍走 /current；「开了还推不出」与「一罐都还没开」仍是两句话
    final current = ref.watch(babyFormulaCurrentProvider).value;

    return bags.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: RowCard(child: LinearProgressIndicator()),
      ),
      error: (_, _) => _FormulaPlaceholder(
        text: '需要联网查看奶粉余量',
        onAction: () => context.push(RoutePath.babyFormulaEdit),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return _FormulaPlaceholder(
            text: '还没有奶粉记录',
            onAction: () => context.push(RoutePath.babyFormulaEdit),
          );
        }
        // 清单升序（最早在上、当前罐在最后一条），倒过来取最近三罐，当前罐自然就在最上
        final preview = rows.reversed.take(_previewLimit).toList();
        return Column(
          children: [
            for (final (index, bag) in preview.indexed)
              RowCard(
                child: _FormulaRow(
                  bag: bag,
                  isCurrent: index == 0,
                  estimate: index == 0 ? current?.estimate : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 预览里的一行：当前罐在上（带「在用」角标与余量推算），下面两行是历史罐（开罐日 + 喝了几天）。
/// 点行进编辑页——与列表页同一份交互，改错罐不至于先回列表再翻。
class _FormulaRow extends StatelessWidget {
  const _FormulaRow({
    required this.bag,
    required this.isCurrent,
    required this.estimate,
  });

  final BabyFormulaBag bag;

  /// 是不是当前罐：决定要不要「在用」角标、余量推算行放在哪。
  final bool isCurrent;

  /// 当前罐的余量推算。为 null 表示「开了但推不出」或 `/current` 还没回来，
  /// 那行显示开罐日 + 一句提示，而不是编一个数。
  final BabyFormulaEstimate? estimate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      onTap: () => context.push(RoutePath.babyFormulaEditOf(bag.id)),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.water_drop_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(bag.brand, overflow: TextOverflow.ellipsis),
          ),
          if (bag.current) ...[
            const SizedBox(width: 8),
            const _CurrentTag(),
          ],
        ],
      ),
      subtitle: Text(
        isCurrent
            ? (estimate == null
                  ? '开了 ${formatDateWithTime(bag.startedDate, bag.startedTime)}'
                        ' · 填开罐时的预计日均后可以推算余量'
                  : estimate!.overEstimate
                      ? '已超出预计用量，请确认是否已开新罐'
                      : '剩余约 ${estimate!.remainingGrams} g'
                            ' · 预计还能喝 ${estimate!.daysLeft == 0 ? '今天用完' : '${estimate!.daysLeft} 天'}')
            : '${formatDateWithTime(bag.startedDate, bag.startedTime)} 开罐 · 喝了 ${bag.usageDays ?? 0} 天',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.outline,
      ),
    );
  }
}

/// 「在用」那一格（第 34 轮宝宝页奶粉预览也要，列表页那份是列表页私有的，这里单独留一份）。
class _CurrentTag extends StatelessWidget {
  const _CurrentTag();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '在用',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// 空态与离线态的共用占位：一句说明 + 一个「记一罐」动作。
class _FormulaPlaceholder extends StatelessWidget {
  const _FormulaPlaceholder({required this.text, required this.onAction});

  final String text;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RowCard(
        child: ListTile(
          leading: const Icon(Icons.water_drop_outlined),
          title: Text(text, style: theme.textTheme.bodyMedium),
          trailing: TextButton(onPressed: onAction, child: const Text('记一罐')),
        ),
      ),
    );
  }
}
