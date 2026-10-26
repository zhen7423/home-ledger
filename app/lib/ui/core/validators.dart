import 'money.dart';

final RegExp _phonePattern = RegExp(r'^1[3-9]\d{9}$');
final RegExp _letter = RegExp('[A-Za-z]');
final RegExp _digit = RegExp(r'\d');

/// 金额的形态：不带正负号，小数点后可有可无、至多两位。整数位的长度另外判，见 `validateAmount`。
final RegExp _amountPattern = RegExp(r'^\d+(?:\.\d{1,2})?$');

// 入参一律可空：TextFormField 的 validator 签名就是 String? Function(String?)

String? validatePhone(String? value) {
  final phone = value?.trim() ?? '';
  if (phone.isEmpty) return '请输入手机号';
  if (!_phonePattern.hasMatch(phone)) return '请输入 11 位手机号';
  return null;
}

/// 登录时只查空：老账号的密码未必符合当前规则，拿注册规则去卡登录会把人挡在门外。
String? validateLoginPassword(String? value) =>
    (value ?? '').isEmpty ? '请输入密码' : null;

String? validateNewPassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return '请输入密码';
  if (password.length < 8 || password.length > 20) return '密码需 8–20 位';
  if (!_letter.hasMatch(password) || !_digit.hasMatch(password)) {
    return '密码需同时包含字母和数字';
  }
  return null;
}

String? validateNickname(String? value) {
  final nickname = value?.trim() ?? '';
  if (nickname.isEmpty) return '请输入昵称';
  if (nickname.length > 12) return '昵称最多 12 个字符';
  return null;
}

/// 家庭名称可留空，留空时后端填「<昵称>的家」。
String? validateFamilyName(String? value) =>
    (value?.trim() ?? '').length > 20 ? '家庭名称最多 20 个字符' : null;

/// 改名不许留空：默认名只在创建时由后端补，改名时留空会被拒。
String? validateFamilyRename(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return '请填写家庭名称';
  return validateFamilyName(name);
}

String? validateInviteCode(String? value) =>
    RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '') ? null : '邀请码是 6 位数字';

String? validateRequired(String? value) =>
    (value ?? '').isEmpty ? '请输入密码' : null;

/// 金额。规则与后端逐条对齐：> 0、最多两位小数、整数位不超过 10 位（列是 DECIMAL(12,2)）。
/// 超两位小数是直接拒绝，不做四舍五入——把 12.345 悄悄记成 12.34 是笔没人会发现的错。
String? validateAmount(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return '请输入金额';
  if (!_amountPattern.hasMatch(text)) return '金额最多两位小数';
  if (text.split('.').first.length > 10) return '金额太大，记不下';
  if (toCents(text) == 0) return '金额要大于 0';
  return null;
}

/// 大类名，≤ 6 字。
String? validateMajorCategoryName(String? value) =>
    _shortName(value, level: '大类', maxLength: 6);

/// 小类名，≤ 8 字。
String? validateSubCategoryName(String? value) =>
    _shortName(value, level: '小类', maxLength: 8);

/// 支付方式名，≤ 8 字，与后端 DTO 那句「支付方式名称最多 8 个字符」同口径。
String? validatePaymentAccountName(String? value) =>
    _shortName(value, level: '支付方式', maxLength: 8);

/// 规则名，≤ 20 字。预算金额不设新校验器，与记一笔同一套口径，直接用 `validateAmount`。
String? validateRecurringRuleName(String? value) =>
    _shortName(value, level: '规则', maxLength: 20);

/// 四处名称上限都照服务端写的同一套数字来。界面本来就知道自己在编辑哪一级，
/// 所以报得出具体上限，不像后端 `CATEGORY_NAME_TOO_LONG` 那样只能把两级写进一句。
String? _shortName(
  String? value, {
  required String level,
  required int maxLength,
}) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return '请输入$level名称';
  if (name.length > maxLength) return '$level名称最多 $maxLength 个字符';
  return null;
}
