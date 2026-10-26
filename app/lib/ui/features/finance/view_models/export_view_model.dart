import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/models/export_format.dart';
import '../../../../data/models/finance_statistics.dart';
import '../../../../data/models/transaction_summary.dart';
import '../../../../data/repositories/export_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../../data/services/file_sharer.dart';
import '../../../core/error_copy.dart';

part 'export_view_model.freezed.dart';

/// §4.2.7 导出页的状态。
@freezed
abstract class ExportState with _$ExportState {
  const factory ExportState({
    @Default(ExportFormat.xlsx) ExportFormat format,

    /// 从统计页进来时带的是统计页当前那套条件（F6 的 `exportWith` 把它编进路由的
    /// 查询参数），从设置页进来时是这个默认值，也就是「导出全部」。
    @Default(StatisticsQuery()) StatisticsQuery query,
    TransactionSummary? summary,
    @Default(false) bool counting,
    @Default(false) bool exporting,
    String? error,
  }) = _ExportState;
}

/// 用 `Notifier` 而不是 `AsyncNotifier`：这一页没有「先加载好才有内容」的形态。
/// 格式选择器与继承来的条件在 build 时就定了，行数只是个附属提示，查行数加载中 / 失败
/// 都只该影响「共 N 笔」那一句，不该把整页换成转圈或换成错误页。
class ExportViewModel extends Notifier<ExportState> {
  int _generation = 0;

  @override
  ExportState build() => const ExportState();

  /// 页面 init 时调一次，把路由带来的条件装进去并查一次行数。
  ///
  /// 不放在 `build()` 里自动查：provider 每次重建都会跑 `build`，用户改一次格式就白跑一趟
  /// 概览接口。行数只在条件变化时重算。
  Future<void> open(StatisticsQuery query) async {
    state = state.copyWith(query: query, summary: null);
    await _count();
  }

  void selectFormat(ExportFormat format) =>
      state = state.copyWith(format: format);

  /// 导出页上改时间范围或记录人（§4.2.7：「用户可在导出页改」）。
  Future<void> applyQuery(StatisticsQuery query) async {
    state = state.copyWith(query: query, summary: null);
    await _count();
  }

  /// 生成文件并交给系统分享面板。成功回 null，失败回要显示给用户的那句话。
  Future<String?> export() async {
    // 连点两下会并发两个几 MB 的下载，这里挡一道
    if (state.exporting) {
      return null;
    }
    state = state.copyWith(exporting: true, error: null);
    try {
      final file = await _repository.download(state.query, state.format);
      // `DownloadedFile` 那边叫 contentType，`FileSharer.shareBytes` 这边叫 mimeType，
      // 是同一个值——前者是 HTTP 的说法，后者是分享面板的说法
      await ref
          .read(fileSharerProvider)
          .shareBytes(
            bytes: file.bytes,
            filename: file.filename,
            mimeType: file.contentType,
          );
    } on ApiException catch (e) {
      state = state.copyWith(exporting: false, error: errorCopy(e));
      return errorCopy(e);
    } catch (e) {
      // shareBytes 走文件 I/O 与平台通道，磁盘满或通道异常时抛的不是 ApiException
      state = state.copyWith(exporting: false, error: errorCopy(e));
      return errorCopy(e);
    }
    state = state.copyWith(exporting: false);
    return null;
  }

  /// 行数查不到**不拦导出**。这句「共 N 笔」是个体量提示，真正的 5 万行上限由后端在生成
  /// 时判（B7），判超限回 400 + JSON，那条路走的是 `export()` 的 catch，文案用后端那句。
  ///
  /// `_generation` 挡的是并发：进页面预查一趟，用户紧接着改了条件又查一趟，两趟都在飞的时候
  /// 慢的那趟后到，笔数就停在旧条件上——chips 写着「本月」而规模写着「共 8 万笔」，
  /// 用户会照着那个数决定要不要导出。
  Future<void> _count() async {
    final generation = ++_generation;
    state = state.copyWith(counting: true, error: null);
    try {
      final summary = await _repository.count(state.query);
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(counting: false, summary: summary);
    } on ApiException catch (e) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(counting: false, error: errorCopy(e));
    } catch (e) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(counting: false, error: errorCopy(e));
    }
  }

  ExportRepository get _repository => ref.read(exportRepositoryProvider);
}

final exportViewModelProvider = NotifierProvider<ExportViewModel, ExportState>(
  ExportViewModel.new,
);
