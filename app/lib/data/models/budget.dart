import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

/// 一条预算，对应后端的 BudgetResponse。
///
/// `scope` 是 FAMILY / CATEGORY / MEMBER 三个字符串之一，不生成 Dart 枚举：后端回的是名字，
/// 前端只拿它做分支，而枚举默认按序号序列化，要按名字还得额外配 `@JsonKey`。
///
/// **`id` 每次保存都会变**——`PUT /budgets` 是整体替换，实现上是先物理删光再重插（需求文档 §4.2.4）。
/// 所以不能拿它当跨请求稳定的标识，也没有「按 id 改一条」的接口，改任何一条都要整份提交。
@freezed
abstract class Budget with _$Budget {
  const factory Budget({
    required int id,
    required String scope,
    int? categoryId,
    String? categoryName,
    int? memberUserId,
    String? memberName,
    required String amount,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);
}
