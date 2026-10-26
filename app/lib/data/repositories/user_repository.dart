import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

/// §4.1.5 昵称、§4.1.6 注销账号。
class UserRepository {
  UserRepository({required this._api});

  final ApiClient _api;

  Future<UserProfile> me() async {
    final data = await _api.get('/users/me');
    return UserProfile.fromJson(requireData(data));
  }

  /// 改名不回写 family_member.nickname_snapshot：快照只在退出或被移除那一刻定格，
  /// 在籍成员一律显示实时昵称。
  Future<UserProfile> updateNickname(String nickname) async {
    final data = await _api.patch('/users/me', body: {'nickname': nickname});
    return UserProfile.fromJson(requireData(data));
  }

  /// 需密码二次确认。创建者须先转让创建者身份或解散家庭，否则后端拒绝。
  Future<void> deactivate(String password) =>
      _api.delete('/users/me', body: {'password': password});
}

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(api: ref.watch(apiClientProvider)),
);
