import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/member.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../../../core/validators.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/profile_view_model.dart';

/// §4.1.5 昵称、§4.1.2 改密码与退出登录、§4.1.6 注销账号，以及 §4.1.3 要求的限制告知。
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('账号与安全')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorCopy(error), textAlign: TextAlign.center),
          ),
        ),
        data: (user) => ListView(
          children: [
            ListTile(
              title: const Text('昵称'),
              subtitle: Text(user.nickname),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editNickname(context, ref, user.nickname),
            ),
            ListTile(title: const Text('手机号'), subtitle: Text(user.phone)),
            ListTile(
              title: const Text('我的角色'),
              subtitle: Text(switch (user.role) {
                MemberRole.owner => '家庭创建者',
                MemberRole.member => '家庭成员',
                _ => '尚未加入家庭',
              }),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.password_outlined),
              title: const Text('修改密码'),
              subtitle: const Text('修改后本设备自动续期，其他设备需要重新登录'),
              onTap: () => _changePassword(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('退出登录'),
              onTap: () => _signOut(context, ref),
            ),
            ListTile(
              leading: Icon(
                Icons.no_accounts_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '注销账号',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => _deactivate(context, ref),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Text(
                '关于找回密码：本期没有短信通道，App 内无法自助找回密码，'
                '忘记密码需联系部署者在服务器侧重置。',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editNickname(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final nickname = await promptForText(
      context,
      title: '修改昵称',
      label: '昵称',
      initialValue: current,
      validator: validateNickname,
    );
    if (nickname == null) return;
    final error = await ref
        .read(profileViewModelProvider.notifier)
        .updateNickname(nickname);
    if (error != null && context.mounted) showSnackBar(context, error);
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String oldPassword, String newPassword})>(
      context: context,
      builder: (dialogContext) =>
          _ChangePasswordDialog(dialogContext: dialogContext),
    );
    if (result == null) return;
    final error = await ref
        .read(profileViewModelProvider.notifier)
        .changePassword(
          oldPassword: result.oldPassword,
          newPassword: result.newPassword,
        );
    if (!context.mounted) return;
    showSnackBar(context, error ?? '密码已修改');
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: '退出登录',
      message: '退出后本地令牌与业务数据会被清空，登录名保留以便下次填充。',
      confirmLabel: '退出',
    );
    if (!ok) return;
    await ref.read(authViewModelProvider.notifier).signOut();
  }

  Future<void> _deactivate(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: '注销账号',
      message:
          '账号会被删除，且同一手机号无法自助重新注册。'
          '若你是家庭创建者，需先转让创建者身份或解散家庭。此操作需要密码确认。',
      confirmLabel: '继续',
    );
    if (!ok || !context.mounted) return;

    final password = await promptForText(
      context,
      title: '确认注销',
      label: '登录密码',
      confirmLabel: '注销',
      obscureText: true,
      validator: validateRequired,
    );
    if (password == null) return;
    final error = await ref
        .read(profileViewModelProvider.notifier)
        .deactivate(password);
    if (error != null && context.mounted) showSnackBar(context, error);
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.dialogContext});

  final BuildContext dialogContext;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _oldController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(widget.dialogContext, (
      oldPassword: _oldController.text,
      newPassword: _newController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('修改密码'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _oldController,
              obscureText: true,
              autofocus: true,
              validator: validateLoginPassword,
              decoration: const InputDecoration(labelText: '原密码'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newController,
              obscureText: true,
              validator: validateNewPassword,
              decoration: const InputDecoration(
                labelText: '新密码',
                helperText: '8–20 位，需同时包含字母和数字',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              validator: (value) =>
                  value == _newController.text ? null : '两次输入的密码不一致',
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: '确认新密码'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(widget.dialogContext),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('确定')),
      ],
    );
  }
}
