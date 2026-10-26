import 'package:flutter/material.dart';

import 'date_format.dart';

/// §5.4 那句提示的文案。表单页按钮下面、对话框禁用态的说明用的是同一句话，写一处。
const String offlineSubmitHint = '需联网后保存';

/// 「离线模式 · 数据截至 2026-09-14 15:20」横幅，挂在展示缓存数据的页面顶部。
///
/// `savedAt` 为 null 时只写「离线模式」：流水详情页的 `get(id)` 回的是一个裸 `Transaction`，
/// 带不出缓存时刻（F4 没改它的签名），而编一个时刻出来比不写更糟。
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({this.savedAt, super.key});

  final DateTime? savedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = savedAt;
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 18,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                saved == null ? '离线模式' : '离线模式 · 数据截至 ${formatDateTime(saved)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 保存按钮底下那句提示。按钮自己变灰说明不了「为什么点不动」，§5.4 要求把话写出来。
///
/// `text` 可换：导出页那个按钮底下要说的是「离线时无法生成导出文件」（F7⑤），
/// 样式一模一样，没必要在另一处把 Padding + bodySmall + error 三个属性重抄一遍。
class OfflineSubmitHint extends StatelessWidget {
  const OfflineSubmitHint({this.text = offlineSubmitHint, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
