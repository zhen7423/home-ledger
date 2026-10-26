import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_value.freezed.dart';
part 'period_value.g.dart';

/// 周期的具体参数，四种 periodType 各用其中一部分字段，其余为 null。
///
/// 不拆成四个子类型：后端存的是一个扁平 JSON 对象（需求文档 §4.2.3），拆开后 fromJson 要自己
/// 写一套按 type 的分派、toJson 还要再写回来，比留着 null 字段麻烦得多。
/// 「哪个字段该有值」由后端判（结构不合法与数值越界是两个错码），前端只按 periodType 显示对应那几个。
@freezed
abstract class PeriodValue with _$PeriodValue {
  const factory PeriodValue({
    int? intervalDays,
    List<int>? weekdays,
    List<int>? daysOfMonth,
    int? month,
  }) = _PeriodValue;

  factory PeriodValue.fromJson(Map<String, dynamic> json) =>
      _$PeriodValueFromJson(json);
}
