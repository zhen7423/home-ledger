import 'dart:async';
import 'dart:typed_data';

import 'package:homeledger/data/models/export_format.dart';
import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/data/models/transaction_summary.dart';
import 'package:homeledger/data/repositories/export_repository.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/data/services/api_exception.dart';

/// 导出仓库替身。真那份要下载几 MB 字节，替身只回一段固定字节并把条件记下来。
class FakeExportRepository implements ExportRepository {
  FakeExportRepository({required this.summary});

  /// `count` 回的就是这一份。
  final TransactionSummary summary;

  final List<StatisticsQuery> countQueries = [];
  final List<({StatisticsQuery query, ExportFormat format})> downloads = [];

  /// 非 null 时 `count` 抛它。「行数查不到不拦导出」（F5③）这条要能被测到。
  ApiException? countError;

  /// 非 null 时 `download` 抛它。超限的 400 走这一条。
  ApiException? downloadError;

  /// 非 null 时 `count` 挂在这个 Completer 上，用来验 `_generation` 那道闸。
  Completer<TransactionSummary>? holdCount;

  Uint8List bytes = Uint8List.fromList(const [1, 2, 3]);

  String filename = '家记流水_2026-09-01_2026-09-14.xlsx';

  String contentType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  @override
  Future<TransactionSummary> count(StatisticsQuery query) {
    countQueries.add(query);
    final held = holdCount;
    if (held != null) {
      return held.future;
    }
    final thrown = countError;
    if (thrown != null) {
      return Future.error(thrown);
    }
    return Future.value(summary);
  }

  @override
  Future<DownloadedFile> download(
    StatisticsQuery query,
    ExportFormat format,
  ) async {
    downloads.add((query: query, format: format));
    final thrown = downloadError;
    if (thrown != null) {
      throw thrown;
    }
    return DownloadedFile(
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }
}
