import 'package:freezed_annotation/freezed_annotation.dart';

part 'cat_food_estimate.freezed.dart';
part 'cat_food_estimate.g.dart';

/// 当前袋的余量推算，对应后端的 CatFoodEstimateResponse（§4.3.4 卡片那五行）。
///
/// **九个字段全部非空**：推不出的信号是整个 estimate 为 null，不是其中某一栏为 null。
/// `depletionDate` 恒等于「今天 + `daysLeft`」，所以它永远有个日期可画，哪怕那条进度条已经触底。
///
/// `dailyAverage` 是**当前袋推算的输入**（由已完成袋折算，或退到用户手填的预估），与统计页那个
/// 「区间总克数 ÷ 区间天数」的日均不是一个数，同一只猫两个值可以差很远（§4.3.4 与 §4.3.5 各说一件事）。
@freezed
abstract class CatFoodEstimate with _$CatFoodEstimate {
  const factory CatFoodEstimate({
    required int usedDays,
    required int dailyAverage,
    required int consumedGrams,
    required int remainingGrams,
    required int remainingPercent,
    required int daysLeft,
    required DateTime depletionDate,
    required bool fromHistory,
    required bool overEstimate,
  }) = _CatFoodEstimate;

  factory CatFoodEstimate.fromJson(Map<String, dynamic> json) =>
      _$CatFoodEstimateFromJson(json);
}
