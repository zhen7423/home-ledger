import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/family.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';

/// 当前家庭。null 表示还没建也没加入，是正常状态，引导页据此出现。
/// 写操作返回 null 代表成功，否则是可直接展示的错误文案。
class FamilyViewModel extends AsyncNotifier<Family?> {
  @override
  Future<Family?> build() async {
    // 未登录不请求；退出登录时这条 watch 会让缓存自动清空
    if (ref.watch(authViewModelProvider.select((s) => s.status)) !=
        SessionStatus.signedIn) {
      return null;
    }
    return ref.read(familyRepositoryProvider).current();
  }

  /// 名称留空则后端填「<昵称>的家」。
  Future<String?> create(String name) =>
      _save(() => ref.read(familyRepositoryProvider).create(name));

  Future<String?> join(String inviteCode) =>
      _save(() => ref.read(familyRepositoryProvider).join(inviteCode));

  Future<String?> rename(String name) =>
      _save(() => ref.read(familyRepositoryProvider).rename(name));

  /// 仅创建者。开 = 签发新码；关 = 清码并关闭邀请入口。
  Future<String?> setInviteEnabled(bool enabled) =>
      _save(() => ref.read(familyRepositoryProvider).setInviteEnabled(enabled));

  Future<String?> transferOwner(int targetUserId) => _save(
    () => ref.read(familyRepositoryProvider).transferOwner(targetUserId),
  );

  /// 后端这三个接口只回成功与否，成员列表得重新拉一次。
  Future<String?> removeMember(int userId) =>
      _reload(() => ref.read(familyRepositoryProvider).removeMember(userId));

  Future<String?> leave() => _reload(ref.read(familyRepositoryProvider).leave);

  Future<String?> disband(String password) =>
      _reload(() => ref.read(familyRepositoryProvider).disband(password));

  Future<String?> _save(Future<Family> Function() action) async {
    try {
      state = AsyncData(await action());
      return null;
    } on ApiException catch (e) {
      return errorCopy(e);
    }
  }

  Future<String?> _reload(Future<void> Function() action) async {
    try {
      await action();
    } on ApiException catch (e) {
      return errorCopy(e);
    }
    try {
      state = AsyncData(await ref.read(familyRepositoryProvider).current());
    } on ApiException catch (e) {
      state = AsyncError(e, StackTrace.current);
      return errorCopy(e);
    }
    return null;
  }
}

final familyViewModelProvider = AsyncNotifierProvider<FamilyViewModel, Family?>(
  FamilyViewModel.new,
);
