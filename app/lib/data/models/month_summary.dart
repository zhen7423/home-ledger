import 'package:freezed_annotation/freezed_annotation.dart';

part 'month_summary.freezed.dart';
part 'month_summary.g.dart';

/// 后端按月聚合的收支小计，对应 MonthSummary。`month` 形如 "2026-09"。
///
/// 三个金额都是字符串，与 `Transaction.amount` 同一套口径。结余由后端算好交出来，
/// 前端不重算：一旦自己也写一份减法，两份口径就有对不上的一天。
/// 这份小计覆盖的是**整套筛选条件下的全部结果**，不是本页那 30 条的和（需求文档 §8）。
@freezed
abstract class MonthSummary with _$MonthSummary {
  const factory MonthSummary({
    required String month,
    required String income,
    required String expense,
    required String balance,
    required int count,
  }) = _MonthSummary;

  factory MonthSummary.fromJson(Map<String, dynamic> json) =>
      _$MonthSummaryFromJson(json);
}
