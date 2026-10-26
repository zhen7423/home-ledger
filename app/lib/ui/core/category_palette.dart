import 'package:flutter/material.dart';

/// 类别配色（§4.2.2 → UI 设计语言规范「暖居」§2.4）。后端只存 `color_index`，
/// 24 色色板只在前端这一份。
///
/// 设计口径（暖居 v1.0）：
/// - 饱和度统一 0.55、明度统一 0.55——比最初的 0.62/0.55 降饱和提明度，去荧光感、加柔和感，
///   让整组颜色与暖橙主题共享同一份「温润彩铅」气质。
/// - 色相不再是等距 15°，改用 24 个手工编排的色相位（见 [_categoryHues]）：常用的支出预置类别
///   优先分到暖区（餐饮橙红、居住琥珀棕、宠物金黄），收入类别用财意味浓的绿 / 金，
///   两个「其他」（index 10 / 16）做成中性暖灰，从彩色群里退一步。
/// - 同屏可见的任意两色（记账格子的同行/邻格、饼图扇区、成员对比柱）色相差 ≥ 12°；
///   只有跨收支两树、永不同屏的成对色（奖金 30 / 居住 40）允许更近。
///
/// 索引越界不会抛错——Dart 的 `%` 对负数也回正数，24 以上则绕回第一轮，所以后端哪天改了取号规则，
/// 界面上是颜色重复而不是白屏（这条不变量由 `test/ui/core/category_palette_test.dart` 钉住）。
Color categoryColor(int index) {
  final i = index % 24;
  final hue = _categoryHues[i];
  if (hue == null) {
    // index 10 / 16（支出与收入的「其他」）：中性暖灰，S 压到 0.10 让它安静地退在彩色群后面。
    // 支出「其他」浅一档、收入「其他」深一档——24 色互不相同的不变量测试要求两位不相等，
    // 而两者永不同屏（收支两棵树的「其他」不会同时出现），深浅差既满足不变量又不破坏中性观感。
    // 查不到参数时回退浅灰而不是抛错：与「索引越界颜色重复、不白屏」同为一条原则。
    final (greyHue, sat, light) =
        _categoryNeutrals[i] ?? const (228.0, 0.10, 0.52);
    return HSLColor.fromAHSL(1, greyHue, sat, light).toColor();
  }
  return HSLColor.fromAHSL(1, hue, 0.55, 0.55).toColor();
}

/// 24 个色相位，数组下标即 `color_index`；null 是「其他」的两个中性灰位。
const List<double?> _categoryHues = [
  18, 196, 316, 40, 350, //  0–4  餐饮 / 交通 / 购物 / 居住 / 医疗
  212, 262, 52, 296, 2, //  5–9  教育 / 娱乐 / 宠物 / 宝宝 / 人情往来
  null, //       10    支出·其他（中性灰）
  152, 30, 178, 226, 338, // 11–15 工资 / 奖金 / 理财收益 / 兼职 / 红包礼金
  null, //       16    收入·其他（中性灰）
  70, 92, 114, 136, 165, 244, 278, // 17–23 自定义大类的 7 个空位
];

/// 中性灰参数（hue, saturation, lightness），键是 color_index。
const Map<int, (double, double, double)> _categoryNeutrals = {
  10: (228, 0.10, 0.52),
  16: (228, 0.10, 0.42),
};

/// 色块上的前景色。0.14 透明度的同色底 + 本色图标，比「实色底 + 白图标」在白底上更稳，
/// 也不用给 24 个色各配一个文字色（不变量测试钉住 alpha 0.14 与色相不变）。
Color categoryTint(Color color) => color.withValues(alpha: 0.14);

/// 下钻到小类时沿用它所属大类的色相、按小类序号调明度（§4.2.2）。
///
/// 起点 0.36、步长 0.06、序号取模 7：一个小类通常也就五六个，明度铺在 0.36–0.72 这一段，
/// 最暗的一片仍看得清扇区边界，最亮的一片在白底上也没淡到消失。第八个及以后绕回第一轮，
/// 与 `categoryColor` 索引越界绕回是同一个思路——颜色重复比抛错好。
Color categoryShade(Color base, int index) =>
    HSLColor.fromColor(base).withLightness(0.36 + 0.06 * (index % 7)).toColor();
