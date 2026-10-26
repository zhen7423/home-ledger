import 'package:freezed_annotation/freezed_annotation.dart';

part 'cat_deworming.freezed.dart';
part 'cat_deworming.g.dart';

/// 一条驱虫记录，对应后端的 CatDewormingResponse（§4.3.3 列表的一行）。
///
/// `daysToDue` 与 `overdueDays` 是两个互斥的字段而不是一个带符号的数：界面对「还有 N 天」和
/// 「逾期 N 天」是两套颜色，用符号判断会把 0（今天该驱）染成红色。两者不会同时为 null，
/// 因为 `nextDate` 非空——用户没填时服务端按周期算出来（`medicine` 必填、`dosage` 选填）。
///
/// `catName` 是实时反查而不是落库快照，与流水的名称快照刻意相反：档案名要跟着改名走。
@freezed
abstract class CatDeworming with _$CatDeworming {
  const factory CatDeworming({
    required int id,
    required int catId,
    required String catName,
    required String type,
    required DateTime doneDate,
    required String medicine,
    String? dosage,
    required DateTime nextDate,
    int? daysToDue,
    int? overdueDays,
    String? remark,
  }) = _CatDeworming;

  factory CatDeworming.fromJson(Map<String, dynamic> json) =>
      _$CatDewormingFromJson(json);
}
