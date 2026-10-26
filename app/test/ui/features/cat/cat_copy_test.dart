import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/ui/features/cat/cat_copy.dart';

import '../../../support/s6_fixtures.dart';

/// 猫模块那几句「怎么念这行数据」。三处口径都在这里：生日的三态、倒计时的三选一、
/// 每袋小结的那一串。它们各自只在页面上显示半行字，真机上一眼看过去是对的，
/// 而估算态少了「约」字、日均写成 0 这类事只有把整串比对出来才看得见。
void main() {
  group('birthdayLabel', () {
    test('整栏没填时说的是未知', () {
      expect(birthdayLabel(catFixture()), '生日未知');
    });

    test('估算生日只到月，且带约字', () {
      expect(
        birthdayLabel(
          catFixture(
            birthday: DateTime(2024, 3),
            birthdayEstimated: true,
          ),
        ),
        '约 2024 年 3 月',
      );
    });

    test('精确生日到日', () {
      expect(
        birthdayLabel(catFixture(birthday: DateTime(2024, 3, 17))),
        '2024-03-17',
      );
    });

    // 三条一起才是 §4.3.1「估算态存的是该月 1 日」的取证：估算那份的日期同样落在某月 1 日，
    // 只有「约」这一个标记能把两者分开。所以第二条断的是整串，不是 contains('约')。
    test('估算态的日期本身就是 1 日，去掉约字就与精确态混了', () {
      expect(
        birthdayLabel(catFixture(birthday: DateTime(2024, 3, 1), birthdayEstimated: true)),
        '约 2024 年 3 月',
      );
    });
  });

  group('dueLabel', () {
    test('还有 n 天', () {
      expect(dueLabel(daysToDue: 2, overdueDays: null), '还有 2 天');
    });

    test('今天到期不写零天', () {
      expect(dueLabel(daysToDue: 0, overdueDays: null), '今天到期');
    });

    test('逾期写作逾期 n 天', () {
      expect(dueLabel(daysToDue: null, overdueDays: 5), '逾期 5 天');
    });

    test('两个数都拿不到时按今天到期说，不凭空造一句', () {
      // 服务端那两列互斥且必有一个非空（`next_date` 非空），所以这一支永远走不到；
      // 走到的话 `?? 0` 把它落回「今天到期」，比显示「还有 0 天」或空串都稳。
      expect(dueLabel(daysToDue: null, overdueDays: null), '今天到期');
    });

    test('两个都有值时按逾期说', () {
      // 挡的是有人把判断顺序换成 `daysToDue`：那样这句会回「还有 2 天」，
      // 而一条已经逾期 5 天的记录被说成还没到，颜色也不会红。
      expect(dueLabel(daysToDue: 2, overdueDays: 5), '逾期 5 天');
    });
  });

  group('bagSummaryLine', () {
    test('日均已知', () {
      expect(bagSummaryLine(bagFixture()), '2000 g 装 · 用了 40 天 · 日均 50 g');
    });

    test('日均未知时那一栏是破折号', () {
      // 当前袋的两个派生字段本就是 null：一袋还没吃完，它的折算日均不是一个事实。
      expect(
        bagSummaryLine(
          bagFixture(current: true, usageDays: null, dailyAverage: null),
        ),
        '2000 g 装 · 日均 —',
      );
    });
  });

  group('gramsText', () {
    test('整数克数直接带单位，不落小数点', () {
      expect(gramsText(1450), '1450 g');
      expect(gramsText(0), '0 g');
    });
  });

  group('三个 *Label 的默认分支', () {
    test('码值不在表里时回它自己', () {
      // `UNKNOWN` 是 gender / neutered 的合法码值，兜底文案与它是两回事：
      // 把默认分支改成「未知」会让一个没预料到的码（比如后端新加的）永远显示成未知。
      expect(genderLabel('XX'), 'XX');
      expect(neuteredLabel('SOMETIMES'), 'SOMETIMES');
      expect(dewormingLabel(''), '');
    });

    test('表里那三个码各有一个说法', () {
      expect([genderLabel('MALE'), genderLabel('FEMALE'), genderLabel('UNKNOWN')], [
        '公',
        '母',
        '未知',
      ]);
      expect(
        [
          neuteredLabel('YES'),
          neuteredLabel('NO'),
          neuteredLabel('UNKNOWN'),
        ],
        ['已绝育', '未绝育', '未知'],
      );
      expect(
        [dewormingLabel('INTERNAL'), dewormingLabel('EXTERNAL')],
        ['内驱', '外驱'],
      );
    });
  });
}
