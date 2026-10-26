import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/export_format.dart';
import '../models/finance_statistics.dart';
import '../models/transaction_summary.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

/// §4.2.7 的导出。同步生成文件流，没有任务 id、没有轮询、没有进度回调。
class ExportRepository {
  ExportRepository({required this._api});

  final ApiClient _api;

  /// 行数超限是 400 + JSON，ApiClient 会把它翻成 ApiException（F2 的 `_bodyOf` 就是为这一步修的）。
  /// 文案直接用后端抛出的那句（B7：`本次要导出 N 笔，超过上限 50000 笔，请缩小时间区间后再试`），前端不另抄一份。
  Future<DownloadedFile> download(StatisticsQuery query, ExportFormat format) =>
      _api.download(
        '/export/transactions',
        query: {...query.toQuery(), 'format': format.param},
      );

  /// 导出页那句「共 N 笔」（§4.2.7）。
  ///
  /// 走的是统计概览那个端点，但**不写快照**：导出页的条件可能与统计页不同——从设置页
  /// 进来时是「导出全部」——把它写进 F4② 那个单槽快照会把统计页的离线数据顶掉，
  /// 用户断网再回统计页，看到的是另一套条件下的数，横幅上那个时刻也对不上。
  Future<TransactionSummary> count(StatisticsQuery query) async {
    final data = await _api.get(
      '/transactions/summary',
      query: query.toQuery(),
    );
    return TransactionSummary.fromJson(requireData(data));
  }
}

final exportRepositoryProvider = Provider<ExportRepository>(
  (ref) => ExportRepository(api: ref.watch(apiClientProvider)),
);
