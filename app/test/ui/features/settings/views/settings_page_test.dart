import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeledger/data/models/family.dart';
import 'package:homeledger/data/models/pending_reminder.dart';
import 'package:homeledger/data/models/reminder_setting.dart';
import 'package:homeledger/data/repositories/reminder_repository.dart';
import 'package:homeledger/data/services/reminder_notifier.dart';
import 'package:homeledger/data/services/reminder_state_store.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/family/view_models/family_view_model.dart';
import 'package:homeledger/ui/features/settings/view_models/local_cache_view_model.dart';
import 'package:homeledger/ui/features/settings/views/settings_page.dart';

import '../../../../support/fake_reminder_notifier.dart';
import '../../../../support/fake_reminder_state_store.dart';
import '../../../../support/s4_fixtures.dart';
import '../../../../support/s5_fixtures.dart';

/// 设置页的「数据」那一栏（§4.2.7 与 §5.4）。上面几栏是 S2/S3/S4 的入口，这一页 S5 只动了
/// 数据导出那一条路由，所以测的是：三行各就各位、点导出落到不带条件的导出页、
/// 清除缓存问一句再动手、备份说明只是几句话。
void main() {
  late _StubLocalCache cache;
  Uri? exportUri;

  setUp(() {
    cache = _StubLocalCache();
    exportUri = null;
  });

  /// 打开设置页。`exportUri` 是被推到的那条地址，测试靠它看「数据导出」带了什么条件。
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: RoutePath.settings,
      routes: [
        GoRoute(
          path: RoutePath.settings,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: RoutePath.export,
          builder: (context, state) {
            exportUri = state.uri;
            return const _Placeholder('导出页');
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
          familyViewModelProvider.overrideWith(_StubFamily.new),
          localCacheViewModelProvider.overrideWithValue(cache),
          reminderRepositoryProvider.overrideWithValue(
            _FakeReminderRepository(),
          ),
          reminderNotifierProvider.overrideWith(
            (_) => FakeReminderNotifier(initResult: true),
          ),
          reminderStateStoreProvider.overrideWithValue(
            FakeReminderStateStore(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('「数据」那一栏三行：导出、清缓存、备份说明', (tester) async {
    await open(tester);
    await _reveal(tester, find.text('数据备份说明'));

    expect(find.text('数据'), findsOneWidget);
    expect(find.widgetWithText(ListTile, '数据导出'), findsOneWidget);
    expect(find.widgetWithText(ListTile, '清除本地缓存'), findsOneWidget);
    expect(find.widgetWithText(ListTile, '数据备份说明'), findsOneWidget);
  });

  testWidgets('清缓存与备份说明不带箭头：一个当场办完，一个只是几句话', (tester) async {
    await open(tester);
    await _reveal(tester, find.text('数据备份说明'));

    for (final title in ['清除本地缓存', '数据备份说明']) {
      expect(
        _tile(tester, title).trailing,
        isNull,
        reason: '带箭头是「还有一页」，这两行都不该给人这种预期',
      );
    }
    expect(_tile(tester, '数据导出').trailing, isNotNull);
  });

  testWidgets('从设置进导出页，不带条件，也就是「导出全部」', (tester) async {
    await open(tester);
    await _reveal(tester, find.text('数据导出'));

    await tester.tap(find.widgetWithText(ListTile, '数据导出'));
    await tester.pumpAndSettle();

    expect(find.text('导出页'), findsOneWidget);
    // 统计页那条入口才带条件（`RoutePath.exportWith`）；这一条一个查询参数都不该有
    expect(exportUri!.path, RoutePath.export);
    expect(exportUri!.queryParameters, isEmpty);
  });

  testWidgets('清除本地缓存先问一句，点清除才真清，并回一句话', (tester) async {
    await open(tester);
    await _reveal(tester, find.text('清除本地缓存'));

    await tester.tap(find.widgetWithText(ListTile, '清除本地缓存'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('服务端的数据不受影响'), findsOneWidget);
    expect(cache.clearCalls, 0);

    await tester.tap(find.widgetWithText(FilledButton, '清除'));
    await tester.pumpAndSettle();

    expect(cache.clearCalls, 1);
    expect(find.text('已清除本地缓存'), findsOneWidget);
  });

  testWidgets('反悔了就什么都不做', (tester) async {
    await open(tester);
    await _reveal(tester, find.text('清除本地缓存'));

    await tester.tap(find.widgetWithText(ListTile, '清除本地缓存'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(cache.clearCalls, 0);
    expect(find.text('已清除本地缓存'), findsNothing);
  });

  testWidgets('备份说明照 §5.3 报出备份时刻与保留天数，一句话关掉', (tester) async {
    await open(tester);
    await _reveal(tester, find.text('数据备份说明'));

    await tester.tap(find.widgetWithText(ListTile, '数据备份说明'));
    await tester.pumpAndSettle();

    expect(find.textContaining('凌晨 03:00'), findsOneWidget);
    expect(find.textContaining('保留 7 天'), findsOneWidget);

    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}

ListTile _tile(WidgetTester tester, String title) =>
    tester.widget<ListTile>(find.widgetWithText(ListTile, title));

/// 两步：先滚到那一行**被建出来**（ListView 是懒建的，屏幕外那几行不在树里），
/// 再把它**带进可视区**（只用 `scrollUntilVisible` 时，行已经在树里它就一帧都不滚，
/// 点下去的坐标还在屏外）。
Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

/// 只数清了几次。真那份要四份 store，而这一页要验的是「问完一句才把这件事交下去」。
class _StubLocalCache implements LocalCacheViewModel {
  int clearCalls = 0;

  @override
  Future<void> clear() async {
    clearCalls++;
  }
}

/// 待提醒为空：这一页只读它的条数做角标，红点本身归通知设置页测。
class _FakeReminderRepository implements ReminderRepository {
  @override
  Future<List<ReminderSetting>> settings() async => reminderSettings();

  @override
  Future<void> saveSettings(List<ReminderSettingItem> items) async {}

  @override
  Future<List<PendingReminder>> pending() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

class _StubFamily extends FamilyViewModel {
  @override
  Future<Family?> build() async => family();
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(text)));
}
