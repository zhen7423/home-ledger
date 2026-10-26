import 'package:freezed_annotation/freezed_annotation.dart';

part 'member.freezed.dart';
part 'member.g.dart';

/// 家庭成员列表项，对应后端 MemberResponse。刻意不含手机号：成员之间不该互相看到完整号码。
@freezed
abstract class Member with _$Member {
  const Member._();

  const factory Member({
    required int userId,
    required String nickname,
    required String role,
    required DateTime joinedAt,
  }) = _Member;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

  bool get isOwner => role == MemberRole.owner;
}

/// family_member.role 的两个取值。后端按字符串回传，前端同样按字符串比对，不各维护一份映射。
abstract class MemberRole {
  static const String owner = 'OWNER';
  static const String member = 'MEMBER';
}
