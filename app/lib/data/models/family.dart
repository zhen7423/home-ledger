import 'package:freezed_annotation/freezed_annotation.dart';

import 'member.dart';

part 'family.freezed.dart';
part 'family.g.dart';

/// 当前家庭，对应后端 FamilyResponse：家庭信息与成员列表一次返回，首页一个请求就够。
/// 还没有家庭时后端回 200 + data:null，前端持有 null 而不是本类实例；404 专用于跨家庭越权。
/// 第 33 轮起 inviteCode / inviteCodeExpireAt 可空：邀请是手动开关，关着或已用掉时没有码。
@freezed
abstract class Family with _$Family {
  const factory Family({
    required int id,
    required String name,
    required int ownerUserId,
    required bool inviteEnabled,
    String? inviteCode,
    DateTime? inviteCodeExpireAt,
    required List<Member> members,
  }) = _Family;

  factory Family.fromJson(Map<String, dynamic> json) => _$FamilyFromJson(json);
}
