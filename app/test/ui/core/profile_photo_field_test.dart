import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/ui/core/profile_photo_field.dart';

/// 档案编辑页顶部的照片区（S10）。两个编辑页复用同一块，所以在这里集中断它的四种形态。
void main() {
  Future<void> pump(WidgetTester tester, ProfilePhotoField field) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: field)),
    );
  }

  testWidgets('还没有照片：显示上传按钮，不显示删除', (tester) async {
    await pump(
      tester,
      ProfilePhotoField(
        photoUrl: null,
        enabled: true,
        uploading: false,
        onPick: () {},
        onClear: () {},
        placeholderIcon: Icons.pets_outlined,
      ),
    );

    expect(find.text('上传照片'), findsOneWidget);
    expect(find.text('删除照片'), findsNothing);
    expect(find.byIcon(Icons.pets_outlined), findsOneWidget);
  });

  testWidgets('已有照片：换成「更换照片」并出现删除入口', (tester) async {
    await pump(
      tester,
      ProfilePhotoField(
        photoUrl: '/photos/abc.jpg',
        enabled: true,
        uploading: false,
        onPick: () {},
        onClear: () {},
        placeholderIcon: Icons.pets_outlined,
      ),
    );

    expect(find.text('更换照片'), findsOneWidget);
    expect(find.text('删除照片'), findsOneWidget);
  });

  testWidgets('上传中：只剩转圈，两个按钮都不响应（也都不显示）', (tester) async {
    await pump(
      tester,
      ProfilePhotoField(
        photoUrl: '/photos/abc.jpg',
        enabled: true,
        uploading: true,
        onPick: () {},
        onClear: () {},
        placeholderIcon: Icons.pets_outlined,
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('更换照片'), findsNothing);
    expect(find.text('删除照片'), findsNothing);
  });

  testWidgets('离线：按钮禁用（与保存按钮同一口径），预览仍显示', (tester) async {
    await pump(
      tester,
      ProfilePhotoField(
        photoUrl: '/photos/abc.jpg',
        enabled: false,
        uploading: false,
        onPick: () {},
        onClear: () {},
        placeholderIcon: Icons.pets_outlined,
      ),
    );

    final change = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '更换照片'),
    );
    expect(change.onPressed, isNull, reason: '离线时提交被禁，照片操作同样该禁');
    final clear = tester.widget<TextButton>(
      find.widgetWithText(TextButton, '删除照片'),
    );
    expect(clear.onPressed, isNull);
  });
}