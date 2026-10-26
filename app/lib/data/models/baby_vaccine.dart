import 'package:freezed_annotation/freezed_annotation.dart';

part 'baby_vaccine.freezed.dart';
part 'baby_vaccine.g.dart';

/// 应种清单的一行，对应后端的 `BabyVaccinePlanResponse`（§4.4.4）。
///
/// `status` 是落库四态（`PENDING` / `DONE` / `SKIPPED` / `NA`），`displayStatus` 是展示态
/// （待接种 / 即将接种 / 逾期）。两个都给：界面按 `displayStatus` 上色，而「标记跳过 / 撤销」
/// 要判的是落库态——从展示态反推落库态会在「即将接种」与「逾期」之间出错。
///
/// `manual` 决定这一行能不能删（字典生成的行只能跳过或不适用）。`recordId` 非空时界面据它
/// 去接种记录里取回该行的实际接种日期。
///
/// 日期有三层（2026-10-26 需求②）：`dueDate` 是程序表推导的原定应种日；`plannedDate` 是用户
/// 设定的计划接种日期（可空，null = 未改期）；`effectiveDate` = plannedDate ?? dueDate，服务端
/// 算好——界面的日期展示与排序一律取它，客户端不自己再写一遍 COALESCE。
@freezed
abstract class BabyVaccinePlan with _$BabyVaccinePlan {
  const factory BabyVaccinePlan({
    required int id,
    required int babyId,
    required String vaccineName,
    required String doseNo,
    required DateTime dueDate,
    DateTime? plannedDate,
    required DateTime effectiveDate,
    required String status,
    String? skipReason,
    int? recordId,
    required bool manual,
    required String displayStatus,
  }) = _BabyVaccinePlan;

  factory BabyVaccinePlan.fromJson(Map<String, dynamic> json) =>
      _$BabyVaccinePlanFromJson(json);
}

/// 一条接种记录，对应后端的 `BabyVaccineRecordResponse`（§4.4.4）。
///
/// `planId` 为空是正常状态：自费疫苗的首次录入、名称写法不同的补种都没有对应行可回写。
/// `nextDate` 为空同样是正常状态——该疫苗在本宝宝清单里没有未完成剂次。
@freezed
abstract class BabyVaccineRecord with _$BabyVaccineRecord {
  const factory BabyVaccineRecord({
    required int id,
    required int babyId,
    int? planId,
    required String vaccineName,
    required String doseNo,
    required DateTime givenDate,
    String? clinic,
    String? batchNo,
    String? reaction,
    DateTime? nextDate,
    String? remark,
  }) = _BabyVaccineRecord;

  factory BabyVaccineRecord.fromJson(Map<String, dynamic> json) =>
      _$BabyVaccineRecordFromJson(json);
}
