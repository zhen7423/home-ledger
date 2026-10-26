import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/baby.dart';
import 'package:homeledger/data/repositories/baby_repository.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/views/baby_list_page.dart';

import '../../../../support/fake_baby_repository.dart';
import '../../../../support/s7_fixtures.dart';

/// §4.4.1 的档案清单。这一页的「显示已归档」是一个**纯界面过滤**（一次请求把两份都装进来），
/// 而归档与删除共用一个菜单、判断方向只看当前 `archived`——三处都容易改错而界面上看不出来。
void main() {
  late FakeBabyRepository repo;

  Future<void> open(WidgetTester tester, {List<Baby>? rows}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    repo = FakeBabyRepository(rows: rows ?? [babyFixture()]);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
          babyRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: BabyListPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickMenu(WidgetTester tester, String label) async {
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('默认只列在册的，归档的要打开开关才出现', (tester) async {
    await open(
      tester,
      rows: [
        babyFixture(),
        babyFixture(
          id: 2,
          name: '小红',
          birthDate: DateTime(2024, 5, 1),
          ageText: '2 岁 4 个月',
          archived: true,
        ),
      ],
    );

    expect(find.text('小明'), findsOneWidget);
    expect(find.text('小红'), findsNothing);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.text('小红'), findsOneWidget);
    expect(find.text('已归档'), findsOneWidget, reason: '开关打开后才看得到那枚徽章');
    // 开关不动任何请求：两份本来就在那一次 `includeArchived: true` 里。
    expect(repo.listCalls, 1);
  });

  testWidgets('一个在册的都没有时提示去看已归档，而不是说档案丢了', (tester) async {
    await open(tester, rows: [babyFixture(archived: true)]);

    expect(find.text('在册的宝宝一个都没有，打开上面的开关看已归档的'), findsOneWidget);
    expect(find.text('还没有宝宝档案'), findsNothing);
  });

  testWidgets('一条档案都没有时说还没有档案，并给建档入口', (tester) async {
    await open(tester, rows: const []);

    expect(find.text('还没有宝宝档案'), findsOneWidget);
    expect(find.text('建档'), findsOneWidget);
  });

  testWidgets('归档先问一句，取消就什么都不发', (tester) async {
    await open(tester);

    await pickMenu(tester, '归档');
    expect(find.text('归档「小明」？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(repo.toggles, isEmpty);
  });

  testWidgets('确认后归档的是这一个宝宝', (tester) async {
    await open(tester);

    await pickMenu(tester, '归档');
    await tester.tap(find.text('归档'));
    await tester.pumpAndSettle();

    expect(repo.toggles, [1]);
  });

  testWidgets('已归档那行的菜单说的是恢复到册，方向由当前状态判', (tester) async {
    await open(tester, rows: [babyFixture(archived: true)]);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await pickMenu(tester, '恢复到册');

    expect(find.text('把「小明」恢复到册？'), findsOneWidget);
  });

  testWidgets('删除的确认框把那句「有记录时只能归档」说出来', (tester) async {
    await open(tester);

    await pickMenu(tester, '删除');
    expect(find.text('名下已有身高体重、疫苗或就诊记录时删不掉，只能归档。删除后无法恢复。'), findsOneWidget);

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(repo.removes, [1]);
  });
}

class _AlwaysSignedIn extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}
