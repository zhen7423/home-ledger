import 'package:homeledger/data/models/budget.dart';
import 'package:homeledger/data/models/budget_progress.dart';
import 'package:homeledger/data/models/flow_type.dart';
import 'package:homeledger/data/models/pending_reminder.dart';
import 'package:homeledger/data/models/period_value.dart';
import 'package:homeledger/data/models/recurring_execution.dart';
import 'package:homeledger/data/models/recurring_rule.dart';
import 'package:homeledger/data/models/reminder_setting.dart';

/// S4 那批模型的样例，ViewModel 与页面测试共用一份。
///
/// 默认值取的是「最普通的一条」：每月 1 日的房租支出、家庭总预算的正常进度。
/// 要别的形态在调用处覆盖，别在这里加分支——一份样例长出十种参数就没法读了。

RecurringRule rule({
  int id = 1,
  String name = '房租',
  String type = FlowType.expense,
  String amount = '3000.00',
  int categoryId = 3,
  String categoryName = '居住',
  int accountId = 1,
  String accountName = '微信',
  String periodType = 'MONTHLY',
  PeriodValue periodValue = const PeriodValue(daysOfMonth: [1]),
  DateTime? startDate,
  DateTime? endDate,
  bool enabled = true,
}) => RecurringRule(
  id: id,
  name: name,
  type: type,
  amount: amount,
  categoryId: categoryId,
  categoryName: categoryName,
  accountId: accountId,
  accountName: accountName,
  periodType: periodType,
  periodValue: periodValue,
  startDate: startDate ?? DateTime(2026, 9, 1),
  endDate: endDate,
  enabled: enabled,
  createdAt: DateTime(2026, 9, 1),
  updatedAt: DateTime(2026, 9, 1),
);

/// 一条规则的一次执行。后端不给金额（F7 实施记录里记了原因），这里也不假装有。
RecurringExecution execution({
  int id = 1,
  required DateTime bizDate,
  int transactionId = 900,
  DateTime? executedDate,
  bool backfilled = false,
}) => RecurringExecution(
  id: id,
  bizDate: bizDate,
  transactionId: transactionId,
  executedDate: executedDate ?? bizDate,
  backfilled: backfilled,
);

Budget budget({
  int id = 1,
  String scope = 'FAMILY',
  int? categoryId,
  String? categoryName,
  int? memberUserId,
  String? memberName,
  String amount = '5000.00',
}) => Budget(
  id: id,
  scope: scope,
  categoryId: categoryId,
  categoryName: categoryName,
  memberUserId: memberUserId,
  memberName: memberName,
  amount: amount,
);

/// 一行预算进度。名字不叫 `progress`：实现 `BudgetRepository` 的替身里那个方法名会把它遮住。
BudgetProgress budgetProgress({
  String month = '2026-09',
  String scope = 'FAMILY',
  int? categoryId,
  String? categoryName,
  int? memberUserId,
  String? memberName,
  String amount = '5000.00',
  String used = '1000.00',
  String remaining = '4000.00',
  int usedPercent = 20,
  String level = 'NORMAL',
  int remainingDays = 16,
}) => BudgetProgress(
  month: month,
  scope: scope,
  categoryId: categoryId,
  categoryName: categoryName,
  memberUserId: memberUserId,
  memberName: memberName,
  amount: amount,
  used: used,
  remaining: remaining,
  usedPercent: usedPercent,
  level: level,
  remainingDays: remainingDays,
);

PendingReminder reminder({
  String type = 'BUDGET_OVERRUN',
  String module = 'FINANCE',
  String key = 'BUDGET_OVERRUN:FAMILY',
  String title = '家庭总预算已超支',
  String body = '本月已支出 5200 元，超出预算 200 元',
  String route = '/finance/budgets',
  DateTime? fireAt,
}) => PendingReminder(
  type: type,
  module: module,
  key: key,
  title: title,
  body: body,
  route: route,
  fireAt: fireAt,
  // 两列要么都有要么都没有（§4.5.2 的形状约定），替身也照这条造数据
  fireDate: fireAt == null
      ? null
      : DateTime(fireAt.year, fireAt.month, fireAt.day),
);

ReminderSetting setting({
  required String type,
  required String label,
  required bool enabled,
  required bool pushed,
}) =>
    ReminderSetting(type: type, label: label, enabled: enabled, pushed: pushed);

/// 后端 `ReminderType` 的七项，`enabled` 取各自的 `defaultEnabled`。
///
/// 抄的是枚举而不是某个接口响应：这七行的顺序与默认值是 §4.5.1 那张表的落地形态，
/// 测试里凑数少一项，「保存时全量覆盖」那条断言就白写了。
List<ReminderSetting> reminderSettings({bool warningEnabled = false}) => [
  setting(
    type: 'CAT_DEWORMING_INTERNAL',
    label: '猫咪体内驱虫到期',
    enabled: true,
    pushed: true,
  ),
  setting(
    type: 'CAT_DEWORMING_EXTERNAL',
    label: '猫咪体外驱虫到期',
    enabled: true,
    pushed: true,
  ),
  setting(type: 'CAT_FOOD_LOW', label: '猫粮即将见底', enabled: true, pushed: true),
  setting(
    type: 'VACCINE_UPCOMING',
    label: '疫苗接种即将到期',
    enabled: true,
    pushed: true,
  ),
  setting(type: 'BUDGET_OVERRUN', label: '预算已超支', enabled: true, pushed: true),
  setting(
    type: 'BUDGET_WARNING',
    label: '预算即将超支',
    enabled: warningEnabled,
    pushed: false,
  ),
  setting(
    type: 'GROWTH_RECORD_DUE',
    label: '宝宝成长记录待补',
    enabled: true,
    pushed: false,
  ),
];
