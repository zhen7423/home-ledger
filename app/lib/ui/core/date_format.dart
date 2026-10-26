// 后端回的是不带时区标记的本地时间串，DateTime.parse 解出来即本地时间，直接渲染。

String formatDateTime(DateTime value) =>
    '${value.year}-${_pad(value.month)}-${_pad(value.day)} ${_pad(value.hour)}:${_pad(value.minute)}';

String formatDate(DateTime value) =>
    '${value.year}-${_pad(value.month)}-${_pad(value.day)}';

/// 分组头的月份标签。入参是后端 `DATE_FORMAT(biz_date, '%Y-%m')` 出来的 "2026-09"，
/// 月份去掉前导零：界面上写「2026年9月」，不是「2026年09月」。
String formatMonthLabel(String month) {
  final parts = month.split('-');
  return '${parts.first}年${int.parse(parts.last)}月';
}

/// 开罐日期 + 具体时刻的组合展示（2026-10-26 需求①）。`time` 为 null 时只给日期；
/// 非空时取 "HH:mm"（服务端回 "08:30" 或 "08:30:45"，前 5 位都是我们想要的）。
String formatDateWithTime(DateTime date, String? time) {
  if (time == null || time.isEmpty) return formatDate(date);
  return '${formatDate(date)} ${time.length >= 5 ? time.substring(0, 5) : time}';
}

/// 列表行内的日期。分组头已经把年月写过了，这里只补日。
String formatDayLabel(DateTime value) => '${value.day}日';

/// 最近动态那一列的时间（§4.6 第 6 条）：「刚刚 / 12 分钟前 / 3 小时前 / 2 天前」，
/// 超过一周就直接给日期。
///
/// 相对时间是**现算**的，服务端不下发「3 分钟前」这种字符串——那种字符串离开服务器就开始过期，
/// 而界面并不会因为一条列表没刷新就把它改成正确的说法。
String formatRelativeTime(DateTime value, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(value);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return formatDate(value);
}

/// `DateTime(2026, 9, 1)` → `"2026-09"`。与后端 `DATE_FORMAT(biz_date, '%Y-%m')` 同口径。
/// 离线重算月度小计（F4）与按月分缓存文件（F4）都要它，写一处。
String monthKey(DateTime date) => '${date.year}-${_pad(date.month)}';

String _pad(int value) => value.toString().padLeft(2, '0');
