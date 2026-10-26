import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/models/baby.dart';
import '../../../../data/models/baby_growth.dart';
import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../baby_copy.dart';
import '../view_models/baby_growth_view_model.dart';
import '../view_models/baby_list_view_model.dart';

/// §4.4.2 的身高体重记录。`?babyId=` 有值就是这一个宝宝的，缺省是整个家庭的（每行带宝宝名）。
///
/// 过滤是**本地** `where`（照猫驱虫那一页）：视图模型装的是全量那份，`babyId` 从 URL 来、
/// 页面里没有改它的第二条路径。**不分页**——一个宝宝到 7 岁也就几十条。
class BabyGrowthListPage extends ConsumerWidget {
  const BabyGrowthListPage({this.babyId, super.key});

  /// null = 全部。由路由从 `?babyId=` 解出来。
  final int? babyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(babyGrowthViewModelProvider);
    final babies = ref.watch(babyListViewModelProvider).value ?? const <Baby>[];

    // 过滤在 `when` 之前算：AppBar 的标题要读宝宝名，而 `when` 只喂 body 那一块。
    final rows = [
      for (final row in records.value ?? const <BabyGrowth>[])
        if (babyId == null || row.babyId == babyId) row,
    ];
    // 名字从档案列表里查，行上不留快照：改完名字回来要看到新的那个。冷启动直接 push 进这一页时
    // 那份列表可能还在飞，查不到就退成不带名字的行。
    String? nameOf(int id) {
      for (final baby in babies) {
        if (baby.id == id) return baby.name;
      }
      return null;
    }

    final subject = babyId == null ? null : nameOf(babyId!);

    return Scaffold(
      appBar: AppBar(
        title: Text(subject == null ? '身高体重' : '$subject 的身高体重'),
        actions: [
          IconButton(
            tooltip: '记一次',
            icon: const Icon(Icons.add),
            // 不带 `?babyId=`：新增表单里的宝宝是一个选择器，哪一种筛法进来都由用户在表单里定。
            onPressed: () => context.push(RoutePath.babyGrowthEdit),
          ),
        ],
      ),
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorCopy(error), textAlign: TextAlign.center),
          ),
        ),
        data: (_) => rows.isEmpty
            ? const _EmptyGrowths()
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  // 每行一张独立小卡（问题单：卡片间有间距），不再整份塞进一张大卡。
                  for (final row in rows)
                    RowCard(
                      child: _GrowthTile(
                        row: row,
                        // 「全部宝宝」那一份才逐行重复宝宝名。
                        babyName:
                            babyId == null ? nameOf(row.babyId) : null,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// 一条记录的三个度量格（身高 / 体重 / 头围），横向排三列（参考图：表头带单位、数值大字、
/// 下面一枚「百分之多少 + 是否正常」的胶囊）。
/// 没量的那一列数值给「--」，百分比与状态一整格留空——「没量」与「超范围」是两件事。
List<({String label, String unit, String value, String delta, String percent})>
_metricCells(BabyGrowth row) {
  final delta = row.deltaFromPrevious;
  final percentiles = row.percentiles;
  // 差值不单独一列：跟在数值后面，如 `58 (+1.5)`；没有「上一次」或上次没量这一项时不带括号。
  String deltaOf(String? measured, String? previousDelta) =>
      measured == null || previousDelta == null
      ? ''
      : '(${signedDelta(previousDelta)})';

  return [
    (
      label: '身高',
      unit: 'cm',
      value: row.heightCm ?? '--',
      delta: deltaOf(row.heightCm, delta?.heightCm),
      percent: percentiles?.height ?? '',
    ),
    (
      label: '体重',
      unit: 'kg',
      value: row.weightKg ?? '--',
      delta: deltaOf(row.weightKg, delta?.weightKg),
      percent: percentiles?.weight ?? '',
    ),
    (
      label: '头围',
      unit: 'cm',
      value: row.headCm ?? '--',
      delta: deltaOf(row.headCm, delta?.headCm),
      percent: percentiles?.headCircumference ?? '',
    ),
  ];
}

class _GrowthTile extends ConsumerWidget {
  const _GrowthTile({required this.row, this.babyName});

  final BabyGrowth row;

  /// 只在「全部宝宝」那一份里显示。
  final String? babyName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final delta = row.deltaFromPrevious;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return InkWell(
      onTap: () => context.push(RoutePath.babyGrowthEditOf(row.id)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    babyName == null
                        ? formatDate(row.measureDate)
                        : '$babyName · ${formatDate(row.measureDate)}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    delta?.days == null
                        ? '首条记录，还没有上次可比'
                        : '距上次 ${delta!.days} 天',
                    style: muted,
                  ),
                  const SizedBox(height: 10),
                  // 三列表头：身高cm / 体重kg / 头围cm（单位跟在小字里，与参考图一致）。
                  _gridRow(
                    (cell) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(cell.label, style: theme.textTheme.titleSmall),
                        const SizedBox(width: 2),
                        Text(
                          cell.unit,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 数值大字（参考图：58）；差值跟在后面一小格，没量给 `--`。
                  // `FittedBox` 让「大字 + 差值」在窄列上等比缩小而不是顶出屏幕。
                  _gridRow(
                    (cell) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            cell.value,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cell.value == '--'
                                  ? theme.colorScheme.outline
                                  : null,
                            ),
                          ),
                          if (cell.delta.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                cell.delta,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 百分之多少 + 是否正常（参考图：一枚浅底胶囊，如 `40.5% 正常`）。
                  // 没量的那一列整格留空：值都是 `--` 了，再挂一枚「正常」标就是替没发生过的事背书。
                  _gridRow(
                    (cell) => cell.value == '--'
                        ? const SizedBox.shrink()
                        : _PercentileCell(percent: cell.percent),
                  ),
                  if (row.remark != null) ...[
                    const SizedBox(height: 6),
                    Text(row.remark!, style: muted),
                  ],
                ],
              ),
            ),
            // `DELETE /baby-growths/{id}` 的入口就在这一格（§5.2）。整行点进编辑、
            // 菜单里再给一次编辑与删除——照 `cat_food_bag_list_page.dart` 那一行。
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit'
                  ? context.push(RoutePath.babyGrowthEditOf(row.id))
                  : _delete(context, ref),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('编辑')),
                PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 三列里任一列交给 `buildCell`，三列等宽对齐：表头、数值、百分比三行用的是
  /// 同一个格子划分，各列才不会错位。
  Widget _gridRow(
    Widget Function(
      ({String label, String unit, String value, String delta, String percent})
      cell,
    )
    buildCell,
  ) {
    final cells = _metricCells(row);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          Expanded(child: buildCell(cells[i])),
          if (i < cells.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  /// 删一条会改这个宝宝后面各条的「较上一次」，曲线与统计也跟着重算（服务端读时派生），
  /// 所以确认框把这件事说出来——它是这一屏唯一一个会改动**别的行**的动作。
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: '删除 ${formatDate(row.measureDate)} 这条记录？',
      message: '这个宝宝后面各条的「较上一次」、生长曲线与统计都会跟着重算。删除后无法恢复。',
      confirmLabel: '删除',
    );
    if (!confirmed) return;
    final error = await ref
        .read(babyGrowthViewModelProvider.notifier)
        .remove(row.id);
    if (error != null && context.mounted) showSnackBar(context, error);
  }
}

/// 底部一枚胶囊：百分之多少 + 是否正常（参考图：`40.5% 正常`）。百分位在 3–97 之间是
/// 正常参考范围；`"<3%"` / `">97%"` 建议咨询儿保医生；百分比为空（超标准表覆盖范围）只出「超范围」。
class _PercentileCell extends StatelessWidget {
  const _PercentileCell({required this.percent});

  /// 服务端算好的「百分之多少」：`40.5%` / `<3%` / `>97%`，空串 = 超出标准表覆盖范围。
  final String percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (percent) {
      '' => ('超范围', theme.colorScheme.outline),
      '<3%' => ('偏低', Colors.orange.shade800),
      '>97%' => ('偏高', Colors.orange.shade800),
      _ => ('正常', Colors.green.shade600),
    };

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (percent.isNotEmpty)
              Text(
                percent,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (percent.isNotEmpty) const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGrowths extends StatelessWidget {
  const _EmptyGrowths();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.straighten_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('还没有身高体重记录', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '记下第一次测量，生长曲线与统计才有得算',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
