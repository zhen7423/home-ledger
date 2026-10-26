import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/ui/features/finance/view_models/statistics_series.dart';

import '../../../../support/s5_fixtures.dart';

/// 图表整形。fl_chart 用 CustomPainter 画图，widget 测试断不到图里的内容，
/// 所以「哪几片可见」「坐标轴上限取多少」「刻度隔几个显示一次」全在这里验。
void main() {
  final stats = overview();

  test('饼图那一片的 value 单位是分而不是元', () {
    // 这一条是整个文件最重要的：写成元的话 axisLabel 会把 ¥1234 显示成「12.34」，
    // 而 widget 测试永远看不到那个数字。
    expect(sliceData(stats.categoryBreakdown).first.value, 180000.0);
  });

  test('显示用的是 caption，百分比与类别 id 原样带过去', () {
    final first = sliceData(stats.categoryBreakdown).first;

    expect(first.label, '餐饮');
    expect(first.caption, '¥1,800.00');
    expect(first.percent, 56);
    expect(first.id, 1);
  });

  test('顶层是大类，下钻到餐饮拿到它那两片小类', () {
    expect(visibleSlices(stats, null).map((s) => s.name), ['餐饮', '交通', '其他']);
    expect(visibleSlices(stats, 1).map((s) => s.name), ['早餐', '外卖']);
  });

  test('下钻的目标不在数据里时回落成顶层，而不是给一张空饼图', () {
    // 那种情况只可能是数据在两次渲染之间被换掉了（离线快照刚被拨回另一个区间）。
    expect(visibleSlices(stats, 999).length, 3);
  });

  test('「其他」那一片没有 id，界面据此禁掉它的下钻', () {
    expect(sliceData(stats.categoryBreakdown).last.id, isNull);
  });

  test('支付方式与月度趋势的 value 同样是分，月度刻度只写月份', () {
    expect(accountData(stats.accountBreakdown).first.value, 200000.0);

    final month = monthlyData([
      trend('2026-09', income: '8000.00', expense: '3200.00'),
    ]).single;
    expect(month.label, '9月');
    expect(month.income, 800000.0);
    expect(month.expense, 320000.0);
    expect(month.balance, 480000.0);
  });

  test('月份刻度不带前导零', () {
    expect(monthTick('2026-09'), '9月');
    expect(monthTick('2026-12'), '12月');
  });

  test('每日支出的刻度是「几日」，尖峰带着日期与金额', () {
    expect(dailyData(stats.dailyTrend).first.label, '12日');

    final peak = dailyPeak(stats.dailyTrend)!;
    expect(peak.label, '9月14日');
    expect(peak.caption, '¥320.00');
  });

  test('每天都没有支出时不给尖峰', () {
    expect(
      dailyPeak([
        DailyPoint(date: DateTime(2026, 9, 12), expense: '0.00'),
        DailyPoint(date: DateTime(2026, 9, 13), expense: '0.00'),
      ]),
      isNull,
    );
    expect(dailyPeak(const []), isNull);
  });

  test('成员那组柱子与大类逐项对齐，图例按下标取名字', () {
    final member = memberData(stats.memberComparison).first;

    expect(member.bars.length, stats.categoryBreakdown.length);
    expect(member.bars.first.value, 120000.0);
    expect(member.bars.last.id, isNull);
    expect(memberBarLabels(stats.categoryBreakdown), ['餐饮', '交通', '其他']);
  });

  test('坐标轴上限取到好看的数，刻度步长是跨度的四分之一', () {
    expect(axisMax(0), 1);
    expect(axisMax(1), 1);
    expect(axisMax(1234), 2000);
    expect(axisMax(320), 500);
    expect(axisMax(99999), 100000);

    expect(axisInterval(0, 2000), 500);
    expect(axisInterval(5, 5), 1);
  });

  test('刻度文字：整元不带小数，万元以上写「万」，负结余的符号自己处理', () {
    expect(axisLabel(100000), '1000');
    expect(axisLabel(123456), '1234.56');
    expect(axisLabel(1234567), '1.2万');
    expect(axisLabel(-1700000), '-1.7万');
  });

  test('两张横向滚动的图：内容宽度与刻度间隔', () {
    // 柱子铺不满一屏时占满一屏，免得三五天的区间里柱子被拉成门板。
    expect(dailyChartWidth(3, 360), 360);
    expect(dailyChartWidth(366, 360), 5856);
    expect(dailyLabelInterval(5), 1);
    expect(dailyLabelInterval(6), 5);
    expect(memberChartWidth(2, 3), 320);
    expect(memberChartWidth(5, 9), 2160);
  });
}
