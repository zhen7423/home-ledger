import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/ui/core/dialogs.dart';

/// 单输入框对话框。类别与支付方式那两个页面的「保存」就是这个确定按钮，
/// 所以离线禁用（F7②）要能在没有整页的情况下被验一遍。
void main() {
  late Future<String?> result;

  Future<void> host(
    WidgetTester tester, {
    String? confirmDisabledHint,
    String? Function(String? value)? validator,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  result = promptForText(
                    context,
                    title: '新建类别',
                    label: '名称',
                    validator: validator,
                    confirmDisabledHint: confirmDisabledHint,
                  );
                },
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
  }

  testWidgets('传了禁用提示时确定按钮是灰的，那句话显示在输入框下面', (tester) async {
    await host(tester, confirmDisabledHint: '需联网后保存');

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.text('需联网后保存'), findsOneWidget);
  });

  testWidgets('按回车也绕不过去：确定点不动的时候回车也不提交', (tester) async {
    await host(tester, confirmDisabledHint: '需联网后保存');

    var settled = false;
    result.then((_) => settled = true);

    await tester.enterText(find.byType(TextFormField), '餐饮');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // 少了 `_submit()` 里那句 `_blocked` 判断，这里就会「按钮灰着但回车能提交」。
    expect(settled, isFalse);
    expect(find.text('新建类别'), findsOneWidget);
  });

  testWidgets('不传提示时行为与从前一致：交回去过掉首尾空格的输入', (tester) async {
    await host(tester);

    await tester.enterText(find.byType(TextFormField), '  餐饮  ');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(await result, '餐饮');
  });

  testWidgets('不传提示时校验照旧拦', (tester) async {
    await host(
      tester,
      validator: (value) => value == null || value.isEmpty ? '请输入名称' : null,
    );

    var settled = false;
    result.then((_) => settled = true);

    await tester.enterText(find.byType(TextFormField), '');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(settled, isFalse);
    expect(find.text('请输入名称'), findsOneWidget);
  });
}
