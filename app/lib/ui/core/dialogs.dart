import 'package:flutter/material.dart';

/// 弹一个单输入框，返回填写的内容（已去首尾空格），取消则返回 null。
/// 改名、改昵称、改密码、解散与注销的密码确认都走这里，省得每处各写一遍对话框。
Future<String?> promptForText(
  BuildContext context, {
  required String title,
  required String label,
  String? initialValue,
  String confirmLabel = '确定',
  bool obscureText = false,
  TextInputType? keyboardType,
  String? Function(String? value)? validator,

  /// 非 null 时**确定按钮为禁用态**，这句话显示在输入框下面。
  /// §5.4：离线时类别与支付方式这两个页面的写操作要禁掉，而它们的「保存按钮」就是对话框里的确定。
  String? confirmDisabledHint,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _PromptDialog(
      title: title,
      label: label,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      confirmDisabledHint: confirmDisabledHint,
      dialogContext: dialogContext,
    ),
  );
}

/// 二次确认。§5.2 要求敏感操作先问一句，返回 true 才继续。
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '确定',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({
    required this.title,
    required this.label,
    required this.confirmLabel,
    required this.obscureText,
    required this.dialogContext,
    this.initialValue,
    this.keyboardType,
    this.validator,
    this.confirmDisabledHint,
  });

  final String title;
  final String label;
  final String confirmLabel;
  final bool obscureText;
  final BuildContext dialogContext;
  final String? initialValue;
  final TextInputType? keyboardType;
  final String? Function(String? value)? validator;
  final String? confirmDisabledHint;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _blocked => widget.confirmDisabledHint != null;

  void _submit() {
    if (_blocked) return;
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(widget.dialogContext, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(labelText: widget.label),
            ),
            if (widget.confirmDisabledHint != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.confirmDisabledHint!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(widget.dialogContext),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _blocked ? null : _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
