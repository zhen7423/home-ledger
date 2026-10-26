import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/api_client.dart';

/// 带登录态的档案照片（S10，§4.3.1 / A6）。
///
/// 后端下发的 `photo_url` 只是相对路径（`/photos/<uuid>.<ext>`），读取要走鉴权端点——
/// 直接 `Image.network` 不会带 Bearer 头，后端一律 401。这里改走 ApiClient.download，
/// 续期、401 重放、失败翻译与其它请求同一条链路。
///
/// 失败（照片被清掉、网络差）或还没有照片时渲染占位图：头像不值得让整页报错，
/// 而且加载失败大多意味着「这张照片已经不存在」，占位图正是事实。
class AuthImage extends ConsumerStatefulWidget {
  const AuthImage({
    super.key,
    required this.photoUrl,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.placeholderIcon = Icons.pets_outlined,
    this.cacheWidth,
  });

  /// 相对路径。为 null 时不发请求，直接渲染占位图。
  final String? photoUrl;

  final BoxFit fit;

  /// 自定义占位图。没给就用图标。
  final Widget? placeholder;

  final IconData placeholderIcon;

  /// 解码缓存宽度（物理像素）。档案图上传前限到 1200×1200，全分辨率解码约
  /// 5.76 MB/张；列表里应传「逻辑尺寸 × 2（高 DPI）」，否则多卡同屏时缓存
  /// 膨胀、滚动掉帧。不传则按原分辨率解码（单张大图预览的默认行为）。
  final int? cacheWidth;

  @override
  ConsumerState<AuthImage> createState() => _AuthImageState();
}

class _AuthImageState extends ConsumerState<AuthImage> {
  /// 同一个家庭的档案清单会同时渲染多张（列表页），而照片按 UUID 命名、基本不变；
  /// 在内存里按 url 留一份，列表重建时不用每格重新下载。极端情况是几千张照片把
  /// 内存吃满——单张 ≤ 5 MB 且家庭规模是 10 只猫 / 5 个宝宝，量级上不存在。
  static final Map<String, Uint8List> _cache = {};

  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AuthImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) {
      _load();
    }
  }

  Future<void> _load() async {
    final url = widget.photoUrl;
    if (url == null) {
      // 不清就会拿旧字节继续画上一张照片（调用方重建 widget 时不丢，但同一实例
      // 从有图改到无图会中：比如编辑页删照片后留在本页）——S10 审查 N2。
      if (mounted && _bytes != null) {
        setState(() => _bytes = null);
      }
      return;
    }
    final cached = _cache[url];
    if (cached != null) {
      if (mounted) {
        setState(() => _bytes = cached);
      }
      return;
    }
    try {
      final file = await ref.read(apiClientProvider).download(url);
      // 下载期间 widget 可能已被复用去显示另一张照片
      if (!mounted || url != widget.photoUrl) {
        return;
      }
      _cache[url] = file.bytes;
      setState(() => _bytes = file.bytes);
    } catch (_) {
      // 任何失败都落回占位图；不向调用方抛错（见类注释）
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: widget.fit,
        gaplessPlayback: true,
        cacheWidth: widget.cacheWidth,
      );
    }
    final placeholder = widget.placeholder;
    if (placeholder != null) {
      return placeholder;
    }
    return Icon(
      widget.placeholderIcon,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}
