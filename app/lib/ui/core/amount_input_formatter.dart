import 'package:flutter/services.dart';

/// 金额输入的整串约束：至多一个小数点、小数至多两位、整数位至多 10 位（与 `validateAmount`
/// 同一套数字，后端列是 DECIMAL(12,2)）。
///
/// 不能用 `FilteringTextInputFormatter.allow(\d*\.?\d{0,2})`：allow 的语义是「保留所有能匹配的
/// 片段」，`"1.2.3"` 会被拼成 `"1.2"`+`".3"` 原样放行，第二个小数点与第三位小数全都没拦住
/// （复扫 2026-10-26 P3）。这里的做法是对**编辑后的整串**判形，不合法就拒绝本次编辑。
class AmountInputFormatter extends TextInputFormatter {
  static final RegExp _shape = RegExp(r'^\d{0,10}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 删除到空串是合法的中间态（还没填），交给 validator 在提交时把关
    if (newValue.text.isEmpty) return newValue;
    if (!_shape.hasMatch(newValue.text)) return oldValue;
    return newValue;
  }
}
