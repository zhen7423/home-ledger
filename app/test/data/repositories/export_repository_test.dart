import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/export_format.dart';
import 'package:homeledger/data/models/finance_statistics.dart';
import 'package:homeledger/data/repositories/export_repository.dart';
import 'package:homeledger/data/services/api_client.dart';
import 'package:homeledger/data/services/api_exception.dart';
import 'package:homeledger/data/services/statistics_cache_store.dart';

import '../../support/fake_http.dart';
import '../../support/fake_token_storage.dart';
import '../../support/s5_fixtures.dart';

/// 导出的两件事：把条件编进查询串，把响应头里的文件名安全地接下来。
/// 真下载只到 `ApiClient` 那一层为止，这里给的是三个字节。
void main() {
  late Directory root;
  late StatisticsCacheStore snapshots;
  late ExportRepository repository;
  late ScriptedHttp http;

  const query = StatisticsQuery(startDate: '2026-09-01', endDate: '2026-09-14');

  void stub(ResponseBody Function(RequestOptions options) script) {
    http = ScriptedHttp(script);
    repository = ExportRepository(
      api: ApiClient(
        storage: FakeTokenStorage(),
        adapter: http,
        origin: 'http://test.local',
      ),
    );
  }

  /// 下载成功，文件名由响应头给。
  void stubDownload(String disposition) {
    stub(
      (_) => binary(const [1, 2, 3], disposition: 'attachment; $disposition'),
    );
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('export_repository');
    snapshots = StatisticsCacheStore(directoryResolver: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('format 跟着单选走', () async {
    stubDownload('filename="a.xlsx"');
    await repository.download(const StatisticsQuery(), ExportFormat.xlsx);

    expect(http.call.path, '/api/v1/export/transactions');
    expect(http.call.method, 'GET');
    expect(http.call.query['format'], 'xlsx');

    stubDownload('filename="a.csv"');
    await repository.download(const StatisticsQuery(), ExportFormat.csv);

    expect(http.call.query['format'], 'csv');
  });

  test('统计条件原样带过去，空着的那项不进查询串', () async {
    stubDownload('filename="a.xlsx"');

    await repository.download(query, ExportFormat.xlsx);

    expect(http.call.query, {
      'startDate': '2026-09-01',
      'endDate': '2026-09-14',
      'format': 'xlsx',
    });
  });

  test('UTF-8 编码过的中文文件名解得回来', () async {
    stubDownload(
      "filename*=UTF-8''%E5%AE%B6%E8%AE%B0%E6%B5%81%E6%B0%B4_2026-09.xlsx",
    );

    final file = await repository.download(query, ExportFormat.xlsx);

    expect(file.filename, '家记流水_2026-09.xlsx');
  });

  test('没编码的那一支也认，带不带引号都行', () async {
    stubDownload('filename="export.csv"');
    expect(
      (await repository.download(query, ExportFormat.csv)).filename,
      'export.csv',
    );

    stubDownload('filename=export.csv');
    expect(
      (await repository.download(query, ExportFormat.csv)).filename,
      'export.csv',
    );
  });

  test('响应头压根没给文件名时用兜底名', () async {
    stub((_) => binary(const [1, 2, 3]));

    final file = await repository.download(query, ExportFormat.xlsx);

    expect(file.filename, 'export.bin');
    expect(file.bytes, [1, 2, 3]);
    expect(
      file.contentType,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  });

  test('名字里的路径分隔符换成下划线：响应头来的东西不能拼进本地路径', () async {
    stubDownload('filename="../../evil.xlsx"');

    final name = (await repository.download(query, ExportFormat.xlsx)).filename;

    expect(name, isNot(contains('/')));
    expect(name, isNot(contains(r'\')));
    expect(name, '.._.._evil.xlsx');
  });

  test('导出超限的 400 把后端那句话原样交出去', () async {
    stub(
      (_) => envelope(
        code: 'BAD_REQUEST',
        message: '本次要导出 80000 笔，超过上限 50000 笔，请缩小时间区间后再试',
        status: 400,
      ),
    );

    // 下载走的是 ResponseType.bytes，出错时响应体是一串字节。解不回来的话
    // 界面上就只剩一句「导出失败」，用户不知道该缩哪个区间（F2①）。
    await expectLater(
      repository.download(query, ExportFormat.xlsx),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'BAD_REQUEST')
            .having(
              (e) => e.message,
              'message',
              '本次要导出 80000 笔，超过上限 50000 笔，请缩小时间区间后再试',
            ),
      ),
    );
  });

  test('数行数打的是概览端点，且不写统计快照', () async {
    stub((_) => envelope(data: summary().toJson()));

    final result = await repository.count(query);

    expect(http.call.path, '/api/v1/transactions/summary');
    expect(result.count, 12);
    // 导出页的条件可能来自设置页那个「导出全部」，写进单槽快照会把统计页的离线数据顶掉。
    expect(await snapshots.read(), isNull);
  });
}
