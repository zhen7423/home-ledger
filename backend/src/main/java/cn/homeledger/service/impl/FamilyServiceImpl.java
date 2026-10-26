package cn.homeledger.service.impl;

import java.security.SecureRandom;
import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;

import cn.homeledger.common.AuthContext;
import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.dto.FamilyNameRequest;
import cn.homeledger.dto.JoinFamilyRequest;
import cn.homeledger.entity.Family;
import cn.homeledger.entity.FamilyMember;
import cn.homeledger.entity.User;
import cn.homeledger.mapper.BudgetMapper;
import cn.homeledger.mapper.FamilyMapper;
import cn.homeledger.mapper.FamilyMemberMapper;
import cn.homeledger.mapper.RecurringRuleMapper;
import cn.homeledger.mapper.UserMapper;
import cn.homeledger.security.RateLimitService;
import cn.homeledger.security.TokenVersionService;
import cn.homeledger.service.FamilyService;
import cn.homeledger.service.PresetFinanceDictService;
import cn.homeledger.vo.FamilyResponse;
import cn.homeledger.vo.MemberResponse;

/**
 * §4.1.4 家庭的创建与加入、§4.1.6 家庭生命周期。
 * <p>
 * 本类原先读的三张表（family / family_member / user）都在租户白名单内（§5.2），拦截器不会替它们注入
 * family_id，所以每条查询都必须自带 user_id 或 family_id 条件——这是本类最需要代码评审盯住的一点。
 * <p>
 * S4 起它还要写两张受租户拦截的表（成员退出与解散时顺带处理周期规则和预算，见 §4.2.3 / §4.2.4）。
 * 那里条件是双重的：语句自己带 family_id，拦截器还会再加一次。两处取的是同一个值——家庭关系在一次请求内
 * 不会因为 markLeft 而变，登录态是请求开始时解析好的。
 */
@Service
public class FamilyServiceImpl implements FamilyService {

	/** §4.1.4 成员上限。含创建者本人。 */
	static final int MAX_MEMBERS = 5;

	/** §4.1.4（第 33 轮）邀请码有效期 24 小时。到期或使用一次后入口自动关闭。 */
	static final int INVITE_CODE_TTL_HOURS = 24;

	/** §4.1.4 随机取号最多重试 5 次，仍冲突即报错，不降级为更长的码。 */
	static final int INVITE_CODE_MAX_ATTEMPTS = 5;

	static final int INVITE_CODE_POOL = 1_000_000;

	private static final Logger log = LoggerFactory.getLogger(FamilyServiceImpl.class);

	private final FamilyMapper familyMapper;

	private final FamilyMemberMapper familyMemberMapper;

	private final UserMapper userMapper;

	private final PasswordEncoder passwordEncoder;

	private final TokenVersionService tokenVersionService;

	private final RateLimitService rateLimitService;

	private final Clock clock;

	private final PresetFinanceDictService presetFinanceDictService;

	private final RecurringRuleMapper recurringRuleMapper;

	private final BudgetMapper budgetMapper;

	private final SecureRandom random = new SecureRandom();

	public FamilyServiceImpl(FamilyMapper familyMapper, FamilyMemberMapper familyMemberMapper, UserMapper userMapper,
			PasswordEncoder passwordEncoder, TokenVersionService tokenVersionService, RateLimitService rateLimitService,
			Clock clock, PresetFinanceDictService presetFinanceDictService, RecurringRuleMapper recurringRuleMapper,
			BudgetMapper budgetMapper) {
		this.familyMapper = familyMapper;
		this.familyMemberMapper = familyMemberMapper;
		this.userMapper = userMapper;
		this.passwordEncoder = passwordEncoder;
		this.tokenVersionService = tokenVersionService;
		this.rateLimitService = rateLimitService;
		this.clock = clock;
		this.presetFinanceDictService = presetFinanceDictService;
		this.recurringRuleMapper = recurringRuleMapper;
		this.budgetMapper = budgetMapper;
	}

	@Override
	@Transactional
	public FamilyResponse create(Long userId, FamilyNameRequest request) {
		User user = lockUser(userId);
		assertNoFamily(userId);
		String name = (request.name() == null || request.name().isBlank())
				? user.getNickname() + "的家" : request.name().trim();
		assertNameLength(name);

		Family family = new Family();
		family.setName(name);
		family.setOwnerUserId(userId);
		// 第 33 轮：创建家庭不再自动签发邀请码，入口默认关闭，由创建者在家庭管理页手动开
		family.setInviteEnabled(0);
		this.familyMapper.insert(family);

		insertMembership(family.getId(), userId, AuthContext.ROLE_OWNER, user.getNickname());
		// 新家庭一建好就要有一套能直接用的类别与支付方式；join 的路径不调用，那个家庭装过了
		this.presetFinanceDictService.install(family.getId(), userId);
		log.info("创建家庭 familyId={} ownerUserId={}", family.getId(), userId);
		return toResponse(family);
	}

	@Override
	@Transactional
	public FamilyResponse join(Long userId, JoinFamilyRequest request, String ip) {
		this.rateLimitService.checkJoinFamily(ip);
		User user = lockUser(userId);
		// 验收用例 4：已属于家庭的账号再输入其他邀请码，须得到明确错误
		assertNoFamily(userId);

		String code = request.inviteCode().trim();
		Family family = this.familyMapper.findLatestByInviteCode(code);
		if (family == null) {
			// 第 33 轮：入口关闭的码已被清空，查不到即入口不存在；已解散家庭也落到这里（防泄露存在性）
			throw new BizException(ErrorCode.INVITE_CODE_NOT_FOUND);
		}
		// §4.1.4 要求三项校验各自返回不同文案，不合并为笼统的「邀请码无效」
		if (!family.getInviteCodeExpireAt().isAfter(LocalDateTime.now(this.clock))) {
			throw new BizException(ErrorCode.INVITE_CODE_EXPIRED);
		}
		if (countMembers(family.getId()) >= MAX_MEMBERS) {
			throw new BizException(ErrorCode.FAMILY_MEMBER_LIMIT);
		}
		// 一次性使用（第 33 轮）：条件 UPDATE 原子消费，两步并发拿同一个码只有一个能成功；
		// 本事务内与上方校验共享行锁，先校验后消费，码不存在就根本走不到这里
		if (this.familyMapper.consumeInvite(family.getId(), code) == 0) {
			throw new BizException(ErrorCode.INVITE_CODE_NOT_FOUND);
		}
		// 消费成功即入口关闭，落回实体让响应不再带码（与 current 读到的状态一致）
		family.setInviteEnabled(0);
		family.setInviteCode(null);
		family.setInviteCodeExpireAt(null);

		insertMembership(family.getId(), userId, AuthContext.ROLE_MEMBER, user.getNickname());
		log.info("加入家庭 familyId={} userId={}", family.getId(), userId);
		return toResponse(family);
	}

	/** §8：用户尚无家庭时返回 null，由 Controller 转成 200 + data:null，不返回 404。 */
	@Override
	public FamilyResponse current(Long userId) {
		FamilyMember membership = activeMembership(userId);
		if (membership == null) {
			return null;
		}
		Family family = this.familyMapper.selectById(membership.getFamilyId());
		return (family == null) ? null : toResponse(family);
	}

	@Override
	@Transactional
	public FamilyResponse rename(Long userId, FamilyNameRequest request) {
		Family family = requireCurrentFamily(userId);
		String name = (request.name() == null) ? "" : request.name().trim();
		if (name.isEmpty()) {
			throw new BizException(ErrorCode.BAD_REQUEST, "请填写家庭名称");
		}
		assertNameLength(name);
		family.setName(name);
		this.familyMapper.updateById(family);
		return toResponse(family);
	}

	/**
	 * 第 33 轮：邀请手动开关，仅创建者。
	 * 开 = 签发新 6 位码（24 小时有效、只能使用一次）；已开着再开一次等价于原来的「重置」——
	 * 换发新码并顺延 24 小时，旧码立即作废。
	 * 关 = 清空邀请码并关闭邀请入口（将来 join 走到 findLatestByInviteCode 时查不到即入口不存在）。
	 */
	@Override
	@Transactional
	public FamilyResponse setInviteEnabled(Long userId, boolean enabled) {
		Family family = requireCurrentFamily(userId);
		requireOwner(userId);
		if (enabled) {
			family.setInviteEnabled(1);
			family.setInviteCode(generateInviteCode());
			family.setInviteCodeExpireAt(LocalDateTime.now(this.clock).plusHours(INVITE_CODE_TTL_HOURS));
			this.familyMapper.updateById(family);
			log.info("开启邀请 familyId={} operatorUserId={}", family.getId(), userId);
		} else {
			// 关 = 条件 UPDATE 清码关入口；家庭若已解散则这行匹配不到，视作入口已不存在
			if (this.familyMapper.disableInvite(family.getId()) == 0) {
				throw new BizException(ErrorCode.NO_FAMILY);
			}
			family.setInviteEnabled(0);
			family.setInviteCode(null);
			family.setInviteCodeExpireAt(null);
			log.info("关闭邀请 familyId={} operatorUserId={}", family.getId(), userId);
		}
		return toResponse(family);
	}

	/**
	 * §4.1.6 转让创建者。单事务内同时改 family.owner_user_id 与两行 family_member.role，
	 * 中途失败整体回滚，不会出现「两个 OWNER」或「零个 OWNER」。
	 * <p>
	 * 不递增令牌版本号：角色每请求实时查库（见 AuthContext），下一个请求自然看到新角色；
	 * 若照 §5.2 原文对双方 bump，刚上任的创建者会被自己的转让操作踢下线。
	 */
	@Override
	@Transactional
	public FamilyResponse transferOwner(Long userId, Long targetUserId) {
		Family family = requireCurrentFamily(userId);
		requireOwner(userId);
		if (userId.equals(targetUserId)) {
			throw new BizException(ErrorCode.CANNOT_TRANSFER_TO_SELF);
		}
		FamilyMember target = activeMembershipOf(family.getId(), targetUserId);
		if (target == null) {
			throw new BizException(ErrorCode.MEMBER_NOT_FOUND);
		}

		family.setOwnerUserId(targetUserId);
		this.familyMapper.updateById(family);
		updateRole(family.getId(), targetUserId, AuthContext.ROLE_OWNER);
		updateRole(family.getId(), userId, AuthContext.ROLE_MEMBER);
		log.info("转让创建者 familyId={} from={} to={}", family.getId(), userId, targetUserId);
		return toResponse(family);
	}

	/** §4.1.6：被移除者的登录态立即失效，故递增其令牌版本号。 */
	@Override
	@Transactional
	public void removeMember(Long ownerUserId, Long targetUserId) {
		Family family = requireCurrentFamily(ownerUserId);
		requireOwner(ownerUserId);
		if (ownerUserId.equals(targetUserId)) {
			throw new BizException(ErrorCode.CANNOT_REMOVE_SELF);
		}
		FamilyMember target = activeMembershipOf(family.getId(), targetUserId);
		if (target == null) {
			throw new BizException(ErrorCode.MEMBER_NOT_FOUND);
		}
		this.familyMemberMapper.markLeft(family.getId(), targetUserId);
		detachFamilyFinanceData(family.getId(), targetUserId);
		this.tokenVersionService.bump(targetUserId);
		log.info("移除成员 familyId={} operatorUserId={} targetUserId={}", family.getId(), ownerUserId, targetUserId);
	}

	/**
	 * 主动退出。无家庭时静默返回：注销账号（§4.1.6）复用同一套摘除逻辑，而注销者可能本就没有家庭。
	 * 端点侧的「必须有家庭」由 @RequiresFamily 拦截器负责，不在这里重复。
	 */
	@Override
	@Transactional
	public void leave(Long userId) {
		detach(userId, "创建者需先转让创建者身份或解散家庭，才能退出");
	}

	/** §4.1.6 注销账号：创建者须先转让创建者身份或解散家庭。与主动退出同一条约束，仅文案随动作而变。 */
	@Override
	@Transactional
	public void leaveForAccountClosure(Long userId) {
		detach(userId, "创建者需先转让创建者身份或解散家庭，才能注销账号");
	}

	private void detach(Long userId, String ownerBlockedMessage) {
		FamilyMember membership = activeMembership(userId);
		if (membership == null) {
			return;
		}
		if (AuthContext.ROLE_OWNER.equals(membership.getRole())) {
			throw new BizException(ErrorCode.OWNER_CANNOT_LEAVE, ownerBlockedMessage);
		}
		this.familyMemberMapper.markLeft(membership.getFamilyId(), userId);
		detachFamilyFinanceData(membership.getFamilyId(), userId);
		log.info("摘除成员关系 familyId={} userId={}", membership.getFamilyId(), userId);
	}

	/**
	 * §4.1.6 解散家庭：仅创建者 + 密码校验；家庭与成员关系一律逻辑删除，保留 30 天供服务器侧恢复，
	 * 自动物理清除推迟至 S10（与备份保留策略一并设计）。
	 * <p>
	 * 递增除操作者本人以外全体成员的令牌版本号。本人不 bump：解散后其 familyId 自然解析为 null，
	 * 会被引导到「创建/加入家庭」页；若连自己一起 bump，用户会因为执行了自己的操作而被登出。
	 */
	@Override
	@Transactional
	public void disband(Long userId, String password) {
		Family family = requireCurrentFamily(userId);
		requireOwner(userId);
		User user = this.userMapper.selectById(userId);
		if (user == null || !this.passwordEncoder.matches(password, user.getPasswordHash())) {
			throw new BizException(ErrorCode.PASSWORD_MISMATCH);
		}
		List<MemberResponse> members = this.familyMemberMapper.selectMembers(family.getId());
		this.familyMemberMapper.markAllLeft(family.getId());
		// 解散时整批作废而不是逐个 disableByCreator：按人暂停只会停到创建者自己头上，其他成员的规则还在跑
		this.recurringRuleMapper.softDeleteByFamily(family.getId());
		// 与 deleteById 的区别：markDissolved 会同时写 deleted_at——30 天物理清除的起点（§4.1.6）
		this.familyMapper.markDissolved(family.getId());
		members.stream().map(MemberResponse::userId).filter(id -> !id.equals(userId))
			.forEach(this.tokenVersionService::bump);
		log.info("解散家庭 familyId={} operatorUserId={} 受影响成员数={}", family.getId(), userId, members.size() - 1);
	}

	/**
	 * 成员离开这个家庭后，把他名下的两样东西收尾（§4.2.3、§4.2.4）。
	 * <p>
	 * 一个暂停、一个删除，看着不对称，其实是同一句判断的两种结果：规则代表一个仍然成立的意图（房租照要交，
	 * 可能由别人接手继续用），而预算代表一个已经失效的额度——不在册的人不该继续占着一份家庭额度，
	 * 预算管理页也是按在册成员渲染的，留着就是一行谁也动不了的死数据。
	 * 规则不删还有一个硬理由：历史流水上的 rule_id 要能反查到规则。
	 */
	private void detachFamilyFinanceData(Long familyId, Long userId) {
		this.recurringRuleMapper.disableByCreator(familyId, userId);
		this.budgetMapper.deleteMemberBudgets(familyId, userId);
	}

	private User lockUser(Long userId) {
		// 行锁串行化同一用户的「创建/加入家庭」，兜住「同时只属于一个家庭」这条无法用唯一索引表达的约束
		if (this.userMapper.lockById(userId) == null) {
			throw new BizException(ErrorCode.UNAUTHORIZED);
		}
		User user = this.userMapper.selectById(userId);
		if (user == null) {
			throw new BizException(ErrorCode.UNAUTHORIZED);
		}
		return user;
	}

	private void assertNoFamily(Long userId) {
		if (activeMembership(userId) != null) {
			throw new BizException(ErrorCode.ALREADY_IN_FAMILY);
		}
	}

	private Family requireCurrentFamily(Long userId) {
		FamilyMember membership = activeMembership(userId);
		if (membership == null) {
			throw new BizException(ErrorCode.NO_FAMILY);
		}
		Family family = this.familyMapper.selectById(membership.getFamilyId());
		if (family == null) {
			throw new BizException(ErrorCode.NO_FAMILY);
		}
		return family;
	}

	private void requireOwner(Long userId) {
		if (!AuthContext.ROLE_OWNER.equals(activeMembership(userId).getRole())) {
			throw new BizException(ErrorCode.NOT_FAMILY_OWNER);
		}
	}

	private FamilyMember activeMembership(Long userId) {
		return first(this.familyMemberMapper
			.selectList(new LambdaQueryWrapper<FamilyMember>().eq(FamilyMember::getUserId, userId)));
	}

	private FamilyMember activeMembershipOf(Long familyId, Long userId) {
		return first(this.familyMemberMapper.selectList(new LambdaQueryWrapper<FamilyMember>()
			.eq(FamilyMember::getFamilyId, familyId)
			.eq(FamilyMember::getUserId, userId)));
	}

	private static FamilyMember first(List<FamilyMember> members) {
		return members.isEmpty() ? null : members.get(0);
	}

	private long countMembers(Long familyId) {
		Long count = this.familyMemberMapper
			.selectCount(new LambdaQueryWrapper<FamilyMember>().eq(FamilyMember::getFamilyId, familyId));
		return (count == null) ? 0L : count;
	}

	private void insertMembership(Long familyId, Long userId, String role, String nickname) {
		// 先尝试复活同一家庭内的软删除历史行：uk_member_family_user 对已软删的行同样生效，直接 INSERT 会撞唯一键
		if (this.familyMemberMapper.revive(familyId, userId, role, nickname) > 0) {
			return;
		}
		FamilyMember member = new FamilyMember();
		member.setFamilyId(familyId);
		member.setUserId(userId);
		member.setNicknameSnapshot(nickname);
		member.setRole(role);
		this.familyMemberMapper.insert(member);
	}

	private void updateRole(Long familyId, Long userId, String role) {
		this.familyMemberMapper.update(null, new LambdaUpdateWrapper<FamilyMember>()
			.eq(FamilyMember::getFamilyId, familyId)
			.eq(FamilyMember::getUserId, userId)
			.set(FamilyMember::getRole, role));
	}

	private void assertNameLength(String name) {
		if (name.length() > 20) {
			throw new BizException(ErrorCode.BAD_REQUEST, "家庭名称最多 20 字符");
		}
	}

	private String generateInviteCode() {
		for (int attempt = 0; attempt < INVITE_CODE_MAX_ATTEMPTS; attempt++) {
			String code = String.format("%06d", this.random.nextInt(INVITE_CODE_POOL));
			if (this.familyMapper.countUnexpiredByInviteCode(code) == 0) {
				return code;
			}
		}
		log.error("邀请码连续 {} 次取号冲突，请检查 family 表是否堆积了大量未过期邀请码", INVITE_CODE_MAX_ATTEMPTS);
		throw new BizException(ErrorCode.INVITE_CODE_GENERATION_FAILED);
	}

	private FamilyResponse toResponse(Family family) {
		List<MemberResponse> members = this.familyMemberMapper.selectMembers(family.getId());
		// inviteEnabled 是「入口当前是否有效」：开关开着、有码、且没过期才算开。
		// 到期后（第 33 轮）入口自动关闭，join 同样会以 EXPIRED 拦住，两处同一口径。
		boolean inviteEnabled = Integer.valueOf(1).equals(family.getInviteEnabled())
				&& family.getInviteCode() != null
				&& family.getInviteCodeExpireAt() != null
				&& family.getInviteCodeExpireAt().isAfter(LocalDateTime.now(this.clock));
		return new FamilyResponse(family.getId(), family.getName(), family.getOwnerUserId(), inviteEnabled,
				family.getInviteCode(), family.getInviteCodeExpireAt(), members);
	}

}
