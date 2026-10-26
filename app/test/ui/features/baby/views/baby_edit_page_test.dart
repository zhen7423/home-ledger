import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeledger/data/models/baby.dart';
import 'package:homeledger/data/repositories/baby_repository.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/core/profile_photo_field.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/baby/views/baby_edit_page.dart';

import '../../../../support/fake_baby_repository.dart';
import '../../../../support/s7_fixtures.dart';

/// §4.4.1 的建档与编辑（常态是新增）。出生日期是必填但它是 `ListTile` 而不是 `TextFormField`，
/// 所以它那一条错误自己装着——「服务端会拒」不能替掉这一句，用户要当场看见哪一格不对。
void main() {
  late FakeBabyRepository repo;

  /// 建档页那一屏是真路由器的一层子路由：「没找到这个宝宝」那一支要 `context.pop()` 退回，
  /// 而它得有个上一屏可退。
  Future<void> open(WidgetTester tester, {int? id, List<Baby>? rows}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    repo = FakeBabyRepository(rows: rows ?? [babyFixture()]);
    final router = _router(id);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedIn.new),
          babyRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> setText(WidgetTester tester, String label, String value) async {
    await tester.enterText(find.widgetWithText(TextFormField, label), value);
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
  }

  /// 输入框当前显示的那一份。`initialValue` 建的控制器在 State 里，widget 上取不到。
  String fieldText(WidgetTester tester, String label) => tester
      .widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextFormField, label),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;

  /// 出生日期那一格今天点不到别处去，选中的就是「今天」。
  Future<void> pickBirthDate(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.cake_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('建档：姓名与出生日期缺一个都不行，一次请求都不发', (tester) async {
    await open(tester);

    await save(tester);

    expect(find.text('请输入昵称'), findsOneWidget);
    expect(find.text('请选择出生日期'), findsOneWidget);
    expect(repo.creates, isEmpty);
  });

  testWidgets('出生身高多一位小数就拦下，不留给 MySQL 悄悄四舍五入', (tester) async {
    await open(tester);
    await setText(tester, '出生身高（cm，选填）', '50.55');

    await save(tester);

    expect(find.text('出生身高最多一位小数'), findsOneWidget);
    expect(repo.creates, isEmpty);
  });

  testWidgets('填齐了两格能存：草稿就是这两格，存完留在本页说已建档', (tester) async {
    await open(tester);
    await setText(tester, '姓名/小名', '朵朵');
    await pickBirthDate(tester);

    await save(tester);

    expect(repo.creates.single.name, '朵朵');
    // 保存成功不自动跳：跳回去会把「已建档」这句反馈一起吃掉（归档与删除才有下一个落点）。
    expect(find.text('已建档'), findsOneWidget);
    expect(find.text('宝宝建档'), findsOneWidget);
  });

  testWidgets('性别默认男宝，切到女宝之后提交的是女宝', (tester) async {
    await open(tester);
    await setText(tester, '姓名/小名', '朵朵');
    await pickBirthDate(tester);

    await tester.tap(find.text('女宝'));
    await tester.pumpAndSettle();
    await save(tester);

    expect(repo.creates.single.gender, 'FEMALE');
  });

  testWidgets('编辑态回填既有档案，改生日先问一句', (tester) async {
    await open(tester, id: 1);

    expect(fieldText(tester, '姓名/小名'), '小明');
    expect(find.text('2025-09-16'), findsOneWidget);
    expect(find.text('编辑宝宝'), findsOneWidget);

    // 挪一天：生日一移，服务端要在同一事务里整份重算应种清单，比其它字段重得多。
    await tester.tap(find.byIcon(Icons.cake_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await save(tester);

    expect(find.text('改了出生日期'), findsOneWidget);
    expect(repo.updates, isEmpty, reason: '还没点「继续保存」');
  });

  testWidgets('生日那一问点了继续保存才真的提交', (tester) async {
    await open(tester, id: 1);
    await tester.tap(find.byIcon(Icons.cake_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await save(tester);
    await tester.tap(find.text('继续保存'));
    await tester.pumpAndSettle();

    expect(repo.updates.single.id, 1);
    expect(find.text('已保存'), findsOneWidget);
  });

  testWidgets('不动生日的编辑不问那一句', (tester) async {
    await open(tester, id: 1);
    await setText(tester, '出生体重（kg，选填）', '3.50');

    await save(tester);

    expect(find.text('改了出生日期'), findsNothing);
    expect(repo.updates.single.draft.birthWeight, '3.50');
  });

  testWidgets('没找到这个宝宝时说一声并退回，不摆一张空表单', (tester) async {
    // 既有的记录挂的宝宝被删掉时才走得到这里（归档不会：归档的宝宝仍在列表里）。
    await open(tester, id: 99, rows: [babyFixture()]);

    expect(find.text('没有找到这个宝宝，它可能已经被删除了'), findsOneWidget);
    expect(find.text('上一屏'), findsOneWidget);
  });

  // 照片挂在已存在的 baby id 上（POST /babies/{id}/photo）：建档态没有 id，
  // 渲染出上传入口只会把 widget.id! 撞爆（S10 审查 C1），所以入口该整块不出现。
  testWidgets('建档态不渲染照片入口，免撞 widget.id!', (tester) async {
    await open(tester);

    expect(find.byType(ProfilePhotoField), findsNothing);
    expect(find.text('上传照片'), findsNothing);
  });

  testWidgets('编辑态才出现照片入口', (tester) async {
    await open(tester, id: 1);

    expect(find.byType(ProfilePhotoField), findsOneWidget);
    expect(find.text('上传照片'), findsOneWidget);
  });
}

/// 建档页是 `/` 的一层子路由：`initialLocation` 直接落在子路由上，`pop()` 就有上一屏可退。
GoRouter _router(int? id) => GoRouter(
  initialLocation: RoutePath.babyEdit,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const _Placeholder('上一屏'),
      routes: [
        GoRoute(
          path: RoutePath.babyEdit.substring(1),
          builder: (context, state) => BabyEditPage(id: id),
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
