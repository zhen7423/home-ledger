import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeledger/data/models/baby.dart';
import 'package:homeledger/data/models/baby_growth.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_growth_view_model.dart';
import 'package:homeledger/ui/features/baby/view_models/baby_list_view_model.dart';
import 'package:homeledger/ui/features/baby/views/baby_growth_list_page.dart';

import '../../../../support/s7_fixtures.dart';

/// §4.4.2 的身高体重列表。两条自己人容易写错的地方：`?babyId=` 过滤时逐行不再重复宝宝名
/// （给了一个人的筛选就说明看的是谁），以及「较上次」那一行在首条上整行不出现。
void main() {
  late _StubGrowth growth;

  Future<void> open(
    WidgetTester tester, {
    int? babyId,
    List<BabyGrowth>? rows,
    List<Baby>? babies,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    growth = _StubGrowth(
      rows ??
          [
            growthFixture(),
            growthFixture(
              id: 101,
              babyId: 2,
              measureDate: DateTime(2026, 8, 20),
              // 首条没有「上一次」，服务端给的这一段就是空的（§4.4.2）。
              delta: null,
            ),
          ],
    );
    final router = _router(babyId);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
          babyListViewModelProvider.overrideWith(
            () => _StubBabies(
              babies ?? [babyFixture(), babyFixture(id: 2, name: '小红')],
            ),
          ),
          babyGrowthViewModelProvider.overrideWith(() => growth),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickMenu(WidgetTester tester, String label) async {
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('不给 babyId 时每行都带宝宝名，名字从档案里现查', (tester) async {
    await open(tester);

    expect(find.text('身高体重'), findsOneWidget);
    expect(find.text('小明 · 2026-09-10'), findsOneWidget);
    expect(find.text('小红 · 2026-08-20'), findsOneWidget);
  });

  testWidgets('给了 babyId 就只列那一个，行里不再重复宝宝名', (tester) async {
    await open(tester, babyId: 1);

    expect(find.text('小明 的身高体重'), findsOneWidget);
    expect(find.text('2026-09-10'), findsOneWidget);
    expect(find.textContaining('小红'), findsNothing);
  });

  testWidgets('横向三列照参考图：表头带单位、数值大字、下面一枚「百分之多少 + 正常」胶囊', (tester) async {
    await open(tester);

    // 两条记录里只有一条有「上一次」：有差值的在 30 天前，首条给「首条记录」而不是一排破折号。
    expect(find.text('距上次 30 天'), findsOneWidget);
    expect(find.text('首条记录，还没有上次可比'), findsOneWidget);

    // 表头三列各带单位：身高cm / 体重kg / 头围cm。
    expect(find.text('身高'), findsNWidgets(2), reason: '两条记录各一行表头');
    expect(find.text('cm'), findsNWidgets(4), reason: '身高与头围各两条');
    expect(find.text('kg'), findsNWidgets(2));

    // 数值大字（不带单位），差值跟在后面一小格：`76.5 (+1.5)`。
    expect(find.text('76.5'), findsNWidgets(2));
    expect(find.text('(+1.5)'), findsOneWidget);
    expect(find.text('(+0.40)'), findsOneWidget);
    expect(find.text('(+0.5)'), findsOneWidget);

    // 百分比直接写几位数（一位小数），不是 P50–P75 区间；默认两份都是三项全正常。
    expect(find.text('40.5%'), findsNWidgets(2), reason: '身高各两条');
    expect(find.text('25.0%'), findsNWidgets(2), reason: '体重各两条');
    expect(find.text('75.0%'), findsNWidgets(2), reason: '头围各两条');
    expect(find.text('P50–P75'), findsNothing);
    expect(find.text('正常'), findsNWidgets(6), reason: '每个宝宝三项');
  });

  testWidgets('只量了一项时其余两列数值给「--」，百分比与状态两格留空', (tester) async {
    await open(
      tester,
      babyId: 1,
      rows: [
        growthFixture(
          heightCm: null,
          headCm: null,
          weightKg: '9.80',
          delta: const BabyGrowthDelta(days: 30, weightKg: '0.40'),
          percentiles: const BabyPercentiles(weight: '25.0%'),
        ),
      ],
    );

    // 三列里只有体重有数值三段数据，身高与头围两列给「--」且不带百分比与状态标。
    expect(find.text('--'), findsNWidgets(2));
    expect(find.text('9.80'), findsOneWidget);
    expect(find.text('(+0.40)'), findsOneWidget);
    expect(find.text('25.0%'), findsOneWidget);
    expect(find.text('正常'), findsOneWidget);
  });

  testWidgets('超档位与超范围各有各的标：偏低 / 偏高 / 超范围，不再用「正常」冒充', (tester) async {
    await open(
      tester,
      babyId: 1,
      rows: [
        growthFixture(
          percentiles: const BabyPercentiles(
            height: '<3%',
            weight: '>97%',
            headCircumference: '',
          ),
        ),
      ],
    );

    expect(find.text('<3%'), findsOneWidget);
    expect(find.text('偏低'), findsOneWidget);
    expect(find.text('>97%'), findsOneWidget);
    expect(find.text('偏高'), findsOneWidget);
    // 头围量了但超出标准表覆盖范围：胶囊里只出「超范围」。
    expect(find.text('超范围'), findsOneWidget);
    expect(find.text('正常'), findsNothing);
  });

  testWidgets('一条记录都没有时给一句话加一个落点', (tester) async {
    await open(tester, rows: const []);

    expect(find.text('还没有身高体重记录'), findsOneWidget);
    expect(find.text('记下第一次测量，生长曲线与统计才有得算'), findsOneWidget);
  });

  testWidgets('删一条先问一句，那句话点明它会改到别的行', (tester) async {
    await open(tester);
    await pickMenu(tester, '删除');

    expect(find.text('删除 2026-09-10 这条记录？'), findsOneWidget);
    expect(find.text('这个宝宝后面各条的「较上一次」、生长曲线与统计都会跟着重算。删除后无法恢复。'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();

    expect(growth.removed, isEmpty);
  });

  testWidgets('确认之后删的是菜单那一行挂的那条记录', (tester) async {
    await open(tester);
    await pickMenu(tester, '删除');

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(growth.removed, [100]);
  });

  testWidgets('整行点进录入页，菜单里的「编辑」进的是同一页', (tester) async {
    await open(tester);

    await tester.tap(find.text('小明 · 2026-09-10'));
    await tester.pumpAndSettle();
    expect(find.text('身高体重录入'), findsOneWidget);

    // 替身那一屏没有 AppBar，`pageBack()` 找不到返回键；照产品那一句 `context.pop()` 退回。
    GoRouter.of(tester.element(find.text('身高体重录入'))).pop();
    await tester.pumpAndSettle();
    await pickMenu(tester, '编辑');
    expect(find.text('身高体重录入'), findsOneWidget);
  });
}

/// 列表页是 `/` 的一层子路由，录入页挂在同一个父上：整行点击与菜单里的编辑都往那儿走。
GoRouter _router(int? babyId) => GoRouter(
  initialLocation: RoutePath.babyGrowths,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _Placeholder('上一屏'),
      routes: [
        GoRoute(
          path: RoutePath.babyGrowthEdit.substring(1),
          builder: (context, state) => const _Placeholder('身高体重录入'),
        ),
        GoRoute(
          path: RoutePath.babyGrowths.substring(1),
          builder: (context, state) => BabyGrowthListPage(babyId: babyId),
        ),
      ],
    ),
  ],
);

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(text)));
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

class _StubGrowth extends BabyGrowthViewModel {
  _StubGrowth(this.rows);

  final List<BabyGrowth> rows;
  final List<int> removed = [];

  @override
  Future<List<BabyGrowth>> build() async => rows;

  @override
  Future<String?> remove(int id) async {
    removed.add(id);
    return null;
  }
}
