import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/baby.dart';
import 'package:homeledger/data/models/baby_formula_bag.dart';
import 'package:homeledger/data/models/baby_statistics.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_formula_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_home_view_model.dart';
import 'package:homeledger/ui/features/baby/views/baby_home_page.dart';

import '../../../../support/s7_fixtures.dart';

/// §4.4 的总览。这一屏是三段合一，所以断的是「三段各画在哪儿、先后怎么排」；
/// 待办那一卡的排序（逾期在前、逾期久者在前）与「先建档」那一支是这一页独有的判断，
/// 两处都容易被改坏而界面看着还算正常。
void main() {
  /// 页面的状态直接由替身交出来：这一屏的三段由 `BabyHomeViewModel` 合并，而合并本身
  /// 在 `baby_home_view_model_test.dart` 里验过了（含快照回落）。这里要的是画出来的东西。
  Future<void> open(
    WidgetTester tester,
    BabyHomeState state, {
    List<BabyFormulaBag> formulaRows = const [],
  }) async {
    // 加高视口：奶粉区在总览下半段，默认测试屏（360×800 逻辑像素）装不下，断言前要滚动。
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        // 失败的异步 provider 默认按指数退避重试 10 次，替身里不许出现那种路径。
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
          babyHomeViewModelProvider.overrideWith(() => _StubHome(state)),
          // 奶粉区第 34 轮起读开罐清单 /current 两份：测试各给替身，避免真实 Dio 在 fake 时钟下挂起
          babyFormulaViewModelProvider.overrideWith(() => _StubFormulaRows(formulaRows)),
          babyFormulaCurrentProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: BabyHomePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('档案卡在上、疫苗待办在下（问题单 2），逾期那几行排在临近之前', (tester) async {
    await open(tester, homeState());

    // 问题单 2：总览把「宝宝是谁」放在最前，待办卡退到档案之后。
    final archiveHeader = tester.getRect(find.text('宝宝档案'));
    final todoHeader = tester.getRect(find.text('疫苗待办'));
    expect(archiveHeader.top, lessThan(todoHeader.top));

    // 默认那份里一个宝宝有两条待办：逾期 15 天的脊灰第 3 剂与还有 3 天的百白破第 2 剂
    final overdue = tester.getRect(find.text('小明 · 脊灰疫苗'));
    final upcoming = tester.getRect(find.text('小明 · 百白破疫苗'));
    expect(overdue.top, lessThan(upcoming.top));
    expect(find.text('逾期 15 天'), findsOneWidget);
    expect(find.text('还有 3 天'), findsOneWidget);
  });

  testWidgets('逾期那行右边那句用错误色，临近那行不着色', (tester) async {
    await open(tester, homeState());

    final theme = Theme.of(tester.element(find.byType(BabyHomePage)));
    final scheme = theme.colorScheme;
    expect(
      tester.widget<Text>(find.text('逾期 15 天')).style?.color,
      scheme.error,
    );
    // 染不染红写的是 `overdueDays != null`：拿天数比大小会把「今天到期」也染上（§4.4.4）。
    // 不染那一支传的是 `color: null`，而 `copyWith(color: null)` 是保留原色，所以比的是默认文字色。
    expect(
      tester.widget<Text>(find.text('还有 3 天')).style?.color,
      theme.textTheme.bodyMedium?.color,
    );
  });

  testWidgets('待办卡最多列五行，剩下的由「全部」接过去', (tester) async {
    await open(
      tester,
      homeState(
        vaccineTodo: vaccineStatisticsFixture(
          perBaby: [
            vaccineItemFixture(
              overdueList: const [],
              upcoming: [
                for (var days = 1; days <= 8; days++)
                  planItemFixture(
                    planId: 300 + days,
                    doseNo: '$days',
                    daysToDue: days,
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    // 数「还有 N 天」而不是 ListTile 总数：奶粉区空态也占了一个 ListTile，
    // 数的对象错的话两个区的行数会被加在一起。
    expect(find.text('还有 1 天'), findsOneWidget);
    expect(find.text('还有 5 天'), findsOneWidget);
    expect(find.text('还有 6 天'), findsNothing);
  });

  testWidgets('一条待办都没有时那一卡给一句话，不整块消失', (tester) async {
    await open(
      tester,
      homeState(
        vaccineTodo: vaccineStatisticsFixture(
          perBaby: [
            vaccineItemFixture(upcoming: const [], overdueList: const []),
          ],
        ),
      ),
    );

    expect(find.text('没有临近或逾期的疫苗。到了应种日会在这里提示。'), findsOneWidget);
  });

  testWidgets('宝宝卡带最新体格那一行与三个百分位段', (tester) async {
    await open(tester, homeState());

    expect(find.text('最新体格 · 2026-09-10'), findsOneWidget);
    expect(find.text('身高 76.5 cm'), findsOneWidget);
    expect(find.text('体重 9.80 kg'), findsOneWidget);
    expect(find.text('头围 46.0 cm'), findsOneWidget);
    // 档案与卡片上的那行名片：性别说「男宝」，月龄一个字节都不在前端算（§1.4 第 8 条）。
    expect(find.text('男宝 · 2025-09-16 · 1 岁 0 个月'), findsOneWidget);
  });

  testWidgets('没量过身高体重时卡上说没有，不摆一排破折号', (tester) async {
    await open(
      tester,
      homeState(
        latestGrowth: growthStatisticsFixture(
          perBaby: [growthItemFixture(latest: null)],
        ),
      ),
    );

    expect(find.text('还没有身高体重记录'), findsOneWidget);
    expect(find.text('—'), findsNothing);
  });

  testWidgets('看快照时挂横幅并写明截至时刻', (tester) async {
    await open(
      tester,
      homeState(fromCache: true, savedAt: DateTime(2026, 9, 14, 8, 0)),
    );

    expect(find.text('离线模式 · 数据截至 2026-09-14 08:00'), findsOneWidget);
  });

  testWidgets('连着网取回来的那一份不挂横幅', (tester) async {
    await open(tester, homeState());

    expect(find.textContaining('离线模式'), findsNothing);
  });

  testWidgets('一个宝宝都没有时整屏给出建档入口，曲线那枚图标按住并说明原因', (tester) async {
    await open(tester, homeState(babies: const []));

    expect(find.text('还没有宝宝档案'), findsOneWidget);
    expect(find.text('建档'), findsOneWidget);
    // 按钮变灰说明不了「为什么点不动」（§5.4 同一条规矩），原因写在 tooltip 上。
    final curve = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.show_chart),
    );
    expect(curve.onPressed, isNull);
    expect(curve.tooltip, '先建档一个宝宝');
  });

  testWidgets('有宝宝时曲线工具提示是它自己的名字，统计不要求先选宝宝', (tester) async {
    await open(tester, homeState());

    expect(find.byTooltip('生长曲线'), findsOneWidget);
    expect(find.byTooltip('统计'), findsOneWidget);
  });

  testWidgets('奶粉区从清单取数据：空清单时给「还没有奶粉记录」，含 记一罐 入口', (tester) async {
    await open(tester, homeState());
    await _scrollToFormula(tester);

    expect(find.text('还没有奶粉记录'), findsOneWidget);
    // 节标题与空态各有一个「记一罐」；「全部」出现两次（疫苗待办节也有一个）
    expect(find.text('记一罐'), findsNWidgets(2));
    expect(find.text('全部'), findsNWidgets(2));
  });

  testWidgets('奶粉区最多列三罐，最近三罐在上、当前罐在最上且带「在用」', (tester) async {
    // 清单是开罐日升序（最早在上、当前罐在最后一条），预览应取最后三条并倒过来
    await open(
      tester,
      homeState(),
      formulaRows: [
        // 后端按开罐日升序回（最早在上、当前罐在最后一条）
        _bag(id: 4, brand: '最老一罐', started: DateTime(2026, 6, 1), current: false),
        _bag(id: 1, brand: '最早一罐', started: DateTime(2026, 7, 1), current: false),
        _bag(id: 2, brand: '中间一罐', started: DateTime(2026, 8, 1), current: false),
        _bag(id: 3, brand: '当前一罐', started: DateTime(2026, 9, 1), current: true),
      ],
    );
    await _scrollToFormula(tester);

    // 只显示最近三罐，最老那一罐被挤出总览
    expect(find.text('最早一罐'), findsOneWidget);
    expect(find.text('中间一罐'), findsOneWidget);
    expect(find.text('当前一罐'), findsOneWidget);
    expect(find.text('最老一罐'), findsNothing);
    expect(find.text('在用'), findsOneWidget);

    // 顺序：当前罐的卡片在最上（top 最小），其后是中间、最早
    final currentTop = tester.getTopLeft(find.text('当前一罐'));
    final middleTop = tester.getTopLeft(find.text('中间一罐'));
    final oldestTop = tester.getTopLeft(find.text('最早一罐'));
    expect(currentTop.dy, lessThan(middleTop.dy));
    expect(middleTop.dy, lessThan(oldestTop.dy));
  });

  testWidgets('当前罐那行显示余量推算，历史罐那行显示开罐天数', (tester) async {
    await open(
      tester,
      homeState(),
      formulaRows: [
        _bag(id: 1, brand: '旧罐', started: DateTime(2026, 8, 1), current: false, usageDays: 20),
        _bag(id: 2, brand: '新罐', started: DateTime(2026, 9, 1), current: true, usageDays: null),
      ],
    );
    await _scrollToFormula(tester);

    expect(find.text('2026-09-01 开罐 · 喝了 0 天'), findsNothing); // 当前罐不显示「喝了 0 天」
    expect(find.text('开罐 2026-08-01 开罐 · 喝了 20 天'), findsNothing);
    expect(find.text('2026-08-01 开罐 · 喝了 20 天'), findsOneWidget);
    // /current 替身给 null（没有推算），当前罐那行给「填预计日均后可以推算」的提示
    expect(
      find.textContaining('填开罐时的预计日均后可以推算余量'),
      findsOneWidget,
    );
  });
}

/// 奶粉区在总览页的下半段，先滚到「奶粉」节标题，再多拖一段让三行都进可视区。
Future<void> _scrollToFormula(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('奶粉'),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.drag(find.byType(ListView), const Offset(0, -240));
  await tester.pumpAndSettle();
}

BabyFormulaBag _bag({
  required int id,
  required String brand,
  required DateTime started,
  required bool current,
  int? usageDays,
}) => BabyFormulaBag(
  id: id,
  brand: brand,
  packGrams: 800,
  startedDate: started,
  usageDays: usageDays,
  current: current,
);

/// 三段默认齐全（照 `overviewFixture` 的形状），要哪一段空在调用处覆盖。
BabyHomeState homeState({
  List<Baby>? babies,
  BabyGrowthStatistics? latestGrowth,
  BabyVaccineStatistics? vaccineTodo,
  bool fromCache = false,
  DateTime? savedAt,
}) => BabyHomeState(
  babies: babies ?? [babyFixture()],
  latestGrowth: latestGrowth ?? growthStatisticsFixture(),
  vaccineTodo: vaccineTodo ?? vaccineStatisticsFixture(),
  fromCache: fromCache,
  savedAt: savedAt,
);

class _AlwaysSignedIn extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

/// 奶粉开罐清单的替身：页面只读不写（总览没有记录入口），build 直接交出那排罐即可。
class _StubFormulaRows extends BabyFormulaViewModel {
  _StubFormulaRows(this.rows);

  final List<BabyFormulaBag> rows;

  @override
  Future<List<BabyFormulaBag>> build() async => rows;
}

class _StubHome extends BabyHomeViewModel {
  _StubHome(this.stubbed);

  /// 不能叫 `state`：`AsyncNotifier` 自己有一个 `state`，同名字段会顶掉它。
  final BabyHomeState stubbed;

  @override
  Future<BabyHomeState> build() async => stubbed;
}
