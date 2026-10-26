import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// 三态而不是布尔（§5.4）：冷启动时一次请求都还没发过，此刻既不能说在线也不能说离线。
/// 未知必须允许提交——按「离线」处理会让用户一打开 App 就发现记不了账，
/// 而实际上网络可能好得很。
enum NetworkStatus { unknown, online, offline }

/// 不引 `connectivity_plus`：插件给的是网卡状态，不是后端可达性。
/// 连着 WiFi 但后端挂了，插件说「在线」，而用户什么都做不了（§5.4 第 22 轮）。
class NetworkStatusNotifier extends Notifier<NetworkStatus> {
  StreamSubscription<bool>? _subscription;

  @override
  NetworkStatus build() {
    final client = ref.watch(apiClientProvider);
    _subscription?.cancel();
    _subscription = client.reachability.listen(
      (reachable) =>
          state = reachable ? NetworkStatus.online : NetworkStatus.offline,
    );
    ref.onDispose(() => _subscription?.cancel());
    return NetworkStatus.unknown;
  }
}

final networkStatusProvider =
    NotifierProvider<NetworkStatusNotifier, NetworkStatus>(
      NetworkStatusNotifier.new,
    );

/// 五处表单的保存按钮一律看它，不要各自去比 `networkStatusProvider`：
/// 「未知允许提交」这条规则只该写在一个地方。
final canSubmitProvider = Provider<bool>(
  (ref) => ref.watch(networkStatusProvider) != NetworkStatus.offline,
);
