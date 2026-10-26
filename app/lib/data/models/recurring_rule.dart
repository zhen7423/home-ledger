import 'package:freezed_annotation/freezed_annotation.dart';

import 'period_value.dart';

part 'recurring_rule.freezed.dart';
part 'recurring_rule.g.dart';

/// 一条周期记账规则，对应后端的 RecurringRuleResponse。
///
/// categoryName / accountName 是**实时解析**的当前名，不是快照——规则是「将来要记什么」的配置，
/// 类别改了名规则该跟着显示新名，这与 Transaction 上的快照字段语义相反，别照抄错了。
/// 实时解析之所以安全，是因为后端保证了被未删规则引用的类别与支付方式删不掉（需求文档 §4.2.3）。
@freezed
abstract class RecurringRule with _$RecurringRule {
  const factory RecurringRule({
    required int id,
    required String name,
    required String type,
    required String amount,
    required int categoryId,
    required String categoryName,
    int? subCategoryId,
    String? subCategoryName,
    required int accountId,
    required String accountName,
    required String periodType,
    required PeriodValue periodValue,
    required DateTime startDate,
    DateTime? endDate,
    required bool enabled,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _RecurringRule;

  factory RecurringRule.fromJson(Map<String, dynamic> json) =>
      _$RecurringRuleFromJson(json);
}
