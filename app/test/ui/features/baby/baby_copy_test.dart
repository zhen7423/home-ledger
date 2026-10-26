import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/ui/features/baby/baby_copy.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_curve_view_model.dart';

/// 宝宝模块那几句「怎么念这行数据」。四处口径都在这里：待办行的三选一、增减量的补号、
/// 剂次的中文、以及那两张码值表。它们各自只在页面上显示半行字，真机上一眼看过去是对的，
/// 而「今天到期」被染成逾期、`0` 被补成 `+0` 这类事只有把整串比对出来才看得见。
void main() {
  group('vaccineDueLabel', () {
    test('还有 n 天', () {
      expect(vaccineDueLabel(daysToDue: 3, overdueDays: null), '还有 3 天');
    });

    test('今天到期不写零天', () {
      expect(vaccineDueLabel(daysToDue: 0, overdueDays: null), '今天到期');
    });

    test('逾期写作逾期 n 天', () {
      expect(vaccineDueLabel(daysToDue: null, overdueDays: 15), '逾期 15 天');
    });

    test('两个都有值时按逾期说', () {
      // 挡的是有人把判断顺序换成 `daysToDue`：那样这句会回「还有 2 天」，
      // 而一条已经逾期 5 天的记录被说成还没到，颜色也不会红（§4.4.4 的逾期判定是严格大于今天）。
      expect(vaccineDueLabel(daysToDue: 2, overdueDays: 5), '逾期 5 天');
    });

    test('两个数都拿不到时按今天到期说，不凭空造一句', () {
      // 服务端那两列互斥且必有一个非空，所以这一支走不到；走到的话 `?? 0` 落回「今天到期」，
      // 比显示「还有 0 天」或空串都稳。
      expect(vaccineDueLabel(daysToDue: null, overdueDays: null), '今天到期');
    });

    test('逾期 0 天也是一个有值的逾期，不退成今天到期', () {
      // `overdueDays != null` 才是染不染红的判据，所以一个 0 天的逾期照样得说「逾期」。
      expect(vaccineDueLabel(daysToDue: 0, overdueDays: 0), '逾期 0 天');
    });
  });

  group('signedDelta', () {
    test('正数补加号', () {
      expect(signedDelta('1.2'), '+1.2');
      expect(signedDelta('0.40'), '+0.40');
    });

    test('负数本来就有减号，不再补', () {
      expect(signedDelta('-0.30'), '-0.30');
    });

    test('零不补符号', () {
      // `0` 与 `null` 在两个模型里是两件事（§4.4.2：「较上次没量身高」与「较上次身高没变」），
      // 后者由调用方整段不显示，前者该显示成「0.00」而不是「+0.00」。
      expect(signedDelta('0.00'), '0.00');
    });

    test('解不开的串原样交出，不吞成空', () {
      expect(signedDelta(''), '');
      expect(signedDelta('—'), '—');
    });
  });

  group('doseLabel', () {
    test('数字剂次念成第 n 剂', () {
      expect(doseLabel('1'), '第 1 剂');
      expect(doseLabel('5'), '第 5 剂');
    });

    test('自由输入的剂次原样显示，不套第 / 剂', () {
      // 手建的自费项可以写「加强针」（§4.4.4 的剂次那一行允许自定义），
      // 不判一下就会念成「第 加强针 剂」。
      expect(doseLabel('加强针'), '加强针');
      expect(doseLabel(''), '');
    });
  });

  group('两张码值表', () {
    test('五个可选指标与 chips 那份清单一一对应', () {
      // 这两个清单分住两个文件：`growthMetrics` 是请求顺序，这里是显示文案。
      // 少一个键界面上就是一枚空白 chip，多一个键则是一枚点了没用的 chip。
      expect(growthMetricLabels.keys.toSet(), growthMetrics.toSet());
    });

    test('性别说男宝 / 女宝而不是男 / 女', () {
      // 这一栏在档案列表与总览卡片上都是给别人看的名片，不是数据字段（§4.4.1）。
      expect(genderLabels, {'MALE': '男宝', 'FEMALE': '女宝'});
    });

    test('疫苗五态各有一个说法，键与后端枚举名对应', () {
      expect(vaccineDisplayLabels.keys.toSet(), {
        'VACCINATED',
        'MARKED',
        'OVERDUE',
        'DUE_SOON',
        'UPCOMING',
      });
    });

    test('两张标准表各有一句口径说明，键就是响应里的 standardMetric', () {
      // 这是 `standardMetric` 存在的唯一理由（§1.4 第 14 条）：用户选的是「体重别身高」，
      // 实际用哪张表取决于年龄，不说清就没法解释横轴为什么是身长。
      expect(standardMetricNotes.keys.toSet(), {
        'WEIGHT_LENGTH',
        'WEIGHT_HEIGHT',
      });
    });
  });

  group('常量本身', () {
    test('里程碑那排候选项非空且互不重复', () {
      expect(milestonePresets, isNotEmpty);
      expect(milestonePresets.toSet(), hasLength(milestonePresets.length));
    });

    test('免责声明非空，且两句来源与那句「仅供参考」都在', () {
      // 与后端 `BabyDisclaimers.STANDARD` 的**逐字**比对做不了：那是 Java 常量，
      // 这一侧只能断它承载的那几件事在。逐字那一半落在 §8 第 5 条的 grep 上。
      expect(babyDataDisclaimer, isNotEmpty);
      expect(babyDataDisclaimer, contains('WS/T 423—2022'));
      expect(babyDataDisclaimer, contains('2026 年版'));
      expect(babyDataDisclaimer, contains('不作为医学诊断依据'));
    });
  });
}
