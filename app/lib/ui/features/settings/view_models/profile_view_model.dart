import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/user_profile.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/services/api_exception.dart';
import '../../../core/error_copy.dart';
import '../../auth/view_models/auth_view_model.dart';

/// 账号与安全页。写操作返回 null 代表成功，否则是可直接展示的错误文案。
class ProfileViewModel extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() => ref.read(userRepositoryProvider).me();

  Future<String?> updateNickname(String nickname) async {
    try {
      state = AsyncData(
        await ref.read(userRepositoryProvider).updateNickname(nickname),
      );
      return null;
    } on ApiException catch (e) {
      return errorCopy(e);
    }
  }

  /// 改密码走 AuthRepository：它会递增令牌版本号并带回新令牌，换到本地才不会被自己踢下线。
  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(oldPassword: oldPassword, newPassword: newPassword);
      return null;
    } on ApiException catch (e) {
      return errorCopy(e);
    }
  }

  /// 注销成功后账号已不存在，本地必须跟着登出，否则界面还停在已登录态。
  Future<String?> deactivate(String password) async {
    try {
      await ref.read(userRepositoryProvider).deactivate(password);
    } on ApiException catch (e) {
      return errorCopy(e);
    }
    await ref.read(authViewModelProvider.notifier).signOut();
    return null;
  }
}

// autoDispose：换账号登录后不能沿用上一个用户的资料
final profileViewModelProvider =
    AsyncNotifierProvider.autoDispose<ProfileViewModel, UserProfile>(
      ProfileViewModel.new,
    );
