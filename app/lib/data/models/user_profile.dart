import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// GET /users/me，对应后端 UserProfileResponse。
///
/// familyId 与 role 取自实时解析的登录态，用户还没加入家庭时两者为 null。
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required int id,
    required String phone,
    required String nickname,
    int? familyId,
    String? role,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
