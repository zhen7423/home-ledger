import '../../../data/models/baby_formula_bag.dart';

/// 宝宝模块的中文词表与两句「怎么念这份数据」，模板是 `ui/features/cat/cat_copy.dart`：
/// 码值在模型里是 `String` 而不是 enum，翻译只发生在这一个文件里。
///
/// 与后端 `common/BabyDisclaimers.java` 的 `STANDARD` 逐字一致（§4.4.3）：曲线页读响应里
/// 的那一份，疫苗清单页读这一份（那条端点不下发它）。改一处必须改两处——两页的小字讲的是
/// 同一件事，分写迟早有一段措辞先改。
const String babyDataDisclaimer =
    '本曲线的生长标准数据转录自《7 岁以下儿童生长标准》WS/T 423—2022 附录 A，'
    '疫苗免疫程序转录自《国家免疫规划疫苗儿童免疫程序及说明（2026 年版）》，'
    '仅供参考，不作为医学诊断依据。';

/// 里程碑内置常用项（§4.4.5）。库里只有 `title` 一个文本列，自定义项与内置项在数据上
/// 没有区别，这张表只是给输入框一排候选 chips。
const List<String> milestonePresets = <String>[
  '第一次抬头',
  '第一次翻身',
  '第一次独坐',
  '第一次爬',
  '第一次扶站',
  '第一次独走',
  '第一次叫爸爸妈妈',
  '第一颗牙',
  '断奶',
  '会说短句',
];

/// 疫苗五态的界面文案，键与后端 `common/BabyVaccineDisplay` 的枚举名一一对应（§4.4.4）。
/// 用 map 而不是 switch：服务端哪天加第六态，取不到就显示它自己，界面该少一种颜色而不是崩。
const Map<String, String> vaccineDisplayLabels = <String, String>{
  'VACCINATED': '已接种',
  'MARKED': '已跳过 / 不适用',
  'OVERDUE': '逾期',
  'DUE_SOON': '即将接种',
  'UPCOMING': '待接种',
};

/// 宝宝性别的界面标签（§4.4.1：男 / 女两选一，百分位曲线依赖性别）。说「男宝 / 女宝」
/// 而不是「男 / 女」：这一栏在档案列表与总览卡片上都是给别人看的名片，不是数据字段。
const Map<String, String> genderLabels = <String, String>{
  'MALE': '男宝',
  'FEMALE': '女宝',
};

/// 剂次。字典里的 `dose_no` 是官方表序号的原样字符串（`1`–`5`），而手建的自费项可以写
/// 「加强针」（§4.4.4 的剂次那一行允许自定义），所以补「第 / 剂」之前先判一下是不是数字，
/// 否则会念成「第 加强针 剂」。
String doseLabel(String doseNo) =>
    int.tryParse(doseNo) == null ? doseNo : '第 $doseNo 剂';

/// 待办行右侧那句。「逾期 N 天 / 今天到期 / 还有 N 天」三选一（§4.4.6：两列互斥且总有一列非空，
/// 所以不需要「两个都拿不到」的分支，`?? 0` 落到「今天到期」正是它的原意）。
///
/// 入参是那两个可空天数而不是某个类型：总览的待办卡与统计页的两张小列表吃的是同名的
/// `daysToDue` / `overdueDays`，吃类型的写法会让后一处为同一句文案再抄一遍三态判断。
/// 与 `cat_copy.dart` 的 `dueLabel` 逐字同形，但**不跨模块引用猫那份**：猫模块被摘掉时
/// 宝宝模块不该跟着编译不过。
///
/// **用 `daysToDue <= 0` 判红是错的**，那会把「今天到期」染成逾期（§4.4.4 的逾期判定是
/// 「今天 > 应种日期」，不含等于），染不染红写成 `overdueDays != null` 那一句就够。
String vaccineDueLabel({required int? daysToDue, required int? overdueDays}) {
  if (overdueDays != null) return '逾期 $overdueDays 天';
  final days = daysToDue ?? 0;
  return days == 0 ? '今天到期' : '还有 $days 天';
}

/// 五个可选指标的界面文案，键与 `baby_curve_view_model.dart` 的 `growthMetrics` 一一对应。
/// **`WEIGHT_LENGTH` 不在其中**（§1.4 第 23 条）：它是服务端按年龄选的那张表（2 岁以下用身长），
/// 不是用户能选的指标。
const Map<String, String> growthMetricLabels = <String, String>{
  'HEIGHT': '身高',
  'WEIGHT': '体重',
  'WEIGHT_HEIGHT': '体重别身高',
  'BMI': 'BMI',
  'HEAD_CIRCUMFERENCE': '头围',
};

/// 曲线页副标题上那句口径说明，键是响应里的 `standardMetric`（§1.4 第 14 条）。
/// **这是 `standardMetric` 存在的唯一理由**：用户选的是「体重别身高」，而实际用的是哪张表
/// 取决于年龄，不说清就没法解释横轴为什么是身长而不是身高。
const Map<String, String> standardMetricNotes = <String, String>{
  'WEIGHT_LENGTH': '2 岁以下按身长',
  'WEIGHT_HEIGHT': '2 岁以上按身高',
};

/// 增减量。服务端下发的是带符号的十进制字符串（`BigDecimal` 相减，§4.4.2 的 `deltaFromPrevious`
/// 与统计里的三段增量都是），正数在这里补「+」——「1.2」在界面上读不出是涨了还是少了。
///
/// **零不补符号**（「0.00」原样显示）：`0` 与 `null` 在两个模型里是两件事（§4.4.2：
/// 「较上次没量身高」与「较上次身高没变」），后者由调用方整段不显示，前者该显示成「0」而不是「+0」。
String signedDelta(String value) {
  final number = num.tryParse(value);
  return number == null || number <= 0 ? value : '+$value';
}

/// 克数。`int` 直接带单位，不加小数点：全项目的克数都是整数（§7.2）。
String formulaGramsText(int grams) => '$grams g';

/// 一罐奶粉下面那句「800 g 装 · 喝了 20 天 · 日均 53 g」。
///
/// 与猫粮列表那一句逐字同形，但**不跨模块引用猫的那一份**（§4.5.3）：猫模块被摘掉时
/// 宝宝模块不该跟着编译不过——同一条理由见上面 {@code vaccineDueLabel}。
/// 当前罐那两个派生字段本就是 null（§4.5.3），显示「—」而不是 0。
String formulaBagSummaryLine(BabyFormulaBag bag) =>
    '${formulaGramsText(bag.packGrams)} 装'
    '${bag.usageDays == null ? '' : ' · 喝了 ${bag.usageDays} 天'}'
    ' · 日均 ${bag.dailyAverage == null ? '—' : formulaGramsText(bag.dailyAverage!)}';
