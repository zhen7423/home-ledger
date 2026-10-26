package cn.homeledger.vo;

import java.time.LocalDateTime;

/**
 * 成员列表项，同时是 FamilyMemberMapper.selectMembers 的投影目标（列别名须与组件名一致）。
 * 刻意不含 phone：家庭内成员不应互相看到完整手机号。
 */
public record MemberResponse(Long userId, String nickname, String role, LocalDateTime joinedAt) {

}
