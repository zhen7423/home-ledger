import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/reminder_state.dart';
import 'package:homeledger/data/services/reminder_state_store.dart';

void main() {
  late Directory root;
  late ReminderStateStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('reminder_state_store');
    store = ReminderStateStore(directoryResolver: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('两张表写进去原样读回来', () async {
    const state = ReminderState(
      notified: {'BUDGET_OVERRUN:FAMILY': '2026-09-14'},
      dismissed: {'BUDGET_WARNING:FAMILY': '2026-09-13'},
    );

    await store.write(state);

    expect(await store.read(), state);
  });

  test('整份覆盖：第二次写替掉第一次，不在旧表上追加', () async {
    await store.write(
      const ReminderState(notified: {'BUDGET_OVERRUN:FAMILY': '2026-09-13'}),
    );
    await store.write(
      const ReminderState(notified: {'BUDGET_OVERRUN:FAMILY': '2026-09-14'}),
    );

    expect(
      await store.read(),
      const ReminderState(notified: {'BUDGET_OVERRUN:FAMILY': '2026-09-14'}),
    );
  });

  test('默认值让「只有一张表」的写法成立', () async {
    const state = ReminderState(
      dismissed: {'BUDGET_OVERRUN:FAMILY': '2026-09-14'},
    );

    await store.write(state);

    final read = await store.read();
    expect(read.notified, isEmpty);
    expect(read.dismissed, state.dismissed);
  });

  test('还没写过时读出空状态', () async {
    expect(await store.read(), const ReminderState());
  });

  test('读操作不创建文件', () async {
    await store.read();

    expect(File('${root.path}/reminder-state.json').existsSync(), isFalse);
  });

  test('坏 JSON、不是对象、值类型不对，一律当空状态而不是抛出来', () async {
    final file = File('${root.path}/reminder-state.json');

    await file.writeAsString('{不是JSON');
    expect(await store.read(), const ReminderState());

    await file.writeAsString('"只是个字符串"');
    expect(await store.read(), const ReminderState());

    await file.writeAsString('{"notified":{"k":123}}');
    expect(await store.read(), const ReminderState());
  });

  test('写完只留下目标文件，中间那份 .tmp 已经 rename 走了', () async {
    await store.write(const ReminderState());

    expect(root.listSync().map((e) => e.uri.pathSegments.last), [
      'reminder-state.json',
    ]);
  });

  test('update 改一个字段，另外两个原样留着', () async {
    await store.write(
      const ReminderState(
        notified: {'BUDGET_OVERRUN:FAMILY': '2026-09-14'},
        dismissed: {'BUDGET_WARNING:FAMILY': '2026-09-13'},
      ),
    );

    final updated = await store.update(
      (current) => current.copyWith(batteryGuideShown: true),
    );

    expect(updated.batteryGuideShown, isTrue);
    expect(updated.notified, {'BUDGET_OVERRUN:FAMILY': '2026-09-14'});
    expect(updated.dismissed, {'BUDGET_WARNING:FAMILY': '2026-09-13'});
    expect((await store.read()).batteryGuideShown, isTrue);
  });

  test('并发 update 排成一条队，谁也不覆盖谁', () async {
    // 三次读改写一次性发出去：各自「读出来→改→写回去」的话，最后落盘的只会剩最后一次改动
    await Future.wait([
      store.update((s) => s.copyWith(batteryGuideShown: true)),
      store.update((s) => s.copyWith(notified: {'BUDGET_OVERRUN:FAMILY': '2026-09-14'})),
      store.update((s) => s.copyWith(dismissed: {'BUDGET_WARNING:FAMILY': '2026-09-13'})),
    ]);

    final state = await store.read();
    expect(state.batteryGuideShown, isTrue);
    expect(state.notified, {'BUDGET_OVERRUN:FAMILY': '2026-09-14'});
    expect(state.dismissed, {'BUDGET_WARNING:FAMILY': '2026-09-13'});
  });

  test('回原文表示这一轮没有改动，就不落盘', () async {
    await store.update((current) => current);

    expect(File('${root.path}/reminder-state.json').existsSync(), isFalse);
  });
}
