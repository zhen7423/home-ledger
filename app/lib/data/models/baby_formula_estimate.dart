import 'package:freezed_annotation/freezed_annotation.dart';

part 'baby_formula_estimate.freezed.dart';
part 'baby_formula_estimate.g.dart';

/// 当前罐的余量推算，对应后端的 BabyFormulaEstimateResponse（§4.5.3 奶粉卡那五行）。
///
/// **九个字段全部非空**：推不出的信号是整个 estimate 为 null，不是其中某一栏为 null。
/// `depletionDate` 恒等于「今天 + `daysLeft`」，所以它永远有个日期可画，哪怕那条进度条已经触底。
/// `dailyAverage` 与统计页那个「区间总克数 ÷ 区间天数」的日均不是一个数，两个值可以差很远。
@freezed
abstract class BabyFormulaEstimate with _$BabyFormulaEstimate {
  const factory BabyFormulaEstimate({
    required int usedDays,
    required int dailyAverage,
    required int consumedGrams,
    required int remainingGrams,
    required int remainingPercent,
    required int daysLeft,
    required DateTime depletionDate,
    required bool fromHistory,
    required bool overEstimate,
  }) = _BabyFormulaEstimate;

  factory BabyFormulaEstimate.fromJson(Map<String, dynamic> json) =>
      _$BabyFormulaEstimateFromJson(json);
}