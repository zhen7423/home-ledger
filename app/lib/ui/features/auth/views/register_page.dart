import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_router.dart';
import '../../../core/validators.dart';
import '../view_models/auth_view_model.dart';
import 'auth_page_shell.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authViewModelProvider.notifier)
        .signUp(
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          nickname: _nicknameController.text.trim(),
        );
  }

  String? _validateConfirm(String? value) =>
      value == _passwordController.text ? null : '两次输入的密码不一致';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);

    return AuthPageShell(
      title: '注册',
      subtitle: '注册成功后直接进入创建或加入家庭的引导',
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
                controller: _nicknameController,
                maxLength: 12,
                validator: validateNickname,
                decoration: const InputDecoration(
                  labelText: '昵称',
                  helperText: '家庭内可见，用于标记记录人',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: validateNewPassword,
                decoration: const InputDecoration(
                  labelText: '密码',
                  helperText: '8–20 位，需同时包含字母和数字',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                validator: _validateConfirm,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(labelText: '确认密码'),
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
                    : const Text('注册并登录'),
              ),
            ],
          ),
        ),
        Align(
          child: TextButton(
            onPressed: () => context.go(RoutePath.login),
            child: const Text('已有账号，去登录'),
          ),
        ),
      ],
    );
  }
}
