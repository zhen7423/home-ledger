import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/baby_vaccine.dart';
import '../../../../data/repositories/baby_vaccine_record_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../settings/view_models/reminder_view_model.dart';
import 'baby_home_view_model.dart';
import 'baby_statistics_view_model.dart';
import 'baby_vaccine_view_model.dart';

/// §4.4.4 的接种记录。状态是**全量**（不带 `babyId` 过滤），理由同应种清单那一层。
class BabyVaccineRecordViewModel
    extends AsyncNotifier<List<BabyVaccineRecord>> {
  @override
  Future<List<BabyVaccineRecord>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    return _repository.list();
  }

  /// 没有 `GET /baby-vaccine-records/{id}`，编辑表单从这份列表里回填。
  BabyVaccineRecord? byId(int id) {
    for (final row in state.value ?? const <BabyVaccineRecord>[]) {
      if (row.id == id) {
        return row;
      }
    }
    return null;
  }

  Future<String?> create(VaccineRecordDraft draft) async {
    final error = await _write(() => _repository.create(draft));
    if (error == null) {
      _fanOut();
    }
    return error;
  }

  /// 允许改疫苗名称与剂次（§1.4 第 20 条）：服务端先撤销旧绑定、再按新键重新匹配。
  Future<String?> save(int id, VaccineRecordDraft draft) async {
    final error = await _write(() => _repository.update(id, draft));
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

  BabyVaccineRecordRepository get _repository =>
      ref.read(babyVaccineRecordRepositoryProvider);

  /// 四处一漏，症状就是「录完接种记录回去看清单还是灰的」：应种清单要被回写成 `DONE` 或退回
  /// `PENDING`，总览的待办卡与统计的完成率随之变，`VACCINE_UPCOMING` 提醒也会增减。
  void _fanOut() {
    ref.invalidate(babyVaccineViewModelProvider);
    ref.invalidate(babyHomeViewModelProvider);
    ref.invalidate(babyStatisticsViewModelProvider);
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

final babyVaccineRecordViewModelProvider =
    AsyncNotifierProvider<
      BabyVaccineRecordViewModel,
      List<BabyVaccineRecord>
    >(BabyVaccineRecordViewModel.new);
