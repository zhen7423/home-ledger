import 'package:flutter/material.dart';

import '../core/app_widgets.dart';

/// 启动时的落点：登录态与家庭都还在异步确认，先占住这一屏避免闪跳。
/// 「暖居」§7：品牌角标 + 名称 + 加载指示，即启动的那盏灯牌。
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(size: 88),
            const SizedBox(height: 20),
            Text(
              '家庭日记',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
