import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/module_preference.dart';
import 'package:homeledger/data/repositories/module_preference_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/settings/views/module_page.dart';

import '../../../../support/s9_fixtures.dart';

class _FakeModuleRepository implements ModulePreferenceRepository {
  _FakeModuleRepository(this.rows);

  List<ModulePreference> rows;

  final List<List<ModulePreferenceItem>> saved = [];

  Object? failure;

  @override
  Future<List<ModulePreference>> modules() async => rows;

  @override
  Future<void> saveModules(List<ModulePreferenceItem> items) async {
    final error = failure;
    if (error != null) throw error;
    saved.add(items);
    // 服务端按数组顺序重排 sortNo，替身也照这条改，否则「写完重拉」拿到的还是旧顺序
    rows = [
      for (var i = 0; i < items.length; i++)
        ModulePreference(
          moduleKey: items[i].moduleKey,
          label: _labelOf(items[i].moduleKey),
          enabled: items[i].enabled,
          sortNo: i,
        ),
    ];
  }

  static String _labelOf(String moduleKey) => switch (moduleKey) {
    'FINANCE' => '记账',
    'CAT' => '猫咪',
    _ => '宝宝',
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

Future<_FakeModuleRepository> _open(
  WidgetTester tester, {
  List<ModulePreference>? rows,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final repository = _FakeModuleRepository(rows ?? modulePreferences());
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
        modulePreferenceRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: ModulePage()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

List<String> _rowLabels(WidgetTester tester) => tester
    .widgetList<ListTile>(find.byType(ListTile))
    .map((tile) => (tile.title! as Text).data!)
    .toList();

List<bool> _switches(WidgetTester tester) => tester
    .widgetList<Switch>(find.byType(Switch))
    .map((row) => row.value)
    .toList();

void main() {
  testWidgets('三个模块各一行，开关状态与服务端一致，顺序也照服务端的 sortNo', (tester) async {
    await _open(
      tester,
      rows: [
        ModulePreference(moduleKey: 'BABY', label: '宝宝', enabled: true, sortNo: 0),
        ModulePreference(moduleKey: 'FINANCE', label: '记账', enabled: false, sortNo: 1),
        ModulePreference(moduleKey: 'CAT', label: '猫咪', enabled: true, sortNo: 2),
      ],
    );

    expect(_rowLabels(tester), ['宝宝', '记账', '猫咪']);
    expect(_switches(tester), [true, false, true]);
  });

  testWidgets('拨一个开关：交上去的是整份三项，没被拨的保持原值（顺序照默认：记账→宝宝→猫咪，问题单 8）', (tester) async {
    final repository = await _open(tester);

    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();

    final items = repository.saved.single;
    expect(items.map((item) => item.moduleKey), ['FINANCE', 'BABY', 'CAT']);
    expect(items.map((item) => item.enabled), [true, false, true]);
  });

  testWidgets('写失败不本地改序：界面回到原来那份，并说一句', (tester) async {
    final repository = await _open(tester);
    repository.failure = const ApiException(
      code: 'BAD_REQUEST',
      message: '不认识的模块：STOCK',
    );

    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();

    expect(find.text('不认识的模块：STOCK'), findsOneWidget);
    expect(_switches(tester), [true, true, true], reason: '服务端没收下，界面不许自己认了');
  });

  testWidgets('拖拽换序：交上去的顺序跟着变，重拉之后界面也是新顺序', (tester) async {
    final repository = await _open(tester);

    // `tester.drag` 一步到位，而可重排列表要的是「按下 → 分几步移动 → 抬起」：
    // 一次性的位移常常还没被识别成拖拽就已经结束了
    final handle = find.byIcon(Icons.drag_handle).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    final items = repository.saved.single;
    expect(items.first.moduleKey, isNot('FINANCE'), reason: '记账被拖到了后面');
    expect(_rowLabels(tester), isNot(['记账', '猫咪', '宝宝']));
  });
}
