import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/baby.dart';
import '../models/baby_statistics.dart';

/// 宝宝总览页的快照，单槽一个文件（§5.4）。
///
/// 存的是成品模型而不是响应原文：`latestGrowth` 与 `vaccineTodo` 在写入前已经过一遍 `fromJson`，
/// 读的时候不必再碰 JSON，「离线打开总览」与「在线打开总览」因此走同一段渲染代码。
///
/// 只存总览页那三段。宝宝统计页、生长曲线页、应种清单页、接种记录页、里程碑与就诊页一律不进快照
/// （第 24 轮 (t)）：离线时它们显示横幅与「重试」，不显示假数据。
///
/// 没有 `query` 字段：总览页没有可选条件，`savedAt` 一个时间戳就足够解释「这是什么时候的」。
class BabyOverviewCacheStore {
  /// `directoryResolver` 是测试注入临时目录的口子（同统计快照与猫咪那一份）。
  BabyOverviewCacheStore({Future<Directory> Function()? directoryResolver})
    : _directoryResolver = directoryResolver ?? getApplicationSupportDirectory;

  static const String _file = 'baby-overview.json';

  final Future<Directory> Function() _directoryResolver;

  /// 读不到、或读出来少一段（信封的 `babies` 与 `savedAt` 都是必填）都算「没有快照」，
  /// 返回 null 由调用方照原样报错。
  Future<BabyOverview?> read() async {
    try {
      final body = jsonDecode(await File(await _path()).readAsString());
      if (body is! Map<String, dynamic>) {
        return null;
      }
      return BabyOverview.fromJson(body);
    } catch (_) {
      return null;
    }
  }

  Future<void> write({
    required List<Baby> babies,
    BabyGrowthStatistics? latestGrowth,
    BabyVaccineStatistics? vaccineTodo,
  }) async {
    try {
      final target = File(await _path());
      final temp = File('${target.path}.tmp');
      final envelope = BabyOverview(
        savedAt: DateTime.now(),
        babies: babies,
        latestGrowth: latestGrowth,
        vaccineTodo: vaccineTodo,
      );
      await temp.writeAsString(jsonEncode(envelope.toJson()), flush: true);
      await temp.rename(target.path);
    } catch (_) {
      // 同 StatisticsCacheStore：写失败吞掉，缓存是优化不是功能。
    }
  }

  /// 设置页「清除本地缓存」调它（§4.7；本文件是第 24 轮 (t) 由四类扩为五类时加进来的第五类）。
  Future<void> clear() async {
    try {
      final file = File(await _path());
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 删失败也吞掉：这一次没清掉，下一次成功加载会整份覆盖回来。
    }
  }

  Future<String> _path() async => '${(await _directoryResolver()).path}/$_file';
}

final babyOverviewCacheStoreProvider = Provider<BabyOverviewCacheStore>(
  (ref) => BabyOverviewCacheStore(),
);
