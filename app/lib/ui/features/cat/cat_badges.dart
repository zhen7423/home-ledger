import 'package:flutter/material.dart';

import 'cat_copy.dart';

/// 驱虫类型的小色块。列表页与统计页的时间线共用，两处必须同色，
/// 所以颜色跟着 `type` 字面量走，不跟着列表下标走。
class CatTypeBadge extends StatelessWidget {
  const CatTypeBadge({required this.type, super.key});

  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 内驱蓝、外驱绿：这一处没有类别色可借（`categoryColor` 按列表下标取，
    // 而类型只有两个值，按下标取色会让同一个类型在两页里不同色）
    final color = type == 'INTERNAL' ? Colors.blue.shade300 : Colors.green.shade400;

    return Container(
      alignment: Alignment.center,
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        dewormingLabel(type),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
