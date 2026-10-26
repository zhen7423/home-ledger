import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/family.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

/// §4.1.4 家庭的创建与加入、§4.1.6 家庭生命周期。
///
/// 每个写操作都返回后端重新组装的 Family，调用方直接拿它刷新状态，不必再发一次查询。
class FamilyRepository {
  FamilyRepository({required this._api});

  final ApiClient _api;

  /// 用户还没有家庭时返回 null——这是正常状态，不是错误。后端对这种情况回 200 + data:null，
  /// 404 被专门留给跨家庭越权。
  Future<Family?> current() async {
    final data = await _api.get('/families/current');
    return data == null ? null : Family.fromJson(data);
  }

  /// 名称留空则后端填「<昵称>的家」。
  Future<Family> create(String name) async {
    final data = await _api.post('/families', body: {'name': name});
    return Family.fromJson(requireData(data));
  }

  Future<Family> join(String inviteCode) async {
    final data = await _api.post(
      '/families/join',
      body: {'inviteCode': inviteCode},
    );
    return Family.fromJson(requireData(data));
  }

  Future<Family> rename(String name) async {
    final data = await _api.patch('/families/current', body: {'name': name});
    return Family.fromJson(requireData(data));
  }

  /// 仅创建者。第 33 轮：邀请码是手动开关——开即签发新 6 位码（24 小时有效、只能使用一次），
  /// 关则清空邀请码并关闭邀请入口；开着时再开一次等价于重置（换发新码并顺延 24 小时）。
  Future<Family> setInviteEnabled(bool enabled) async {
    final data = await _api.put(
      '/families/current/invite',
      body: {'enabled': enabled},
    );
    return Family.fromJson(requireData(data));
  }

  /// 仅创建者，且目标须是本家庭内在籍成员、不能是自己。
  Future<Family> transferOwner(int targetUserId) async {
    final data = await _api.post(
      '/families/current/owner/transfer',
      body: {'targetUserId': targetUserId},
    );
    return Family.fromJson(requireData(data));
  }

  /// 仅创建者，不能移除自己。被移除者的登录态由服务端立即吊销。
  Future<void> removeMember(int userId) =>
      _api.delete('/families/current/members/$userId');

  /// 创建者需先转让或解散才能退出，否则后端回 OWNER_CANNOT_LEAVE。
  Future<void> leave() => _api.post('/families/current/leave');

  /// 仅创建者，需密码二次确认。家庭逻辑删除并保留 30 天。
  Future<void> disband(String password) =>
      _api.delete('/families/current', body: {'password': password});
}

final familyRepositoryProvider = Provider<FamilyRepository>(
  (ref) => FamilyRepository(api: ref.watch(apiClientProvider)),
);
