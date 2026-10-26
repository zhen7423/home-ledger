package cn.homeledger.service.impl;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BizException;
import cn.homeledger.common.BudgetLevel;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.FinanceDictionaryResolver;
import cn.homeledger.dto.BudgetSaveRequest;
import cn.homeledger.entity.Budget;
import cn.homeledger.entity.Category;
import cn.homeledger.entity.FamilyMember;
import cn.homeledger.entity.User;
import cn.homeledger.mapper.BudgetMapper;
import cn.homeledger.mapper.CategoryMapper;
import cn.homeledger.mapper.FamilyMemberMapper;
import cn.homeledger.mapper.TransactionMapper;
import cn.homeledger.mapper.UserMapper;
import cn.homeledger.service.BudgetService;
import cn.homeledger.vo.BudgetProgressResponse;
import cn.homeledger.vo.BudgetResponse;

/**
 * §4.2.4 三维度预算。
 * <p>
 * 本类不存「已用额度」，那是每次从流水现算的（{@code progress}）。它只负责一份额度配置的形状与防重，
 * 所以整个类里最讲究的是 {@link #derive} ——bucketKey 的派生规则只写在那一处。
 */
@Service
public class BudgetServiceImpl implements BudgetService {

	private static final String SCOPE_FAMILY = "FAMILY";

	private static final String SCOPE_CATEGORY = "CATEGORY";

	private static final String SCOPE_MEMBER = "MEMBER";

	/** 一个月还没有流水时的已用值。带两位小数，与流水金额的收发口径一致。 */
	private static final BigDecimal NO_SPEND = new BigDecimal("0.00");

	private static final Logger log = LoggerFactory.getLogger(BudgetServiceImpl.class);

	private final BudgetMapper budgetMapper;

	private final TransactionMapper transactionMapper;

	private final CategoryMapper categoryMapper;

	private final FamilyMemberMapper familyMemberMapper;

	private final UserMapper userMapper;

	private final FinanceDictionaryResolver dictionaryResolver;

	private final Clock clock;

	public BudgetServiceImpl(BudgetMapper budgetMapper, TransactionMapper transactionMapper,
			CategoryMapper categoryMapper, FamilyMemberMapper familyMemberMapper, UserMapper userMapper,
			FinanceDictionaryResolver dictionaryResolver, Clock clock) {
		this.budgetMapper = budgetMapper;
		this.transactionMapper = transactionMapper;
		this.categoryMapper = categoryMapper;
		this.familyMemberMapper = familyMemberMapper;
		this.userMapper = userMapper;
		this.dictionaryResolver = dictionaryResolver;
		this.clock = clock;
	}

	@Override
	public List<BudgetResponse> list() {
		Long familyId = currentFamilyId();
		List<Budget> budgets = this.budgetMapper.selectList(inFamily(familyId));
		Names names = resolveNames(familyId, budgets);
		return budgets.stream()
			.map(budget -> new BudgetResponse(budget.getId(), budget.getScope(), budget.getCategoryId(),
					names.categoryName(budget.getCategoryId()), budget.getMemberUserId(),
					names.memberName(budget.getMemberUserId()), budget.getAmount()))
			.toList();
	}

	@Override
	@Transactional
	public void save(Long userId, BudgetSaveRequest request) {
		Long familyId = currentFamilyId();
		List<BudgetSaveRequest.Item> items = (request.items() == null) ? List.of() : request.items();
		List<Bucket> buckets = validate(items, familyId);
		// 先删后插而不是逐行 diff：预算是「当前配置」不是历史记录，整体替换让防重只有一条路径可走，
		// 不必处理「这行原来有现在没有」「这行换了维度」那些边角。代价是每次保存所有 id 都会变
		this.budgetMapper.deleteAllByFamily(familyId);
		for (Bucket bucket : buckets) {
			Budget budget = new Budget();
			budget.setFamilyId(familyId);
			budget.setScope(bucket.item().scope());
			budget.setCategoryId(bucket.item().categoryId());
			budget.setMemberUserId(bucket.item().memberUserId());
			budget.setBucketKey(bucket.key());
			budget.setAmount(bucket.item().amount());
			budget.setCreatedBy(userId);
			this.budgetMapper.insert(budget);
		}
		log.info("保存预算 familyId={} count={} operatorUserId={}", familyId, buckets.size(), userId);
	}

	@Override
	public List<BudgetProgressResponse> progress(String month) {
		Long familyId = currentFamilyId();
		YearMonth target = parseMonth(month);
		LocalDate today = LocalDate.now(this.clock);
		LocalDate from = target.atDay(1);
		LocalDate to = target.atEndOfMonth();
		// 剩余天数只对当前月有意义：过去月份给 0 而不是负数，未来月份给 0 而不是整月天数
		int remainingDays = target.equals(YearMonth.from(today)) ? target.lengthOfMonth() - today.getDayOfMonth() + 1
				: 0;

		List<Budget> budgets = this.budgetMapper.selectList(inFamily(familyId));
		if (budgets.isEmpty()) {
			return List.of();
		}
		BigDecimal familyExpense = this.transactionMapper.sumExpenseInRange(familyId, from, to);
		Map<Long, BigDecimal> byCategory = this.transactionMapper.sumExpenseByCategory(familyId, from, to)
			.stream()
			.collect(Collectors.toMap(TransactionMapper.CategorySpend::categoryId,
					TransactionMapper.CategorySpend::amount));
		Map<Long, BigDecimal> byMember = this.transactionMapper.sumExpenseByCreator(familyId, from, to)
			.stream()
			.collect(Collectors.toMap(TransactionMapper.MemberSpend::createdBy, TransactionMapper.MemberSpend::amount));
		Names names = resolveNames(familyId, budgets);
		return budgets.stream()
			.map(budget -> toProgress(budget, target.toString(), remainingDays, familyExpense, byCategory, byMember,
					names))
			.toList();
	}

	/** 校验顺序：维度形状 → 字典与成员归属 → 请求内去重 → 金额。测试按这个顺序断言错误码。 */
	private List<Bucket> validate(List<BudgetSaveRequest.Item> items, Long familyId) {
		List<Bucket> buckets = new ArrayList<>(items.size());
		Set<String> keys = new HashSet<>();
		for (BudgetSaveRequest.Item item : items) {
			Bucket bucket = derive(item, familyId);
			// 请求内去重不能省：uk_budget_bucket 挡不住同一事务里的重复——先删后插时第二行才撞键，
			// 而那时用户看到的是一条 500 而不是一句「这个维度已经设过了」
			if (!keys.add(bucket.key())) {
				throw new BizException(ErrorCode.BUDGET_DUPLICATED);
			}
			this.dictionaryResolver.assertAmount(item.amount());
			buckets.add(bucket);
		}
		return buckets;
	}

	/**
	 * 逐维度核对空值形状并派生 bucketKey。缺了要报，<b>多了也要报</b>：一个带了 categoryId 的 FAMILY 行
	 * 说明客户端把三个维度的表单串成了一份，静默丢掉那个 id 会让用户以为类别预算设好了。
	 */
	private Bucket derive(BudgetSaveRequest.Item item, Long familyId) {
		return switch (item.scope()) {
		case SCOPE_FAMILY -> {
			if (item.categoryId() != null || item.memberUserId() != null) {
				throw new BizException(ErrorCode.BUDGET_SCOPE_INVALID);
			}
			yield new Bucket(item, SCOPE_FAMILY);
		}
		case SCOPE_CATEGORY -> {
			if (item.categoryId() == null || item.memberUserId() != null) {
				throw new BizException(ErrorCode.BUDGET_SCOPE_INVALID);
			}
			assertMajorCategory(familyId, item.categoryId());
			yield new Bucket(item, "C:" + item.categoryId());
		}
		case SCOPE_MEMBER -> {
			if (item.memberUserId() == null || item.categoryId() != null) {
				throw new BizException(ErrorCode.BUDGET_SCOPE_INVALID);
			}
			assertFamilyMember(familyId, item.memberUserId());
			yield new Bucket(item, "M:" + item.memberUserId());
		}
		default -> throw new BizException(ErrorCode.BUDGET_SCOPE_INVALID);
		};
	}

	/** 类别维度只认大类，但<b>不要求启用</b>：给一个已停用的大类设预算是有意义的——历史流水还在往里记，用户要看它这个月花了多少。 */
	private void assertMajorCategory(Long familyId, Long categoryId) {
		Category category = this.categoryMapper
			.selectOne(new LambdaQueryWrapper<Category>().eq(Category::getId, categoryId)
				.eq(Category::getFamilyId, familyId));
		if (category == null) {
			throw new BizException(ErrorCode.CATEGORY_NOT_FOUND);
		}
		if (category.getParentId() != null) {
			throw new BizException(ErrorCode.BUDGET_CATEGORY_NOT_MAJOR);
		}
	}

	/**
	 * family_member 在租户白名单里（§5.2），拦截器不会替它加家庭条件，所以这里的 family_id 是唯一防线。
	 * {@code @TableLogic} 会自动带上 deleted = 0，已退出的成员查不到，正好是要的语义。
	 */
	private void assertFamilyMember(Long familyId, Long memberUserId) {
		FamilyMember membership = this.familyMemberMapper
			.selectOne(new LambdaQueryWrapper<FamilyMember>().eq(FamilyMember::getFamilyId, familyId)
				.eq(FamilyMember::getUserId, memberUserId));
		if (membership == null) {
			throw new BizException(ErrorCode.BUDGET_MEMBER_NOT_IN_FAMILY);
		}
	}

	private BudgetProgressResponse toProgress(Budget budget, String month, int remainingDays,
			BigDecimal familyExpense, Map<Long, BigDecimal> byCategory, Map<Long, BigDecimal> byMember, Names names) {
		// 类别维度直接取大类的聚合值：流水的大类恒记在 category_id 上，小类留没留空都一样，
		// 所以「小类算进所属大类」在这条 SQL 里是免费的
		BigDecimal used = switch (budget.getScope()) {
		case SCOPE_FAMILY -> familyExpense;
		case SCOPE_CATEGORY -> byCategory.getOrDefault(budget.getCategoryId(), NO_SPEND);
		case SCOPE_MEMBER -> byMember.getOrDefault(budget.getMemberUserId(), NO_SPEND);
		default -> throw new BizException(ErrorCode.BAD_REQUEST, "预算行的维度不认识：" + budget.getScope());
		};
		BigDecimal amount = budget.getAmount();
		return new BudgetProgressResponse(month, budget.getScope(), budget.getCategoryId(),
				names.categoryName(budget.getCategoryId()), budget.getMemberUserId(),
				names.memberName(budget.getMemberUserId()), amount, used, amount.subtract(used),
				percentOf(used, amount), levelOf(used, amount), remainingDays);
	}

	/**
	 * 已用百分比向下取整。
	 * <p>
	 * 用 DOWN 而不是 HALF_UP：79.6% 必须显示成 79% 且档位仍是 NORMAL。四舍五入成 80% 的话，用户会看到
	 * 「进度条写着 80%、颜色已经变橙、提醒说的却是即将超支」，三个信号互相打架。
	 * 档位判定用的是没取整的原始比值（{@link #levelOf}），所以取整方向影响不到档位。
	 */
	private static int percentOf(BigDecimal used, BigDecimal budget) {
		if (budget.signum() == 0) {
			return used.signum() == 0 ? 0 : 100;
		}
		return used.multiply(BigDecimal.valueOf(100)).divide(budget, 0, RoundingMode.DOWN).intValue();
	}

	/** 写成 {@code used * 5 >= budget * 4} 而不是 {@code used / budget >= 0.8}：BigDecimal 除不尽会抛 ArithmeticException，而这里根本不需要商。 */
	private static BudgetLevel levelOf(BigDecimal used, BigDecimal budget) {
		// 恰好花完额度算超支而不是预警：§4.2.4 的阈值表写的是「进度 ≥ 100%」，两档的分界是闭区间在超支这边
		if (used.compareTo(budget) >= 0) {
			return BudgetLevel.EXCEEDED;
		}
		if (used.multiply(BigDecimal.valueOf(5)).compareTo(budget.multiply(BigDecimal.valueOf(4))) >= 0) {
			return BudgetLevel.WARNING;
		}
		return BudgetLevel.NORMAL;
	}

	private YearMonth parseMonth(String month) {
		if (month == null || month.isBlank()) {
			return YearMonth.now(this.clock);
		}
		try {
			return YearMonth.parse(month.trim());
		}
		catch (DateTimeParseException e) {
			throw new BizException(ErrorCode.BAD_REQUEST, "月份要写成 2026-09 这样");
		}
	}

	/**
	 * 出参里的类别名与成员名都是实时解析的，整页各查一次。
	 * <p>
	 * 成员名取 {@code family_member.nickname_snapshot} 而不是 {@code user.nickname}：这一页显示的是
	 * 「他在这个家庭里的名字」，与成员列表同一口径（§4.1.5）。
	 */
	private Names resolveNames(Long familyId, List<Budget> budgets) {
		Set<Long> categoryIds = new HashSet<>();
		Set<Long> memberIds = new HashSet<>();
		for (Budget budget : budgets) {
			if (budget.getCategoryId() != null) {
				categoryIds.add(budget.getCategoryId());
			}
			if (budget.getMemberUserId() != null) {
				memberIds.add(budget.getMemberUserId());
			}
		}
		Map<Long, String> categories = categoryIds.isEmpty()
				? Map.of()
				: this.categoryMapper.selectList(new LambdaQueryWrapper<Category>().eq(Category::getFamilyId, familyId)
					.in(Category::getId, categoryIds))
					.stream()
					.collect(Collectors.toMap(Category::getId, Category::getName));
		Map<Long, String> members = memberIds.isEmpty() ? Map.of() : memberNames(familyId, memberIds);
		return new Names(categories, members);
	}

	/**
	 * family_member 在租户白名单里（拦截器不加 family_id 条件），每条查询必须自带 family_id 或
	 * user_id 之外的收敛条件（FamilyServiceImpl 的铁律）：只按 userId 查的话，一旦同一 user 存在
	 * 多家庭在籍行（手工修数/并发加入时序异常），toMap 会随机取到别家的昵称快照（扫描报告 P1-2）。
	 */
	private Map<Long, String> memberNames(Long familyId, Set<Long> memberIds) {
		Map<Long, String> names = this.familyMemberMapper
			.selectList(new LambdaQueryWrapper<FamilyMember>().eq(FamilyMember::getFamilyId, familyId)
				.in(FamilyMember::getUserId, memberIds))
			.stream()
			.collect(Collectors.toMap(FamilyMember::getUserId, FamilyMember::getNicknameSnapshot,
					(first, second) -> first));
		// 快照里没有的那个人只可能是已经退出的（B8 会删掉他的预算行，真出现说明数据被绕过接口改过），
		// 回落到 user 表，好让列表里永远有一个名字而不是空白
		List<Long> missing = memberIds.stream().filter(id -> !names.containsKey(id)).toList();
		if (!missing.isEmpty()) {
			this.userMapper.selectList(new LambdaQueryWrapper<User>().in(User::getId, missing))
				.forEach(user -> names.put(user.getId(), user.getNickname()));
		}
		return names;
	}

	private static LambdaQueryWrapper<Budget> inFamily(Long familyId) {
		// 按 id 升序就是用户提交时的先后：雪花 id 单调递增，整体替换又是在一个循环里按序插进去的
		return new LambdaQueryWrapper<Budget>().eq(Budget::getFamilyId, familyId).orderByAsc(Budget::getId);
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	/** 校验通过、带派生键的一行。 */
	private record Bucket(BudgetSaveRequest.Item item, String key) {

	}

	private record Names(Map<Long, String> categories, Map<Long, String> members) {

		String categoryName(Long categoryId) {
			return (categoryId == null) ? null : this.categories.get(categoryId);
		}

		String memberName(Long memberUserId) {
			return (memberUserId == null) ? null : this.members.get(memberUserId);
		}

	}

}
