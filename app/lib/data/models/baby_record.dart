import 'package:freezed_annotation/freezed_annotation.dart';

part 'baby_record.freezed.dart';
part 'baby_record.g.dart';

/// 一条里程碑，对应后端的 `BabyMilestoneResponse`（§4.4.5）。
///
/// 带 `babyId`：列表的 `babyId` 缺省时按顶层数组跨宝宝返回，界面得靠它标出这一条是谁的。
/// 内置常用项与自由输入落同一列 `title`，库里没有区别——界面只负责给出常用项建议。
@freezed
abstract class BabyMilestone with _$BabyMilestone {
  const factory BabyMilestone({
    required int id,
    required int babyId,
    required DateTime occurDate,
    required String title,
    String? description,
  }) = _BabyMilestone;

  factory BabyMilestone.fromJson(Map<String, dynamic> json) =>
      _$BabyMilestoneFromJson(json);
}

/// 一条就诊记录，对应后端的 `BabyMedicalResponse`（§4.4.5）。
///
/// `costAmount` 是金额，按字符串下发（§1.4 第 15 条）：与流水同一套理由，走 JSON 数字会在前端
/// 被转成二进制浮点。这一列纯记录、不同步生成流水，所以它不带任何财务语义。
@freezed
abstract class BabyMedical with _$BabyMedical {
  const factory BabyMedical({
    required int id,
    required int babyId,
    required DateTime visitDate,
    String? hospital,
    String? department,
    String? diagnosis,
    String? medicine,
    String? costAmount,
    String? remark,
  }) = _BabyMedical;

  factory BabyMedical.fromJson(Map<String, dynamic> json) =>
      _$BabyMedicalFromJson(json);
}
