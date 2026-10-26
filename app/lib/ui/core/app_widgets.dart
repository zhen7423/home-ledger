import 'package:flutter/material.dart';

/// 「暖居」设计语言（docs/UI设计语言规范-暖居.md）里的共享组件：
/// 区块标题、列表行小卡、品牌角标。放 `ui/core` 是因为首页、猫/宝首页、统计页、设置页
/// 都要用同一个样子——各写一份，改一处漏一处。
///
/// <b>卡片间距统一标准（问题单：各页卡片间距自查）</b>：
/// - 列表行小卡（`RowCard`）：左右 16、上下 5 —— 流水 / 身高体重 / 疫苗 / 档案等所有行列表。
/// - 统计页区块卡：左右 16、上 4、下 8 —— 财务 / 猫咪 / 宝宝统计的一整块图或表。
/// - 总览数据卡（首页概要 / 预算 / 自动记账等独立卡）：四周 6（卡间距 12）。
/// 横向滚动卡片（首页待办）自带左右 4 + 间距，不属于行列表。

/// 区块标题（问题单：卡片化后的轻量标题）。不再带左侧强调条——一张大卡已经给出了
/// 区块边界，再叠一条橙色竖条就是多余的装饰；标题压成普通字重的小标题即可。
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 18, 16, 10),
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// 列表行小卡（问题单：列表要小卡片，卡与卡之间有间距）。
/// 数据列表的每一行独立一张纸白小卡，卡色比底色浅，间距由 margin 给出——
/// 不再把整份列表塞进一张大卡。间距标准：左右 16、上下 5。
class RowCard extends StatelessWidget {
  const RowCard({super.key, required this.child, this.margin});

  final Widget child;

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 5, 16, 5),
      child: child,
    );
  }
}

/// 「保存中…」按钮的内容。提交期间换成 16×16 小转圈 + 文字，其余时候是纯文字。
///
/// 各录入页的保存按钮（记一笔 / 记身高体重 / 建档 / 各类弹层……）共用这一份，
/// 避免每页手写一遍 `Row(转圈 + 文字)`：转一圈转圈的尺寸、间距只有一处可改。
/// 转圈不带颜色参数：按钮里的默认主题色（FilledButton 上是 `onPrimary`）就是对的。
Widget submitButtonText({
  required bool saving,
  String label = '保存',
  String savingLabel = '保存中…',
  TextStyle? textStyle,
}) {
  if (!saving) return Text(label, style: textStyle);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SizedBox.square(
        dimension: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      const SizedBox(width: 8),
      Text(savingLabel, style: textStyle),
    ],
  );
}

/// 品牌角标：家里的猫（圆角方块照片）。
///
/// 与桌面 App 图标同一张图、同一个裁切框——图标源图裁切后落成
/// `app/assets/brand/cat_mark.jpg`，这里直接铺满。登录/注册外壳与启动页共用。
///
/// 圆角取 0.26：与脚本里 legacy 图标的方块圆角同值，页内角标与桌面图标一个形状；
/// 照片跟着父级 `Clip` 裁，所以 boxShadow 画在 decoration 上、不会被裁掉。
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 72});

  /// 角标图：换图要连 pubspec 的 assets 一起看。
  static const String assetPath = 'assets/brand/cat_mark.jpg';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        // 角标尺寸固定、解码后也就 512，不加 cacheWidth 反而每次缩放都重采样
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stack) => ColoredBox(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            Icons.pets_rounded,
            size: size * 0.5,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
