import 'package:flutter/material.dart';

/// 预算档位的文案与配色。
///
/// 首页那一块与预算管理页给同一行进度上色，两处各写一份 switch 迟早会给出
/// 「首页说超支、管理页说快到了」这种自相矛盾——档位在后端只判一次（`level`），
/// 界面上就该只有一处把它翻译成人话。
///
/// 一律看 `level`，不要拿 `usedPercent` 自己比阈值：那个数是向下取整的显示值。
Color budgetLevelColor(ColorScheme scheme, String level) => switch (level) {
  'WARNING' => Colors.orange,
  'EXCEEDED' => scheme.error,
  _ => scheme.primary,
};

String budgetLevelLabel(String level) => switch (level) {
  'WARNING' => '即将超支',
  'EXCEEDED' => '已超支',
  _ => '正常',
};

/// 进度行与额度行左边的名字。家庭维度没有名字，另外两类取服务端给的当前名，
/// 查不到时（类别被删、成员已退出）落回维度本身，而不是显示空白。
String budgetTitle(String scope, String? name) => switch (scope) {
  'CATEGORY' => (name ?? '').isEmpty ? '类别预算' : name!,
  'MEMBER' => (name ?? '').isEmpty ? '成员预算' : name!,
  _ => '家庭总预算',
};
