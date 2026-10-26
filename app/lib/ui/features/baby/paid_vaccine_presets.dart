/// 常用自费疫苗预置（第 30 轮确认：五联 + 一组常用自费预设，一键生成完整剂次序列）。
///
/// 剂次按「出生月份」表达，与免疫规划程序表同一口径：应种日期 = 出生日期 + N 个日历月。
/// 行里的日期只是「建议」，接种时以接种医生与说明书为准，用户可在自定义模式下改。
///
/// 数据逐条转录自官方文件 / 说明书，不凭记忆生成：
///  - 五联疫苗（DTaP-IPV/Hib）：安顺市卫健局《含 b 型流感嗜血杆菌成分疫苗》科普（2021-11，
///    http://wjj.anshun.gov.cn/wjgz/zsyd/202111/t20211129_71828125.html）：2、3、4 月龄基础各
///    1 剂，18 月龄加强 1 剂；
///  - 13 价肺炎球菌多糖结合疫苗：辉瑞《沛儿13用药指南》说明书的常规程序（2、4、6 月龄基础 +
///    12～15 月龄加强），https://www.pfizermedicalinformation.cn/products/medication-guidelines/prevenar13；
///  - 五价轮状病毒减毒活疫苗：MSD 诊疗手册专业版（2026-05 更新）：共 3 剂，2、4、6 月龄各 1 剂，
///    不应在 8 月龄 0 天之后接种，https://www.msdmanuals.cn/professional/infectious-diseases/immunization/rotavirus-vaccine；
///  - 肠道病毒 71 型灭活疫苗（手足口）：武汉生物制品研究所说明书（2023-08 修订）：基础免疫 2 剂次、
///    间隔 1 个月，对象为 6 月龄至 71 月龄，http://www.wibp.com.cn/detail.php?Id=17874；
///  - 水痘减毒活疫苗：广东疾控《水痘传染性强易感染！你的疫苗打齐了吗？》（2026-06）：
///    第 1 剂 12～24 月龄、第 2 剂 4～6 周岁，两剂间隔 ≥3 个月（≤14 岁），
///    https://cdcp.gd.gov.cn/zzzq/jkts/content/post_4916611.html。
///
/// 刻意不含流感疫苗：流感是「每年接种」的日期型程序，按固定月龄生成一条应种项只会得到
/// 一条跟着年龄永远过期的待办，是误导；需要时走自定义模式逐剂添加。
/// 四联与 Hib 单苗同样不预设：程序与五联高度重叠且各厂家剂次不一（1–4 剂），预设一个固定
/// 剂次序列反而容易记错。
class PaidVaccineDose {
  const PaidVaccineDose({required this.doseNo, required this.ageMonths});

  /// 剂次序号，与 `baby_vaccine_plan.dose_no` 同一形状（'1'…'4'）。
  final String doseNo;

  /// 出生后第几个月接种（0 = 出生当月，与免疫规划字典的 `due_age_months` 同口径）。
  final int ageMonths;
}

class PaidVaccinePreset {
  const PaidVaccinePreset({
    required this.name,
    required this.doses,
    this.note,
  });

  /// 疫苗名称，≤ 30 字符（后端 `vaccine_name` 上限）。存进应种清单的就是它。
  final String name;

  final List<PaidVaccineDose> doses;

  /// 弹层里展示的接种说明：覆盖关系、接种窗口、与免疫规划的重叠提示。
  final String? note;
}

const List<PaidVaccinePreset> paidVaccinePresets = [
  PaidVaccinePreset(
    name: '五联疫苗',
    doses: [
      PaidVaccineDose(doseNo: '1', ageMonths: 2),
      PaidVaccineDose(doseNo: '2', ageMonths: 3),
      PaidVaccineDose(doseNo: '3', ageMonths: 4),
      PaidVaccineDose(doseNo: '4', ageMonths: 18),
    ],
    note: '基础免疫 2、3、4 月龄，18 月龄加强 1 剂。可替代同月龄的脊灰与百白破部分剂次'
        '（含 Hib），请把清单里重叠的剂次标记跳过。',
  ),
  PaidVaccinePreset(
    name: '13价肺炎球菌多糖结合疫苗',
    doses: [
      PaidVaccineDose(doseNo: '1', ageMonths: 2),
      PaidVaccineDose(doseNo: '2', ageMonths: 4),
      PaidVaccineDose(doseNo: '3', ageMonths: 6),
      PaidVaccineDose(doseNo: '4', ageMonths: 12),
    ],
    note: '基础免疫 2、4、6 月龄各 1 剂，12～15 月龄加强 1 剂；此处按 12 月龄生成第 4 剂。',
  ),
  PaidVaccinePreset(
    name: '五价轮状病毒减毒活疫苗',
    doses: [
      PaidVaccineDose(doseNo: '1', ageMonths: 2),
      PaidVaccineDose(doseNo: '2', ageMonths: 4),
      PaidVaccineDose(doseNo: '3', ageMonths: 6),
    ],
    note: '首剂 6～12 周龄起，各剂间隔 4～10 周，全部剂次应在 8 月龄前完成。',
  ),
  PaidVaccinePreset(
    name: '肠道病毒71型灭活疫苗',
    doses: [
      PaidVaccineDose(doseNo: '1', ageMonths: 6),
      PaidVaccineDose(doseNo: '2', ageMonths: 7),
    ],
    note: '6 月龄起接种，共 2 剂、间隔 1 个月，用于预防 EV71 所致手足口病。',
  ),
  PaidVaccinePreset(
    name: '水痘减毒活疫苗',
    doses: [
      PaidVaccineDose(doseNo: '1', ageMonths: 12),
      PaidVaccineDose(doseNo: '2', ageMonths: 48),
    ],
    note: '第 1 剂 12～24 月龄、第 2 剂 4～6 周岁（此处按 12、48 月龄生成），两剂间隔 ≥3 个月。',
  ),
];

/// 应种日期 = 出生日期 + 若干个月（日历月）。
///
/// 月底归一化与后端 `LocalDate.plusMonths` 同一口径：**钳到当月最后一天**而不是溢出到
/// 下个月——`DateTime` 原生构造会把 1 月 31 日 + 1 个月溢出成 3 月 3 日，而服务器给
/// 免疫规划字典算应种日期用的是钳制（1 月 31 日 + 1 个月 = 2 月 28 日）。两个宝宝一条
/// 自费五联一条应种清单，同一天的定义必须只有一处。
DateTime paidVaccineDueDate(DateTime birthDate, int months) {
  final year = birthDate.year + (birthDate.month - 1 + months) ~/ 12;
  final month = (birthDate.month - 1 + months) % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, birthDate.day > lastDay ? lastDay : birthDate.day);
}

/// 取一个预置。找不到回 null——调用方（弹层里已选定的值）不会走到这一支，写在这里只是
/// 让「名称查预置」只有一个入口。
PaidVaccinePreset? paidVaccinePresetByName(String name) {
  for (final preset in paidVaccinePresets) {
    if (preset.name == name) {
      return preset;
    }
  }
  return null;
}