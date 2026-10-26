// 把统计响应整形成图表能直接吃的形状。
//
// 抽出来的理由是测试：fl_chart 用 CustomPainter 画图，widget 测试断言不到图里的内容，
// 所以「哪几片可见」「坐标轴上限取多少」「刻度隔几个显示一次」这些决定必须能在没有 widget 的地方验。
// 本文件是纯函数 + 只读数据类，**不 import material**，颜色由页面去查（那是主题的事，不是数据的事）。
//
// 这也是全项目唯一让 double 碰到钱的地方（§6.1 的那一个例外）：fl_chart 的几何参数只吃 double。
// double 只用于画图，界面上显示出来的金额一律走 caption 里那份 formatYuan 之后的字符串。
library;

import 'dart:math' as math;

import '../../../../data/models/finance_statistics.dart';
import '../../../../data/models/month_summary.dart';
import '../../../core/date_format.dart';
import '../../../core/money.dart';

/// 饼图 / 柱状图上的一项。
///
/// `value` 的单位是**分**（由 toCents 得来），不是元——差 100 倍是这种代码最容易犯的错，
/// 写成整数分还能让 double 在 2^53 以内完全精确。
class ChartDatum {
  const ChartDatum({
    this.label = '',
    required this.value,
    this.caption = '',
    this.percent = 0,
    this.id,
  });

  /// 图例与坐标轴上的短标签。成员对比里的柱子没有自己的标签，图例文字另取自 [memberBarLabels]。
  final String label;

  /// 只给几何用，**不要直接显示它**。
  final double value;

  /// 显示用的金额串，已经过 formatYuan（`"¥1,234.00"`）。
  final String caption;

  final int percent;

  /// 类别 id 或成员 userId，看是哪个函数给的。null 表示「其他」那一档，界面据此禁掉下钻。
  final int? id;
}

/// 月度收支趋势的一个月。
class MonthDatum {
  const MonthDatum({
    required this.label,
    required this.income,
    required this.expense,
    required this.balance,
  });

  final String label;
  final double income;
  final double expense;
  final double balance;
}

/// 成员支出对比的一组。
class MemberDatum {
  const MemberDatum({
    required this.label,
    required this.userId,
    required this.total,
    required this.bars,
  });

  final String label;
  final int userId;
  final double total;

  /// 「按大类」视图用；每根的 `id` 是 categoryId（可为 null，表示「其他」档）。
  /// 与 categoryBreakdown 逐项对齐，所以名字与颜色按下标取（见 [memberBarLabels]）。
  final List<ChartDatum> bars;
}

/// 饼图该画哪几片。`drilledCategoryId` 为 null 是顶层（大类），非 null 是下钻到那个大类的小类。
///
/// 下钻的目标找不到时回落成顶层而不是回一个空列表：那种情况只可能是数据在两次渲染之间被换掉了
/// （比如离线快照刚被拨回另一个区间），给用户看一张空饼图不如把他带回顶层。
List<CategorySlice> visibleSlices(
  FinanceStatistics overview,
  int? drilledCategoryId,
) {
  if (drilledCategoryId == null) {
    return overview.categoryBreakdown;
  }
  for (final slice in overview.categoryBreakdown) {
    if (slice.categoryId == drilledCategoryId) {
      return slice.subCategories;
    }
  }
  return overview.categoryBreakdown;
}

List<ChartDatum> sliceData(List<CategorySlice> slices) => [
  for (final slice in slices)
    ChartDatum(
      label: slice.name,
      value: toCents(slice.amount).toDouble(),
      caption: formatYuan(slice.amount),
      percent: slice.percent,
      id: slice.categoryId,
    ),
];

List<ChartDatum> accountData(List<AccountSlice> slices) => [
  for (final slice in slices)
    ChartDatum(
      label: slice.name,
      value: toCents(slice.amount).toDouble(),
      caption: formatYuan(slice.amount),
      percent: slice.percent,
      id: slice.accountId,
    ),
];

List<MonthDatum> monthlyData(List<MonthSummary> trend) => [
  for (final month in trend)
    MonthDatum(
      label: monthTick(month.month),
      income: toCents(month.income).toDouble(),
      expense: toCents(month.expense).toDouble(),
      balance: toCents(month.balance).toDouble(),
    ),
];

/// 趋势图底部的刻度只写月份。年份写在区块副标题里（「2025年10月 – 2026年9月」）：
/// 12 个刻度在 360dp 的屏上各占约 30dp，塞不下「2026年9月」这七个字。
String monthTick(String month) => '${int.parse(month.substring(5))}月';

List<ChartDatum> dailyData(List<DailyPoint> points) => [
  for (final point in points)
    ChartDatum(
      label: formatDayLabel(point.date),
      value: toCents(point.expense).toDouble(),
      caption: formatYuan(point.expense),
      id: null,
    ),
];

/// 区间内支出最高的那一天。这张图的用途就是「发现异常尖峰」（§4.2.6），
/// 把尖峰直接写成一句话，比让用户在 30 根柱子里自己找要省事。全是 0 时回 null。
ChartDatum? dailyPeak(List<DailyPoint> points) {
  DailyPoint? peak;
  for (final point in points) {
    if (peak == null || toCents(point.expense) > toCents(peak.expense)) {
      peak = point;
    }
  }
  if (peak == null || toCents(peak.expense) == 0) {
    return null;
  }
  return ChartDatum(
    label: '${peak.date.month}月${peak.date.day}日',
    value: toCents(peak.expense).toDouble(),
    caption: formatYuan(peak.expense),
  );
}

List<MemberDatum> memberData(List<MemberSlice> members) => [
  for (final member in members)
    MemberDatum(
      label: member.nickname,
      userId: member.userId,
      total: toCents(member.total).toDouble(),
      bars: [
        for (final item in member.byCategory)
          ChartDatum(
            value: toCents(item.amount).toDouble(),
            id: item.categoryId,
          ),
      ],
    ),
];

/// 「按大类」视图的图例文字。**直接按下标取 categoryBreakdown 的名字，不做 id 匹配**：
/// byCategory 与 categoryBreakdown 逐项对齐是后端 B9 钉住的契约，按下标取正是这条契约的用法。
/// 自己再匹配一次 id，等于假定契约不成立——那它成立时多花一遍工夫，不成立时两边一起错。
List<String> memberBarLabels(List<CategorySlice> breakdown) => [
  for (final slice in breakdown) slice.name,
];

/// 坐标轴上限：向上取到 1 / 2 / 5 × 10ⁿ。
///
/// 直接拿最大值当上限，最高那根柱子的圆角会被边框裁掉一半；取到「好看的数」还顺带让刻度是整数。
/// `maxValue <= 0` 时回 1：区间内一笔支出都没有，而 fl_chart 的 maxY 不能等于 minY。
double axisMax(double maxValue) {
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

/// 左侧刻度的步长。取跨度的四分之一再向上取整到「好看的数」，于是刻度值总是整元，
/// 不会在轴上写出 "1234.56" 这种数字。
double axisInterval(double minY, double maxY) {
  final span = maxY - minY;
  return span <= 0 ? 1 : axisMax(span / 4);
}

/// 刻度文字。入参是**分**。
///
/// 万元以上写「1.2万」：手机给左侧刻度留不出六七个字符的宽度。负数只有结余那一档会出现，
/// 符号单独处理——Dart 的 `%` 对正除数恒回非负值，`-13 % 10` 是 7，直接拼会写出「-1.7万」。
String axisLabel(double cents) {
  final whole = cents.round();
  final sign = whole < 0 ? '-' : '';
  final absolute = whole.abs();
  if (absolute >= 1000000) {
    final tenths = (absolute / 100000).round();
    return '$sign${tenths ~/ 10}.${tenths % 10}万';
  }
  return absolute % 100 == 0
      ? '$sign${absolute ~/ 100}'
      : '$sign${fromCents(absolute)}';
}

/// 每日支出图一根柱子占的横向空间（逻辑像素）。366 天的区间因此是 5856 像素宽，
/// 一屏放不下，横向滚动看（§4.2.6）。
const double dailyBarWidth = 16.0;

/// 每日支出图的内容宽度。柱子铺不满一屏时占满一屏，免得三五天的区间里柱子被拉成门板。
double dailyChartWidth(int days, double viewport) =>
    math.max(days * dailyBarWidth, viewport);

/// 每日支出图底部刻度的间隔，直接喂给 `SideTitles.interval`。
///
/// 按**像素**算而不是按「一屏放得下几个标签」算：这张图是横向滚动的，标签铺在整个内容宽度上。
/// 一根柱子 16 像素，「9日」这样的标签约 22 像素宽，每 5 天标一个就是 80 像素的间距，
/// 既不互相压住，也不会滚两屏才看见一个数字。天数不超过 5 时天天标。
int dailyLabelInterval(int days) => days <= 5 ? 1 : 5;

/// 成员对比图的内容宽度，外面套横向滚动（与每日支出图同一套做法）。
/// 「按大类」视图下一个成员最多 9 根柱子（Top 8 + 其他），5 个成员就是 45 根，一屏放不下。
double memberChartWidth(int memberCount, int barsPerMember) =>
    math.max(memberCount * barsPerMember * 48.0, 320.0);
