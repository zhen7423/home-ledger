import '../../../data/models/cat.dart';
import '../../../data/models/cat_food_bag.dart';
import '../../core/date_format.dart';

/// 猫模块的中文词表与几句「怎么念这行数据」。模板是 `ui/core/period_copy.dart`：
/// 码值在模型里是 `String` 而不是 enum，全项目没有枚举转换器，翻译只发生在这一个文件里。
///
/// 每个 switch 的默认分支回原码而不是回「未知」：`UNKNOWN` 本身是 `gender` / `neutered`
/// 的合法码值，兜底文案与它是两回事，一个没预料到的码显示成它自己才会在测试里露出来。
String genderLabel(String code) => switch (code) {
  'MALE' => '公',
  'FEMALE' => '母',
  'UNKNOWN' => '未知',
  _ => code,
};

String neuteredLabel(String code) => switch (code) {
  'YES' => '已绝育',
  'NO' => '未绝育',
  'UNKNOWN' => '未知',
  _ => code,
};

/// 驱虫类型。码值是 `INTERNAL` / `EXTERNAL`，服务端枚举自带中文，但那是排序与提醒用的口径，不跨端传。
String dewormingLabel(String code) => switch (code) {
  'INTERNAL' => '内驱',
  'EXTERNAL' => '外驱',
  _ => code,
};

/// 生日。三态：**未填 / 估算 / 精确**，全链路可空，依据是 §4.3.1 生日那一行。
/// 估算态必须带「约」字且不显示日——那一栏存的是该月 1 日，是个占位不是事实。
String birthdayLabel(Cat cat) {
  final birthday = cat.birthday;
  if (birthday == null) return '生日未知';
  return cat.birthdayEstimated
      ? '约 ${birthday.year} 年 ${birthday.month} 月'
      : formatDate(birthday);
}

/// 卡片与列表行下面那一句。缺的段根本不进列表：一只没填体重、也没填品种的小猫
/// 要显示「公」而不是「公 · · ·」。
String catSummaryLine(Cat cat) => [
  genderLabel(cat.gender),
  if (cat.breed != null) cat.breed!,
  if (cat.weightKg != null) '${cat.weightKg} kg',
].join(' · ');

/// 克数。`int` 直接带单位，不加小数点：全项目的克数都是整数（§7.2），
/// 补成 `1450.0` 会被读成一个还没算完的中间值。
String gramsText(int grams) => '$grams g';

/// 一袋猫粮下面那句「2000 g 装 · 用了 40 天 · 日均 50 g」。
///
/// 猫粮袋那一屏与统计页的「每袋用时」渲染的是同一条 [CatFoodBag] 的三个派生字段，
/// 句式和「取不到时显示 `—`」的规矩必须逐字一致——两处各写一遍，迟早一处写「日均 —」、
/// 一处写「— 日均」。当前袋那两个派生字段本就是 null（§4.3.2）。
String bagSummaryLine(CatFoodBag bag) =>
    '${gramsText(bag.packGrams)} 装'
    '${bag.usageDays == null ? '' : ' · 用了 ${bag.usageDays} 天'}'
    ' · 日均 ${bag.dailyAverage == null ? '—' : gramsText(bag.dailyAverage!)}';

/// 到期倒计时那一格的空态句。总览页与统计页各画各的形状（前者在一个 `Padding` 里、
/// 后者在一张空态卡里），形状不同所以不抽 Widget；但这一句必须逐字相同，
/// 两处各写一遍的话，迟早有一处先把它缩短成「暂无」。
const String catCountdownEmptyHint =
    '还没有驱虫记录。记一次内驱或外驱，这里就开始倒计时。';

/// 倒计时右侧那句。「逾期 N 天 / 今天到期 / 还有 N 天」三选一。
///
/// 两列互斥且必有一个非空（§4.3.3：`next_date` 非空），所以这里不需要「两个都拿不到」的分支；
/// `?? 0` 只是把可空天数拆回 `int`，`0` 落到「今天到期」正是它的原意。
///
/// **入参是那两个可空天数，不是某个类型**：倒计时的条目与驱虫记录行都带同名的
/// `daysToDue` / `overdueDays`，吃类型的写法会让驱虫列表页为同一句文案再抄一遍三态判断。
/// **用 `daysToDue <= 0` 判红是错的**，那会把「今天到期」染成逾期（§4.3.3 的逾期判定是
/// 「今天 > 下次日期」，不含等于），染不染红写成 `overdueDays != null` 那一句就够。
String dueLabel({required int? daysToDue, required int? overdueDays}) {
  if (overdueDays != null) return '逾期 $overdueDays 天';
  final days = daysToDue ?? 0;
  return days == 0 ? '今天到期' : '还有 $days 天';
}
