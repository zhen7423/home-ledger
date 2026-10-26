import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/baby.dart';
import 'package:homeledger/data/models/baby_growth.dart';
import 'package:homeledger/data/services/network_status.dart';
import 'package:homeledger/ui/core/offline_banner.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/baby_badges.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_curve_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_list_view_model.dart';
import 'package:homeledger/ui/features/baby/views/baby_growth_curve_page.dart';

import '../../../../support/s7_fixtures.dart';

/// §4.4.3 的生长曲线。这一页一个百分位都不算，只把服务端算好的东西叠成四层，
/// 所以断的是叠法：八条线各自画成什么样、六段带的三档深浅、以及一个点时那条折线不画。
/// 「空档位」那一支也在这里——`PercentileBand(null)` 与「没量过」是两件事。
void main() {
  Future<void> open(
    WidgetTester tester, {
    BabyCurve Function(BabyCurveQuery)? curve,
    List<Baby>? babies,
    NetworkStatus? network,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        // 失败的异步 provider 默认按指数退避重试 10 次，替身里不许出现那种路径。
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
          babyListViewModelProvider.overrideWith(
            () => _StubBabies(babies ?? [babyFixture()]),
          ),
          babyCurveViewModelProvider.overrideWith2(
            (query) => _StubCurve(curve ?? (query) => curveFixture(), query),
          ),
          if (network != null)
            networkStatusProvider.overrideWith(
              () => _FixedNetworkStatus(network),
            ),
        ],
        child: const MaterialApp(home: BabyGrowthCurvePage(babyId: 1)),
      ),
    );
    await tester.pumpAndSettle();
  }

  LineChartData chartData(WidgetTester tester) =>
      tester.widget<LineChart>(find.byType(LineChart)).data;

  ColorScheme schemeOf(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(BabyGrowthCurvePage))).colorScheme;

  testWidgets('八条线：两条边界线、虚线中位线、四条透明骨架、一条实测', (tester) async {
    await open(tester);

    final scheme = schemeOf(tester);
    final bars = chartData(tester).lineBarsData;
    expect(bars, hasLength(8));

    // 下标就是百分位位次：0 与 6 是 P3 / P97 的外边界。
    expect(bars[0].color, scheme.outline);
    expect(bars[0].barWidth, 1);
    expect(bars[6].color, scheme.outline);
    expect(bars[6].barWidth, 1);

    // 中间四条（P10 / P25 / P75 / P90）自己不描线，只为让六段带有的可指。
    for (final index in const [1, 2, 4, 5]) {
      expect(bars[index].color, Colors.transparent, reason: '下标 $index 是骨架');
      expect(bars[index].barWidth, 0);
      expect(bars[index].dotData.show, isFalse);
    }

    // P50 是虚线中位线：`dashArray` 之后它才与上下两条实线分得开。
    expect(bars[3].color, scheme.primary);
    expect(bars[3].barWidth, 1.5);
    expect(bars[3].dashArray, [6, 4]);

    // 实测折线在最后一条，颜色与标准表的任何一条都不同。
    expect(bars[7].color, scheme.tertiary);
    expect(bars[7].barWidth, 2);
    expect(bars[7].dotData.show, isTrue);
    expect(bars[7].spots, hasLength(2));
  });

  testWidgets('六段相邻的带，三档深浅由外向内加深', (tester) async {
    await open(tester);

    final primary = schemeOf(tester).primary;
    final bands = chartData(tester).betweenBarsData;

    expect(bands, hasLength(6));
    expect([for (final band in bands) band.fromIndex], [0, 5, 1, 4, 2, 3]);
    expect([for (final band in bands) band.toIndex], [1, 6, 2, 5, 3, 4]);

    const shades = <double>[0.06, 0.06, 0.14, 0.14, 0.24, 0.24];
    for (var i = 0; i < bands.length; i++) {
      expect(bands[i].color, primary.withValues(alpha: shades[i]));
    }
  });

  testWidgets('一个实测点时那条折线不画，散点还在', (tester) async {
    await open(
      tester,
      curve: (query) => curveFixture(points: [curvePointFixture()]),
    );

    final bar = chartData(tester).lineBarsData[7];
    // 一个点连不成线，硬画会得到一条零长度的线，看着像数据缺了一段（§4.4.3 末条）。
    expect(bar.color, Colors.transparent);
    expect(bar.dotData.show, isTrue);
    expect(bar.spots, hasLength(1));
  });

  testWidgets('一个实测点都没有时带照画，底下说一句先记一次测量', (tester) async {
    await open(tester, curve: (query) => curveFixture(points: const []));

    // 带跟着标准表走、与点数无关，所以图还在；这句话的条件是「一条记录都没有」而不是「点少于两个」。
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('这个宝宝还没有身高体重记录，先记一次测量'), findsOneWidget);
  });

  testWidgets('实测与标准表都空的时候给一句话，不摆一张空图', (tester) async {
    await open(
      tester,
      curve: (query) => curveFixture(points: const [], standard: const []),
    );

    expect(find.text('这个指标既没有实测记录，也超出了标准表的覆盖范围'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('标题与横轴说明都以响应里的 standardMetric 为准，不看用户选的那个', (tester) async {
    await open(
      tester,
      curve: (query) => curveFixture(standardMetric: 'WEIGHT_LENGTH'),
    );

    expect(find.text('身高 的百分位曲线'), findsOneWidget);
    expect(find.text('2 岁以下按身长 · 横轴：身长 / 身高（cm）'), findsOneWidget);
  });

  testWidgets('年龄别指标那一张没有口径说明，横轴写的是月龄', (tester) async {
    await open(tester);

    expect(find.text('横轴：月龄（月）'), findsOneWidget);
  });

  testWidgets('五个可选指标各一枚 chip，身长那张表不在其中', (tester) async {
    await open(tester);

    expect(find.byType(ChoiceChip), findsNWidgets(5));
    for (final label in const ['身高', '体重', '体重别身高', 'BMI', '头围']) {
      expect(find.text(label), findsOneWidget);
    }
    // 它是服务端按年龄选的那张表，用户选错了会得到一段与表无关的百分位（§1.4 第 23 条）。
    expect(find.text('身长'), findsNothing);
  });

  testWidgets('换一枚 chip 换的是新指标那一份，横轴那句跟着走', (tester) async {
    final queries = <BabyCurveQuery>[];
    await open(
      tester,
      curve: (query) {
        queries.add(query);
        return curveFixture(
          metric: query.metric,
          standardMetric: 'WEIGHT_HEIGHT',
        );
      },
    );
    expect(queries.single, (babyId: 1, metric: 'HEIGHT'));

    await tester.tap(find.text('体重别身高'));
    await tester.pumpAndSettle();

    expect(queries.last.metric, 'WEIGHT_HEIGHT');
    expect(find.text('体重别身高 的百分位曲线'), findsOneWidget);
    expect(find.text('2 岁以上按身高 · 横轴：身长 / 身高（cm）'), findsOneWidget);
  });

  testWidgets('图支持横向缩放：双指放大、左右拖动，上限 10 倍（问题单 6）', (tester) async {
    await open(tester);

    final config = tester.widget<LineChart>(find.byType(LineChart)).transformationConfig;
    expect(config.scaleAxis, FlScaleAxis.horizontal, reason: '只放大横轴，早期密集的点才能拉开');
    expect(config.minScale, 1);
    expect(config.maxScale, 10);
    expect(config.panEnabled, isTrue);
    expect(config.scaleEnabled, isTrue);
    expect(config.transformationController, isNotNull);
  });

  testWidgets('成长小结：最近一次测量读出百分位区间与正常范围口径（问题单 7）', (tester) async {
    await open(tester);

    // curveFixture 默认两个点，最后一个是 12 月龄、P50–P75。
    expect(find.text('成长小结'), findsOneWidget);
    expect(
      find.textContaining(
        '身高 最近一次（2026-09-10 · 月龄 12） 为 76.5 cm，处于 P50–P75 区间',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('P3–P97 之间均属常见参考范围'), findsOneWidget);
  });

  testWidgets('成长小结：超出标准表那一点给一句「未能给出百分位区间」', (tester) async {
    await open(
      tester,
      curve: (query) =>
          curveFixture(points: [curvePointFixture(percentileBand: null)]),
    );

    expect(find.text('成长小结'), findsOneWidget);
    expect(
      find.textContaining('已超出标准表的覆盖范围，未能给出百分位区间'),
      findsOneWidget,
    );
  });

  testWidgets('免责声明折着的时候不占地方，点开才出文案', (tester) async {
    await open(tester);

    expect(find.text('数据来源与免责声明'), findsOneWidget);
    expect(find.textContaining('仅供参考，不作为医学诊断依据'), findsNothing);

    await tester.ensureVisible(find.text('数据来源与免责声明'));
    await tester.tap(find.text('数据来源与免责声明'));
    await tester.pumpAndSettle();

    expect(find.textContaining('仅供参考，不作为医学诊断依据'), findsOneWidget);
  });

  testWidgets('离线时挂一条横幅', (tester) async {
    await open(tester, network: NetworkStatus.offline);

    expect(find.byType(OfflineBanner), findsOneWidget);
  });

  testWidgets('档位拿到 null 时说「已超出标准表覆盖范围」，那不是缺数据', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: PercentileBand(band: null))),
      ),
    );
    expect(find.text('已超出标准表覆盖范围'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: PercentileBand(band: 'P50–P75')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('P50–P75'), findsOneWidget);
    expect(find.text('已超出标准表覆盖范围'), findsNothing);
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

/// 曲线是按 `(babyId, metric)` 取的一条：替身把工厂交回来，换指标就是一个新的键。
class _StubCurve extends BabyCurveViewModel {
  _StubCurve(this.builds, BabyCurveQuery query) : super(query);

  final BabyCurve Function(BabyCurveQuery query) builds;

  @override
  Future<BabyCurve?> build() async => builds(query);
}

class _FixedNetworkStatus extends NetworkStatusNotifier {
  _FixedNetworkStatus(this.status);

  final NetworkStatus status;

  @override
  NetworkStatus build() => status;
}
