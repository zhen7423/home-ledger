import '../../data/models/period_value.dart';

/// 把 `periodType` + `periodValue` 翻成一句中文。
///
/// 单独一个文件是因为列表、详情、编辑三处都要用，而口径必须一致——三处各写一个 switch，
/// 迟早会出现「列表说每月 31 日、详情说每月月末」。
///
/// 文案里**不解释短月钳制**：「每月 31 日」在 2 月实际落在 28 日，那是引擎的行为，
/// 写进标签会变成一行没人看得懂的说明。用户第一次在 2 月看到 28 日的流水时会自己明白。
String periodCopy(String periodType, PeriodValue value) => switch (periodType) {
  'DAILY' => '每 ${value.intervalDays ?? 1} 天',
  'WEEKLY' =>
    '每周${[for (final d in _sorted(value.weekdays)) _weekdayName(d)].join('、')}',
  'MONTHLY' => '每月 ${_dayList(value.daysOfMonth)}',
  'YEARLY' => '每年 ${value.month ?? 1} 月 ${_dayList(value.daysOfMonth)}',
  // 后端只认这四种；走到这里说明服务端比这份 App 新，宁可显示得难看也不能崩在列表里
  _ => '暂不支持的周期类型',
};

/// 一二三四五六日。后端存的是 ISO 序号（周一 = 1，周日 = 7），与 Java 的 `DayOfWeek.value` 一致。
const List<String> _weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];

String _weekdayName(int isoDay) =>
    (isoDay >= 1 && isoDay <= 7) ? _weekdayNames[isoDay - 1] : '$isoDay';

String _dayList(List<int>? days) => '${_sorted(days).join('、')} 日';

/// 后端不重排用户传上来的数组，而「每月 31、5 日」读着像出了 bug。
List<int> _sorted(List<int>? values) => [...?values]..sort();
