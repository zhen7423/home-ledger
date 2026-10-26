import 'dart:async';
import 'dart:ui';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/services/reminder_notifier.dart';
import 'router/app_router.dart';
import 'ui/core/app_theme.dart';
import 'ui/features/settings/view_models/reminder_view_model.dart';

void main() {
  // 最后防线：模型解析的 TypeError、平台通道异常等非 ApiException 一旦逃出调用链，
  // 没有这两道钩子就是静默丢失（debug 控制台红字、release 无声无息），线上无从排查
  // （扫描报告 2026-10-26 P3-4）。现阶段只落 debugPrint，接日志服务时改这里两处即可。
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('flutter error: $details');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('unhandled async error: $error\n$stack');
    return true;
  };
  runZonedGuarded(
    () {
      runApp(
        ProviderScope(
          overrides: [
            // 通知点开要能跳到后端给的那条 route 上。`reminder_notifier.dart` 自己不 import
            // GoRouter（否则测试里没法实例化），这里是唯一同时看得见 routerProvider
            // 与 ProviderScope 的位置。
            //
            // §4.5.2「进入相应列表页后红点消除」：系统通知里只有落点、没有 key，所以按落点
            // 把同一屏的提醒一起记为今天看过。冷启动那一次不走这里（列表还没到手上），
            // 它在 PendingReminderViewModel 里用同一个落点处理。
            reminderNotifierProvider.overrideWith(
              (ref) => LocalReminderNotifier(
                onNavigate: (route) {
                  ref
                      .read(pendingReminderViewModelProvider.notifier)
                      .dismissByRoute(route);
                  ref.read(routerProvider).push(route);
                },
              ),
            ),
          ],
          child: const HomeLedgerApp(),
        ),
      );
    },
    (error, stack) => debugPrint('zone error: $error\n$stack'),
  );
}

class HomeLedgerApp extends ConsumerWidget {
  const HomeLedgerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Android 12+ 取系统壁纸配色，其他平台或低版本拿到 null，由 AppTheme 落回种子色
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp.router(
        title: '家庭日记',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(lightDynamic),
        darkTheme: AppTheme.dark(darkDynamic),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('zh', 'CN')],
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}
