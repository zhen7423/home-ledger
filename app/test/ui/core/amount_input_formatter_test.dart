import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/ui/core/amount_input_formatter.dart';

/// AmountInputFormatter 的核心约定：对**编辑后的整串**判形，不合法就拒绝本次编辑。
/// 旧的 allow 正则拦不住 "1.2.3" / "12.345"（复扫 2026-10-26 P3），这组用例就是钉死它们。
void main() {
  final formatter = AmountInputFormatter();

  // 测试环境没有真实输入法，直接模拟「用户输入后」的新值，断言被接受还是被退回旧值。
  TextEditingValue edit(String oldText, String newText) {
    final oldValue = TextEditingValue(text: oldText);
    final newValue = TextEditingValue(text: newText);
    return formatter.formatEditUpdate(oldValue, newValue);
  }

  test('合法输入放行：纯整数、一位/两位小数', () {
    expect(edit('', '12').text, '12');
    expect(edit('12', '12.').text, '12.');
    expect(edit('12.', '12.5').text, '12.5');
    expect(edit('12.5', '12.55').text, '12.55');
  });

  test('第二个小数点被拒绝（1.2.3 不会拼出来）', () {
    expect(edit('1.2', '1.2.3'), const TextEditingValue(text: '1.2'));
  });

  test('第三位小数被拒绝', () {
    expect(edit('12.55', '12.555'), const TextEditingValue(text: '12.55'));
  });

  test('整数位超过 10 位被拒绝（DECIMAL(12,2) 口径）', () {
    expect(edit('1234567890', '12345678901'),
        const TextEditingValue(text: '1234567890'));
  });

  test('字母负号空格等一概不进（形状不符）', () {
    expect(edit('', 'a'), const TextEditingValue(text: ''));
    expect(edit('', '12a'), const TextEditingValue(text: ''));
    expect(edit('12', '12 '), const TextEditingValue(text: '12'));
  });

  test('全删到空串是合法中间态，交给提交时校验', () {
    expect(edit('12', '').text, '');
  });
}
