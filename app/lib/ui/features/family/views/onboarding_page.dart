import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_router.dart';
import '../../../core/validators.dart';
import '../view_models/family_view_model.dart';

enum _Mode { create, join }

/// 注册后没有家庭时的落点。创建与加入互斥：一个用户同一时间只能属于一个家庭。
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();

  _Mode _mode = _Mode.create;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    final family = ref.read(familyViewModelProvider.notifier);
    final error = _mode == _Mode.create
        ? await family.create(_nameController.text.trim())
        : await family.join(_inviteCodeController.text.trim());

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = error;
    });
  }

  void _switchMode(_Mode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('开始使用'),
        actions: [
          IconButton(
            tooltip: '账号与安全',
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(RoutePath.account),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<_Mode>(
                      segments: const [
                        ButtonSegment(value: _Mode.create, label: Text('创建家庭')),
                        ButtonSegment(value: _Mode.join, label: Text('加入家庭')),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selection) =>
                          _switchMode(selection.first),
                    ),
                    const SizedBox(height: 24),
                    if (_mode == _Mode.create)
                      TextFormField(
                        controller: _nameController,
                        maxLength: 20,
                        validator: validateFamilyName,
                        decoration: const InputDecoration(
                          labelText: '家庭名称',
                          helperText: '留空则默认「<昵称>的家」',
                        ),
                      )
                    else
                      TextFormField(
                        controller: _inviteCodeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 6,
                        validator: validateInviteCode,
                        decoration: const InputDecoration(
                          labelText: '邀请码',
                          helperText: '6 位数字，向家庭创建者索取',
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_mode == _Mode.create ? '创建家庭' : '加入家庭'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
