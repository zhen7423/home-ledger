import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/reminder_state.dart';

/// 提醒状态的本地读写，只认文件不认网络。
///
/// 形状照 `DictCacheStore`：目录可注入（测试指到临时目录）、先写 `.tmp` 再 rename、
/// 读写失败一律吞掉。它是 `DictCacheStore` 的同类而不是它的一部分——两份数据的生命周期不同
/// （字典跟着网络请求刷新，这份跟着通知刷新），合成一个文件会让任一侧写入都得先把另一份读回来。
///
/// 不用 `flutter_secure_storage`：这不是秘密数据，而它背后是 EncryptedSharedPreferences，
/// 按 key-value 存一张会长大的表本就别扭，换不来任何东西。令牌继续走 secure_storage。
class ReminderStateStore {
  ReminderStateStore({Future<Directory> Function()? directoryResolver})
    : _directoryResolver = directoryResolver ?? getApplicationSupportDirectory;

  static const String _file = 'reminder-state.json';

  final Future<Directory> Function() _directoryResolver;

  /// 上一次写入的完成信号。见 [update]。
  Future<void> _queue = Future.value();

  /// 读不到就是「什么都没发生过」。空状态在这里是安全默认值：宁可多发一条通知，
  /// 也不能因为文件坏了就把红点消掉——那是用户唯一能看到逾期事项的地方。
  Future<ReminderState> read() async {
    try {
      final body = jsonDecode(await File(await _path()).readAsString());
      if (body is! Map<String, dynamic>) {
        return const ReminderState();
      }
      return ReminderState.fromJson(body);
    } catch (_) {
      return const ReminderState();
    }
  }

  /// 整份覆盖。写失败吞掉：这份状态丢了最坏是多弹一条通知，不值得让设置页报错。
  Future<void> write(ReminderState state) async {
    try {
      final target = File(await _path());
      final temp = File('${target.path}.tmp');
      await temp.writeAsString(jsonEncode(state.toJson()), flush: true);
      await temp.rename(target.path);
    } catch (_) {
      // 见上。
    }
  }

  /// 读、改、写一步做完，并把同一进程内的并发调用排成一条队。
  ///
  /// 这一份是整份覆盖的一个文件，而改它的地方有三处：待提醒重算写 `notified`、用户划掉写
  /// `dismissed`、首页首启引导写 `batteryGuideShown`。三处各自「读出来→改一改→写回去」的话，
  /// 两次写入之间落地的另一处改动会被无声地覆盖掉——典型症状是引导刚记下「弹过了」又被重算
  /// 写回 false，下次启动再弹一遍，而首页挂载与首次重算恰恰是同时发生的。
  ///
  /// [change] 回原文表示这一轮没有改动。返回落盘后的那一份，调用方要拿它继续算下去时不必再读一次。
  Future<ReminderState> update(
    ReminderState Function(ReminderState current) change,
  ) {
    final next = _queue.then((_) async {
      final current = await read();
      final updated = change(current);
      if (!identical(updated, current)) {
        await write(updated);
      }
      return updated;
    });
    // 队列本身不能因为某一次调用失败而断掉：read/write 已经各自吞了异常，
    // 这里再兜一层，避免一个意料之外的异常让后续所有写入都排在一条已经失败的链上
    _queue = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<String> _path() async => '${(await _directoryResolver()).path}/$_file';
}

final reminderStateStoreProvider = Provider<ReminderStateStore>(
  (ref) => ReminderStateStore(),
);
