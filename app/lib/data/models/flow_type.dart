/// 收支类型。后端在 `category.type` 与 `transaction.type` 上都收发这两个字符串，
/// 前端集中在这一处，界面里不再散落 'EXPENSE' 字面量。
abstract class FlowType {
  static const String expense = 'EXPENSE';
  static const String income = 'INCOME';
}
