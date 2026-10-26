import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/ui/core/date_format.dart';
import 'package:homeledger/ui/core/offline_banner.dart';

/// 离线横幅与按钮下面那句提示。这两个小件被六处页面共用，样式跑偏一次要在六个地方改，
/// 所以把它们能在没有整页的情况下验的这一遍留着。
String _argb(Color color) => '${color.a},${color.r},${color.g},${color.b}';

void main() {
  final savedAt = DateTime(2026, 9, 14, 15, 20);

  Future<void> openBanner(WidgetTester tester, {DateTime? at}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OfflineBanner(savedAt: at)),
      ),
    );
  }

  Future<void> openHint(WidgetTester tester, {String? text}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: text == null
                ? const OfflineSubmitHint()
                : OfflineSubmitHint(text: text),
          ),
        ),
      ),
    );
  }

  testWidgets('给了时刻就写明数据截至什么时候', (tester) async {
    await openBanner(tester, at: savedAt);

    expect(find.textContaining('离线模式'), findsOneWidget);
    expect(find.textContaining(formatDateTime(savedAt)), findsOneWidget);
  });

  testWidgets('没给时刻时只写「离线模式」，不编一个时间出来', (tester) async {
    await openBanner(tester);

    expect(find.text('离线模式'), findsOneWidget);
    expect(find.textContaining('数据截至'), findsNothing);
  });

  testWidgets('底色走次级容器而不是错误色：离线是状态，不是坏了', (tester) async {
    await openBanner(tester, at: savedAt);

    final scheme = Theme.of(
      tester.element(find.byType(OfflineBanner)),
    ).colorScheme;
    final banner = tester.widget<Material>(
      find.descendant(
        of: find.byType(OfflineBanner),
        matching: find.byType(Material),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text).first);

    expect(_argb(banner.color!), _argb(scheme.secondaryContainer));
    expect(_argb(text.style!.color!), _argb(scheme.onSecondaryContainer));
  });

  testWidgets('提示默认为那一句，导出页传自己那句进来', (tester) async {
    await openHint(tester);
    expect(find.text('需联网后保存'), findsOneWidget);

    await openHint(tester, text: '离线时无法生成导出文件');
    expect(find.text('离线时无法生成导出文件'), findsOneWidget);
    expect(find.text('需联网后保存'), findsNothing);
  });
}
