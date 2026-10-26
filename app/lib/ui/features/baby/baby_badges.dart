import 'package:flutter/material.dart';

import 'baby_copy.dart';

/// 疫苗五态徽章。应种清单的每一行与统计页的状态分布给同一行上同一色，
/// 所以颜色跟着 `displayStatus` 字面量走，不跟着列表下标走。
class VaccineStatusBadge extends StatelessWidget {
  const VaccineStatusBadge({required this.displayStatus, super.key});

  final String displayStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = vaccineStatusColor(theme.colorScheme, displayStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        vaccineDisplayLabels[displayStatus] ?? displayStatus,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          // 「已跳过 / 不适用」与「待接种」同是灰色（§4.4.4），删除线是这两行唯一的分别。
          decoration: displayStatus == 'MARKED'
              ? TextDecoration.lineThrough
              : null,
        ),
      ),
    );
  }
}

/// 五态的配色（§4.4.4 的展示列：即将接种蓝高亮、逾期红、已接种绿、跳过与不适用灰）。
///
/// 默认分支同时接住「待接种」与没预料到的码值：两边都是不掉色的中性灰，服务端加第六态时
/// 界面该少一种颜色，而不是崩或显示成另一种态。
Color vaccineStatusColor(ColorScheme scheme, String displayStatus) =>
    switch (displayStatus) {
      'VACCINATED' => Colors.green.shade400,
      'DUE_SOON' => Colors.blue.shade300,
      'OVERDUE' => scheme.error,
      'MARKED' => Colors.blueGrey,
      _ => scheme.outline,
    };

/// 百分位带（§4.4.3）。`null` 是「超出标准表覆盖范围」这个有含义的空值，不是缺数据：
/// 7 岁以后、头围 3 岁以后、体重别身高超出所选那张表的横轴范围都会走到这里。
///
/// `'P50–P75'` 这样的一整条原样显示，**不在前端拆开**：拆开就得再实现一遍区间判定，
/// 而那条判定只在服务端一处（`GrowthPercentile.bandOf`）。
class PercentileBand extends StatelessWidget {
  const PercentileBand({required this.band, super.key});

  final String? band;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = band == null
        ? theme.colorScheme.outline
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        band ?? '已超出标准表覆盖范围',
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
