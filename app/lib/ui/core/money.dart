// 金额换算全部集中在这里，**全程不把金额交给 `double`**。
// `(12.30 * 100).round()` 在个别值上会差一分，而那一分正是钱；后端 BigDecimal 以 JSON
// 字符串收发，前端就按字符串切分，只在做比较和求和时转成「分」这个整数单位（需求文档 §4.2.1）。
library;

import 'package:intl/intl.dart';

/// 允许负号：结余（收入减支出）本来就是负的，界面上要原样显示出来。
/// 小数位最多两位是后端 `DECIMAL(12,2)` 的口径，超出来的输入在这里就拦下。
final RegExp _yuanPattern = RegExp(r'^(-?)(\d+)(?:\.(\d{1,2}))?$');

/// 界面语言写死中文，不跟系统区域设置走：千分位分隔符要跟着 App 的语言而不是跟着手机，
/// 否则同一份数据在英文系统的中文界面上会显示成两种样子。
const String _locale = 'zh_CN';

/// 元 → 分。`"12.30"` 得 1230，`"12.3"` 补零得 1230，`"12"` 得 1200。
/// 小数超过两位或压根不是数字时抛 FormatException，由调用方的校验器提前拦掉。
int toCents(String amount) {
  final match = _yuanPattern.firstMatch(amount.trim());
  if (match == null) {
    throw FormatException('不是两位小数以内的金额', amount);
  }
  final cents = int.parse(
    '${match.group(2)}${(match.group(3) ?? '').padRight(2, '0')}',
  );
  return match.group(1) == '-' ? -cents : cents;
}

/// 分 → 元，固定两位小数，与后端的 `DECIMAL(12,2)` 输出一模一样。
String fromCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final absolute = cents.abs();
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  return '$sign${absolute ~/ 100}.$fraction';
}

/// `"1230.50"` → `"¥1,230.50"`。
///
/// 整数部分交给 intl 分组，两位小数仍由 fromCents 决定——补零的规则只写一处。全程没有浮点数。
String formatYuan(String amount) {
  final cents = toCents(amount);
  final sign = cents < 0 ? '-' : '';
  final parts = fromCents(cents.abs()).split('.');
  final grouped = NumberFormat.decimalPattern(
    _locale,
  ).format(int.parse(parts.first));
  return '$sign¥$grouped.${parts.last}';
}
