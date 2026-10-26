import 'package:flutter/material.dart';

/// 用户协议与隐私政策共用的一页（§4.7）。
///
/// 正文是常量，来自 `legal_copy.dart`。段落用 `List<String>` 而不是一整块带 `\n` 的文本：
/// 一页可滚动的长文本里，段间距靠样式给，靠手写空行迟早会与别处不一致。
class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.title, required this.paragraphs});

  final String title;

  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final paragraph in paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                paragraph,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
        ],
      ),
    );
  }
}
