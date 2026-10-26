import 'dart:typed_data';

import 'package:homeledger/data/services/file_sharer.dart';

/// share_plus 在 `flutter test` 下没有平台通道，真那份 `LocalFileSharer` 一调就是
/// MissingPluginException。形状照 `FakeReminderNotifier`：把每次调用记下来供断言。
class FakeFileSharer implements FileSharer {
  final List<SharedFile> shared = [];

  /// 非 null 时 `shareBytes` 抛这个异常，模拟磁盘满或平台通道失败。
  Object? shareError;

  SharedFile get last => shared.last;

  @override
  Future<void> shareBytes({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    final err = shareError;
    if (err != null) {
      throw err;
    }
    shared.add((bytes: bytes, filename: filename, mimeType: mimeType));
  }
}

/// 一次分享的快照。
typedef SharedFile = ({Uint8List bytes, String filename, String mimeType});
