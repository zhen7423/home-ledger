import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/data/models/transaction_summary.dart';
import 'package:homeledger/data/repositories/statistics_repository.dart';
import 'package:homeledger/data/services/api_exception.dart';

/// 统计仓库替身。真那份要两个端点加一份磁盘快照，页面与 ViewModel 测试里既跑不起来也没必要跑。
///
/// `implements` 一个具体类是本项目既有做法（`_FakeBudgetRepository` 就是这么写的）：
/// Dart 只要求实现公开成员，那两个私有字段不构成接口的一部分。
class FakeStatisticsRepository implements StatisticsRepository {
  FakeStatisticsRepository({required this.summary, required this.overview});

  /// `load` 回的就是这两份，页面与 ViewModel 测试要别的形态在调用处给。
  final TransactionSummary summary;
  final FinanceStatistics overview;

  /// 每次 `load` 把条件记下来，用来断言「点了区间 chip 之后真的带着新条件又查了一趟」。
  final List<StatisticsQuery> queries = [];

  /// 非 null 时 `load` 抛它。缓存回落那条路在真仓库里自己判，替身只管抛。
  ApiException? error;

  /// 非 null 时 `load` 回它而不是现拼一份——命中快照那一支就是这么回来的。
  StatisticsLoadResult? snapshot;

  int get loadCalls => queries.length;

  @override
  Future<StatisticsLoadResult> load(StatisticsQuery query) async {
    queries.add(query);
    final thrown = error;
    if (thrown != null) {
      throw thrown;
    }
    final cached = snapshot;
    if (cached != null) {
      return cached;
    }
    return StatisticsLoadResult(
      summary,
      overview,
      query: query,
      fromCache: false,
    );
  }
}
