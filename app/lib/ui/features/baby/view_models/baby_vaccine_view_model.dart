import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/baby_vaccine.dart';
import '../../../../data/repositories/baby_vaccine_plan_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../settings/view_models/reminder_view_model.dart';
import 'baby_home_view_model.dart';
import 'baby_statistics_view_model.dart';
import 'baby_vaccine_record_view_model.dart';

/// §4.4.4 的应种清单。状态是**全量**（不带 `babyId` 过滤）：「只看这个宝宝」由界面自己 `where`，
/// 理由同身高体重那一层。
class BabyVaccineViewModel extends AsyncNotifier<List<BabyVaccinePlan>> {
  @override
  Future<List<BabyVaccinePlan>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    return _repository.list();
  }

  /// 没有 `GET /baby-vaccine-plans/{id}`：界面上那一行要判断的落库态与 `manual` 都在这份列表里。
  BabyVaccinePlan? byId(int id) {
    for (final row in state.value ?? const <BabyVaccinePlan>[]) {
      if (row.id == id) {
        return row;
      }
    }
    return null;
  }

  /// 手动新增自费项。落 `manual = 1`，只有这种行能删。
  Future<String?> createManual(ManualPlanDraft draft) async {
    final error = await _write(() => _repository.createManual(draft));
    if (error == null) {
      _fanOut();
    }
    return error;
  }

  /// 预置疫苗一键整串（第 30 轮）：多剂逐条 POST，整串只重拉一次清单、扇出一次。
  ///
  /// 某一剂失败则就地报错、已写进去的那几剂**不回滚**——每剂都是独立的 manual 行
  /// （后端本就单条建），回滚才会让「已经加好的剂次」凭空消失。但失败也要重拉：
  /// 已落库的那几剂是既成事实，陈旧列表会让弹层的「已在清单」判定漏掉它们，
  /// 用户重试必被服务端 `assertKeyFree` 拒回第一剂，永远补不完。
  Future<String?> createManualSeries(List<ManualPlanDraft> drafts) async {
    String? writeError;
    try {
      for (final draft in drafts) {
        await _repository.createManual(draft);
      }
    } on ApiException catch (e) {
      writeError = errorCopy(e);
    }
    try {
      state = AsyncData(await _repository.list());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return writeError ?? errorCopy(e);
    }
    _fanOut();
    return writeError;
  }

  /// 标记跳过 / 不适用 / 撤销。原因是否必填由页面把关（§4.3③：空原因不发请求），
  /// 服务端也会拒——两边都要有，因为这一层没有输入框可看。
  Future<String?> mark(int id, String status, String? reason) async {
    final error = await _write(() => _repository.mark(id, status, reason));
    if (error == null) {
      _fanOut();
    }
    return error;
  }

  /// 设置 / 清除计划接种日期（2026-10-26 需求②）。`plannedDate` 为 null 表示清除、
  /// 回到程序表应种日期。改期影响排序、展示态、完成率分母与「下一针」提醒，_fanOut 一处不能少。
  Future<String?> setPlannedDate(int id, DateTime? plannedDate) async {
    final error = await _write(() => _repository.setPlannedDate(id, plannedDate));
    if (error == null) {
      _fanOut();
    }
    return error;
  }

  Future<String?> remove(int id) async {
    final error = await _write(() => _repository.remove(id));
    if (error == null) {
      _fanOut();
    }
    return error;
  }

  BabyVaccinePlanRepository get _repository =>
      ref.read(babyVaccinePlanRepositoryProvider);

  /// 标记态是**接种记录回写的前提**（§4.4.4：跳过 / 不适用的行不被自动回写），所以接种记录那份
  /// 列表也得重取；而完成率与四态计数走的是统计那条端点，待办卡与 `VACCINE_UPCOMING` 提醒同理。
  void _fanOut() {
    ref.invalidate(babyHomeViewModelProvider);
    ref.invalidate(babyStatisticsViewModelProvider);
    ref.invalidate(babyVaccineRecordViewModelProvider);
    ref.invalidate(pendingReminderViewModelProvider);
  }

  Future<String?> _write(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      return errorCopy(e);
    }
    try {
      state = AsyncData(await _repository.list());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return errorCopy(e);
    }
    return null;
  }
}

final babyVaccineViewModelProvider =
    AsyncNotifierProvider<BabyVaccineViewModel, List<BabyVaccinePlan>>(
      BabyVaccineViewModel.new,
    );
