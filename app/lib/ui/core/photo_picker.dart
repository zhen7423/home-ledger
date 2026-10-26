import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// 档案照片的 5 MB 硬上限（§4.3.1），与后端 PhotoService 的默认值一致。
const int kProfilePhotoMaxBytes = 5 * 1024 * 1024;

/// 选图链路上「值得告诉用户」的失败（格式不支持、压完仍超限）。
///
/// 不把它做成返回值的一部分，是因为调用方（两个编辑页）对「取消」和「失败」的处理
/// 本来就走两条路：取消静默返回、失败弹 snapBar，异常形态让这条区分留在原处。
class PhotoSelectException implements Exception {
  const PhotoSelectException(this.message);

  final String message;
}

/// 挑一张照片、截取头像区域并压到 5 MB 以内（S10，§4.3.1 / A6；问题单：支持选取区域）。
///
/// 链路：相册选图 → 进入原生裁剪器（锁定 1:1 方形，可拖动/缩放选区）→ 用户确认后
/// 取裁剪结果 → 若仍超过 5 MB 再用质量 85 压缩一遍。裁剪结果已经过裁剪器的 JPEG
/// 压缩且限宽 1200，通常远小于 5 MB，压缩只是兜底不是必经之路。
///
/// 前置校验与服务端 PhotoService 同口径（魔数判 JPG / PNG / WebP，不看扩展名）：
/// 客户端先拦一句人话，好过让用户挑半天后被后端 400 打回（S10 审查 N3）。
///
/// 用户取消选图或取消裁剪时返回 null — 调用方不得把它当成失败。
Future<Uint8List?> pickAndCompressProfilePhoto() async {
  final picker = ImagePicker();
  final XFile? file = await picker.pickImage(source: ImageSource.gallery);
  if (file == null) {
    return null;
  }
  final source = await file.readAsBytes();
  if (!_looksLikeSupportedImage(source)) {
    throw const PhotoSelectException('只支持 JPG / PNG / WebP 格式的照片');
  }

  // 先裁区域再考虑体积：头像只是原图里的一小块，整张上传既浪费流量又占库容。
  // 裁剪链路新增了一批原生/IO 调用（临时目录、写文件、跨 Activity 裁剪），
  // 它们的 FileSystemException / PlatformException / MissingPluginException 不属于
  // PhotoSelectException 通道，而调用方（两个编辑页）只 catch 后者——在此收口成
  // 人话，避免异常逃逸到 Zone（Release 无提示、Debug 红屏，同电池引导的调用方契约）。
  try {
    final cropped = await _crop(source);
    if (cropped == null) {
      return null; // 用户没确认裁剪，整条链路视为取消
    }
    final withinLimit = await _ensureWithinLimit(cropped);
    return withinLimit;
  } on PhotoSelectException {
    rethrow;
  } catch (e) {
    throw PhotoSelectException('没能处理这张照片（$e），请重试或换一张');
  }
}

/// 进原生裁剪器选区域。锁定 1:1（头像位是圆形的，宽高比不同也只会在卡片上被裁掉），
/// 允许拖动与缩放找人脸/脸所在的位置；取消（isCancelled）回 null。
Future<Uint8List?> _crop(Uint8List source) async {
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}'
    '${_extensionOf(source)}',
  );
  try {
    // 写入也在 try 内：磁盘满等失败不会遗留半个临时文件绕过 finally 清理
    await file.writeAsBytes(source, flush: true);
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      // 头像不需要原图全分辨率：限制输出尺寸，减体积也减后续展示时的解码开销
      maxWidth: 1200,
      maxHeight: 1200,
      // 锁定 1:1 方形选区；用户仍能拖动位置、缩放倍率（原生裁剪器的手势）
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: '调整头像', lockAspectRatio: true),
        IOSUiSettings(title: '调整头像', aspectRatioLockEnabled: true),
      ],
    );
    if (cropped == null) {
      return null;
    }
    final bytes = await cropped.readAsBytes();
    return bytes;
  } finally {
    // 裁剪器已把结果存到自己的缓存目录，这份临时源文件可以安全删掉
    try {
      await file.delete();
    } on FileSystemException {
      // 删不掉不阻塞主流程：系统会清理临时目录
    }
  }
}

/// 超过 5 MB 才压缩：quality 85 对人像与宠物照片肉眼几乎无差，JPEG 重编码的体积
/// 通常能压进 1 MB 以内。已经够小就不重编码——每压一次都是新一代的失真。
Future<Uint8List> _ensureWithinLimit(Uint8List bytes) async {
  if (bytes.length <= kProfilePhotoMaxBytes) {
    return bytes;
  }
  final compressed = await FlutterImageCompress.compressWithList(
    bytes,
    quality: 85,
  );
  // 空字节是插件对「解码失败」的表达（README：fail returns empty list）
  if (compressed.isEmpty) {
    throw const PhotoSelectException('这张照片没能处理，换一张试试');
  }
  if (compressed.length > kProfilePhotoMaxBytes) {
    throw const PhotoSelectException('这张照片压缩后仍然太大，请换一张');
  }
  return compressed;
}

/// 按魔数给临时文件一个正确的扩展名：裁剪器按内容识别格式，但部分平台对后缀敏感。
String _extensionOf(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return '.png';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46) {
    return '.webp';
  }
  return '.jpg';
}

/// 魔数嗅探，与后端 PhotoServiceImpl.sniff 逐字节同口径。
bool _looksLikeSupportedImage(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return true; // JPEG
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return true; // PNG
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return true; // WebP
  }
  return false;
}

