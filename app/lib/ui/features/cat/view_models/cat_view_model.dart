import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/cat.dart';
import '../../../../data/repositories/cat_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';
import 'cat_overview_view_model.dart';
import 'cat_statistics_view_model.dart';

/// §4.3.1 的猫咪档案。**一次把在册与归档两份都装进来**（`includeArchived: true`），界面按 `archived` 分格。
///
/// 之所以不走那条更省字节的默认路径，是因为 §8 的猫档案**没有 `GET /cats/{id}`**：编辑页要回填的
/// 那一行只能从这份列表里找，而归档猫同样要能改、能恢复。一个家庭最多 10 只，多拉的那几行是
/// 常量级的开销，换来的是全模块只有一种「取一只猫」的方法。
class CatViewModel extends AsyncNotifier<List<Cat>> {
  @override
  Future<List<Cat>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    return _repository.list(includeArchived: true);
  }

  /// 表单里「给哪只猫」的选择器只列在册的（§4.3.1：归档就是把这只猫从记录选择器里摘掉）。
  List<Cat> active() => [
    for (final cat in state.value ?? const <Cat>[])
      if (!cat.archived) cat,
  ];

  /// 按 id 取一只，取法就是上面那份列表——没有第二条详情端点。
  /// 找不到回 `null`，由编辑页判成「没有这只猫」，不要在这里兜成第一只。
  Cat? byId(int id) {
    for (final cat in state.value ?? const <Cat>[]) {
      if (cat.id == id) {
        return cat;
      }
    }
    return null;
  }

  Future<String?> create(CatDraft draft) async {
    final error = await _write(() => _repository.create(draft));
    if (error == null) _fanOut();
    return error;
  }

  /// 提交既有档案。不叫 `update`：`AsyncNotifier` 自己就有一个 `update(...)`，
  /// 同名会变成签名不合法的覆写。
  Future<String?> save(int id, CatDraft draft) async {
    final error = await _write(() => _repository.update(id, draft));
    if (error == null) _fanOut();
    return error;
  }

  /// 归档与恢复共用这一个方法：后端那条 `PATCH /cats/{id}/archive` 是双向开关，它自己判方向。
  Future<String?> toggleArchive(int id) async {
    final error = await _write(() => _repository.toggle(id));
    if (error == null) _fanOut();
    return error;
  }

  Future<String?> remove(int id) async {
    final error = await _write(() => _repository.remove(id));
    if (error == null) _fanOut();
    return error;
  }

  /// §4.3.1 / S10 档案照片。照片有独立的端点，不走整份表单覆盖；写成功后照常重拉清单
  /// （photoUrl 要跟着进列表页的缩略图）。
  Future<String?> setPhoto(int id, Uint8List bytes, String filename) async {
    final error = await _write(() => _repository.uploadPhoto(id, bytes, filename));
    if (error == null) _fanOut();
    return error;
  }

  Future<String?> clearPhoto(int id) async {
    final error = await _write(() => _repository.clearPhoto(id));
    if (error == null) _fanOut();
    return error;
  }

  CatRepository get _repository => ref.read(catRepositoryProvider);

  /// 猫名是**实时反查**而不是快照（档案名要跟着改名走，而流水是历史凭证），改名会一路影响到
  /// 总览的卡片行、统计页的时间轴与倒计时；三处都在服务端算完，客户端只能整份重取。
  void _fanOut() {
    ref.invalidate(catOverviewViewModelProvider);
    ref.invalidate(catStatisticsViewModelProvider);
  }

  /// 写成功后重拉整份：后端的写接口回一条记录，拼不回界面上那两格列表。
  /// 第二次 try 不能省——重拉失败要把状态改成 error，否则「写成功了但列表没刷新」会静留在屏上。
  Future<String?> _write(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      return errorCopy(e);
    }
    try {
      state = AsyncData(await _repository.list(includeArchived: true));
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return errorCopy(e);
    }
    return null;
  }
}

final catViewModelProvider = AsyncNotifierProvider<CatViewModel, List<Cat>>(
  CatViewModel.new,
);
