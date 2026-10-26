import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeledger/data/models/family.dart';
import 'package:homeledger/data/models/transaction_page.dart';
import 'package:homeledger/data/repositories/category_repository.dart';
import 'package:homeledger/data/repositories/transaction_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/network_status.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/core/date_format.dart';
import 'package:homeledger/ui/core/offline_banner.dart';
import 'package:homeledger/ui/features/auth/view_models/auth_view_model.dart';
import 'package:homeledger/ui/features/family/view_models/family_view_model.dart';
import 'package:homeledger/ui/features/finance/view_models/category_view_model.dart';
import 'package:homeledger/ui/features/finance/views/transaction_list_page.dart';

import '../../../../support/finance_fixtures.dart';
import '../../../../support/s5_fixtures.dart';

/// 流水列表页。这一页 S5 只添了顶部那条离线横幅，所以测的是「横幅什么时候出现、压在谁上面」；
/// 分组、翻页、筛选那些留给 `transaction_list_view_model_test.dart`。
void main() {
  late _FakeTransactionRepository repo;

  setUp(() {
    repo = _FakeTransactionRepository();
  });

  Future<void> open(WidgetTester tester, {NetworkStatus? network}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: RoutePath.finance,
      routes: [
        GoRoute(
          path: RoutePath.finance,
          builder: (context, state) => const TransactionListPage(),
        ),
        GoRoute(
          path: RoutePath.statistics,
          builder: (context, state) => const _Placeholder('统计页'),
        ),
        GoRoute(
          path: RoutePath.categories,
          builder: (context, state) => const _Placeholder('类别管理页'),
        ),
        GoRoute(
          path: RoutePath.paymentAccounts,
          builder: (context, state) => const _Placeholder('支付方式页'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authViewModelProvider.overrideWith(_AlwaysSignedInAuthViewModel.new),
          transactionRepositoryProvider.overrideWithValue(repo),
          categoryViewModelProvider.overrideWith(_StubCategories.new),
          familyViewModelProvider.overrideWith(_StubFamily.new),
          if (network != null)
            networkStatusProvider.overrideWith(
              () => _FixedNetworkStatus(network),
            ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('这一页拿的是缓存：顶部挂横幅，压在筛选条上面', (tester) async {
    final savedAt = DateTime(2026, 9, 14, 15, 20);
    repo
      ..fromCache = true
      ..savedAt = savedAt;
    await open(tester);

    expect(find.textContaining('离线模式'), findsOneWidget);
    expect(find.textContaining(formatDateTime(savedAt)), findsOneWidget);
    // 横幅是列表的第一个 sliver，筛选条紧随其后：位置关系一翻，用户读到的就是
    // 「下面那一排在描述上面这块内容」，两条说明会互相指错。
    expect(
      tester.getRect(find.byType(OfflineBanner)).top,
      lessThan(tester.getRect(find.byType(ActionChip)).top),
    );
  });

  testWidgets('联网取回的不挂横幅，哪怕此刻是离线状态', (tester) async {
    // 断网时仓库回哪一路是仓库的事：拉成功说明这一页的内容是刚取的，不该标成缓存
    await open(tester, network: NetworkStatus.offline);

    expect(find.byType(OfflineBanner), findsNothing);
  });

  testWidgets('缓存里没有落盘时刻时，横幅只说「离线模式」', (tester) async {
    repo.fromCache = true;
    await open(tester);

    expect(find.text('离线模式'), findsOneWidget);
    expect(find.textContaining('数据截至'), findsNothing);
  });

  testWidgets('拉失败给一句话加一个重试，重试是重走第 1 页', (tester) async {
    repo.error = const ApiException(code: ClientErrorCode.network);
    await open(tester);

    expect(find.text('连不上服务器，请检查网络后重试'), findsOneWidget);
    repo.error = null;

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(repo.queries.last.page, 1);
    expect(find.byIcon(Icons.receipt_long_outlined), findsNothing);
    expect(find.text('餐饮'), findsOneWidget);
  });

  testWidgets('AppBar 第三枚图标进统计页', (tester) async {
    await open(tester);

    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pumpAndSettle();

    expect(find.text('统计页'), findsOneWidget);
  });
}

/// 有内容的一页。横幅挂在列表里，空列表走另一套占位，那样它没有地方摆。
TransactionPage _onePage() => transactionPage(
  page: 1,
  pages: 1,
  records: [tx(id: 1, bizDate: DateTime(2026, 9, 20))],
);

/// 只回一页流水，不走网络。`fromCache` / `savedAt` / `error` 都要能在开页之后改，
/// 因为「错误之后重试」这条得先让它失败一次。
class _FakeTransactionRepository implements TransactionRepository {
  /// `fromCache` / `savedAt` / `error` 都要能在开页之后改，
  /// 因为「错误之后重试」那条得先让它失败一次。
  bool fromCache = false;
  DateTime? savedAt;
  ApiException? error;
  final List<TransactionPageQuery> queries = [];

  @override
  Future<TransactionPageResult> page(TransactionPageQuery query) async {
    queries.add(query);
    final thrown = error;
    if (thrown != null) throw thrown;
    return pageResult(_onePage(), fromCache: fromCache, savedAt: savedAt);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _AlwaysSignedInAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: SessionStatus.signedIn);
}

class _StubCategories extends CategoryViewModel {
  @override
  Future<CategoryTreeResult> build() async =>
      CategoryTreeResult(categories(), fromCache: false);
}

class _StubFamily extends FamilyViewModel {
  @override
  Future<Family?> build() async => family();
}

/// 真那份要等一次失败的请求才翻状态，页面测试里不必绕这一圈。
class _FixedNetworkStatus extends NetworkStatusNotifier {
  _FixedNetworkStatus(this.status);

  final NetworkStatus status;

  @override
  NetworkStatus build() => status;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(text)));
}
