import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../router/app_router.dart';
import '../../../core/validators.dart';
import '../view_models/auth_view_model.dart';
import 'auth_page_shell.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefillPhone();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // §4.1.2 退出登录保留登录名，回来时直接填上
  Future<void> _prefillPhone() async {
    final phone = await ref.read(authRepositoryProvider).readLastPhone();
    if (phone != null && mounted) {
      _phoneController.text = phone;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authViewModelProvider.notifier)
        .signIn(
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _showForgotPasswordNotice() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('忘记密码'),
        content: const Text('本期没有短信通道，App 内无法自助找回密码。请联系部署者在服务器侧重置。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);

    return AuthPageShell(
      title: '家庭日记',
      subtitle: '一个家庭共用的生活记录',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: validatePhone,
                decoration: const InputDecoration(labelText: '手机号'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: validateLoginPassword,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(labelText: '密码'),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: state.submitting ? null : _submit,
                child: state.submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('登录'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _showForgotPasswordNotice,
              child: const Text('忘记密码'),
            ),
            TextButton(
              onPressed: () => context.go(RoutePath.register),
              child: const Text('注册新账号'),
            ),
          ],
        ),
      ],
    );
  }
}
