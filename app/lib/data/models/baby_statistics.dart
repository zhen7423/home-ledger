import 'package:freezed_annotation/freezed_annotation.dart';

part 'baby_statistics.freezed.dart';
part 'baby_statistics.g.dart';

/// 体格成长统计，对应后端的 `BabyGrowthStatisticsResponse`（§4.4.6 第一条端点）。
///
/// 不含生长曲线：曲线那条响应要带该性别该指标的标准表全量行，并进这里会让 §5.4 的离线快照
/// 为一条曲线背一整张表。统计页要画曲线读的是同一条 `GET /baby-growths/curve`。
///
/// `perBaby` 含归档的宝宝（历史统计照旧算它），故它比档案选择器长。
@freezed
abstract class BabyGrowthStatistics with _$BabyGrowthStatistics {
  const factory BabyGrowthStatistics({
    @Default(<BabyGrowthItem>[]) List<BabyGrowthItem> perBaby,
  }) = _BabyGrowthStatistics;

  factory BabyGrowthStatistics.fromJson(Map<String, dynamic> json) =>
      _$BabyGrowthStatisticsFromJson(json);
}

/// 一个宝宝的体格块。`latest` 为空表示这个宝宝还没有任何一条身高体重记录，
/// 「当前体格」整张卡都没有内容可显示。
@freezed
abstract class BabyGrowthItem with _$BabyGrowthItem {
  const factory BabyGrowthItem({
    required int babyId,
    required String name,
    required String ageText,
    BabyGrowthLatest? latest,
    required BabyGrowthWindows growth,
  }) = _BabyGrowthItem;

  factory BabyGrowthItem.fromJson(Map<String, dynamic> json) =>
      _$BabyGrowthItemFromJson(json);
}

/// 最新一天的代表行 + 五个指标各自的所处档位。
///
/// `weightHeight` 那一档按 `measureDate` 的月龄选表而不是按今天：一条 20 个月时补录的记录，
/// 该用的是当时那张身长表（§4.4.3）。
@freezed
abstract class BabyGrowthLatest with _$BabyGrowthLatest {
  const factory BabyGrowthLatest({
    required DateTime measureDate,
    String? heightCm,
    String? weightKg,
    String? headCm,
    required BabyPercentileBands bands,
  }) = _BabyGrowthLatest;

  factory BabyGrowthLatest.fromJson(Map<String, dynamic> json) =>
      _$BabyGrowthLatestFromJson(json);
}

/// 五个指标各自落在哪一档（§1.4 第 9 条）。某一档为空有两种原因：这一条没量那个量、
/// 或超出标准表覆盖范围（§4.4.3 不许就近取端点值）。界面两种都出「—」——用户能做的事一样。
@freezed
abstract class BabyPercentileBands with _$BabyPercentileBands {
  const factory BabyPercentileBands({
    String? height,
    String? weight,
    String? weightHeight,
    String? bmi,
    String? headCircumference,
  }) = _BabyPercentileBands;

  factory BabyPercentileBands.fromJson(Map<String, dynamic> json) =>
      _$BabyPercentileBandsFromJson(json);
}

/// 三档增量。`sinceLast` 为空的唯一条件是这一条就是首条；后两条另有「窗口内不足两条代表行」
/// 这个条件——两者都不能拿区间外的记录顶上（§4.4.2）。
@freezed
abstract class BabyGrowthWindows with _$BabyGrowthWindows {
  const factory BabyGrowthWindows({
    BabyGrowthGain? sinceLast,
    BabyGrowthGain? last3Months,
    BabyGrowthGain? last12Months,
  }) = _BabyGrowthWindows;

  factory BabyGrowthWindows.fromJson(Map<String, dynamic> json) =>
      _$BabyGrowthWindowsFromJson(json);
}

/// 一段窗口的增量。三个数值各自可空：这一次或那一次没量那一项——「没量」与「没变」是两件事。
@freezed
abstract class BabyGrowthGain with _$BabyGrowthGain {
  const factory BabyGrowthGain({
    required int days,
    String? heightCm,
    String? weightKg,
    String? headCm,
  }) = _BabyGrowthGain;

  factory BabyGrowthGain.fromJson(Map<String, dynamic> json) =>
      _$BabyGrowthGainFromJson(json);
}

/// 疫苗接种统计，对应后端的 `BabyVaccineStatisticsResponse`（§4.4.6 第二条端点）。
///
/// `perBaby` **只含在册的宝宝**，与猫咪统计的完成度/倒计时同一条口径：待办类统计不该给一个
/// 已归档的宝宝留着永远做不完的逾期格。`milestoneTimeline` 相反是历史，归档宝宝的里程碑照旧在；
/// 它是顶层、跨宝宝的一份，所以每一条都带宝宝名，否则两个宝宝混在一起只能靠猜。
@freezed
abstract class BabyVaccineStatistics with _$BabyVaccineStatistics {
  const factory BabyVaccineStatistics({
    @Default(<BabyVaccineItem>[]) List<BabyVaccineItem> perBaby,
    @Default(<BabyMilestoneItem>[]) List<BabyMilestoneItem> milestoneTimeline,
  }) = _BabyVaccineStatistics;

  factory BabyVaccineStatistics.fromJson(Map<String, dynamic> json) =>
      _$BabyVaccineStatisticsFromJson(json);
}

/// 一个宝宝的完成率、四态计数与三张列表。
@freezed
abstract class BabyVaccineItem with _$BabyVaccineItem {
  const factory BabyVaccineItem({
    required int babyId,
    required String name,
    required int completionRate,
    required BabyVaccineCounts statusCounts,
    @Default(<BabyVaccinePlanItem>[]) List<BabyVaccinePlanItem> upcoming,
    @Default(<BabyVaccinePlanItem>[]) List<BabyVaccinePlanItem> overdueList,
    @Default(<BabyVaccineRecordItem>[])
    List<BabyVaccineRecordItem> recordTimeline,
  }) = _BabyVaccineItem;

  factory BabyVaccineItem.fromJson(Map<String, dynamic> json) =>
      _$BabyVaccineItemFromJson(json);
}

/// 四分段的四个数。已标记（`SKIPPED` / `NA`）的行不进这四个：它们是「本来就不该做」的，
/// 混进任一段都会让那一段的含义变味，所以四个数之和可以小于应种总数（§4.4.6）。
@freezed
abstract class BabyVaccineCounts with _$BabyVaccineCounts {
  const factory BabyVaccineCounts({
    required int vaccinated,
    required int upcoming,
    required int dueSoon,
    required int overdue,
  }) = _BabyVaccineCounts;

  factory BabyVaccineCounts.fromJson(Map<String, dynamic> json) =>
      _$BabyVaccineCountsFromJson(json);
}

/// 待办清单里的一行。两列互斥且总有一列为空：未到期的只有 `daysToDue`（当天是 0），
/// 逾期的只有 `overdueDays`。两列都空的行不会出现在这两张列表里。
///
/// 这里没有宝宝名：这两张列表挂在一个宝宝下面，「是谁的」由上下文给出。
@freezed
abstract class BabyVaccinePlanItem with _$BabyVaccinePlanItem {
  const factory BabyVaccinePlanItem({
    required int planId,
    required String vaccineName,
    required String doseNo,
    required DateTime dueDate,
    int? daysToDue,
    int? overdueDays,
  }) = _BabyVaccinePlanItem;

  factory BabyVaccinePlanItem.fromJson(Map<String, dynamic> json) =>
      _$BabyVaccinePlanItemFromJson(json);
}

/// 时间轴上一条接种记录（§4.4.6）：疫苗名 + 机构，不给批号与不良反应——那是接种记录页的事。
@freezed
abstract class BabyVaccineRecordItem with _$BabyVaccineRecordItem {
  const factory BabyVaccineRecordItem({
    required String vaccineName,
    required DateTime givenDate,
    String? clinic,
  }) = _BabyVaccineRecordItem;

  factory BabyVaccineRecordItem.fromJson(Map<String, dynamic> json) =>
      _$BabyVaccineRecordItemFromJson(json);
}

/// 时间轴上一条里程碑。不给 id：时间轴只读，没有任何操作要指向某一行。
@freezed
abstract class BabyMilestoneItem with _$BabyMilestoneItem {
  const factory BabyMilestoneItem({
    required int babyId,
    required String babyName,
    required DateTime occurDate,
    required String title,
    String? description,
  }) = _BabyMilestoneItem;

  factory BabyMilestoneItem.fromJson(Map<String, dynamic> json) =>
      _$BabyMilestoneItemFromJson(json);
}
