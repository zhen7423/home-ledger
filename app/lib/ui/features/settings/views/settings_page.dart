import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/app_router.dart';
import '../../../core/app_widgets.dart';
import '../../../core/dialogs.dart';
import '../../../core/error_copy.dart';
import '../view_models/local_cache_view_model.dart';
import '../view_models/reminder_view_model.dart';

/// 设置 Tab。分组照 §4.7：模块与 Tab、家庭、账号、记账的三份配置、猫咪、宝宝、通知、数据、关于。
///
/// 各模块那几段在模块关掉之后**仍然保留**（§3.2 的口径）：开关管的是底部 Tab 与首页，
/// 关掉 Tab 不等于要把管理入口也收走——数据还在，用户想进去看一眼就该进得去。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 这一眼 watch 同时是「启动时把待提醒拉一遍」的驱动源，理由见 home_page 里那句
    final pendingCount = ref.watch(pendingReminderCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // 每个分组标题下，每行一张独立小卡（问题单：卡片间有间距）。
          const SectionHeader(title: '家庭与账号'),
          RowCard(
            child: ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('模块与 Tab'),
              subtitle: const Text('记账、猫咪、宝宝的开关与前后顺序'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePath.modules),
            ),
          ),
          RowCard(
            child: ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: const Text('家庭管理'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePath.family),
            ),
          ),
          RowCard(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('账号与安全'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePath.account),
            ),
          ),
          const SectionHeader(title: '记账设置'),
          RowCard(
            child: ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('类别管理'),
              subtitle: const Text('大类、小类与是否启用'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePath.categories),
            ),
          ),
          RowCard(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('支付方式'),
              subtitle: const Text('现金、信用卡与默认那一项'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePath.paymentAccounts),
            ),
          ),
          RowCard(
            child: ListTile(
              leading: const Icon(Icons.repeat_outlined),
              title: const Text('周期记账'),
              subtitle: const Text('房租、订阅这类固定支出'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePath.recurringRules),
            ),
          ),
          RowCard(
            child: ListTile(
              leading: const Icon(Icons.pie_chart_outline),
              title: const Text('预算管理'),
              subtitle: const Text('家庭、类别与成员三个维度'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePath.budgets),
            ),
          ),
          const SectionHeader(title: '猫咪'),
          RowCard(
            child: ListTile(
              leading: const Icon(Icons.pets_outlined),
              title: const Text('猫咪'),
              subtitle: const Text('档案、猫粮袋与驱虫记录'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePath.catHome),
            ),
          ),
          const SectionHeader(title: '宝宝'),
          RowCard(
            child: ListTile(
              leading: const Icon(Icons.child_care_outlined),
              title: const Text('宝宝'),
              subtitle: const Text('档案、身高体重、疫苗与里程碑'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePath.babyHome),
            ),
          ),
          const SectionHeader(title: '通知'),
          RowCard(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('通知设置'),
              subtitle: Text(
                pendingCount == 0 ? '哪些提醒会发通知' : '$pendingCount 条待处理',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePath.notifications),
            ),
          ),
          const SectionHeader(title: '数据'),
          RowCard(
            child: ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('数据导出'),
              subtitle: const Text('Excel 或 CSV，导出流水明细'),
              trailing: const Icon(Icons.chevron_right),
              // 从设置页进不带条件，落到「导出全部」（§4.2.7）
              onTap: () => context.push(RoutePath.export),
            ),
          ),
          RowCard(
            child: ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('清除本地缓存'),
              subtitle: const Text('字典、流水与统计快照'),
              onTap: () => _clearCache(context, ref),
            ),
          ),
          RowCard(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('数据备份说明'),
              onTap: () => _showBackupInfo(context),
            ),
          ),
          const SizedBox(height: 8),
          RowCard(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('关于'),
              subtitle: const Text('版本、用户协议、隐私政策与数据来源'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(RoutePath.about),
            ),
          ),
        ],
      ),
    );
  }

  /// §5.4：清除本地缓存要二次确认。文案里把「不动服务端数据」与「不动通知记录」都写出来，
  /// 这两件是用户最容易担心、也最容易误解的。
  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final ok = await confirmAction(
      context,
      title: '清除本地缓存',
      message:
          '会清掉这台设备上的类别、支付方式、流水与统计快照，下次进入相关页面时'
          '重新从服务端取。服务端的数据不受影响，通知的发送记录也保留。',
      confirmLabel: '清除',
    );
    if (!ok || !context.mounted) {
      return;
    }
    await ref.read(localCacheViewModelProvider).clear();
    // await 之后 context 可能已经失效（用户在等待期间按了返回），这句检查不能省
    if (!context.mounted) {
      return;
    }
    showSnackBar(context, '已清除本地缓存');
  }
}

/// §9：备份说明是**对话框不是页面**，只有几行静态文字，为它开一条路由等于让用户多按一次
/// 返回键。文案里的「凌晨 03:00」「保留 7 天」取自 §5.3，别自己编一个数字。
Future<void> _showBackupInfo(BuildContext context) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('数据备份说明'),
    content: const Text(
      '你的记账数据保存在服务端。服务端每天凌晨 03:00 自动做一次全量备份，'
      '备份文件保留 7 天。\n\n'
      '这台设备上的类别、支付方式、流水与统计都只是缓存，供断网时查看，'
      '清除缓存或重装 App 都不会丢数据。\n\n'
      '想要一份自己手里的副本，用「数据导出」生成 Excel 或 CSV 文件。',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: const Text('知道了'),
      ),
    ],
  ),
);
