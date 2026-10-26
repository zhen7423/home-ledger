package cn.homeledger.vo;

import java.time.LocalDateTime;
import java.util.List;

/**
 * §8 GET /families/current 的响应：家庭信息 + 成员列表一次返回，
 * 让首页只需一次请求即可渲染成员区（验收用例 1）。
 * 用户尚无家庭时整个 data 为 null（HTTP 仍是 200），404 在 §5.2 中专用于跨家庭越权。
 * <p>
 * 第 33 轮：inviteCode / inviteCodeExpireAt 仅邀请开关开启时非空——关闭或已使用时入口已关上，
 * 前端页面展示的「未开启邀请」状态就是由这两个空值 + inviteEnabled=false 组成。
 */
public record FamilyResponse(Long id, String name, Long ownerUserId, boolean inviteEnabled, String inviteCode,
		LocalDateTime inviteCodeExpireAt, List<MemberResponse> members) {

}
