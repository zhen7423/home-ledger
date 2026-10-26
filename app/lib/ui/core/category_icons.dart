import 'package:flutter/material.dart';

/// 类别图标（§4.2.2 → UI 设计语言规范「暖居」§3）。后端存的是 `icon_key` 字符串，
/// 这里把它翻成 `Icons.*_rounded`——**同一组语义、圆润笔画**：Material 圆润变体比默认的
/// 直角线形更亲和，与「暖居」的圆角体系呼应，也是「图标色彩与整体界面调性统一」的一半。
/// 图标与配色共用同一个 `color_index`（见 `category_palette.dart`）。
///
/// 认不出的 key 回落到 `Icons.label_outline_rounded`：后端加了新图标而这台机器上的客户端
/// 还是旧版本时，界面上要有一个能看的占位，既不该崩也不该显示空白。
///
/// 下面这张表只有 23 条而不是 24 条：池子里索引 10（支出「其他」）与 16（收入「其他」）同名，
/// 按 key 查表自然合成一条。
IconData categoryIcon(String iconKey) =>
    _iconPool[iconKey] ?? Icons.label_outline_rounded;

const Map<String, IconData> _iconPool = {
  'restaurant': Icons.restaurant_rounded,
  'directions_bus': Icons.directions_bus_rounded,
  'shopping_bag': Icons.shopping_bag_rounded,
  'home': Icons.home_rounded,
  'local_hospital': Icons.local_hospital_rounded,
  'school': Icons.school_rounded,
  'sports_esports': Icons.sports_esports_rounded,
  'pets': Icons.pets_rounded,
  'child_care': Icons.child_care_rounded,
  'redeem': Icons.redeem_rounded,
  'more_horiz': Icons.more_horiz_rounded,
  'payments': Icons.payments_rounded,
  'emoji_events': Icons.emoji_events_rounded,
  'trending_up': Icons.trending_up_rounded,
  'work_outline': Icons.work_outline_rounded,
  'card_giftcard': Icons.card_giftcard_rounded,
  'flight': Icons.flight_rounded,
  'fitness_center': Icons.fitness_center_rounded,
  'palette': Icons.palette_rounded,
  'build': Icons.build_rounded,
  'local_cafe': Icons.local_cafe_rounded,
  'savings': Icons.savings_rounded,
  'category': Icons.category_rounded,
};
