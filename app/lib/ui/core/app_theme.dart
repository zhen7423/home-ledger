import 'package:flutter/material.dart';

/// 「暖居」设计语言（见 `docs/UI设计语言规范-暖居.md`）在代码里的落地。
///
/// §6.1 的约定：种子色暖橙 #E8862E；M3 方案用**默认的 tonalSpot 变体**派生——实测过
/// `expressive` 会把这颗暖橙种子偏成紫罗兰主色（#895120 的色相被甩到紫色区），违背
/// 「暖调品牌」，故不用（见规范 §2.1 的走查记录）。组件主题全部基于派生出的暖橙调
/// ColorScheme 令牌构建。Android 12+ 的动态取色由 main.dart 的 DynamicColorBuilder
/// 送进来。取不到时——其他平台、或系统版本低于 12——落回种子色，两条路径共用这套组件主题。
abstract class AppTheme {
  static const Color seedColor = Color(0xFFE8862E);

  static ThemeData light(ColorScheme? dynamicScheme) =>
      _build(dynamicScheme ?? ColorScheme.fromSeed(seedColor: seedColor));

  static ThemeData dark(ColorScheme? dynamicScheme) => _build(
    dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
  );

  /// 组件级主题全部基于 `ColorScheme` 令牌构建，动态壁纸色与「暖居」落在同一套结构上。
  static ThemeData _build(ColorScheme scheme) {
    final hairline = scheme.outlineVariant.withValues(alpha: 0.45);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // 底色用比 surface 深一档的浅灰，卡片用更亮的纸白——「卡片比底色浅」（问题单：列表小卡片）。
      // M3 默认 surface 是最亮的一档，卡片容器再降一档就与底色糊在一起了。
      scaffoldBackgroundColor: scheme.surfaceContainerLow,

      // ---- 顶栏 §6.3 ----
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
      ),

      // ---- 卡片：纸白面板、柔和阴影、发丝描边（问题单：适当增加阴影） ----
      cardTheme: CardThemeData(
        elevation: 2,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        // M3 的阴影色默认偏灰；抬一档 alpha 让「小卡浮在浅灰底上」的分层感出来
        shadowColor: Colors.black.withValues(alpha: 0.07),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: hairline),
        ),
      ),

      // ---- 底部导航 §6.4 ----
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          );
        }),
      ),

      // ---- 悬浮按钮 §6.5 ----
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 1,
        highlightElevation: 3,
        shape: const StadiumBorder(),
      ),

      // ---- 输入框 §6.8：Filled、圆角 12、聚焦才描边 ----
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: scheme.primary),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        border: _inputBorder(scheme, scheme.outlineVariant),
        enabledBorder: _inputBorder(scheme, scheme.outlineVariant),
        focusedBorder: _inputBorder(scheme, scheme.primary, width: 1.5),
        errorBorder: _inputBorder(scheme, scheme.error),
        focusedErrorBorder: _inputBorder(scheme, scheme.error, width: 1.5),
      ),

      // ---- Chips §6.7 ----
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.secondaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: TextStyle(
          fontSize: 13,
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 13,
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: scheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ---- 分段选择 §6.6：全宽等分（expandedInsets 由页面传）、选中暖调容器、圆角 12 ----
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.secondaryContainer
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: WidgetStatePropertyAll(
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),

      // ---- 按钮 §6.9 ----
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 44),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ---- 对话框 §6.11 ----
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: hairline),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        contentTextStyle: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: scheme.onSurfaceVariant,
        ),
      ),

      // ---- 底部面板 §6.11 ----
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // ---- 快照条 §6.11 ----
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),

      // ---- 列表行 §6.12 ----
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 13,
          color: scheme.onSurfaceVariant,
        ),
      ),

      // ---- 分隔线：发丝 ----
      dividerTheme: DividerThemeData(color: hairline, thickness: 0.6),

      // ---- 进度条：主色 + 浅色轨道 ----
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(
    ColorScheme scheme,
    Color color, {
    double width = 1,
  }) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: width),
  );
}
