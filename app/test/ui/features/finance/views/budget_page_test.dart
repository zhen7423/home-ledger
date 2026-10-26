import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/budget.dart';
import 'package:homeledger/data/models/budget_progress.dart';
import 'package:homeledger/data/models/category.dart';
import 'package:homeledger/data/models/family.dart';
import 'package:homeledger/data/models/flow_type.dart';
import 'package:homeledger/data/models/member.dart';
import 'package:homeledger/data/repositories/budget_repository.dart';
import 'package:homeledger/data/repositories/category_repository.dart';
import 'package:homeledger/data/repositories/family_repository.dart';
import 'package:homeledger/data/services/network_status.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/finance/views/budget_page.dart';

import '../../../../support/s4_fixtures.dart';

/// 两个启用大类、一个停用大类，外加一个收入大类。
const _categories = [
  Category(
    id: 1,
    type: FlowType.expense,
    name: '餐饮',
    sortNo: 1,
    enabled: true,
    preset: true,
  ),
  Category(
    id: 2,
    type: FlowType.expense,
    name: '交通',
    sortNo: 2,
    enabled: true,
    preset: true,
  ),
  Category(
    id: 3,
    type: FlowType.expense,
    name: '娱乐',
    sortNo: 3,
    enabled: false,
    preset: true,
  ),
  Category(
    id: 4,
    type: FlowType.income,
    name: '工资',
    sortNo: 1,
    enabled: true,
    preset: true,
  ),
];

List<Member> get _members => [
  Member(
    userId: 10,
    nickname: '小明',
    role: MemberRole.owner,
    joinedAt: DateTime(2026, 9, 10),
  ),
  Member(
    userId: 11,
    nickname: '阿芳',
    role: MemberRole.member,
    joinedAt: DateTime(2026, 9, 11),
  ),
];

class _FakeBudgetRepository implements BudgetRepository {
  _FakeBudgetRepository({required this.rows, required this.progresses});

  List<Budget> rows;
  final List<BudgetProgress> progresses;

  final List<List<BudgetDraftItem>?> saves = [];

  /// 摆出「清单还在路上」的那一刻用的：非空时 `list()` 就停在那里不返回
  Completer<void>? holdList;

  @override
  Future<List<Budget>> list() async {
    await holdList?.future;
    return rows;
  }

  @override
  Future<void> save(List<BudgetDraftItem>? items) async {
    saves.add(items);
    // 后端先删光再重插，id 换一批：替身照这个来，省得测试以为 id 能当 key 用
    rows = [
      for (final (index, item) in (items ?? const <BudgetDraftItem>[]).indexed)
        budget(
          id: index + 1,
          scope: item.scope,
          categoryId: item.categoryId,
          memberUserId: item.memberUserId,
          amount: item.amount,
        ),
    ];
  }

  @override
  Future<List<BudgetProgress>> progress({String? month}) async => progresses;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Future<CategoryTreeResult> tree() async =>
      const CategoryTreeResult(_categories, fromCache: false);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeFamilyRepository implements FamilyRepository {
  @override
  Future<Family?> current() async => Family(
    id: 1,
    name: '小明的家',
    ownerUserId: 10,
    inviteEnabled: true,
    inviteCode: '228286',
    inviteCodeExpireAt: DateTime(2026, 9, 17),
    members: _members,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

/// 三行都设过额度：家庭 / 餐饮大类 / 成员阿芳。
List<Budget> get _threeRows => [
  budget(id: 1, amount: '5000.00'),
  budget(
    id: 2,
    scope: 'CATEGORY',
    categoryId: 1,
    categoryName: '餐饮',
    amount: '2000.00',
  ),
  budget(
    id: 3,
    scope: 'MEMBER',
    memberUserId: 11,
    memberName: '阿芳',
    amount: '1500.00',
  ),
];

/// 三个维度各一档进度，颜色那条用例一次把三档都拍下来。
List<BudgetProgress> get _threeLevels => [
  budgetProgress(
    scope: 'FAMILY',
    amount: '5000.00',
    used: '2000.00',
    remaining: '3000.00',
    usedPercent: 40,
  ),
  budgetProgress(
    scope: 'CATEGORY',
    categoryName: '餐饮',
    amount: '2000.00',
    used: '1640.00',
    remaining: '360.00',
    usedPercent: 82,
    level: 'WARNING',
  ),
  budgetProgress(
    scope: 'MEMBER',
    memberName: '阿芳',
    amount: '1500.00',
    used: '1620.00',
    remaining: '-120.00',
    usedPercent: 108,
    level: 'EXCEEDED',
  ),
];

Future<_FakeBudgetRepository> _open(
  WidgetTester tester, {
  List<Budget>? rows,
  List<BudgetProgress>? progresses,
  Completer<void>? holdList,
  NetworkStatus? network,
}) async {
  // 默认 800x600 的测试窗口比手机矮，这一页底部那条保存栏会挤出视口
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final repo = _FakeBudgetRepository(
    rows: rows ?? _threeRows,
    progresses: progresses ?? _threeLevels,
  )..holdList = holdList;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
        budgetRepositoryProvider.overrideWithValue(repo),
        categoryRepositoryProvider.overrideWithValue(_FakeCategoryRepository()),
        familyRepositoryProvider.overrideWithValue(_FakeFamilyRepository()),
        if (network != null)
          networkStatusProvider.overrideWith(
            () => _FixedNetworkStatus(network),
          ),
      ],
      child: const MaterialApp(home: BudgetPage()),
    ),
  );
  // 清单停住时没有「稳定」可言，pumpAndSettle 会一直等到超时
  if (holdList == null) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return repo;
}

/// 真那份要等一次失败的请求才翻状态，页面测试里不必绕这一圈。
class _FixedNetworkStatus extends NetworkStatusNotifier {
  _FixedNetworkStatus(this.status);

  final NetworkStatus status;

  @override
  NetworkStatus build() => status;
}

Future<void> _setAmount(WidgetTester tester, String label, String value) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), value);
  await tester.pump();
}

Future<void> _tapSave(WidgetTester tester) async {
  final save = find.widgetWithText(FilledButton, '保存');
  await tester.scrollUntilVisible(
    save,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(save);
  await tester.pumpAndSettle();
}

/// 输入框当前显示的那一份。`initialValue` 建的控制器在 State 里，widget 上取不到。
String _fieldText(WidgetTester tester, String label) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, label),
        matching: find.byType(EditableText),
      ),
    )
    .controller
    .text;

/// 颜色按分量比：`Color.toString()` 的格式在 Flutter 版本间变过。
String _argb(Color color) => '${color.a},${color.r},${color.g},${color.b}';

void main() {
  testWidgets('三个维度各摆一行额度，值取服务端那份', (tester) async {
    await _open(tester);

    expect(_fieldText(tester, '家庭总预算'), '5000.00');
    expect(_fieldText(tester, '餐饮'), '2000.00');
    expect(_fieldText(tester, '阿芳'), '1500.00');
  });

  testWidgets('家庭那一行不给删：三行额度里只有它是常驻的', (tester) async {
    await _open(tester);

    // 三行、两把删除，少的那一把就是家庭那行——它没有可删一说，留空即不设预算
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
  });

  testWidgets('进度条按档位上色：正常 primary、预警橙、超支 error', (tester) async {
    await _open(tester);

    final scheme = Theme.of(
      tester.element(find.byType(BudgetPage)),
    ).colorScheme;
    final bars = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .toList();

    expect(bars, hasLength(3));
    expect(_argb(bars[0].color!), _argb(scheme.primary));
    expect(_argb(bars[1].color!), _argb(Colors.orange));
    expect(_argb(bars[2].color!), _argb(scheme.error));
    // 档位文案也走同一处：管理页与首页不能一个说超支一个说快到了
    expect(find.text('已超支'), findsOneWidget);
    expect(find.text('即将超支'), findsOneWidget);
  });

  testWidgets('留空的行不交上去，其余照原样全量提交', (tester) async {
    final repo = await _open(tester);
    await _setAmount(tester, '阿芳', '');

    await _tapSave(tester);

    final items = repo.saves.single!;
    expect(items.map((item) => item.scope), ['FAMILY', 'CATEGORY']);
    expect(find.text('已保存'), findsOneWidget);
  });

  testWidgets('删掉一行就是把它从全量清单里去掉', (tester) async {
    final repo = await _open(tester);
    // 删除按钮按「类别行在前、成员行在后」摆，第一个是餐饮
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, '餐饮'), findsNothing);

    await _tapSave(tester);

    expect(repo.saves.single!.map((item) => item.scope), ['FAMILY', 'MEMBER']);
  });

  testWidgets('额度填成 0 当场拦下，一次请求都不发', (tester) async {
    final repo = await _open(tester);
    await _setAmount(tester, '家庭总预算', '0');

    await _tapSave(tester);

    expect(find.text('金额要大于 0'), findsOneWidget);
    expect(repo.saves, isEmpty);
  });

  testWidgets('三行全清空交上去的是空清单，不是「没提交」', (tester) async {
    final repo = await _open(tester);
    for (final label in ['家庭总预算', '餐饮', '阿芳']) {
      await _setAmount(tester, label, '');
    }

    await _tapSave(tester);

    expect(repo.saves.single, isEmpty);
  });

  testWidgets('清单还在路上时保存按不下去', (tester) async {
    // 那时 `_draft` 只有家庭一行，提交会把另外两个维度当成被用户删掉
    final repo = await _open(tester, holdList: Completer<void>());

    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '保存'),
    );
    expect(save.onPressed, isNull);
    expect(repo.saves, isEmpty);
  });

  testWidgets('添加类别预算时停用的大类也在里面，还标着已停用', (tester) async {
    final repo = await _open(tester);

    await tester.tap(find.widgetWithText(TextButton, '添加').first);
    await tester.pumpAndSettle();
    expect(find.text('娱乐（已停用）'), findsOneWidget);
    await tester.tap(find.text('娱乐（已停用）'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, '娱乐'), findsOneWidget);
    await _setAmount(tester, '娱乐', '800');
    await _tapSave(tester);

    final added = repo.saves.single!.firstWhere(
      (item) => item.scope == 'CATEGORY' && item.categoryId == 3,
    );
    expect(added.amount, '800');
  });

  testWidgets('收入大类不进预算弹窗：三个维度都只统计支出', (tester) async {
    await _open(tester);

    await tester.tap(find.widgetWithText(TextButton, '添加').first);
    await tester.pumpAndSettle();

    expect(find.text('工资'), findsNothing);
  });

  testWidgets('刚点添加就空着保存，说清楚而不是静默丢掉', (tester) async {
    final repo = await _open(tester);
    await tester.tap(find.widgetWithText(TextButton, '添加').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('交通'));
    await tester.pumpAndSettle();

    await _tapSave(tester);

    expect(find.text('「交通」的额度还没填，填一个再保存'), findsOneWidget);
    expect(repo.saves, isEmpty);
  });

  testWidgets('成员都设过了就直说，不再弹一个空弹窗', (tester) async {
    await _open(
      tester,
      rows: [
        budget(id: 1),
        budget(id: 2, scope: 'MEMBER', memberUserId: 10, memberName: '小明'),
        budget(id: 3, scope: 'MEMBER', memberUserId: 11, memberName: '阿芳'),
      ],
    );

    await tester.tap(find.widgetWithText(TextButton, '添加').last);
    await tester.pumpAndSettle();

    expect(find.text('这个维度都已经设过预算了'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('一行预算都没设过时，进度那段给出说明而不是空白', (tester) async {
    await _open(tester, rows: const [], progresses: const []);

    expect(find.text('本月进度'), findsOneWidget);
    expect(find.text('还没有设置预算，设了额度的维度才会出现在这里。'), findsOneWidget);
    // 家庭那行常驻，所以这一页永远至少有一个输入框
    expect(find.widgetWithText(TextFormField, '家庭总预算'), findsOneWidget);
  });

  testWidgets('断网时保存按住，并把为什么点不动写在下面', (tester) async {
    final repo = await _open(tester, network: NetworkStatus.offline);

    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '保存'),
    );
    expect(save.onPressed, isNull);
    expect(find.text('需联网后保存'), findsOneWidget);
    expect(repo.saves, isEmpty);
  });

  testWidgets('网络状态还没查出来时不拦保存', (tester) async {
    // 冷启动那一下按「离线」处理，等于用户一打开 App 就改不了预算
    final repo = await _open(tester, network: NetworkStatus.unknown);

    await _tapSave(tester);

    expect(repo.saves, hasLength(1));
    expect(find.text('需联网后保存'), findsNothing);
  });

  testWidgets('保存那颗是通栏的，不是贴着左边缘的一小条', (tester) async {
    await _open(tester);

    // 360 是这台虚拟设备的逻辑宽度，左右各 16 是那条保存栏自己的内边距
    expect(
      tester.getSize(find.widgetWithText(FilledButton, '保存')).width,
      360 - 32,
    );
  });
}
