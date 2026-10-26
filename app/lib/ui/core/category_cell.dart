import 'package:flutter/material.dart';

import '../../data/models/category.dart';
import 'category_icons.dart';
import 'category_palette.dart';

/// 类别选择格子里的那一枚（§6.10——UI 设计语言规范「暖居」）：
/// 未选中 = 浅色（categoryTint）圆底 + 本色图标；选中 = 同类色柔光环 + 实色圆底 + 白图标。
///
/// 柔光环替代原来的主色描边：环色与类别色同源，蓝类别不再套一个橙圈——这正是
/// 「图标色彩与整体界面调性统一」的落点。光环用 `Stack + Clip.none` **绘制溢出**（52dp
/// 绕出 44dp 圆 4dp），布局尺寸恒定为 44dp 圆 + 名称——与原实现完全同高，小屏窄格与
/// 系统大字体下不会把五列网格挤出 `RenderFlex overflow`（这是 52dp 进布局的代价）。
///
/// 记一笔与新建周期规则共用它。放 `ui/core` 而不是留在某个页面里当私有 widget，
/// 是因为这两个表单的类别选择必须是同一个样子——两处各写一份，改一处漏一处。
class CategoryCell extends StatelessWidget {
  const CategoryCell({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  /// 布局尺寸——与原实现一致，是「不变形」承诺的根。
  static const double _circle = 44;

  /// 绘制尺寸：选中时柔光环绕出 [_circle] 四周各 4dp。
  static const double _halo = 52;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category.colorIndex ?? 0);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: _circle,
            height: _circle,
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (selected)
                  Container(
                    width: _halo,
                    height: _halo,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // 选中时的柔光环：18% 的同类色，视觉上是「光晕」而不是一个生硬的外圈
                      color: color.withValues(alpha: 0.18),
                    ),
                  ),
                Container(
                  width: _circle,
                  height: _circle,
                  decoration: BoxDecoration(
                    color: selected ? color : categoryTint(color),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryIcon(category.iconKey ?? ''),
                    color: selected ? Colors.white : color,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: selected ? FontWeight.w600 : null,
              color: selected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
