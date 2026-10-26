import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/family.dart';
import '../../../../data/models/member.dart';
import '../../../core/date_format.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../../../core/validators.dart';
import '../../settings/view_models/profile_view_model.dart';
import '../view_models/family_view_model.dart';

/// §4.1.4 与 §4.1.6：名称、邀请码、成员，以及退出 / 移除 / 转让 / 解散。
class FamilyPage extends ConsumerWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(familyViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('家庭管理')),
      body: family.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(errorCopy(error), textAlign: TextAlign.center),
          ),
        ),
        // 退出或解散后状态会先变成 null，紧接着守卫就把人送去引导页，这里不必渲染内容
        data: (value) => value == null
            ? const SizedBox.shrink()
            : _FamilyDetail(family: value),
      ),
    );
  }
}

class _FamilyDetail extends ConsumerWidget {
  const _FamilyDetail({required this.family});

  final Family family;

  /// 邀请是否「有效开着」：开关打开且还没到失效时间。过期后开关视同关闭，
  /// 展示文案落到 else 分支；此时创建者再开一次会自动换发新码（等价于原来的重置）。
  bool get _inviteOpen {
    final expireAt = family.inviteCodeExpireAt;
    return family.inviteEnabled &&
        expireAt != null &&
        expireAt.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(profileViewModelProvider).value?.id;
    final isOwner = myId != null && family.ownerUserId == myId;

    return ListView(
      children: [
        ListTile(
          title: const Text('家庭名称'),
          subtitle: Text(family.name),
          trailing: const Icon(Icons.edit_outlined),
          onTap: () => _rename(context, ref),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text('邀请码', style: Theme.of(context).textTheme.titleSmall),
        ),
        // 第 33 轮：邀请是手动开关，只有开着才生成码；开关打开的有效状态由后端
        // inviteEnabled + inviteCodeExpireAt 推导，过期即视同关闭（后端 join 也会拦 EXPIRED）
        SwitchListTile(
          title: const Text('开启邀请'),
          subtitle: const Text('开启后生成 6 位邀请码，24 小时有效，一人加入即失效'),
          value: _inviteOpen,
          onChanged: isOwner
              ? (value) => _setInviteEnabled(context, ref, value)
              : null,
        ),
        if (_inviteOpen && family.inviteCode != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              children: [
                Text(
                  family.inviteCode!,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(letterSpacing: 4),
                ),
                IconButton(
                  tooltip: '复制',
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: family.inviteCode!),
                    );
                    if (context.mounted) showSnackBar(context, '邀请码已复制');
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${formatDateTime(family.inviteCodeExpireAt!)} 前有效',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (isOwner)
            TextButton.icon(
              // 开着时再开一次 = 重置：换发新码并顺延 24 小时，旧码立即失效
              onPressed: () => _setInviteEnabled(context, ref, true),
              icon: const Icon(Icons.refresh),
              label: const Text('重新生成邀请码'),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              isOwner ? '未开启邀请，开启后成员才能凭邀请码加入' : '邀请未开启，请联系创建者开启',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            '成员 ${family.members.length}/5',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final member in family.members)
          ListTile(
            leading: CircleAvatar(
              child: Text(member.nickname.characters.first),
            ),
            title: Text(member.nickname),
            subtitle: Text(member.isOwner ? '创建者' : '成员'),
            trailing: (isOwner && member.userId != myId)
                ? _memberMenu(context, ref, member)
                : null,
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('退出家庭'),
          onTap: () => _leave(context, ref),
        ),
        if (isOwner)
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              '解散家庭',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _disband(context, ref),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _memberMenu(BuildContext context, WidgetRef ref, Member member) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        if (action == 'transfer') {
          _transferOwner(context, ref, member);
        } else {
          _removeMember(context, ref, member);
        }
      },
      itemBuilder: (menuContext) => const [
        PopupMenuItem(value: 'transfer', child: Text('转让创建者')),
        PopupMenuItem(value: 'remove', child: Text('移除成员')),
      ],
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await promptForText(
      context,
      title: '修改家庭名称',
      label: '名称',
      initialValue: family.name,
      validator: validateFamilyRename,
    );
    if (name == null || !context.mounted) return;
    await _run(
      context,
      ref.read(familyViewModelProvider.notifier).rename(name),
    );
  }

  /// 开关邀请。关 = 关闭入口（清码）且旧码作废，需确认；开 = 签发新码（开着时再开 = 重置）。
  Future<void> _setInviteEnabled(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (!enabled) {
      final ok = await confirmAction(
        context,
        title: '关闭邀请',
        message: '关闭后当前邀请码立即失效，已经拿到新码的人也无法再加入。',
        confirmLabel: '关闭',
      );
      if (!ok || !context.mounted) return;
    } else if (context.mounted && _inviteOpen) {
      // 开着时再开一次 = 重置：旧码作废换新码
      final ok = await confirmAction(
        context,
        title: '重新生成邀请码',
        message: '旧邀请码会立即失效，已经拿到旧码的人需要重新索取。',
        confirmLabel: '重新生成',
      );
      if (!ok || !context.mounted) return;
    }
    await _run(
      context,
      ref.read(familyViewModelProvider.notifier).setInviteEnabled(enabled),
    );
  }

  Future<void> _transferOwner(
    BuildContext context,
    WidgetRef ref,
    Member member,
  ) async {
    final ok = await confirmAction(
      context,
      title: '转让创建者',
      message: '把创建者身份交给「${member.nickname}」后，你会降为普通成员，家庭数据不变。',
      confirmLabel: '转让',
    );
    if (!ok || !context.mounted) return;
    await _run(
      context,
      ref.read(familyViewModelProvider.notifier).transferOwner(member.userId),
    );
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    Member member,
  ) async {
    final ok = await confirmAction(
      context,
      title: '移除成员',
      message:
          '移除「${member.nickname}」后，对方的登录态会立即失效，'
          '但其历史记录保留，记录人显示为当前昵称。',
      confirmLabel: '移除',
    );
    if (!ok || !context.mounted) return;
    await _run(
      context,
      ref.read(familyViewModelProvider.notifier).removeMember(member.userId),
    );
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: '退出家庭',
      message:
          '退出后你看不到这个家庭的任何数据，你的历史记录保留在家庭里。'
          '创建者需先转让或解散才能退出。',
      confirmLabel: '退出',
    );
    if (!ok || !context.mounted) return;
    await _run(context, ref.read(familyViewModelProvider.notifier).leave());
  }

  Future<void> _disband(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: '解散家庭',
      message: '家庭及其全部业务数据会被删除，30 天内可由部署者在服务器侧恢复。此操作需要密码确认。',
      confirmLabel: '继续',
    );
    if (!ok || !context.mounted) return;

    final password = await promptForText(
      context,
      title: '确认解散',
      label: '登录密码',
      confirmLabel: '解散',
      obscureText: true,
      validator: validateRequired,
    );
    if (password == null || !context.mounted) return;
    await _run(
      context,
      ref.read(familyViewModelProvider.notifier).disband(password),
    );
  }

  /// 成功由守卫接管跳转，这里只管把失败说出来。
  Future<void> _run(BuildContext context, Future<String?> action) async {
    final error = await action;
    if (error != null && context.mounted) {
      showSnackBar(context, error);
    }
  }
}
