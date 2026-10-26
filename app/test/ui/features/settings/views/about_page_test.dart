import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/router/app_router.dart';
import 'package:homeledger/ui/features/baby/baby_copy.dart';
import 'package:homeledger/ui/features/settings/legal_copy.dart';
import 'package:homeledger/ui/features/settings/views/about_page.dart';
import 'package:homeledger/ui/features/settings/views/legal_page.dart';

/// §4.7 的「关于」：版本、协议、隐私、数据来源与免责、以及藏在长按后面的服务端地址。
Future<void> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: RoutePath.about,
    routes: [
      GoRoute(
        path: RoutePath.about,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: RoutePath.terms,
        builder: (context, state) =>
            const LegalPage(title: legalTermsTitle, paragraphs: legalTerms),
      ),
      GoRoute(
        path: RoutePath.privacy,
        builder: (context, state) => const LegalPage(
          title: legalPrivacyTitle,
          paragraphs: legalPrivacy,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('版本号挂在页面上，服务端地址不露出来', (tester) async {
    await _open(tester);

    expect(find.text('版本 $appVersion'), findsOneWidget);
    expect(find.text('服务端地址'), findsNothing);
  });

  testWidgets('长按版本号五次才露出服务端地址', (tester) async {
    await _open(tester);

    for (var i = 0; i < 4; i++) {
      await tester.longPress(find.text('版本 $appVersion'));
      await tester.pumpAndSettle();
    }
    expect(find.text('服务端地址'), findsNothing, reason: '四下还不够');

    await tester.longPress(find.text('版本 $appVersion'));
    await tester.pumpAndSettle();

    expect(find.text('服务端地址'), findsOneWidget);
    expect(find.text(ApiClient.defaultOrigin), findsOneWidget);
  });

  testWidgets('点用户协议进正文页，正文来自那份常量', (tester) async {
    await _open(tester);

    await tester.tap(find.text(legalTermsTitle));
    await tester.pumpAndSettle();

    expect(find.text(legalTerms.first), findsOneWidget);
  });

  testWidgets('隐私政策是另一页，内容与协议不同', (tester) async {
    await _open(tester);

    await tester.tap(find.text(legalPrivacyTitle));
    await tester.pumpAndSettle();

    expect(find.text(legalPrivacy.first), findsOneWidget);
  });

  testWidgets('数据来源与免责声明复用宝宝模块那一份常量，不另写第三段', (tester) async {
    await _open(tester);

    await tester.tap(find.text('数据来源与免责声明'));
    await tester.pumpAndSettle();

    expect(find.text(babyDataDisclaimer), findsOneWidget);
  });

  testWidgets('忘记密码那段把「本期没有短信通道」说清楚', (tester) async {
    await _open(tester);

    await tester.tap(find.text('忘记密码怎么办'));
    await tester.pumpAndSettle();

    expect(find.textContaining('不能自助找回密码'), findsOneWidget);
  });
}
