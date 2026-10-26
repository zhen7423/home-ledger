import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_summary.freezed.dart';
part 'transaction_summary.g.dart';

/// 区间概览，对应后端的 TransactionSummaryResponse（§4.2.6 概览卡片、§8）。
///
/// startDate / endDate 是**解析之后**的区间而不是回显入参：两个日期都不传时后端给的是
/// 「家里第一笔流水的日期 → 今天」。导出页要靠它把「共 N 笔」与将要生成的那份文件对上，
/// 所以这两个字段非空——别照 TransactionPageQuery 的样子写成可空。
///
/// `days` 为 0 只出现在一笔流水都没有的时候，此时 dailyAverageExpense 恒为 "0.00"。
/// 界面上「日均支出」那一格在 days == 0 时显示 "—" 而不是 ¥0.00：零笔流水谈日均没有意义，
/// 写「¥0.00」会被读成「这段时间真的一分没花」。
@freezed
abstract class TransactionSummary with _$TransactionSummary {
  const factory TransactionSummary({
    required DateTime startDate,
    required DateTime endDate,
    required int days,
    required String income,
    required String expense,
    required String balance,
    required String dailyAverageExpense,
    required int count,
  }) = _TransactionSummary;

  factory TransactionSummary.fromJson(Map<String, dynamic> json) =>
      _$TransactionSummaryFromJson(json);
}
