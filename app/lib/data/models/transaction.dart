import 'package:freezed_annotation/freezed_annotation.dart';

import 'flow_type.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

/// 一条收支流水，对应后端的 TransactionResponse。
///
/// 几处刻意的取舍：
/// - 类别名、支付方式名、记录人昵称都是**记账那一刻存下的快照**，字典改名或成员退出不回溯
///   历史记录（需求文档 A3）。所以本类不需要再去查字典就能显示全名。
/// - `amount` 是字符串。后端 BigDecimal 以 JSON 字符串收发，前端一路按字符串走，要比较或求和
///   时才经 `ui/core/money.dart` 转成「分」，全程不落 `double`。
/// - `bizDate` 后端是 `DATE`，解出来是本日零点；`createdAt` / `updatedAt` 是不带时区标记的
///   本地时间串。前端一律不做时区换算（§6.1.2 第六条）。
///   也正因如此，`toJson()` 不能直接当创建/改动的请求体用——它会把日期写成带时刻的 ISO 串，
///   而后端那两处要的是 `yyyy-MM-dd`。请求体在 `TransactionRepository` 里逐字段拼。
/// - `ruleId` 非空说明这笔是周期规则自动生成的（S4），界面上据此打「自动」标记。
///   「只看自动记账」的筛选走查询参数 `source`，不靠前端把整页 records 遍历一遍。
@freezed
abstract class Transaction with _$Transaction {
  const Transaction._();

  const factory Transaction({
    required int id,
    required String type,
    required String amount,
    required int categoryId,
    required String categoryName,
    int? subCategoryId,
    String? subCategoryName,
    required int accountId,
    required String accountName,
    required DateTime bizDate,
    String? remark,
    required int createdBy,
    required String recorderName,
    int? ruleId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  bool get isExpense => type == FlowType.expense;
}
