import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/baby_record.dart';
import '../../../../data/repositories/baby_record_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';
import 'baby_statistics_view_model.dart';

/// §4.4.5 的里程碑。状态是**全量**（不带 `babyId` 过滤）：「只看这个宝宝」由界面自己 `where`，
/// 而统计页底部那条跨宝宝的时间轴读的正是全量。
class BabyMilestoneViewModel extends AsyncNotifier<List<BabyMilestone>> {
  @override
  Future<List<BabyMilestone>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    return _repository.listMilestones();
  }

  /// 没有 `GET /baby-milestones/{id}`，编辑表单从这份列表里回填。
  BabyMilestone? byId(int id) {
    for (final row in state.value ?? const <BabyMilestone>[]) {
      if (row.id == id) {
        return row;
      }
    }
    return null;
  }

  Future<String?> create(MilestoneDraft draft) async {
    final error = await _write(() => _repository.createMilestone(draft));
    if (error == null) {
      _fanOut();
    }
    return error;
  }

  Future<String?> save(int id, MilestoneDraft draft) async {
    final error = await _write(() => _repository.updateMilestone(id, draft));
    if (error == null) {
      _fanOut();
    }
    return error;
  }

  Future<String?> remove(int id) async {
    final error = await _write(() => _repository.removeMilestone(id));
    if (error == null) {
      _fanOut();
    }
    return error;
  }

  BabyRecordRepository get _repository =>
      ref.read(babyRecordRepositoryProvider);

  /// 里程碑时间轴挂在**疫苗那条统计**上（§4.4.6），所以改动只影响统计页那一块。
  void _fanOut() => ref.invalidate(babyStatisticsViewModelProvider);

  Future<String?> _write(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      return errorCopy(e);
    }
    try {
      state = AsyncData(await _repository.listMilestones());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return errorCopy(e);
    }
    return null;
  }
}

final babyMilestoneViewModelProvider =
    AsyncNotifierProvider<BabyMilestoneViewModel, List<BabyMilestone>>(
      BabyMilestoneViewModel.new,
    );

/// §4.4.5 的就诊记录。**没有别的读者**：费用只是记录，不同步生成流水（§4.4.5），
/// 所以它的写操作谁都不用失效——这也正是它和里程碑分成两个 provider 的原因。
class BabyMedicalViewModel extends AsyncNotifier<List<BabyMedical>> {
  @override
  Future<List<BabyMedical>> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const [];
    }
    return _repository.listMedicals();
  }

  BabyMedical? byId(int id) {
    for (final row in state.value ?? const <BabyMedical>[]) {
      if (row.id == id) {
        return row;
      }
    }
    return null;
  }

  Future<String?> create(MedicalDraft draft) async =>
      _write(() => _repository.createMedical(draft));

  Future<String?> save(int id, MedicalDraft draft) async =>
      _write(() => _repository.updateMedical(id, draft));

  Future<String?> remove(int id) async =>
      _write(() => _repository.removeMedical(id));

  BabyRecordRepository get _repository =>
      ref.read(babyRecordRepositoryProvider);

  Future<String?> _write(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      return errorCopy(e);
    }
    try {
      state = AsyncData(await _repository.listMedicals());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return errorCopy(e);
    }
    return null;
  }
}

final babyMedicalViewModelProvider =
    AsyncNotifierProvider<BabyMedicalViewModel, List<BabyMedical>>(
      BabyMedicalViewModel.new,
    );
