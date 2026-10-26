import 'package:freezed_annotation/freezed_annotation.dart';

part 'baby_formula_statistics.freezed.dart';
part 'baby_formula_statistics.g.dart';

/// 奶粉消耗统计（§4.5.3），对应后端的 BabyFormulaStatisticsResponse。
///
/// `dailyAverage` 是「累计克数 ÷ 累计天数」的区间口径，与 [BabyFormulaEstimate.dailyAverage]
/// （当前罐推算的输入）不是一个数。`monthlyTrend` 恒为最近 6 个自然月、升序、缺月补 0。
@freezed
abstract class BabyFormulaStatistics with _$BabyFormulaStatistics {
  const factory BabyFormulaStatistics({
    required int totalGrams,
    required int totalDays,
    required int dailyAverage,
    @Default(<BabyFormulaMonthGrams>[]) List<BabyFormulaMonthGrams> monthlyTrend,
  }) = _BabyFormulaStatistics;

  factory BabyFormulaStatistics.fromJson(Map<String, dynamic> json) =>
      _$BabyFormulaStatisticsFromJson(json);
}

/// 逐月消耗的一根柱子，`month` 形如 `2026-09`，与财务侧、猫粮侧的月度趋势同形。
@freezed
abstract class BabyFormulaMonthGrams with _$BabyFormulaMonthGrams {
  const factory BabyFormulaMonthGrams({required String month, required int grams}) =
      _BabyFormulaMonthGrams;

  factory BabyFormulaMonthGrams.fromJson(Map<String, dynamic> json) =>
      _$BabyFormulaMonthGramsFromJson(json);
}