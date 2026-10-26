import 'package:homeledger/data/models/reminder_state.dart';
import 'package:homeledger/data/services/reminder_state_store.dart';

/// 内存版去重状态。凡是要渲染碰得到待提醒事项的页面测试都得换上它：
/// 真那份读写文件，`testWidgets` 的 fake 时钟推不动 `dart:io` 的完成回调，页面会永远停在
/// loading（`pumpAndSettle` 直接挂死）。落盘行为本身由 `reminder_state_store_test.dart` 验。
class FakeReminderStateStore extends ReminderStateStore {
  FakeReminderStateStore([ReminderState? initial])
    : state = initial ?? const ReminderState();

  ReminderState state;

  @override
  Future<ReminderState> read() async => state;

  @override
  Future<void> write(ReminderState next) async => state = next;
}
