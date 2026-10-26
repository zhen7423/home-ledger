import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/ui/features/baby/paid_vaccine_presets.dart';

/// 常用自费疫苗预置（第 30 轮）。数据是产品内容，测试的责任是把它钉成「不会再被顺手改坏」：
/// 剂次必须升序、名称必须落在后端 `vaccine_name ≤ 30` 的上限内、日期计算与免疫规划字典
/// 同口径（出生日期 + N 个日历月）。
void main() {
  test('预置至少一个，剂次升序且不重复', () {
    expect(paidVaccinePresets, isNotEmpty);

    for (final preset in paidVaccinePresets) {
      expect(preset.doses, isNotEmpty, reason: '${preset.name} 至少一剂');
      final months = [for (final dose in preset.doses) dose.ageMonths];
      expect(
        months,
        [...months]..sort(),
        reason: '${preset.name} 的剂次应按月龄递增，乱序会让界面上的建议日期倒着排',
      );
      expect(
        months.toSet().length,
        months.length,
        reason: '${preset.name} 不允许两个剂次同月龄（同月龄就是同一天，等于重复键）',
      );
    }
  });

  test('名称与剂次都在后端列宽内：疫苗名称 ≤ 30、剂次 ≤ 8', () {
    for (final preset in paidVaccinePresets) {
      expect(preset.name.length, lessThanOrEqualTo(30));
      for (final dose in preset.doses) {
        expect(dose.doseNo.length, lessThanOrEqualTo(8));
      }
    }
  });

  test('预置名两两不重复', () {
    // 弹层的选中态与「已在清单」判定都按名字取第一个命中（paidVaccinePresetByName 同口径），
    // 重名会让两枚 chip 同时高亮、点第二个渲染第一个的剂次，且不会有任何测试红。
    final names = paidVaccinePresets.map((p) => p.name).toList();
    expect(names.toSet().length, names.length);
  });

  test('五联疫苗：2、3、4、18 月龄共 4 剂，且带重叠提示', () {
    final preset = paidVaccinePresetByName('五联疫苗');
    expect(preset, isNotNull);
    expect([for (final dose in preset!.doses) dose.ageMonths], [2, 3, 4, 18]);
    expect(preset.note, isNotNull);
    expect(preset.note, contains('跳过'));
  });

  test('应种日期 = 出生日期 + N 个日历月，跨年正确、月底按后端口径钳制', () {
    final birth = DateTime(2025, 9, 16);
    expect(paidVaccineDueDate(birth, 2), DateTime(2025, 11, 16));
    expect(paidVaccineDueDate(birth, 4), DateTime(2026, 1, 16));
    expect(paidVaccineDueDate(birth, 18), DateTime(2027, 3, 16));

    // 1 月 31 日出生 + 1 个月：后端 `LocalDate.plusMonths` 钳到 2 月最后一天（2026 非闰 → 28）。
    // 不能用 DateTime 原生溢出（它会落到 3 月 3 日）——这条钉的就是两处口径一致。
    expect(paidVaccineDueDate(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
  });

  test('按名字取预置：取得到就返回，取不到回 null', () {
    expect(paidVaccinePresetByName('五联疫苗')?.doses, hasLength(4));
    expect(paidVaccinePresetByName('不存在的疫苗'), isNull);
  });
}
