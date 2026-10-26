package cn.homeledger.vo;

/**
 * GET /users/me。phone 只回给本人，成员列表（MemberResponse）刻意不含 phone，
 * 避免家庭内互相暴露完整手机号。
 */
public record UserProfileResponse(Long id, String phone, String nickname, Long familyId, String role) {

}
