import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/home_overview.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

/// §4.6 首页聚合的一次请求。概要、预算、最近动态三份数据一起回来，
/// 首页因此只有一个加载态——分别发三次请求会有三个可能各自失败的转圈。
///
/// 不做本地缓存：首页是「现在这个家怎么样」，一份离线快照会让人以为今天的账记上了。
class HomeRepository {
  HomeRepository({required this._api});

  final ApiClient _api;

  Future<HomeOverview> overview() async {
    final body = await _api.get('/home/overview');
    // 该端点后端一定回对象；data:null 时交给 fromJson 会变成裸 TypeError，
    // 绕过 ApiException 的错误映射（扫描报告 2026-10-26 P2-1）。
    return HomeOverview.fromJson(requireData(body));
  }
}

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(api: ref.watch(apiClientProvider)),
);
