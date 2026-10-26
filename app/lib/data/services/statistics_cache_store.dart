import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/finance_statistics.dart';
import '../models/transaction_summary.dart';

/// 统计快照，单槽一个文件（§5.4、§6.1）。
///
/// 与流水缓存的规则刻意不同：**每次成功查询都写**，新的盖旧的。统计响应是「一组条件下的一个结果」，
/// 不存在「拼起来才是全集」的问题；流水列表分页拼出来的才是全集，所以那边只写不带条件的。
///
/// 存下 `query` 是为了离线时能把界面的区间 chips 拨回数据真正覆盖的那一段：
/// chips 上写着「本月」而数据是上周算的，比明确显示一个自定义区间更容易被当成 bug。
class StatisticsCacheStore {
  StatisticsCacheStore({Future<Directory> Function()? directoryResolver})
    : _directoryResolver = directoryResolver ?? getApplicationSupportDirectory;

  static const String _file = 'stats-finance.json';

  final Future<Directory> Function() _directoryResolver;

  /// 读不到就是「没有快照」，返回 null 由仓库照原样报错。
  ///
  /// 出参用命名 record 而不是再造一个 freezed 类：这四样东西只在这一个方法里被拼起来、
  /// 在仓库里被拆开，值相等与 copyWith 对它没有意义，多一对生成文件换不来任何东西。
  Future<
    ({
      DateTime savedAt,
      StatisticsQuery query,
      TransactionSummary summary,
      FinanceStatistics overview,
    })?
  >
  read() async {
    try {
      final body = jsonDecode(await File(await _path()).readAsString());
      if (body is! Map<String, dynamic>) {
        return null;
      }
      final savedAt = body['savedAt'];
      final query = body['query'];
      final summary = body['summary'];
      final overview = body['overview'];
      if (savedAt is! String ||
          query is! Map<String, dynamic> ||
          summary is! Map<String, dynamic> ||
          overview is! Map<String, dynamic>) {
        return null;
      }
      final at = DateTime.tryParse(savedAt);
      if (at == null) {
        return null;
      }
      return (
        savedAt: at,
        query: StatisticsQuery.fromJson(query),
        summary: TransactionSummary.fromJson(summary),
        overview: FinanceStatistics.fromJson(overview),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write({
    required StatisticsQuery query,
    required TransactionSummary summary,
    required FinanceStatistics overview,
  }) async {
    try {
      final target = File(await _path());
      final temp = File('${target.path}.tmp');
      final envelope = {
        'savedAt': DateTime.now().toIso8601String(),
        'query': query.toJson(),
        'summary': summary.toJson(),
        'overview': overview.toJson(),
      };
      await temp.writeAsString(jsonEncode(envelope), flush: true);
      await temp.rename(target.path);
    } catch (_) {
      // 同 DictCacheStore：写失败吞掉，缓存是优化不是功能。
    }
  }

  /// 设置页「清除本地缓存」调它（§4.7）。
  Future<void> clear() async {
    try {
      final file = File(await _path());
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 同上。
    }
  }

  Future<String> _path() async => '${(await _directoryResolver()).path}/$_file';
}

final statisticsCacheStoreProvider = Provider<StatisticsCacheStore>(
  (ref) => StatisticsCacheStore(),
);
