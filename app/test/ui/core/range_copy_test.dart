import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/ui/core/range_copy.dart';

void main() {
  test('五个区间一格一个说法，统计页与导出页共用这一份', () {
    // 两处各写一个 switch，迟早出现「统计页写去年、导出页写上年」。
    expect(StatisticsRange.values.map(rangeLabel), [
      '本月',
      '上月',
      '本年',
      '去年',
      '自定义',
    ]);
  });
}
