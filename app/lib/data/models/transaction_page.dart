import 'package:freezed_annotation/freezed_annotation.dart';

import 'month_summary.dart';
import 'transaction.dart';

part 'transaction_page.freezed.dart';
part 'transaction_page.g.dart';

/// 流水分页响应，对应后端的 TransactionPageResponse。
///
/// `monthSummaries` 装的是**同一套筛选条件下全部结果**的月度小计，不是本页 `records`
/// 加起来的数——一页 30 条跨了两个月时，客户端手上只有半个月的流水，整月合计无从算起，
/// 所以后端连着分页一起给（需求文档 §8）。
@freezed
abstract class TransactionPage with _$TransactionPage {
  const factory TransactionPage({
    required List<Transaction> records,
    required int total,
    required int page,
    required int size,
    required int pages,
    required List<MonthSummary> monthSummaries,
  }) = _TransactionPage;

  factory TransactionPage.fromJson(Map<String, dynamic> json) =>
      _$TransactionPageFromJson(json);
}

/// 列表请求的查询条件，字段与后端 TransactionQueryRequest 逐字对应，空着的条件不放进去。
///
/// 日期在这里就是 `"2026-09-01"` 这样的字符串而不是 `DateTime`：查询串由 dio 用 `toString()`
/// 拼，塞一个 `DateTime` 会带出时刻后缀，后端那三个 `LocalDate` 参数解不开。格式化由调用方负责。
///
/// `source` 只有 `AUTO` / `MANUAL` 两个取值，传别的后端报 400 而不是当成「没筛」。
@freezed
abstract class TransactionPageQuery with _$TransactionPageQuery {
  const TransactionPageQuery._();

  const factory TransactionPageQuery({
    String? startDate,
    String? endDate,
    String? type,
    int? categoryId,
    int? subCategoryId,
    int? accountId,
    int? createdBy,
    String? keyword,
    String? amount,
    String? source,
    @Default(1) int page,
    @Default(30) int size,
  }) = _TransactionPageQuery;

  Map<String, dynamic> toQuery() => {
    'startDate': startDate,
    'endDate': endDate,
    'type': type,
    'categoryId': categoryId,
    'subCategoryId': subCategoryId,
    'accountId': accountId,
    'createdBy': createdBy,
    'keyword': keyword,
    'amount': amount,
    'source': source,
    'page': page,
    'size': size,
  };

  /// 只有「什么都不筛」的那次查询才写缓存（§5.4 写缓存策略）。
  /// page 与 size 刻意不算筛选条件：翻页写的是同一个月的更多行，正是要合并进去的。
  bool get isUnfiltered =>
      startDate == null &&
      endDate == null &&
      type == null &&
      categoryId == null &&
      subCategoryId == null &&
      accountId == null &&
      createdBy == null &&
      keyword == null &&
      amount == null &&
      source == null;
}
