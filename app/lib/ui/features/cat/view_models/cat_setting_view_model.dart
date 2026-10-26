import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/cat_setting.dart';
import '../../../../data/repositories/cat_setting_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';
import 'cat_overview_view_model.dart';
import 'cat_statistics_view_model.dart';

/// §4.3.3 / §4.3.4 的猫咪设置。状态是 `CatSetting` 而不是 `CatSetting?`：
/// 后端那条 GET 在家庭从没存过设置时回的是 3 / 1 / null / false，这一屏永远有一个值可显示，
/// 而 `data/models/cat_setting.dart` 四个字段全带默认值，守卫分支直接 `const CatSetting()`。
class CatSettingViewModel extends AsyncNotifier<CatSetting> {
  @override
  Future<CatSetting> build() async {
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return const CatSetting();
    }
    return _repository.get();
  }

  /// 保存。与四组列表 VM 不同，这里**不重拉**：PUT 回的就是保存后的整份
  /// （含现算的 `estimateTakenOverByHistory`），再 GET 一次是白跑一趟。
  /// 失败时不动状态：用户在表单里改了一半被拒，屏上那三个数字该停在他提交前的值上。
  Future<String?> save(CatSettingDraft draft) async {
    try {
      state = AsyncData(await _repository.save(draft));
    } on ApiException catch (e) {
      return errorCopy(e);
    }
    _fanOut();
    return null;
  }

  CatSettingRepository get _repository => ref.read(catSettingRepositoryProvider);

  /// 改周期会影响完成度（应做次数按这一份算），改预估日均会影响余量卡，两者都在服务端；
  /// **已有驱虫记录的 `nextDate` 一字不变**（§4.3.3），所以这一处不碰
  /// `catDewormingViewModelProvider`，也不碰猫粮袋列表——那一列的日均是每袋自己的历史。
  void _fanOut() {
    ref.invalidate(catOverviewViewModelProvider);
    ref.invalidate(catStatisticsViewModelProvider);
  }
}

final catSettingViewModelProvider =
    AsyncNotifierProvider<CatSettingViewModel, CatSetting>(
      CatSettingViewModel.new,
    );
