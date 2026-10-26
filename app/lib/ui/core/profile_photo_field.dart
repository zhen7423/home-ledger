import 'package:flutter/material.dart';

import 'auth_image.dart';

/// 档案编辑页顶部的照片区（S10，§4.3.1 / A6）：一张方形预览 + 换/删两个动作。
/// 猫与宝宝的编辑页共用这一块，不同的只是占位图标。
class ProfilePhotoField extends StatelessWidget {
  const ProfilePhotoField({
    super.key,
    required this.photoUrl,
    required this.enabled,
    required this.uploading,
    required this.onPick,
    required this.onClear,
    this.placeholderIcon = Icons.person_outline,
  });

  /// 当前档案的照片相对路径，null = 还没有照片。
  final String? photoUrl;

  /// 网络不可用时两个按钮一起禁用（口径同保存按钮的 `OfflineSubmitHint`）。
  final bool enabled;

  /// 上传进行中：只显示转圈，不响应第二次点击。
  final bool uploading;

  final VoidCallback onPick;

  final VoidCallback onClear;

  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('档案照片（选填）', style: theme.textTheme.titleSmall),
        ),
        Row(
          children: [
            _preview(theme),
            const SizedBox(width: 16),
            if (uploading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: enabled ? onPick : null,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: Text(photoUrl == null ? '上传照片' : '更换照片'),
                  ),
                  if (photoUrl != null) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: enabled ? onClear : null,
                      child: const Text('删除照片'),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _preview(ThemeData theme) {
    const size = 96.0;
    final url = photoUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: url == null
              ? Icon(
                  placeholderIcon,
                  size: 40,
                  color: theme.colorScheme.outline,
                )
              : AuthImage(
                  photoUrl: url,
                  placeholderIcon: placeholderIcon,
                  // 96 逻辑 px × 2 高 DPI
                  cacheWidth: 192,
                ),
        ),
      ),
    );
  }
}
