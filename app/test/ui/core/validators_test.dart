import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/ui/core/validators.dart';

void main() {
  group('手机号（§4.1.1）', () {
    test('11 位大陆号段通过', () {
      expect(validatePhone('13900000001'), isNull);
      expect(validatePhone(' 19912345678 '), isNull);
    });

    test('位数或号段不对时拦下', () {
      expect(validatePhone(''), '请输入手机号');
      expect(validatePhone('1390000001'), isNotNull);
      expect(validatePhone('139000000012'), isNotNull);
      expect(validatePhone('12900000001'), isNotNull);
      expect(validatePhone('1390000000a'), isNotNull);
    });
  });

  group('密码（§4.1.1）', () {
    test('8–20 位且同时含字母与数字', () {
      expect(validateNewPassword('abc12345'), isNull);
      expect(validateNewPassword('a1'), isNotNull);
    });

    test('长度越界', () {
      expect(validateNewPassword('a123456'), isNotNull);
      expect(validateNewPassword('a${'b' * 20}1'), isNotNull);
    });

    test('缺字母或缺数字', () {
      expect(validateNewPassword('12345678'), isNotNull);
      expect(validateNewPassword('abcdefgh'), isNotNull);
    });

    test('登录时只查空，不套注册规则', () {
      expect(validateLoginPassword('12345678'), isNull);
      expect(validateLoginPassword(''), '请输入密码');
    });
  });

  group('昵称（§4.1.1）', () {
    test('1–12 字符', () {
      expect(validateNickname('小明'), isNull);
      expect(validateNickname('  小明  '), isNull);
      expect(validateNickname(''), '请输入昵称');
      expect(validateNickname('   '), '请输入昵称');
      expect(validateNickname('一二三四五六七八九十一二三'), isNotNull);
    });
  });

  group('家庭（§4.1.4）', () {
    test('创建时名称可留空', () {
      expect(validateFamilyName(''), isNull);
      expect(validateFamilyName('二十个字的家庭名称到底能不能写完呢试试看吧'), isNotNull);
    });

    test('改名不许留空', () {
      expect(validateFamilyRename('新家名'), isNull);
      expect(validateFamilyRename('  '), '请填写家庭名称');
    });

    test('邀请码是 6 位数字', () {
      expect(validateInviteCode('228286'), isNull);
      expect(validateInviteCode('22828'), isNotNull);
      expect(validateInviteCode('2282866'), isNotNull);
      expect(validateInviteCode('22828a'), isNotNull);
    });
  });

  group('金额（§4.2.1）', () {
    test('整数或最多两位小数都收', () {
      expect(validateAmount('12'), isNull);
      expect(validateAmount('12.3'), isNull);
      expect(validateAmount(' 88.05 '), isNull);
    });

    test('三位小数、负数、非数字都拦下', () {
      expect(validateAmount('1.005'), '金额最多两位小数');
      expect(validateAmount('-5'), '金额最多两位小数');
      expect(validateAmount('12.3.4'), '金额最多两位小数');
      expect(validateAmount('abc'), '金额最多两位小数');
    });

    test('零不算一笔账', () {
      expect(validateAmount('0'), '金额要大于 0');
      expect(validateAmount('0.00'), '金额要大于 0');
    });

    // 上限与后端 TransactionServiceImpl.MAX_AMOUNT 同一个数，前端先拦是为了不让用户白填一张表
    test('整数位最多 10 位', () {
      expect(validateAmount('9999999999.99'), isNull);
      expect(validateAmount('10000000000'), '金额太大，记不下');
    });

    test('留空', () {
      expect(validateAmount(null), '请输入金额');
      expect(validateAmount('   '), '请输入金额');
    });
  });

  group('类别与支付方式名称（§4.2.2 §4.2.4）', () {
    test('大类 6 字、小类与支付方式 8 字', () {
      expect(validateMajorCategoryName('餐饮'), isNull);
      expect(validateMajorCategoryName('一二三四五六七'), isNotNull);
      expect(validateSubCategoryName('一日三餐'), isNull);
      expect(validateSubCategoryName('一二三四五六七八九'), isNotNull);
      expect(validatePaymentAccountName('微信零钱'), isNull);
      expect(validatePaymentAccountName('一二三四五六七八九'), isNotNull);
    });

    test('去掉首尾空格后再判空与判长', () {
      expect(validateMajorCategoryName('  餐饮  '), isNull);
      expect(validateSubCategoryName(''), '请输入小类名称');
      expect(validatePaymentAccountName('   '), '请输入支付方式名称');
    });
  });
}
