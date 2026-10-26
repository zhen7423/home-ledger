import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../ui/core/date_format.dart';
import '../models/transaction.dart';

/// 流水的离线缓存：一个自然月一个文件（§5.4、§6.1）。
///
/// 形状照 `DictCacheStore`：目录可注入（测试指到临时目录）、先写 `.tmp` 再 rename、
/// 读写失败一律吞掉——这一层存在的意义就是网络不通时给用户看点东西，它自己不能再成为第二个故障源。
/// 多一个 `clock` 注入口，只因为淘汰是按月份算的，而测试等不了三个月。
///
/// 按月分文件而不是一个大文件：淘汰的单位就是月，一个大文件每次淘汰都要整份读回再整份写出；
/// 而合并写入只需要动被翻页碰到的那一个月。容量测算见 §5.4（约 1250 行 / 月，约 170 KB / 文件）。
class TransactionCacheStore {
  TransactionCacheStore({
    Future<Directory> Function()? directoryResolver,
    DateTime Function()? clock,
  }) : _directoryResolver = directoryResolver ?? getApplicationSupportDirectory,
       _clock = clock ?? DateTime.now;

  static const String _prefix = 'tx-';

  /// 当月 + 前两个自然月（§5.4 淘汰口径）。
  static const int _retained = 3;

  static final RegExp _fileName = RegExp(r'^tx-(\d{4}-\d{2})\.json$');

  final Future<Directory> Function() _directoryResolver;
  final DateTime Function() _clock;

  /// 合并写入。写成功之后顺手淘汰，所以调用方不需要另找地方触发它。
  Future<void> merge(List<Transaction> items) async {
    if (items.isEmpty) {
      return;
    }
    final byMonth = <String, List<Transaction>>{};
    for (final item in items) {
      byMonth.putIfAbsent(monthKey(item.bizDate), () => []).add(item);
    }
    for (final entry in byMonth.entries) {
      final existing = await _read(entry.key);
      // 按 id 合并：新拿到的那一条盖掉旧的同号条目，编辑过一笔之后缓存里不能留着编辑前的样子。
      final merged = <int, Transaction>{
        for (final row in existing.rows) row.id: row,
      };
      for (final row in entry.value) {
        merged[row.id] = row;
      }
      await _write(entry.key, _ordered(merged.values), _clock());
    }
    await _evict();
  }

  /// 读一段区间。`savedAt` 取的是**参与本次读取的几份文件里最早的那个写入时刻**：
  /// 报最晚的那个等于向用户保证「你看到的全部数据都是那一刻的」，而那只对最后翻过的那个月成立。
  /// 横幅上写「数据截至 XX」，宁可悲观也不能说谎。
  Future<({List<Transaction> rows, DateTime? savedAt})> readRange(
    DateTime? start,
    DateTime? end,
  ) async {
    final rows = <Transaction>[];
    DateTime? savedAt;
    for (final month in _retainedMonths()) {
      if (!_overlaps(month, start, end)) {
        continue;
      }
      final file = await _read(month);
      if (file.rows.isEmpty) {
        continue;
      }
      rows.addAll(file.rows);
      final at = file.savedAt;
      if (at != null && (savedAt == null || at.isBefore(savedAt))) {
        savedAt = at;
      }
    }
    return (rows: _ordered(rows), savedAt: savedAt);
  }

  /// 离线打开某一笔的详情（§12：断网时流水仍可读）。列表上那一行是点得动的，
  /// 点进去只有转圈加报错的话，「仍可读」就是句空话。
  Future<Transaction?> readId(int id) async {
    for (final month in _retainedMonths()) {
      for (final row in (await _read(month)).rows) {
        if (row.id == id) {
          return row;
        }
      }
    }
    return null;
  }

  /// 删一笔之后把它从缓存里也摘掉。只扫保留下来的那 ≤3 个文件——淘汰保证了更老的不在盘上，
  /// 所以调用方不必把 bizDate 一路传进来。
  Future<void> removeId(int id) async {
    for (final month in _retainedMonths()) {
      final file = await _read(month);
      final kept = [
        for (final row in file.rows)
          if (row.id != id) row,
      ];
      if (kept.length != file.rows.length) {
        // savedAt 原样带回去：删掉一条不等于「这份缓存刚刚同步过」。
        await _write(month, kept, file.savedAt ?? _clock());
      }
    }
  }

  /// 设置页「清除本地缓存」调它（§4.7）。删所有 `tx-` 开头的文件，写崩留下的 `.json.tmp` 一并带走。
  Future<void> clear() async {
    for (final name in await _cachedFileNames()) {
      await _delete(name);
    }
  }

  /// 服务端的排序口径：`ORDER BY t.biz_date DESC, t.id DESC`（同一天里多笔靠雪花 id 定序）。
  /// 缓存里存升序、交出去前排成降序，读与写两侧看到的是同一批数据的同一种顺序。
  static List<Transaction> _ordered(Iterable<Transaction> rows) =>
      rows.toList()..sort(_byDateAscending);

  static int _byDateAscending(Transaction a, Transaction b) {
    final byDate = a.bizDate.compareTo(b.bizDate);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }

  /// 保留窗口就是「当月往前数三个月」。`DateTime(year, month - i)` 在 month 减到 0 或负数时
  /// Dart 会自己回卷到上一年，不必手写跨年分支。
  List<String> _retainedMonths() {
    final now = _clock();
    return [
      for (var i = _retained - 1; i >= 0; i--)
        monthKey(DateTime(now.year, now.month - i)),
    ];
  }

  bool _overlaps(String month, DateTime? start, DateTime? end) {
    final year = int.parse(month.substring(0, 4));
    final monthOfYear = int.parse(month.substring(5));
    final first = DateTime(year, monthOfYear);
    final last = DateTime(
      year,
      monthOfYear + 1,
    ).subtract(const Duration(days: 1));
    if (start != null &&
        last.isBefore(DateTime(start.year, start.month, start.day))) {
      return false;
    }
    if (end != null && first.isAfter(DateTime(end.year, end.month, end.day))) {
      return false;
    }
    return true;
  }

  Future<void> _evict() async {
    final kept = _retainedMonths().toSet();
    for (final name in await _cachedFileNames()) {
      final match = _fileName.firstMatch(name);
      // 认不出月份的一律当垃圾删：那是写崩留下的 `.json.tmp` 之类，不主动清就永远不会自己消失。
      if (match == null || !kept.contains(match.group(1)!)) {
        await _delete(name);
      }
    }
  }

  Future<List<String>> _cachedFileNames() async {
    try {
      final directory = await _directoryResolver();
      if (!await directory.exists()) {
        return const [];
      }
      final names = <String>[];
      await for (final entity in directory.list()) {
        if (entity is! File) {
          continue;
        }
        // 先收集再删：一边 list 一边 delete 同一目录，在各平台上的行为都不一样。
        final name = entity.path.split(RegExp(r'[\\/]')).last;
        if (name.startsWith(_prefix)) {
          names.add(name);
        }
      }
      return names;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _delete(String name) async {
    try {
      final file = File(await _path(name));
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // 删不掉就算了：淘汰失败最坏是多占几十 KB，下次覆盖写照样会把它换掉。
    }
  }

  Future<({List<Transaction> rows, DateTime? savedAt})> _read(
    String month,
  ) async {
    try {
      final body = jsonDecode(
        await File(await _path('$_prefix$month.json')).readAsString(),
      );
      if (body is! Map<String, dynamic> || body['items'] is! List) {
        return (rows: const <Transaction>[], savedAt: null);
      }
      final rows = <Transaction>[];
      for (final row in body['items'] as List) {
        if (row is! Map<String, dynamic>) {
          return (rows: const <Transaction>[], savedAt: null);
        }
        rows.add(Transaction.fromJson(row));
      }
      return (rows: rows, savedAt: _savedAtOf(body['savedAt']));
    } catch (_) {
      return (rows: const <Transaction>[], savedAt: null);
    }
  }

  static DateTime? _savedAtOf(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  Future<void> _write(
    String month,
    List<Transaction> rows,
    DateTime savedAt,
  ) async {
    try {
      final target = File(await _path('$_prefix$month.json'));
      final temp = File('${target.path}.tmp');
      final envelope = {
        // 不带时区标记，与后端时间串同口径：这个戳只用来显示「数据截至」，不做跨时区比较。
        'savedAt': savedAt.toIso8601String(),
        'items': [for (final row in rows) row.toJson()],
      };
      await temp.writeAsString(jsonEncode(envelope), flush: true);
      await temp.rename(target.path);
    } catch (_) {
      // 数据此刻已经拿到手了，落不了盘不该让界面报错——缓存是优化，不是功能本身。
    }
  }

  /// 不引 `path` 包：只是拼一个文件名，正斜杠在 Windows 与 Android 上都吃这一套（同 DictCacheStore）。
  Future<String> _path(String name) async =>
      '${(await _directoryResolver()).path}/$name';
}

final transactionCacheStoreProvider = Provider<TransactionCacheStore>(
  (ref) => TransactionCacheStore(),
);
