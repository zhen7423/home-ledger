import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/cat_statistics.dart';
import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/ui/features/cat/view_models/cat_statistics_view_model.dart';

/// 区间 chips → 查询串这一层纯函数。页面的区间切换与 VM 的加载都不在这里验，
/// 验的是那两条日期：给错一天，服务端那个「总克数 ÷ 天数」的日均就跟着错一天，而屏上两个数都还在。
void main() {
  final midMonth = DateTime(2026, 9, 15, 10, 30);

  CatFoodStatisticsQuery? queryOf(
    StatisticsRange range, {
    DateTime? start,
    DateTime? end,
  }) => catFoodQueryFor(
    CatStatisticsState(
      range: range,
      customStart: start,
      customEnd: end,
    ),
    now: midMonth,
  );

  test('本月给本月一日到今天，不给月末', () {
    // 给成月末等于把还没过去的十六天算进分母，日均会被摊薄。
    final query = queryOf(StatisticsRange.thisMonth);
    expect(query?.startDate, '2026-09-01');
    expect(query?.endDate, '2026-09-15');
  });

  test('上月给上月的一日到月末', () {
    // 月末这里**该**给：那 31 天全都过去了。
    final query = queryOf(StatisticsRange.lastMonth);
    expect(query?.startDate, '2026-08-01');
    expect(query?.endDate, '2026-08-31');
  });

  test('本年给到今天', () {
    final query = queryOf(StatisticsRange.thisYear);
    expect(query?.startDate, '2026-01-01');
    expect(query?.endDate, '2026-09-15');
  });

  test('去年给到去年年末', () {
    final query = queryOf(StatisticsRange.lastYear);
    expect(query?.startDate, '2025-01-01');
    expect(query?.endDate, '2025-12-31');
  });

  test('自定义只挑了一头时不发请求', () {
    expect(
      queryOf(StatisticsRange.custom, start: DateTime(2026, 7, 1)),
      isNull,
    );
    expect(
      queryOf(StatisticsRange.custom, end: DateTime(2026, 7, 1)),
      isNull,
    );
  });

  test('自定义两头反了也不发', () {
    // 服务端 `DateRanges.assertRange` 会回 400，但那是兜底：界面上那两个日期是分别挑的，
    // 挑反了就该原地不动，而不是去触发一次后端校验、再在屏上落一句错误文案。
    expect(
      queryOf(
        StatisticsRange.custom,
        start: DateTime(2026, 8, 20),
        end: DateTime(2026, 8, 10),
      ),
      isNull,
    );
  });

  test('带时分秒的今天被折回日期本身', () {
    // `midMonth` 是 10:30，日期串里不该出现时刻。
    final query = catFoodQueryFor(
      const CatStatisticsState(),
      now: DateTime(2026, 9, 15, 23, 59),
    );
    expect(query?.endDate, '2026-09-15');
  });

  test('查询串里只有两个日期，没有记录人', () {
    // 不复用财务那份 `StatisticsQuery` 的理由就在这里：猫粮消耗是家庭整体口径，
    // 多一个 `createdBy` 服务端不收。
    expect(
      catFoodQueryFor(const CatStatisticsState(), now: midMonth)!.toQuery().keys,
      unorderedEquals(['startDate', 'endDate']),
    );
  });
}
