import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/services/token_storage.dart';
import 'package:homeledger/ui/features/auth/views/login_page.dart';

import '../../../support/fake_token_storage.dart';

Widget _wrap(TokenStorage storage) => ProviderScope(
  overrides: [tokenStorageProvider.overrideWithValue(storage)],
  child: const MaterialApp(home: LoginPage()),
);

void main() {
  testWidgets('退出登录后保留的登录名会自动填上（§4.1.2）', (tester) async {
    await tester.pumpWidget(_wrap(FakeTokenStorage(lastPhone: '13900000001')));
    await tester.pumpAndSettle();

    expect(find.text('13900000001'), findsOneWidget);
  });

  testWidgets('手机号格式不对时当场拦下', (tester) async {
    await tester.pumpWidget(_wrap(FakeTokenStorage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, '手机号'), '123');
    await tester.tap(find.widgetWithText(FilledButton, '登录'));
    await tester.pumpAndSettle();

    expect(find.text('请输入 11 位手机号'), findsOneWidget);
  });

  testWidgets('密码为空时不当成格式错误', (tester) async {
    await tester.pumpWidget(_wrap(FakeTokenStorage()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, '手机号'),
      '13900000001',
    );
    await tester.tap(find.widgetWithText(FilledButton, '登录'));
    await tester.pumpAndSettle();

    expect(find.text('请输入密码'), findsOneWidget);
    expect(find.text('密码需同时包含字母和数字'), findsNothing);
  });
}
