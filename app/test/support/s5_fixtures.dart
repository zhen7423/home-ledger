import 'package:homeledger/data/models/category.dart';
import 'package:homeledger/data/models/family.dart';
import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/data/models/flow_type.dart';
import 'package:homeledger/data/models/member.dart';
import 'package:homeledger/data/models/month_summary.dart';
import 'package:homeledger/data/models/transaction_summary.dart';
import 'package:homeledger/ui/core/money.dart';

/// S5 的样例数据。统计那几个模型的字段全是必填的，手搓一份能用的响应要三十行，
/// 这里给一套默认值齐全的帮手，要别的形态在调用处覆盖（形状照 s4_fixtures.dart）。

/// 区间概览。默认那一份与 `overview()` 对得上：支出 3200.00、9 月 1 日到 14 日共 14 天。
TransactionSummary summary({
  int count = 12,
  int days = 14,
  String income = '8000.00',
  String expense = '3200.00',
  String balance = '4800.00',
  String dailyAverageExpense = '228.57',
  DateTime? startDate,
  DateTime? endDate,
}) => TransactionSummary(
  startDate: startDate ?? DateTime(2026, 9, 1),
  endDate: endDate ?? DateTime(2026, 9, 14),
  days: days,
  income: income,
  expense: expense,
  balance: balance,
  dailyAverageExpense: dailyAverageExpense,
  count: count,
);

/// 五图合一。三个大类的支出加起来正好是 `summary()` 那个 3200.00，
/// 最后一片 `categoryId` 为 null，是 Top 8 之外合并出来的「其他」。
FinanceStatistics overview({
  List<CategorySlice> categoryBreakdown = const [
    CategorySlice(
      categoryId: 1,
      name: '餐饮',
      amount: '1800.00',
      percent: 56,
      subCategories: [
        CategorySlice(
          categoryId: 11,
          name: '早餐',
          amount: '600.00',
          percent: 33,
        ),
        CategorySlice(
          categoryId: 12,
          name: '外卖',
          amount: '1200.00',
          percent: 67,
        ),
      ],
    ),
    CategorySlice(categoryId: 2, name: '交通', amount: '1000.00', percent: 31),
    CategorySlice(name: '其他', amount: '400.00', percent: 13),
  ],
  List<MonthSummary> monthlyTrend = const [],
  List<DailyPoint>? dailyTrend,
  List<AccountSlice> accountBreakdown = const [
    AccountSlice(accountId: 1, name: '微信', amount: '2000.00', percent: 63),
    AccountSlice(accountId: 2, name: '支付宝', amount: '1200.00', percent: 37),
  ],
  List<MemberSlice> memberComparison = const [
    MemberSlice(
      userId: 10,
      nickname: '小明',
      total: '2000.00',
      byCategory: [
        CategoryAmount(categoryId: 1, amount: '1200.00'),
        CategoryAmount(categoryId: 2, amount: '600.00'),
        CategoryAmount(amount: '200.00'),
      ],
    ),
    MemberSlice(
      userId: 11,
      nickname: '阿芳',
      total: '1200.00',
      byCategory: [
        CategoryAmount(categoryId: 1, amount: '600.00'),
        CategoryAmount(categoryId: 2, amount: '400.00'),
        CategoryAmount(amount: '200.00'),
      ],
    ),
  ],
  DateTime? startDate,
  DateTime? endDate,
}) => FinanceStatistics(
  startDate: startDate ?? DateTime(2026, 9, 1),
  endDate: endDate ?? DateTime(2026, 9, 14),
  categoryBreakdown: categoryBreakdown,
  // 默认给空的趋势：要测 12 个月的刻度就用 trend() 自己拼一份传进来，
  // 这里塞 12 个月会让每个用到 overview() 的用例都背上一屏无关数据。
  monthlyTrend: monthlyTrend,
  // 默认那三天住在函数体里而不是参数列表：DailyPoint 装着 DateTime，const 列表装不下它。
  // 右边留一根 320.00 的尖峰，「区间内支出最高的一天」那句话才有东西可指。
  dailyTrend:
      dailyTrend ??
      [
        DailyPoint(date: DateTime(2026, 9, 12), expense: '100.00'),
        DailyPoint(date: DateTime(2026, 9, 13), expense: '0.00'),
        DailyPoint(date: DateTime(2026, 9, 14), expense: '320.00'),
      ],
  accountBreakdown: accountBreakdown,
  memberComparison: memberComparison,
);

/// 趋势图的一个月。结余用 money.dart 现算，免得样例里出现「收入减支出对不上结余」的数。
MonthSummary trend(
  String month, {
  String income = '0.00',
  String expense = '100.00',
  int count = 3,
}) => MonthSummary(
  month: month,
  income: income,
  expense: expense,
  balance: fromCents(toCents(income) - toCents(expense)),
  count: count,
);

/// 最近 12 个自然月，升序，缺月补 0（B9 的契约）。
List<MonthSummary> twelveMonths({
  int throughYear = 2026,
  int throughMonth = 9,
}) => [
  for (var i = 11; i >= 0; i--)
    trend(monthKeyOf(DateTime(throughYear, throughMonth - i))),
];

/// `DateTime` → `"2026-09"`。与 `ui/core/date_format.dart` 的 `monthKey` 同口径，
/// 这里自己写一份是为了让样例文件不去 import 一个 S5 才加的函数——真要用就用那个。
String monthKeyOf(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}';

/// 两个成员的家庭。统计页与导出页的记录人 chips 都吃它。
Family family({List<Member>? members}) => Family(
  id: 1,
  name: '我们家',
  ownerUserId: 10,
  inviteEnabled: true,
  inviteCode: 'ABC123',
  inviteCodeExpireAt: DateTime(2026, 9, 30),
  members:
      members ??
      [
        Member(
          userId: 10,
          nickname: '小明',
          role: MemberRole.owner,
          joinedAt: DateTime(2026, 9, 10),
        ),
        Member(
          userId: 11,
          nickname: '阿芳',
          role: MemberRole.member,
          joinedAt: DateTime(2026, 9, 11),
        ),
      ],
);

/// 统计页给饼图上色要查当前字典（`_colorIndexOf`），页面测试里 stub `categoryViewModelProvider`
/// 时用它当那份树。
List<Category> categories() => [
  Category(
    id: 1,
    type: FlowType.expense,
    name: '餐饮',
    iconKey: 'bowl_noodle',
    colorIndex: 0,
    sortNo: 1,
    enabled: true,
    preset: true,
  ),
  Category(
    id: 2,
    type: FlowType.expense,
    name: '交通',
    iconKey: 'bus',
    colorIndex: 1,
    sortNo: 2,
    enabled: true,
    preset: true,
  ),
];
