import 'package:freezed_annotation/freezed_annotation.dart';

part 'recurring_execution.freezed.dart';
part 'recurring_execution.g.dart';

/// 一条周期记账的执行记录，对应后端的 RecurringExecutionResponse。
///
/// `transactionId` 指向那次真正生成的流水，点进去就是那条。`backfilled` 是后端算好的
/// 「这次是不是补记的」（`createdAt` 的日期晚于 `bizDate` 即为补记），前端不要拿两个日期自己减——
/// 补记的判定口径只该有一处定义。
@freezed
abstract class RecurringExecution with _$RecurringExecution {
  const factory RecurringExecution({
    required int id,
    required DateTime bizDate,
    required int transactionId,
    required DateTime executedDate,
    required bool backfilled,
  }) = _RecurringExecution;

  factory RecurringExecution.fromJson(Map<String, dynamic> json) =>
      _$RecurringExecutionFromJson(json);
}
