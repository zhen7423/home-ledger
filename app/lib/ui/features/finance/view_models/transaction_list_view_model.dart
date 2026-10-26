import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/models/month_summary.dart';
import '../../../../data/models/transaction.dart';
import '../../../../data/models/transaction_page.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';

part 'transaction_list_view_model.freezed.dart';

/// 流水列表的筛选条件。界面上是一个筛选条，落到请求上就是 `TransactionPageQuery`。
///
/// 日期用 `DateTime` 而不是字符串：选择器给的就是 `DateTime`，转成 `yyyy-MM-dd` 由
/// `_queryFor` 一处负责，界面上不必提前格式化。
@freezed
abstract class TransactionFilter with _$TransactionFilter {
  const factory TransactionFilter({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? categoryId,
    int? subCategoryId,
    int? accountId,
    int? createdBy,
    String? keyword,
    String? amount,

    /// `'AUTO'` 只看周期规则自动生成的，`'MANUAL'` 只看手记的，null 不限。
    /// 首页那块「今天已自动生成 N 笔」点进来带的就是它。
    String? source,
  }) = _TransactionFilter;
}

/// 列表里一个月的那一段：月份、后端给的该月小计、这个月已加载到的流水。
class TransactionGroup {
  const TransactionGroup({
    required this.month,
    required this.summary,
    required this.items,
  });

  /// 形如 "2026-09"，由后端 `DATE_FORMAT(biz_date, '%Y-%m')` 那套口径给出。
  final String month;

  /// 该月小计。筛选结果里这个月一条都没有时为 null，界面按「没有小计」处理。
  final MonthSummary? summary;

  final List<Transaction> items;
}

@freezed
abstract class TransactionListState with _$TransactionListState {
  const factory TransactionListState({
    @Default(<TransactionGroup>[]) List<TransactionGroup> groups,
    @Default(1) int page,
    @Default(0) int pages,
    @Default(false) bool hasMore,
    @Default(TransactionFilter()) TransactionFilter filter,
    @Default(false) bool loadingMore,

    /// 这一屏的数据是本地缓存供的（§5.4）。为 true 时列表顶上挂「离线模式 · 数据截至 …」横幅。
    @Default(false) bool fromCache,

    /// 缓存里**最早**那份月份文件的写入时刻。离线时读的是好几个月的文件，取最早的而不是
    /// 最晚的，理由写在 `TransactionCacheStore.readRange` 的注释里：宁可悲观也不能谎报新鲜度。
    DateTime? savedAt,
  }) = _TransactionListState;
}

/// §4.2.5 的流水列表：分页、筛选、按月分组。
///
/// 分组在这里做而不是在界面里：一页 30 条会跨月，界面上每组还要带该月小计，
/// 让 widget 边滚动边算这些，等于把一份业务逻辑摊进 build。
class TransactionListViewModel extends AsyncNotifier<TransactionListState> {
  @override
  Future<TransactionListState> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const TransactionListState();
    }
    return _load(filter: const TransactionFilter(), page: 1);
  }

  /// 改筛选条件一律回到第 1 页重来：往旧条件的尾巴上追加，列表里会混进两页条件不符的数据。
  Future<String?> apply(TransactionFilter filter) =>
      _run(() => _load(filter: filter, page: 1));

  /// 从新增 / 编辑页返回后调一次。写发生在别的页面，这边只能重拉，而且要保持当前筛选条件。
  Future<String?> reload() => _run(
    () => _load(
      filter: state.value?.filter ?? const TransactionFilter(),
      page: 1,
    ),
  );

  Future<String?> remove(int id) => _run(() async {
    await _repository.remove(id);
    return _load(
      filter: state.value?.filter ?? const TransactionFilter(),
      page: 1,
    );
  });

  /// 上拉加载。追加而非替换：同月的流水要并进同一组，月份组始终按新在前排列。
  Future<String?> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) {
      return null;
    }
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      state = AsyncData(
        await _load(
          filter: current.filter,
          page: current.page + 1,
          existing: current.groups,
        ),
      );
    } on ApiException catch (e) {
      // 回到追加前的样子，别把列表永久卡在「加载中」那格转圈上。
      state = AsyncData(current);
      return errorCopy(e);
    }
    return null;
  }

  TransactionRepository get _repository =>
      ref.read(transactionRepositoryProvider);

  Future<TransactionListState> _load({
    required TransactionFilter filter,
    required int page,
    List<TransactionGroup> existing = const [],
  }) async {
    final result = await _repository.page(_queryFor(filter, page));
    final loaded = result.page;
    return TransactionListState(
      groups: _group(existing, loaded.records, {
        for (final s in loaded.monthSummaries) s.month: s,
      }),
      page: loaded.page,
      pages: loaded.pages,
      hasMore: loaded.page < loaded.pages,
      filter: filter,
      fromCache: result.fromCache,
      savedAt: result.savedAt,
    );
  }

  /// 删一条之后重从第 1 页拉：月度小计、总条数、后续已加载的页都跟着变了，
  /// 逐条就地改状态很容易对不平，少拉一次网络省下的不值这个风险。
  Future<String?> _run(Future<TransactionListState> Function() action) async {
    try {
      state = AsyncData(await action());
    } on ApiException catch (e) {
      return errorCopy(e);
    }
    return null;
  }

  TransactionPageQuery _queryFor(TransactionFilter filter, int page) {
    final start = filter.startDate;
    final end = filter.endDate;
    return TransactionPageQuery(
      startDate: start == null ? null : formatDate(start),
      endDate: end == null ? null : formatDate(end),
      type: filter.type,
      categoryId: filter.categoryId,
      subCategoryId: filter.subCategoryId,
      accountId: filter.accountId,
      createdBy: filter.createdBy,
      keyword: filter.keyword,
      amount: filter.amount,
      source: filter.source,
      page: page,
    );
  }

  List<TransactionGroup> _group(
    List<TransactionGroup> existing,
    List<Transaction> incoming,
    Map<String, MonthSummary> summaries,
  ) {
    final grouped = <String, List<Transaction>>{
      for (final group in existing) group.month: [...group.items],
    };
    for (final transaction in incoming) {
      grouped
          .putIfAbsent(monthKey(transaction.bizDate), () => [])
          .add(transaction);
    }
    // 月份串是 yyyy-MM 定长的，按字典序倒排就是按时间倒排
    final months = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final month in months)
        TransactionGroup(
          month: month,
          summary: summaries[month],
          items: grouped[month]!,
        ),
    ];
  }
}

final transactionListViewModelProvider =
    AsyncNotifierProvider<TransactionListViewModel, TransactionListState>(
      TransactionListViewModel.new,
    );
