import 'package:homeledger/data/models/flow_type.dart';
import 'package:homeledger/data/models/month_summary.dart';
import 'package:homeledger/data/models/transaction.dart';
import 'package:homeledger/data/models/transaction_page.dart';
import 'package:homeledger/data/repositories/transaction_repository.dart';

/// 流水与分页的样例。列表 ViewModel 测试与记账页测试都要造这些，放一处。
///
/// 字段全是必填的，所以默认值只给「一笔最普通的支出」，要别的形态在调用处覆盖。
Transaction tx({
  required int id,
  required DateTime bizDate,
  String type = FlowType.expense,
  String amount = '10.00',
  int categoryId = 1,
  int accountId = 1,
  int? subCategoryId,
  String? remark,
  int? ruleId,
  int createdBy = 1,
}) => Transaction(
  id: id,
  type: type,
  amount: amount,
  categoryId: categoryId,
  categoryName: '餐饮',
  subCategoryId: subCategoryId,
  subCategoryName: subCategoryId == null ? null : '外卖',
  accountId: accountId,
  accountName: '微信',
  bizDate: bizDate,
  remark: remark,
  createdBy: createdBy,
  recorderName: '小明',
  ruleId: ruleId,
  createdAt: bizDate,
  updatedAt: bizDate,
);

MonthSummary monthSummary(String month, {required int count}) => MonthSummary(
  month: month,
  income: '0.00',
  expense: '10.00',
  balance: '-10.00',
  count: count,
);

TransactionPage transactionPage({
  required int page,
  required int pages,
  required List<Transaction> records,
  List<MonthSummary> summaries = const [],
}) => TransactionPage(
  records: records,
  total: records.length,
  page: page,
  size: 30,
  pages: pages,
  monthSummaries: summaries,
);

/// 在线拿到的一页。离线那一路要 `fromCache: true` 与 `savedAt`，在调用处覆盖。
TransactionPageResult pageResult(
  TransactionPage page, {
  bool fromCache = false,
  DateTime? savedAt,
}) => TransactionPageResult(page, fromCache: fromCache, savedAt: savedAt);
