import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/ui/core/money.dart';

void main() {
  group('toCents', () {
    test('两位小数按字面切分', () {
      expect(toCents('12.30'), 1230);
      expect(toCents('0.01'), 1);
      expect(toCents('0.00'), 0);
    });

    test('小数位不足两位的补零，没有小数点的按整元算', () {
      expect(toCents('12.3'), 1230);
      expect(toCents('12'), 1200);
      expect(toCents('0'), 0);
    });

    test('DECIMAL(12,2) 上限内的最大值守得住，这里必须是精确的 int', () {
      expect(toCents('1000000000.00'), 100000000000);
      expect(toCents('9999999999.99'), 999999999999);
    });

    test('负号保留', () {
      expect(toCents('-3500.00'), -350000);
    });

    test('三位小数、空串、带字母的一律抛，不四舍五入也不截断', () {
      expect(() => toCents('12.345'), throwsFormatException);
      expect(() => toCents(''), throwsFormatException);
      expect(() => toCents('12.'), throwsFormatException);
      expect(() => toCents('12元'), throwsFormatException);
      expect(() => toCents('1,230.00'), throwsFormatException);
    });
  });

  group('fromCents', () {
    test('固定吐两位小数', () {
      expect(fromCents(1230), '12.30');
      expect(fromCents(1), '0.01');
      expect(fromCents(0), '0.00');
      expect(fromCents(-350000), '-3500.00');
    });

    test('与 toCents 往返一致', () {
      for (final amount in ['0.01', '12.30', '999.99', '1000000000.00']) {
        expect(fromCents(toCents(amount)), amount);
      }
      for (final cents in [0, 1, 99, 100, 123456789]) {
        expect(toCents(fromCents(cents)), cents);
      }
    });
  });

  group('formatYuan', () {
    test('整数部分千分位分组，小数两位原样带过', () {
      expect(formatYuan('1230.50'), '¥1,230.50');
      expect(formatYuan('0.00'), '¥0.00');
      expect(formatYuan('999.9'), '¥999.90');
      expect(formatYuan('1000000000.00'), '¥1,000,000,000.00');
    });

    test('结余为负时负号在货币符号前面', () {
      expect(formatYuan('-3500.00'), '-¥3,500.00');
    });
  });
}
