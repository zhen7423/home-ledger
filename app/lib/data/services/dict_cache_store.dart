import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/category.dart';
import '../models/payment_account.dart';

/// 字典的本地缓存读写，只认文件不认网络——「先试网络、传输失败才回落」那段判断在仓库里（§6.4）。
///
/// 两份字典各占一个文件，不做成一个：一条仓库只更新自己那一份，合成一个文件就得先把另一份
/// 读出来、原样带回去再整份写，那是自己给自己加的耦合。
///
/// 用普通文件而不是 flutter_secure_storage：字典不是秘密数据，而 secure_storage 背后是
/// EncryptedSharedPreferences，按 key-value 存大列表本就别扭（一个 key 一行，整份还得序列化成
/// 一个字符串），换不来任何东西。令牌继续走 secure_storage。
///
/// 不用 freezed：这是有 IO 的服务，`copyWith` 和值相等对它没用。
class DictCacheStore {
  /// 目录可注入只为测试能指到临时目录；生产走 `DictCacheStore()` 的默认值。
  DictCacheStore({Future<Directory> Function()? directoryResolver})
    : _directoryResolver = directoryResolver ?? getApplicationSupportDirectory;

  static const String _categoriesFile = 'dict-categories.json';
  static const String _accountsFile = 'dict-accounts.json';

  final Future<Directory> Function() _directoryResolver;

  Future<List<Category>> readCategories() =>
      _read(_categoriesFile, Category.fromJson);

  Future<List<PaymentAccount>> readAccounts() =>
      _read(_accountsFile, PaymentAccount.fromJson);

  Future<void> writeCategories(List<Category> items) =>
      _write(_categoriesFile, [for (final item in items) item.toJson()]);

  Future<void> writeAccounts(List<PaymentAccount> items) =>
      _write(_accountsFile, [for (final item in items) item.toJson()]);

  /// 两份一起清。S5 设置页的「清除本地缓存」调它，S3 只实现不接线——那个入口还没做。
  Future<void> clear() async {
    for (final name in const [_categoriesFile, _accountsFile]) {
      try {
        final file = File(await _path(name));
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // 同上：缓存这一层不该成为故障源，清不掉就算了，下次覆盖写照样会把它换掉。
      }
    }
  }

  /// 读盘的任何失败都当作「没有缓存」：文件不存在、JSON 坏掉、少字段、类型不对，一律吞掉返回空。
  /// 这条路径存在的意义就是网络不通时给用户看点东西，它自己不能再成为第二个故障源。
  /// 仓库层拿到空列表会照「缓存不可用」的分支去报错（§6.4）。
  Future<List<T>> _read<T>(
    String name,
    T Function(Map<String, dynamic> json) parse,
  ) async {
    try {
      final body = jsonDecode(await File(await _path(name)).readAsString());
      if (body is! Map<String, dynamic> || body['items'] is! List) {
        return const [];
      }
      final rows = <T>[];
      for (final row in body['items'] as List) {
        if (row is! Map<String, dynamic>) {
          return const [];
        }
        rows.add(parse(row));
      }
      return rows;
    } catch (_) {
      return const [];
    }
  }

  /// 整份覆盖。`savedAt` 在这里盖，调用方不传——缓存什么时候写的，只有写的那一刻知道得准。
  ///
  /// 先写 `.tmp` 再 rename：直接 writeAsString 目标文件时，写到一半进程被杀会留下半截 JSON，
  /// 下次读出来是坏的。rename 在同一目录内是原子操作，最坏情况是留下旧的一份完整缓存。
  ///
  /// 写失败也吞掉：数据此刻已经拿到手了，落不了盘不该让界面报错——缓存是优化，不是功能本身。
  Future<void> _write(String name, List<Map<String, dynamic>> items) async {
    try {
      final target = File(await _path(name));
      final temp = File('${target.path}.tmp');
      // 不带时区标记，与后端时间串的口径一致：这份时间戳只用来显示「数据截至」，不做跨时区比较。
      final envelope = {
        'savedAt': DateTime.now().toIso8601String(),
        'items': items,
      };
      await temp.writeAsString(jsonEncode(envelope), flush: true);
      await temp.rename(target.path);
    } catch (_) {
      // 见上。
    }
  }

  /// 不引 `path` 包：只是拼一个文件名，正斜杠在 Windows 与 Android 上都吃这一套。
  Future<String> _path(String name) async =>
      '${(await _directoryResolver()).path}/$name';
}

final dictCacheStoreProvider = Provider<DictCacheStore>(
  (ref) => DictCacheStore(),
);
