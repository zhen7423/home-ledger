import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/cat.dart';
import '../models/cat_food_bag.dart';
import '../models/cat_food_estimate.dart';
import '../models/cat_statistics.dart';

/// 猫咪总览页的快照，单槽一个文件（§5.4）。
///
/// 信封里存的是**成品模型**而不是响应原文：`cats` 与 `dueCountdown` 在写入前已经过一遍
/// `fromJson`，读的时候不必再碰 JSON，「离线打开总览」与「在线打开总览」因此走同一段渲染代码。
///
/// 只存总览页那三张卡。余量那一卡要 `bag` 与 `estimate` 两份：品牌与开始日只存在于
/// [CatFoodBag]，只存推算的话离线打开会把卡片第一列渲染成空的。统计页与三个列表页不进快照——
/// 总览页是离线时唯一会去看的猫页面，而那些图表本来就是「最近算过一次」的产物。
///
/// 没有 `query` 字段：总览页没有可选条件，`savedAt` 一个时间戳就足够解释「这是什么时候的」，
/// 不像统计那边要把区间 chips 拨回数据真正覆盖的那一段。
class CatOverviewCacheStore {
  /// `directoryResolver` 是测试注入临时目录的口子（同统计快照），读写两条路径都靠它测。
  CatOverviewCacheStore({Future<Directory> Function()? directoryResolver})
    : _directoryResolver = directoryResolver ?? getApplicationSupportDirectory;

  static const String _file = 'cat-overview.json';

  final Future<Directory> Function() _directoryResolver;

  /// 读不到就是「没有快照」，返回 null 由仓库照原样报错。出参用命名 record 的理由同统计那一份。
  Future<
    ({
      DateTime savedAt,
      List<Cat> cats,
      CatFoodBag? bag,
      CatFoodEstimate? estimate,
      List<CatDueCountdownItem> dueCountdown,
    })?
  >
  read() async {
    try {
      final body = jsonDecode(await File(await _path()).readAsString());
      if (body is! Map<String, dynamic>) {
        return null;
      }
      final savedAt = body['savedAt'];
      final cats = body['cats'];
      final dueCountdown = body['dueCountdown'];
      if (savedAt is! String ||
          cats is! List ||
          dueCountdown is! List ||
          DateTime.tryParse(savedAt) == null) {
        return null;
      }
      final bag = body['bag'];
      final estimate = body['estimate'];
      return (
        savedAt: DateTime.parse(savedAt),
        cats: cats
            .map((row) => Cat.fromJson(row as Map<String, dynamic>))
            .toList(),
        // 这两栏「可以没有」不是「坏了」：一袋都还没开时它们同时为 null
        bag: bag is Map<String, dynamic> ? CatFoodBag.fromJson(bag) : null,
        estimate: estimate is Map<String, dynamic>
            ? CatFoodEstimate.fromJson(estimate)
            : null,
        dueCountdown: dueCountdown
            .map(
              (row) =>
                  CatDueCountdownItem.fromJson(row as Map<String, dynamic>),
            )
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write({
    required List<Cat> cats,
    required CatFoodBag? bag,
    required CatFoodEstimate? estimate,
    required List<CatDueCountdownItem> dueCountdown,
  }) async {
    try {
      final target = File(await _path());
      final temp = File('${target.path}.tmp');
      final envelope = {
        'savedAt': DateTime.now().toIso8601String(),
        'cats': cats.map((row) => row.toJson()).toList(),
        // null 而不是 0：一袋都没有与「剩 0 g」是两件事，界面上是两句不同的话
        'bag': bag?.toJson(),
        'estimate': estimate?.toJson(),
        'dueCountdown': dueCountdown.map((row) => row.toJson()).toList(),
      };
      await temp.writeAsString(jsonEncode(envelope), flush: true);
      await temp.rename(target.path);
    } catch (_) {
      // 同 StatisticsCacheStore：写失败吞掉，缓存是优化不是功能。
    }
  }

  /// 设置页「清除本地缓存」调它（§4.7；本文件是第 23 轮 (i) 加进来的第四类）。
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

final catOverviewCacheStoreProvider = Provider<CatOverviewCacheStore>(
  (ref) => CatOverviewCacheStore(),
);
