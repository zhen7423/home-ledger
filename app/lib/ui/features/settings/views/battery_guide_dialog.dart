import 'package:flutter/material.dart';

/// §4.5.3 缓解措施①：首次启动时告诉用户怎么把家庭日记从系统的省电策略里放出来。
///
/// 只给静态路径指引、不做「一键跳转」：各厂商的电池优化页在设置里的层级与 Activity 名都不一样，
/// 插件能拉到的最多是本应用的通知设置页，硬拉一个猜出来的 Activity 在部分机型上会直接失败——
/// 而失败的表现是「点了没反应」，比一句路径文字更难解释。按钮复用通知设置页那个「去系统设置」，
/// 用户自己能在里面找到电池那一栏。
///
/// 文案里的路径随系统版本会变，所以开头给了「大致如下」这四个字，结尾留了通用找法——
/// 一份写着具体层级却过期了的指引，比一句「在电池里把家庭日记设为不受限制」更让人怀疑 App 坏了。
Future<void> showBatteryGuideDialog(
  BuildContext context, {
  required VoidCallback onOpenSettings,
}) {
  final theme = Theme.of(context);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('让提醒准时响'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '家庭日记的提醒由系统在本机按时弹出。系统的省电策略会在后台上限制 App，'
              '那样提醒可能不响。下面是对应机型的大致路径：',
            ),
            const SizedBox(height: 12),
            for (final line in _vendorPaths)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  line,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            const Text('别的机型：在系统设置的「电池」里找「电池优化 / 后台限制」，把家庭日记设为不受限制。'),
            const SizedBox(height: 12),
            Text(
              '就算一条通知都没响，App 里的红点与倒计时也一直在。',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          // 先关掉自己再触发跳转：对话框是模态浮层，用户从系统设置回来时不该还被它挡着
          // （通知设置页那个同名按钮不 pop 是对的——那里本来就在页面上，这里不是）。
          // 异常由调用方兑：onOpenSettings 内部已自行 catch，不会把 Future 抛出来
          onPressed: () {
            Navigator.pop(dialogContext);
            onOpenSettings();
          },
          child: const Text('去系统设置'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

const List<String> _vendorPaths = [
  '小米 / Redmi：设置 → 应用设置 → 应用管理 → 家庭日记 → 省电策略选「无限制」，自启动打开',
  '华为 / 荣耀：设置 → 应用 → 应用启动管理 → 家庭日记 → 关掉「自动管理」后三项手动开关全开',
  'OPPO / 一加 / realme：设置 → 电池 → 应用耗电管理 → 家庭日记 → 允许后台运行',
  'vivo / iQOO：设置 → 电池 → 后台高耗电 → 家庭日记 → 允许',
  '三星：设置 → 电池 → 后台使用限制 → 把家庭日记从「休眠应用」里移除',
  '原生 Android：设置 → 应用 → 家庭日记 → 电池 → 选「不受限制」',
];
