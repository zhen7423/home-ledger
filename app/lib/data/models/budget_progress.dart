import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_progress.freezed.dart';
part 'budget_progress.g.dart';

/// 某个维度的预算进度，对应后端的 BudgetProgressResponse。`month` 形如 "2026-09"。
///
/// 上色与文案一律看 `level`，不要拿 `usedPercent` 自己比阈值：`usedPercent` 是向下取整的显示值
/// （79.6% 显示 79），而档位是服务端用未取整的比值判的，恰好花完额度是 100% 且 `level` 为
/// `EXCEEDED` 而不是 `WARNING`（需求文档 §4.2.4）。两处各判一次，迟早给出「进度条说超支、
/// 提醒说即将超支」这种自相矛盾的界面。
///
/// `remaining` 超支时是负数，直接显示绝对值配「已超支」的措辞，不要再减一次。
@freezed
abstract class BudgetProgress with _$BudgetProgress {
  const factory BudgetProgress({
    required String month,
    required String scope,
    int? categoryId,
    String? categoryName,
    int? memberUserId,
    String? memberName,
    required String amount,
    required String used,
    required String remaining,
    required int usedPercent,
    required String level,
    required int remainingDays,
  }) = _BudgetProgress;

  factory BudgetProgress.fromJson(Map<String, dynamic> json) =>
      _$BudgetProgressFromJson(json);
}
