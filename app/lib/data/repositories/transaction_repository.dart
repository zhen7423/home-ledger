import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/core/date_format.dart';
import '../../ui/core/money.dart';
import '../models/flow_type.dart';
import '../models/month_summary.dart';
import '../models/transaction.dart';
import '../models/transaction_page.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/transaction_cache_store.dart';

/// 一次分页加载的结果。`fromCache` 为 true 时 `savedAt` 一定有值（横幅上那句「数据截至 XX」要用），
/// 为 false 时一定是 null。
class TransactionPageResult {
  const TransactionPageResult(
    this.page, {
    required this.fromCache,
    this.savedAt,
  });

  final TransactionPage page;
  final bool fromCache;
  final DateTime? savedAt;
}

/// §4.2.5 的流水：分页查询、单笔详情、记一笔、改一笔、删一笔。
///
/// **查询接了本地缓存**（§5.4，S5 关闭验收用例 33）：先试网络，只有传输层失败才回落到按月存的 JSON；
/// 回落时筛选与月度小计在内存里重算，且**没有分页**——一口气把缓存里符合区间的都给出。
/// **写操作必须联网**：没有本地写队列，也没有冲突合并，断网时界面上那五个保存按钮是禁用的。
///
/// 入参里的日期一律是 `"2026-09-11"` 这样的字符串而不是 `DateTime`：查询串由 dio 用 `toString()`
/// 拼、请求体由 `toJson` 走 ISO 8601，两种都会带出时刻后缀，后端那三个 `LocalDate` 参数解不开。
/// 格式化归界面层负责，见 `ui/core/date_format.dart`。
class TransactionRepository {
  TransactionRepository({required this._api, required this._cache});

  final ApiClient _api;
  final TransactionCacheStore _cache;

  Future<TransactionPageResult> page(TransactionPageQuery query) async {
    try {
      final data = await _api.get('/transactions', query: query.toQuery());
      final page = TransactionPage.fromJson(requireData(data));
      if (query.isUnfiltered) {
        await _cache.merge(page.records);
      }
      return TransactionPageResult(page, fromCache: false);
    } on ApiException catch (e) {
      if (!e.isTransportFailure) {
        rethrow;
      }
      final cached = await _cache.readRange(
        DateTime.tryParse(query.startDate ?? ''),
        DateTime.tryParse(query.endDate ?? ''),
      );
      // 缓存是空的就照原样报错：分不清「真的一笔都没有」与「从来没缓存过」，
      // 而后者显示成空列表会让用户以为账没了。
      if (cached.rows.isEmpty) {
        rethrow;
      }
      final rows = applyFilters(cached.rows, query)..sort(_byDateDescending);
      return TransactionPageResult(
        TransactionPage(
          records: rows,
          total: rows.length,
          page: 1,
          size: query.size,
          // pages 为 1 让 ViewModel 那边的 hasMore 自然落成 false：离线没有下一页可翻。
          pages: 1,
          monthSummaries: summarizeByMonth(rows),
        ),
        fromCache: true,
        savedAt: cached.savedAt,
      );
    }
  }

  /// 离线时详情也读缓存（§12：断网时流水仍可读）。列表上那一行点得动，点进去只有报错就说不过去。
  ///
  /// 这里不必把 fromCache 一起交出去：详情页的横幅直接看 `networkStatusProvider`——
  /// 在这个页面上「离线」与「数据来自缓存」是同一件事（够得着后端就一定拿的是新数据）。
  /// 列表页与统计页不能用这个替代，因为它们可能正显示着几分钟前拿到的数据，
  /// 而此刻某个不相干的请求失败了。
  Future<Transaction> get(int id) async {
    try {
      final data = await _api.get('/transactions/$id');
      return Transaction.fromJson(requireData(data));
    } on ApiException catch (e) {
      if (!e.isTransportFailure) {
        rethrow;
      }
      final cached = await _cache.readId(id);
      if (cached == null) {
        rethrow;
      }
      return cached;
    }
  }

  /// 收支类型由后端从所选类别推出，客户端不传 `type`。
  /// `subCategoryId` 允许为空，含义是「未细分」（需求文档 A2）。
  Future<Transaction> create({
    required String amount,
    required int categoryId,
    int? subCategoryId,
    required int accountId,
    required String bizDate,
    String? remark,
  }) async {
    final data = await _api.post(
      '/transactions',
      body: _body(
        amount: amount,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        accountId: accountId,
        bizDate: bizDate,
        remark: remark,
      ),
    );
    final created = Transaction.fromJson(requireData(data));
    // 写成功后立刻并回缓存（§5.4 写操作对缓存的影响）。断网时压根到不了这一行，
    // 所以这里不存在「本地记了一笔但服务端没有」的状态。
    await _cache.merge([created]);
    return created;
  }

  /// 换类别会刷新名称快照，只改备注不会——历史流水上显示的还是当初记下那几个字（A3）。
  Future<Transaction> update(
    int id, {
    required String amount,
    required int categoryId,
    int? subCategoryId,
    required int accountId,
    required String bizDate,
    String? remark,
  }) async {
    final data = await _api.patch(
      '/transactions/$id',
      body: _body(
        amount: amount,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        accountId: accountId,
        bizDate: bizDate,
        remark: remark,
      ),
    );
    final updated = Transaction.fromJson(requireData(data));
    // 改了 bizDate 会让这一条落到另一个月文件里：先摘掉旧的再并入新的，
    // 否则同一条流水会在两个月份文件里各留一份，离线列表上出现两行。
    await _cache.removeId(id);
    await _cache.merge([updated]);
    return updated;
  }

  /// 软删除。二次确认在界面上做，「有流水就不许物理删除类别」那条判定算的就是这些已删的行。
  Future<void> remove(int id) async {
    await _api.delete('/transactions/$id');
    await _cache.removeId(id);
  }

  Map<String, Object?> _body({
    required String amount,
    required int categoryId,
    int? subCategoryId,
    required int accountId,
    required String bizDate,
    String? remark,
  }) => {
    'amount': amount,
    'categoryId': categoryId,
    'subCategoryId': subCategoryId,
    'accountId': accountId,
    'bizDate': bizDate,
    'remark': remark,
  };
}

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(
    api: ref.watch(apiClientProvider),
    cache: ref.watch(transactionCacheStoreProvider),
  ),
);

/// 离线读取时在内存里重算筛选，**逐条对齐 `TransactionMapper.xml` 的 `<sql id="filters">`**。
/// 少一条或多一条，「在线看到的」与「断网看到的」就不是同一批数据，而这种不一致只有用户会告诉你。
///
/// 抽成顶层纯函数而不是私有方法：测试不必先造一个仓库和一个缓存目录。
List<Transaction> applyFilters(
  List<Transaction> rows,
  TransactionPageQuery query,
) {
  final start = DateTime.tryParse(query.startDate ?? '');
  final end = DateTime.tryParse(query.endDate ?? '');
  final type = _orNull(query.type);
  final source = _orNull(query.source);
  final keyword = _orNull(query.keyword)?.toLowerCase();

  // 金额在线上是后端按 DECIMAL 比的，"12.3" 与 "12.30" 相等；字符串直接 == 会把它们当成两个值。
  // 输错的金额（"12.3.4"）在线上是 400，离线没有后端可问，一律谁都不匹配。
  final int? amountCents;
  if (_orNull(query.amount) == null) {
    amountCents = null;
  } else {
    try {
      amountCents = toCents(query.amount!);
    } on FormatException {
      return const [];
    }
  }

  return [
    for (final row in rows)
      if ((start == null || !row.bizDate.isBefore(start)) &&
          (end == null || !row.bizDate.isAfter(end)) &&
          (type == null || row.type == type) &&
          (query.categoryId == null || row.categoryId == query.categoryId) &&
          // 小类为 null 的流水永远匹配不上一个具体的 subCategoryId：SQL 里 NULL = 3 也是不成立。
          (query.subCategoryId == null ||
              row.subCategoryId == query.subCategoryId) &&
          (query.accountId == null || row.accountId == query.accountId) &&
          (query.createdBy == null || row.createdBy == query.createdBy) &&
          (amountCents == null || toCents(row.amount) == amountCents) &&
          // MySQL 的 utf8mb4_0900_ai_ci 让 LIKE 不分大小写，内存里也得一样，
          // 否则搜「Starbucks」在线上有结果、断网后一条都没有。
          (keyword == null ||
              (row.remark ?? '').toLowerCase().contains(keyword)) &&
          _sourceMatches(source, row))
        row,
  ];
}

bool _sourceMatches(String? source, Transaction row) => switch (source) {
  // 来源不是一列，是 rule_id 有没有值（同 XML 里那段注释）。
  // 未知取值两个分支都不命中，等于「不筛」——照抄 XML，不擅自当成 MANUAL。
  'AUTO' => row.ruleId != null,
  'MANUAL' => row.ruleId == null,
  _ => true,
};

/// XML 里那几处 `!= null and != ''`：空串等于没筛。
String? _orNull(String? value) =>
    (value == null || value.isEmpty) ? null : value;

/// 离线重算月度小计，口径逐条对齐 `selectMonthSummaries`：
/// 收入求和、支出求和、结余 = 收入 - 支出、笔数计数、月份降序。
///
/// 结余是「收入减支出」而不是「带符号求和」，两种写法在出现负数金额时会分家，而 SQL 用的是前者。
/// 全程用「分」这个整数单位，不碰 double（§4.2.1）。
List<MonthSummary> summarizeByMonth(List<Transaction> rows) {
  final byMonth = <String, ({int income, int expense, int count})>{};
  for (final row in rows) {
    final month = monthKey(row.bizDate);
    final current = byMonth[month] ?? (income: 0, expense: 0, count: 0);
    final cents = toCents(row.amount);
    byMonth[month] = row.type == FlowType.income
        ? (
            income: current.income + cents,
            expense: current.expense,
            count: current.count + 1,
          )
        : (
            income: current.income,
            expense: current.expense + cents,
            count: current.count + 1,
          );
  }
  // 月份串是 yyyy-MM 定长的，按字典序倒排就是按时间倒排（同 selectMonthSummaries 的 ORDER BY month DESC）。
  final months = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final month in months)
      MonthSummary(
        month: month,
        income: fromCents(byMonth[month]!.income),
        expense: fromCents(byMonth[month]!.expense),
        balance: fromCents(byMonth[month]!.income - byMonth[month]!.expense),
        count: byMonth[month]!.count,
      ),
  ];
}

/// 服务端的排序口径：`ORDER BY t.biz_date DESC, t.id DESC`。
int _byDateDescending(Transaction a, Transaction b) {
  final byDate = b.bizDate.compareTo(a.bizDate);
  return byDate != 0 ? byDate : b.id.compareTo(a.id);
}
