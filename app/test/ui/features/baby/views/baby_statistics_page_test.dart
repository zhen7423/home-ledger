import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/baby.dart';
import 'package:homeledger/data/models/baby_formula_statistics.dart';
import 'package:homeledger/data/models/baby_statistics.dart';
import 'package:homeledger/data/services/network_status.dart';
import 'package:homeledger/ui/core/offline_banner.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_formula_statistics_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_list_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_statistics_view_model.dart';
import 'package:homeledger/ui/features/baby/views/baby_statistics_page.dart';

import '../../../../support/s7_fixtures.dart';

/// §4.4.6 的宝宝统计。一屏两段同屏堆叠，所以断的是那九行各自的读法：
/// 体格段里「没量那一项整段不出现」与档位为 null 是两件事、疫苗段的完成率分母只算已到期、
/// 以及逾期清单排在即将接种之前（红色置顶）。
void main() {
  Future<void> open(
    WidgetTester tester, {
    int? babyId,
    BabyGrowthStatistics? growth,
    BabyVaccineStatistics? vaccine,
    List<Baby>? babies,
    NetworkStatus? network,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final state = BabyStatisticsState(
      growth: growth ?? growthStatisticsFixture(),
      vaccine: vaccine ?? vaccineStatisticsFixture(),
    );

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
          babyListViewModelProvider.overrideWith(
            () => _StubBabies(babies ?? [babyFixture()]),
          ),
          babyStatisticsViewModelProvider.overrideWith2(
            (arg) => _StubStatistics(state, arg),
          ),
          // 奶粉消耗卡走实时统计端点，测试里给一份空统计避免真实 Dio 在 fake 时钟下挂起
          babyFormulaStatisticsViewModelProvider.overrideWith(
            () => _StubFormulaStatistics(),
          ),
          if (network != null)
            networkStatusProvider.overrideWith(
              () => _FixedNetworkStatus(network),
            ),
        ],
        child: MaterialApp(home: BabyStatisticsPage(babyId: babyId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 里程碑时间轴是这一列的最后一段，落在视口下方；`find.byType(Scrollable).first`
  /// 会抓到别的滚动条，所以认准 `ListView` 里面那一个。
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      120,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('体格段三项各带档位，派生那两项也在', (tester) async {
    await open(tester);

    expect(find.text('体格成长'), findsOneWidget);
    expect(find.text('1 岁 0 个月'), findsOneWidget);
    expect(find.text('最新体格 · 2026-09-10'), findsOneWidget);
    expect(find.text('身高 76.5 cm'), findsOneWidget);
    expect(find.text('体重 9.80 kg'), findsOneWidget);
    expect(find.text('头围 46.0 cm'), findsOneWidget);
    // 体重别身高与 BMI 是派生量，响应里只给档位、不给实测值。
    expect(find.text('体重别身高'), findsOneWidget);
    expect(find.text('BMI'), findsOneWidget);
    // 身高与头围同档，所以最深那一档出现三次、次深两次。
    expect(find.text('P50–P75'), findsNWidgets(3));
    expect(find.text('P25–P50'), findsNWidgets(2));
    expect(find.text('看曲线'), findsOneWidget);
  });

  testWidgets('有一段窗口里不足两条代表行时那一行整行不显示', (tester) async {
    await open(
      tester,
      growth: growthStatisticsFixture(
        perBaby: [
          growthItemFixture(
            growth: windowsFixture(
              sinceLast: gainFixture(),
              last12Months: gainFixture(days: 365),
            ),
          ),
        ],
      ),
    );

    expect(find.text('较上次'), findsOneWidget);
    expect(find.text('近 3 个月'), findsNothing);
    expect(find.text('近 12 个月'), findsOneWidget);
    // 显示 +0 会把「没量」说成「没变」（§4.4.2），所以那一段整段不出现。
    expect(
      find.text('身高 +1.5 cm · 体重 +0.40 kg · 头围 +0.5 cm · 30 天'),
      findsOneWidget,
    );
    expect(
      find.text('身高 +1.5 cm · 体重 +0.40 kg · 头围 +0.5 cm · 365 天'),
      findsOneWidget,
    );
  });

  testWidgets('没量过身高体重的宝宝在体格段说一句，不摆一排破折号', (tester) async {
    await open(
      tester,
      growth: growthStatisticsFixture(
        perBaby: [growthItemFixture(latest: null)],
      ),
    );

    expect(find.text('还没有身高体重记录'), findsOneWidget);
  });

  testWidgets('只量了身高时，体重别身高与 BMI 整段不出现', (tester) async {
    await open(
      tester,
      growth: growthStatisticsFixture(
        perBaby: [
          growthItemFixture(
            latest: latestFixture(
              weightKg: null,
              bands: bandsFixture(weight: null, weightHeight: null, bmi: null),
            ),
          ),
        ],
      ),
    );

    // 缺一个输入量就算不出来，整项不显示——否则「没量体重」会被格子说成「超出标准表覆盖范围」。
    expect(find.text('体重别身高'), findsNothing);
    expect(find.text('BMI'), findsNothing);
    expect(find.text('身高 76.5 cm'), findsOneWidget);
    expect(find.text('体重 '), findsNothing);
  });

  testWidgets('档位为 null 时那一格写「已超出标准表覆盖范围」，那不是缺数据', (tester) async {
    await open(
      tester,
      growth: growthStatisticsFixture(
        perBaby: [
          growthItemFixture(
            latest: latestFixture(bands: bandsFixture(height: null)),
          ),
        ],
      ),
    );

    expect(find.text('已超出标准表覆盖范围'), findsOneWidget);
  });

  testWidgets('疫苗段的环读的是 0–100 那个整数，并写明分母只算已到期', (tester) async {
    await open(tester);

    expect(find.text('疫苗完成率'), findsOneWidget);
    expect(find.text('已接种 ÷ 已到期的应种项'), findsOneWidget);
    expect(find.text('67%'), findsOneWidget);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      0.67,
    );
  });

  testWidgets('四态计数各一段，逾期清单排在即将接种之前', (tester) async {
    await open(tester);

    expect(find.text('待接种'), findsOneWidget);
    expect(find.text('逾期清单'), findsOneWidget);
    expect(find.text('逾期 15 天'), findsOneWidget);
    expect(find.text('还有 3 天'), findsOneWidget);
    expect(find.text('接种时间轴'), findsOneWidget);
    // 红色置顶（§4.4.6）：逾期的那几行要在即将接种前面。
    expect(
      tester.getRect(find.text('逾期清单')).top,
      lessThan(tester.getRect(find.text('即将接种').last).top),
    );
  });

  testWidgets('里程碑时间轴是跨宝宝的一份，每行都带宝宝名', (tester) async {
    await open(tester);
    await scrollTo(tester, find.text('里程碑时间轴'));

    expect(find.text('里程碑时间轴'), findsOneWidget);
    expect(find.text('小明 · 第一次抬头'), findsOneWidget);
    expect(find.text('小红 · 第一颗牙'), findsOneWidget);
  });

  testWidgets('两段与时间轴各有一句空态', (tester) async {
    await open(
      tester,
      growth: growthStatisticsFixture(perBaby: const []),
      vaccine: vaccineStatisticsFixture(
        perBaby: const [],
        milestoneTimeline: const [],
      ),
    );

    expect(find.text('还没有在册的宝宝'), findsNWidgets(2));
    expect(find.text('还没有里程碑'), findsOneWidget);
  });

  testWidgets('离线时挂一条横幅', (tester) async {
    await open(tester, network: NetworkStatus.offline);

    expect(find.byType(OfflineBanner), findsOneWidget);
  });

  testWidgets('不给 babyId 时标题是「宝宝统计」，给了就带上宝宝名', (tester) async {
    await open(tester);
    expect(find.text('宝宝统计'), findsOneWidget);

    await open(tester, babyId: 1);
    expect(find.text('小明 的统计'), findsOneWidget);
  });
}

class _AlwaysSignedIn extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

class _StubBabies extends BabyListViewModel {
  _StubBabies(this.rows);

  final List<Baby> rows;

  @override
  Future<List<Baby>> build() async => rows;
}

/// 统计那两条端点是一起发的，页面拿到的就是一个两段齐全的状态；这里直接把它交出来。
class _StubStatistics extends BabyStatisticsViewModel {
  _StubStatistics(this.stubbed, int? babyId) : super(babyId);

  final BabyStatisticsState stubbed;

  @override
  Future<BabyStatisticsState> build() async => stubbed;
}

class _FixedNetworkStatus extends NetworkStatusNotifier {
  _FixedNetworkStatus(this.status);

  final NetworkStatus status;

  @override
  NetworkStatus build() => status;
}

/// 奶粉消耗卡的一份空统计：累计 0 → 卡片显示「还没有奶粉记录」，不打扰体格/疫苗的断言。
class _StubFormulaStatistics extends BabyFormulaStatisticsViewModel {
  @override
  Future<BabyFormulaStatistics> build() async => const BabyFormulaStatistics(
    totalGrams: 0,
    totalDays: 0,
    dailyAverage: 0,
  );
}
