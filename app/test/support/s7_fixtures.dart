import 'package:homeledger/data/models/baby.dart';
import 'package:homeledger/data/models/baby_growth.dart';
import 'package:homeledger/data/models/baby_record.dart';
import 'package:homeledger/data/models/baby_statistics.dart';
import 'package:homeledger/data/models/baby_vaccine.dart';

/// S7 的样例数据。宝宝这五个模型的字段大半是必填的，手搓一份能用的响应要三四十行，
/// 这里给一套默认值齐全的帮手，要别的形态在调用处覆盖（形状照 s6_fixtures.dart）。
///
/// 默认那一套的内部是自洽的：一个 12 个月的宝宝，挂一条身高体重、一条应种项、一条接种记录、
/// 一条里程碑与一次就诊，`growthStatisticsFixture()` 与 `vaccineStatisticsFixture()` 断的是同一批数。
/// 各用例要的是「这一屏画了什么」，拿默认那份搭出来再改一两处最小。

/// 一个在册的宝宝。`ageText` 由服务端下发（§1.4 第 8 条），样例里写死一个与 [birthDate] 对得上的：
/// 前端一个字节都不许自己算月龄，测试里也就不必验它算得对不对，只需验它被原样显示。
Baby babyFixture({
  int id = 1,
  String name = '小明',
  String gender = 'MALE',
  DateTime? birthDate,
  String? birthHeight = '50.0',
  String? birthWeight = '3.35',
  String? remark,
  bool archived = false,
  String ageText = '1 岁 0 个月',
}) => Baby(
  id: id,
  name: name,
  gender: gender,
  birthDate: birthDate ?? DateTime(2025, 9, 16),
  birthHeight: birthHeight,
  birthWeight: birthWeight,
  remark: remark,
  archived: archived,
  ageText: ageText,
);

/// 一条身高体重记录。默认带全三项度量与一段「较上次」，把三项都留着是要覆盖界面上
/// 「身高 / 体重 / 头围」三格同时在的最常见那一支；只量其中一项的形态在调用处给。
/// `percentiles` 照「百分之多少」的默认值。
BabyGrowth growthFixture({
  int id = 100,
  int babyId = 1,
  DateTime? measureDate,
  String? heightCm = '76.5',
  String? weightKg = '9.80',
  String? headCm = '46.0',
  String? remark,
  BabyGrowthDelta? delta = const BabyGrowthDelta(
    days: 30,
    heightCm: '1.5',
    weightKg: '0.40',
    headCm: '0.5',
  ),
  BabyPercentiles? percentiles,
}) => BabyGrowth(
  id: id,
  babyId: babyId,
  measureDate: measureDate ?? DateTime(2026, 9, 10),
  heightCm: heightCm,
  weightKg: weightKg,
  headCm: headCm,
  remark: remark,
  deltaFromPrevious: delta,
  percentiles:
      percentiles ??
      const BabyPercentiles(
        height: '40.5%',
        weight: '25.0%',
        headCircumference: '75.0%',
      ),
);

/// 出生那一档标准行，横轴 0 个月。七个数照着《7 岁以下儿童生长标准》男童身长表的量级写，
/// 测试不比大小，只要 `p3 < p50 < p97` 这条形状成立——百分位带是按档位画的。
GrowthStandardRow standardRowFixture({
  double xValue = 0,
  double p3 = 46.3,
  double p10 = 47.9,
  double p25 = 49.1,
  double p50 = 50.4,
  double p75 = 51.7,
  double p90 = 52.9,
  double p97 = 54.5,
}) => GrowthStandardRow(
  xValue: xValue,
  p3: p3,
  p10: p10,
  p25: p25,
  p50: p50,
  p75: p75,
  p90: p90,
  p97: p97,
);

/// 曲线上的一个实测点。默认落在 P50–P75 那一档（§4.4.3 的档位判定只在服务端）。
BabyCurvePoint curvePointFixture({
  DateTime? measureDate,
  int ageMonths = 12,
  double xValue = 12,
  double measured = 76.5,
  String? percentileBand = 'P50–P75',
}) => BabyCurvePoint(
  measureDate: measureDate ?? DateTime(2026, 9, 10),
  ageMonths: ageMonths,
  xValue: xValue,
  measured: measured,
  percentileBand: percentileBand,
);

/// 一份曲线响应。默认四行标准行 + 两个实测点：标准行少于两行画不出带，
/// 实测点少于两个画不出折线，四条与两个是两条边界之上、够画出全部图层的最小份数。
BabyCurve curveFixture({
  int babyId = 1,
  String metric = 'HEIGHT',
  String standardMetric = 'HEIGHT',
  List<BabyCurvePoint>? points,
  List<GrowthStandardRow>? standard,
  String? disclaimer,
}) => BabyCurve(
  babyId: babyId,
  metric: metric,
  standardMetric: standardMetric,
  points:
      points ??
      [
        curvePointFixture(
          measureDate: DateTime(2026, 3, 10),
          ageMonths: 6,
          xValue: 6,
          measured: 68.4,
          percentileBand: 'P25–P50',
        ),
        curvePointFixture(),
      ],
  standard:
      standard ??
      [
        standardRowFixture(xValue: 0),
        standardRowFixture(xValue: 6, p3: 63.6, p50: 68.4, p97: 73.4),
        standardRowFixture(xValue: 12, p3: 71.0, p50: 76.5, p97: 82.3),
        standardRowFixture(xValue: 18, p3: 76.9, p50: 82.7, p97: 88.9),
      ],
  disclaimer:
      disclaimer ??
      '本曲线的生长标准数据转录自《7 岁以下儿童生长标准》WS/T 423—2022 附录 A，'
          '疫苗免疫程序转录自《国家免疫规划疫苗儿童免疫程序及说明（2026 年版）》，'
          '仅供参考，不作为医学诊断依据。',
);

/// 应种清单的一行。默认是字典生成、还没到日子的那一行（`manual: false`、`PENDING` / `UPCOMING`）：
/// 两个态都要给，因为「能不能删」「要不要上色」分别看这两个字段而它们不是一回事（§4.4.4）。
/// plannedDate 默认 null（未改期），effectiveDate 缺省跟 dueDate 同一天——改期用例显式传两者。
BabyVaccinePlan planFixture({
  int id = 200,
  int babyId = 1,
  String vaccineName = '乙肝疫苗',
  String doseNo = '1',
  DateTime? dueDate,
  DateTime? plannedDate,
  DateTime? effectiveDate,
  String status = 'PENDING',
  String? skipReason,
  int? recordId,
  bool manual = false,
  String displayStatus = 'UPCOMING',
}) => BabyVaccinePlan(
  id: id,
  babyId: babyId,
  vaccineName: vaccineName,
  doseNo: doseNo,
  dueDate: dueDate ?? DateTime(2026, 9, 20),
  plannedDate: plannedDate,
  effectiveDate: effectiveDate ?? plannedDate ?? dueDate ?? DateTime(2026, 9, 20),
  status: status,
  skipReason: skipReason,
  recordId: recordId,
  manual: manual,
  displayStatus: displayStatus,
);

/// 一条接种记录。默认回写在第 200 号应种项上（`planId` 非空），`nextDate` 为空表示
/// 该疫苗在本宝宝清单里没有未完成剂次——这是一个正常状态，不是缺数据。
BabyVaccineRecord vaccineRecordFixture({
  int id = 300,
  int babyId = 1,
  int? planId = 200,
  String vaccineName = '乙肝疫苗',
  String doseNo = '1',
  DateTime? givenDate,
  String? clinic = '社区卫生服务中心',
  String? batchNo,
  String? reaction,
  DateTime? nextDate,
  String? remark,
}) => BabyVaccineRecord(
  id: id,
  babyId: babyId,
  planId: planId,
  vaccineName: vaccineName,
  doseNo: doseNo,
  givenDate: givenDate ?? DateTime(2025, 9, 16),
  clinic: clinic,
  batchNo: batchNo,
  reaction: reaction,
  nextDate: nextDate,
  remark: remark,
);

/// 一条里程碑。默认用内置常用项里的一个，测试要验「内置与自由输入落同一列」时
/// 在调用处换成别的 `title`——数据上两者没有区别（§4.4.5）。
BabyMilestone milestoneFixture({
  int id = 400,
  int babyId = 1,
  DateTime? occurDate,
  String title = '第一次抬头',
  String? description,
}) => BabyMilestone(
  id: id,
  babyId: babyId,
  occurDate: occurDate ?? DateTime(2026, 1, 8),
  title: title,
  description: description,
);

/// 一次就诊。默认除宝宝与就诊日期外全填，`costAmount` 是字符串（§1.4 第 15 条）。
BabyMedical medicalFixture({
  int id = 500,
  int babyId = 1,
  DateTime? visitDate,
  String? hospital = '市妇幼保健院',
  String? department = '儿内科',
  String? diagnosis = '上呼吸道感染',
  String? medicine = '小儿氨酚黄那敏颗粒',
  String? costAmount = '128.50',
  String? remark,
}) => BabyMedical(
  id: id,
  babyId: babyId,
  visitDate: visitDate ?? DateTime(2026, 8, 3),
  hospital: hospital,
  department: department,
  diagnosis: diagnosis,
  medicine: medicine,
  costAmount: costAmount,
  remark: remark,
);

/// 五档百分位带。默认五项都有值，要「超出标准表覆盖范围」那一支的在调用处传 `null`。
BabyPercentileBands bandsFixture({
  String? height = 'P50–P75',
  String? weight = 'P25–P50',
  String? weightHeight = 'P50–P75',
  String? bmi = 'P25–P50',
  String? headCircumference = 'P50–P75',
}) => BabyPercentileBands(
  height: height,
  weight: weight,
  weightHeight: weightHeight,
  bmi: bmi,
  headCircumference: headCircumference,
);

/// 最新一天的体格。默认三项度量都量了。
BabyGrowthLatest latestFixture({
  DateTime? measureDate,
  String? heightCm = '76.5',
  String? weightKg = '9.80',
  String? headCm = '46.0',
  BabyPercentileBands? bands,
}) => BabyGrowthLatest(
  measureDate: measureDate ?? DateTime(2026, 9, 10),
  heightCm: heightCm,
  weightKg: weightKg,
  headCm: headCm,
  bands: bands ?? bandsFixture(),
);

/// 一段窗口的增量。默认 `days` 齐、三项数值齐。
BabyGrowthGain gainFixture({
  int days = 30,
  String? heightCm = '1.5',
  String? weightKg = '0.40',
  String? headCm = '0.5',
}) => BabyGrowthGain(
  days: days,
  heightCm: heightCm,
  weightKg: weightKg,
  headCm: headCm,
);

/// 三档增量。默认只给第一档：后两档为空是「窗口内不足两条代表行」，界面整行不显示（§4.4.2）。
/// 三条都要验的用例在调用处把三档都填上。
BabyGrowthWindows windowsFixture({
  BabyGrowthGain? sinceLast = const BabyGrowthGain(
    days: 30,
    heightCm: '1.5',
    weightKg: '0.40',
    headCm: '0.5',
  ),
  BabyGrowthGain? last3Months,
  BabyGrowthGain? last12Months,
}) => BabyGrowthWindows(
  sinceLast: sinceLast,
  last3Months: last3Months,
  last12Months: last12Months,
);

/// 「没写这个参数」的标记。参数默认值必须是编译期常量，而默认那一份要 new 出来，
/// 所以拿它把省略与显式传 `null` 分开：`latest: null` 得能表示「这个宝宝还没量过」。
const Object _unset = Object();

/// 一个宝宝的体格块。`latest` 可空：还没有任何一条记录时「当前体格」整张卡没有内容可显示。
BabyGrowthItem growthItemFixture({
  int babyId = 1,
  String name = '小明',
  String ageText = '1 岁 0 个月',
  Object? latest = _unset,
  BabyGrowthWindows? growth,
}) => BabyGrowthItem(
  babyId: babyId,
  name: name,
  ageText: ageText,
  latest: identical(latest, _unset)
      ? latestFixture()
      : latest as BabyGrowthLatest?,
  growth: growth ?? windowsFixture(),
);

/// 体格统计那一份。默认一个宝宝。
BabyGrowthStatistics growthStatisticsFixture({List<BabyGrowthItem>? perBaby}) =>
    BabyGrowthStatistics(perBaby: perBaby ?? [growthItemFixture()]);

/// 四态计数。四个数之和 6 小于默认那个宝宝的应种总数：已标记的行不进这四个（§4.4.6）。
BabyVaccineCounts countsFixture({
  int vaccinated = 2,
  int upcoming = 3,
  int dueSoon = 2,
  int overdue = 1,
}) => BabyVaccineCounts(
  vaccinated: vaccinated,
  upcoming: upcoming,
  dueSoon: dueSoon,
  overdue: overdue,
);

/// 待办清单里的一行。两列互斥且总有一列非空，默认走「还有 3 天」那一支。
BabyVaccinePlanItem planItemFixture({
  int planId = 201,
  String vaccineName = '百白破疫苗',
  String doseNo = '2',
  DateTime? dueDate,
  int? daysToDue = 3,
  int? overdueDays,
}) => BabyVaccinePlanItem(
  planId: planId,
  vaccineName: vaccineName,
  doseNo: doseNo,
  dueDate: dueDate ?? DateTime(2026, 9, 23),
  daysToDue: daysToDue,
  overdueDays: overdueDays,
);

/// 时间轴上一条接种记录。只有疫苗名与机构，没有批号与不良反应（§4.4.6）。
BabyVaccineRecordItem recordItemFixture({
  String vaccineName = '乙肝疫苗',
  DateTime? givenDate,
  String? clinic = '社区卫生服务中心',
}) => BabyVaccineRecordItem(
  vaccineName: vaccineName,
  givenDate: givenDate ?? DateTime(2025, 9, 16),
  clinic: clinic,
);

/// 时间轴上一条里程碑。带宝宝名：它是顶层跨宝宝的一份，不给名字就只能靠猜（§4.4.6）。
BabyMilestoneItem milestoneItemFixture({
  int babyId = 1,
  String babyName = '小明',
  DateTime? occurDate,
  String title = '第一次抬头',
  String? description,
}) => BabyMilestoneItem(
  babyId: babyId,
  babyName: babyName,
  occurDate: occurDate ?? DateTime(2026, 1, 8),
  title: title,
  description: description,
);

/// 一个宝宝的疫苗块。默认完成率 67%（2 已接种 ÷ 3 已到期），三张列表各一两条。
BabyVaccineItem vaccineItemFixture({
  int babyId = 1,
  String name = '小明',
  int completionRate = 67,
  BabyVaccineCounts? statusCounts,
  List<BabyVaccinePlanItem>? upcoming,
  List<BabyVaccinePlanItem>? overdueList,
  List<BabyVaccineRecordItem>? recordTimeline,
}) => BabyVaccineItem(
  babyId: babyId,
  name: name,
  completionRate: completionRate,
  statusCounts: statusCounts ?? countsFixture(),
  upcoming: upcoming ?? [planItemFixture()],
  overdueList:
      overdueList ??
      [
        planItemFixture(
          planId: 202,
          vaccineName: '脊灰疫苗',
          doseNo: '3',
          dueDate: DateTime(2026, 9, 1),
          daysToDue: null,
          overdueDays: 15,
        ),
      ],
  recordTimeline: recordTimeline ?? [recordItemFixture()],
);

/// 疫苗统计那一份。默认一个宝宝 + 两条里程碑，`milestoneTimeline` 跨宝宝所以第二条是别人的。
BabyVaccineStatistics vaccineStatisticsFixture({
  List<BabyVaccineItem>? perBaby,
  List<BabyMilestoneItem>? milestoneTimeline,
}) => BabyVaccineStatistics(
  perBaby: perBaby ?? [vaccineItemFixture()],
  milestoneTimeline:
      milestoneTimeline ??
      [
        milestoneItemFixture(),
        milestoneItemFixture(
          babyId: 2,
          babyName: '小红',
          occurDate: DateTime(2026, 5, 20),
          title: '第一颗牙',
        ),
      ],
);

/// 单槽快照的信封（§5.4）。默认三段齐全、`savedAt` 固定，好让横幅上那句「截至」断言得出。
BabyOverview overviewFixture({
  DateTime? savedAt,
  List<Baby>? babies,
  BabyGrowthStatistics? latestGrowth,
  BabyVaccineStatistics? vaccineTodo,
}) => BabyOverview(
  savedAt: savedAt ?? DateTime(2026, 9, 14, 8, 0),
  babies: babies ?? [babyFixture()],
  latestGrowth: latestGrowth ?? growthStatisticsFixture(),
  vaccineTodo: vaccineTodo ?? vaccineStatisticsFixture(),
);
