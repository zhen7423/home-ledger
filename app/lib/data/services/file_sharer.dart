import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 把一份字节交给系统分享面板（§4.2.7）。
///
/// 抽成接口不是为了「将来好换实现」，而是因为 `SharePlus.instance` 是个 static final，
/// 测试里换不掉它，而 share_plus 在 `flutter test` 下没有平台通道——不抽象就没法测导出流程。
/// 形状照 `ReminderNotifier`：一个接口 + 一个真实实现 + 测试里 overrideWith 替身。
abstract interface class FileSharer {
  Future<void> shareBytes({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  });
}

class LocalFileSharer implements FileSharer {
  @override
  Future<void> shareBytes({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    // 落在 cache 目录而不是 support 目录：这是一份用完即弃的产物，系统空间紧张时可以随手清掉，
    // 而 support 目录里住着字典 / 流水 / 统计三类缓存，清了用户离线就什么都看不到了。
    final directory = await getApplicationCacheDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    // 分享完不删：分享面板是异步的，这边一返回就删文件，用户点「发送到微信」时会拿到一个空路径。
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        // 必传。cross_file 在非 Web 平台会忽略 XFile 的 name，不显式覆盖的话
        // 分享面板上显示的是临时文件名，而不是「家记流水_2026-01-01_2026-01-31.xlsx」。
        fileNameOverrides: [filename],
      ),
    );
  }
}

/// 测试里一律 `overrideWith((ref) => FakeFileSharer())` 换掉（同 reminderNotifierProvider）。
final fileSharerProvider = Provider<FileSharer>((ref) => LocalFileSharer());
