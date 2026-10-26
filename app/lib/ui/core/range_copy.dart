import '../../data/models/finance_statistics.dart';

/// 时间范围那五格的中文标签。统计页与导出页是同一套控件（§4.2.6、§4.2.7），
/// 两处各写一个 switch，迟早会出现「统计页写去年、导出页写上年」这种对不上的标签。
String rangeLabel(StatisticsRange range) => switch (range) {
  StatisticsRange.thisMonth => '本月',
  StatisticsRange.lastMonth => '上月',
  StatisticsRange.thisYear => '本年',
  StatisticsRange.lastYear => '去年',
  StatisticsRange.custom => '自定义',
};
