import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/baby.dart';
import '../../../../data/repositories/baby_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/date_format.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';
import 'baby_curve_view_model.dart';
import 'baby_home_view_model.dart';
import 'baby_statistics_view_model.dart';
import 'baby_vaccine_view_model.dart';

/// §4.4.1 的宝宝档案。**一次把在册与归档两份都装进来**（`includeArchived: true`），界面按 `archived` 分格。
///
/// 理由同猫档案那一份：没有 `GET /babies/{id}`，编辑页要回填的那一行只能从这份列表里找，
/// 而归档的宝宝同样要能改、能恢复。档案列表的「显示已归档」开关因此是纯界面过滤，不多打一次请求。
class BabyListViewModel extends AsyncNotifier<List<Baby>> {
  @override
  Future<List<Baby>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    return _repository.list(includeArchived: true);
  }

  /// 各页的宝宝选择器只要在册的（§4.4.1：归档就是把宝宝从记录表单里摘掉）。
  List<Baby> active() => [
    for (final baby in state.value ?? const <Baby>[])
      if (!baby.archived) baby,
  ];

  /// 按 id 取一个，取法就是上面那份列表——没有第二条详情端点。找不到回 `null`，
  /// 由编辑页判成「没有这个宝宝」，不要在这里兜成第一个。
  Baby? byId(int id) {
    for (final baby in state.value ?? const <Baby>[]) {
      if (baby.id == id) {
        return baby;
      }
    }
    return null;
  }

  Future<String?> create(BabyDraft draft) async {
    final error = await _write(() => _repository.create(draft));
    if (error == null) {
      _fanOut(planRegenerated: true);
    }
    return error;
  }

  /// 提交既有档案。不叫 `update`：`AsyncNotifier` 自己就有一个 `update(...)`，
  /// 同名会变成签名不合法的覆写。
  Future<String?> save(int id, BabyDraft draft) async {
    final before = byId(id);
    final changed =
        before == null ||
        formatDate(before.birthDate) != formatDate(draft.birthDate);
    final error = await _write(() => _repository.update(id, draft));
    if (error == null) {
      _fanOut(planRegenerated: changed, curveChanged: changed);
    }
    return error;
  }

  /// 归档与恢复共用这一个方法：后端那条 `PATCH /babies/{id}/archive` 是双向开关，它自己判方向。
  /// 归档不等于删除，清单与历史记录照旧算在这个宝宝头上，所以只失效档案那两处。
  Future<String?> toggle(int id) async {
    final error = await _write(() => _repository.toggle(id));
    if (error == null) {
      _fanOut();
    }
    return error;
  }

  Future<String?> remove(int id) async {
    final error = await _write(() => _repository.remove(id));
    if (error == null) {
      _fanOut(planRegenerated: true);
    }
    return error;
  }

  /// §4.4.1 / S10 档案照片，语义同 `CatViewModel.setPhoto`。
  Future<String?> setPhoto(int id, Uint8List bytes, String filename) async {
    final error = await _write(() => _repository.uploadPhoto(id, bytes, filename));
    if (error == null) {
      _fanOut();
    }
    return error;
  }

  Future<String?> clearPhoto(int id) async {
    final error = await _write(() => _repository.clearPhoto(id));
    if (error == null) {
      _fanOut();
    }
    return error;
  }

  BabyRepository get _repository => ref.read(babyRepositoryProvider);

  /// 档案段变了 → 总览的卡片要重取；在册数变了 → 统计按宝宝分组会少/多一行，
  /// 改性别也会动统计——百分位档是按性别那张标准表算的。
  ///
  /// `planRegenerated`：建档、改出生日期、删除这三种写让应种清单整份变了（生成 / 重算 / 随档案软删），
  /// 其余档案改动都不动它（§4.4.1）。
  /// `curveChanged`：只有改出生日期——曲线的横轴是月龄，生日一移整条横轴都变（§4.4.3）。
  void _fanOut({bool planRegenerated = false, bool curveChanged = false}) {
    ref.invalidate(babyHomeViewModelProvider);
    ref.invalidate(babyStatisticsViewModelProvider);
    if (planRegenerated) {
      ref.invalidate(babyVaccineViewModelProvider);
    }
    if (curveChanged) {
      ref.invalidate(babyCurveViewModelProvider);
    }
  }

  /// 写成功后重拉整份：写接口回一条记录，拼不回界面上那份清单。
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

final babyListViewModelProvider =
    AsyncNotifierProvider<BabyListViewModel, List<Baby>>(
      BabyListViewModel.new,
    );
