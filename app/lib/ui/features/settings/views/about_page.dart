import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../data/services/api_client.dart';
import '../../../../router/app_router.dart';
import '../../baby/baby_copy.dart';
import '../legal_copy.dart';

/// App 版本号的唯一落点。
///
/// 与 `pubspec.yaml` 的 `version:` 保持一致。S10 的 CI 可以在构建时用
/// `--dart-define=APP_VERSION=x.y.z` 覆盖它——本项目不引 `package_info_plus`：
/// 为了读一个字符串加一个带平台代码的插件不划算，而这个常量只有这一处读者。
const String appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.0.0+1',
);

/// §4.7 的「关于」。协议、隐私、数据来源与免责、版本、以及长按版本号五次才露出来的服务端地址。
///
/// 服务端地址藏在调试入口后面，是因为它对普通用户没有意义，而错填一个地址会让 App 连不上——
/// 需要它的人是部署者自己，他本来就知道该长按哪里。
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const int _tapsToRevealDebug = 5;

  int _taps = 0;

  bool get _debugRevealed => _taps >= _tapsToRevealDebug;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text('家庭日记', style: theme.textTheme.titleLarge),
                // 长按而不是点击：调试入口要「够得着但碰不到」
                GestureDetector(
                  onLongPress: () => setState(() => _taps++),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '版本 $appVersion',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(legalTermsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RoutePath.terms),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(legalPrivacyTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(RoutePath.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('数据来源与免责声明'),
            subtitle: const Text('生长标准与免疫程序表的出处'),
            onTap: () => _showDialog(context, '数据来源与免责声明', babyDataDisclaimer),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('忘记密码怎么办'),
            subtitle: const Text('本期没有短信通道，需要部署者帮忙重置'),
            onTap: () => _showDialog(
              context,
              '忘记密码怎么办',
              '本期没有短信通道，不能自助找回密码。请联系部署者（通常就是家里搭这套服务的人），'
                  '由他在服务器上为你重置。'
                  '在资质就绪之前，这条限制会一直在这里。',
            ),
          ),
          if (_debugRevealed) ...[
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: const Text('服务端地址'),
              subtitle: SelectableText(ApiClient.defaultOrigin),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showDialog(BuildContext context, String title, String body) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
