package cn.homeledger.service;

import cn.homeledger.dto.FamilyNameRequest;
import cn.homeledger.dto.JoinFamilyRequest;
import cn.homeledger.vo.FamilyResponse;

/**
 * §4.1.4 家庭的创建与加入、§4.1.6 家庭生命周期。
 * <p>
 * 全部方法以 {@code userId} 而非 {@code familyId} 定位家庭：一个用户同时只属于一个家庭（§4.1.4），
 * 故当前家庭可由 userId 唯一推出，客户端无从伪造 familyId 越权。
 */
public interface FamilyService {

	/**
	 * 创建家庭。名称留空则回落为「{昵称}的家」；创建者自动成为 OWNER 成员。
	 * 已有家庭时抛 ALREADY_IN_FAMILY。
	 */
	FamilyResponse create(Long userId, FamilyNameRequest request);

	/**
	 * 用邀请码加入家庭。校验分四层（§4.1.4）：入口关闭（码不存在）/ 已过期 / 成员已满 5 人，
	 * 以及第 33 轮起的一次性消费——两个并发加入者只有一个能成功。
	 * 「家庭已解散」并入「码不存在」，避免泄露该码曾属于一个真实存在过的家庭（第 10 轮确认）。
	 */
	FamilyResponse join(Long userId, JoinFamilyRequest request, String ip);

	/** §8：用户尚无家庭时返回 {@code null}，由 Controller 转成 200 + data:null，不返回 404。 */
	FamilyResponse current(Long userId);

	/** 改名。任意成员可改（§4.1.6 未限定创建者）；名称非空且 ≤ 20 字符。 */
	FamilyResponse rename(Long userId, FamilyNameRequest request);

	/**
	 * 开关邀请（第 33 轮，仅创建者）。开 = 签发新 6 位码（24 小时有效、只能使用一次）；
	 * 关 = 清空邀请码并关闭邀请入口。
	 */
	FamilyResponse setInviteEnabled(Long userId, boolean enabled);

	/**
	 * §4.1.6 转让创建者（仅创建者）。目标须为本家庭在籍成员，不能是自己。
	 * 单事务内同时改 family.owner_user_id 与两行 family_member.role。
	 * 不递增令牌版本号，理由见 §4.1.6 与 §5.2。
	 */
	FamilyResponse transferOwner(Long userId, Long targetUserId);

	/** §4.1.6 移除成员（仅创建者，不能移除自己）。被移除者令牌版本号递增，登录态立即失效。 */
	void removeMember(Long ownerUserId, Long targetUserId);

	/**
	 * 主动退出。创建者须先转让或解散，否则抛 OWNER_CANNOT_LEAVE。
	 * 无家庭时静默返回——端点侧的「必须有家庭」由 {@code @RequiresFamily} 拦截器负责。
	 * 不递增令牌版本号（§5.2）。
	 */
	void leave(Long userId);

	/** §4.1.6 注销账号复用同一套摘除逻辑，仅拒绝文案随动作而变。 */
	void leaveForAccountClosure(Long userId);

	/**
	 * §4.1.6 解散家庭（仅创建者 + 密码校验）。家庭与成员关系一律逻辑删除，保留 30 天。
	 * 递增除操作者本人以外全体成员的令牌版本号；本人不递增，否则会因执行自己的操作而被登出。
	 */
	void disband(Long userId, String password);

}
