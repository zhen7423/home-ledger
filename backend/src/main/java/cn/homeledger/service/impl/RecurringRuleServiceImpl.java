package cn.homeledger.service.impl;

import java.time.Clock;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.FinanceDictionaryResolver;
import cn.homeledger.dto.RecurringRuleCreateRequest;
import cn.homeledger.dto.RecurringRuleUpdateRequest;
import cn.homeledger.entity.Category;
import cn.homeledger.entity.PaymentAccount;
import cn.homeledger.entity.RecurringExecutionLog;
import cn.homeledger.entity.RecurringRule;
import cn.homeledger.mapper.CategoryMapper;
import cn.homeledger.mapper.PaymentAccountMapper;
import cn.homeledger.mapper.RecurringExecutionLogMapper;
import cn.homeledger.mapper.RecurringRuleMapper;
import cn.homeledger.service.RecurringGenerationService;
import cn.homeledger.service.RecurringRuleService;
import cn.homeledger.vo.RecurringExecutionResponse;
import cn.homeledger.vo.RecurringRuleResponse;
import tools.jackson.databind.ObjectMapper;

/**
 * §4.2.3 周期记账规则的增删改查。
 * <p>
 * 这里只管配置，生成流水的是 {@link RecurringGenerationService}。只有 A4「当月立即生效」那一处例外：
 * 新建与恢复规则时会在同一个请求里同步补跑当天窗口，所以本类是引擎除定时任务外唯一的调用方。
 * 两件事共用同一套字典与金额校验（{@link FinanceDictionaryResolver}），
 * 因为「规则能建但流水记不进」是这两处口径走偏时唯一会露出来的症状，而且很难查。
 */
@Service
public class RecurringRuleServiceImpl implements RecurringRuleService {

	/** DAILY 的间隔上限：一年 365 天，再长的间隔在家庭记账里没有意义。 */
	private static final int MAX_INTERVAL_DAYS = 365;

	private static final int MAX_WEEKDAY = 7;

	private static final int MAX_DAY_OF_MONTH = 31;

	private static final int MAX_MONTH = 12;

	private static final String PERIOD_DAILY = "DAILY";

	private static final String PERIOD_WEEKLY = "WEEKLY";

	private static final String PERIOD_MONTHLY = "MONTHLY";

	private static final String PERIOD_YEARLY = "YEARLY";

	private static final Logger log = LoggerFactory.getLogger(RecurringRuleServiceImpl.class);

	private final RecurringRuleMapper ruleMapper;

	private final RecurringExecutionLogMapper executionLogMapper;

	private final CategoryMapper categoryMapper;

	private final PaymentAccountMapper paymentAccountMapper;

	private final FinanceDictionaryResolver dictionaryResolver;

	private final RecurringGenerationService generationService;

	private final ObjectMapper objectMapper;

	private final Clock clock;

	public RecurringRuleServiceImpl(RecurringRuleMapper ruleMapper, RecurringExecutionLogMapper executionLogMapper,
			CategoryMapper categoryMapper, PaymentAccountMapper paymentAccountMapper,
			FinanceDictionaryResolver dictionaryResolver, RecurringGenerationService generationService,
			ObjectMapper objectMapper, Clock clock) {
		this.ruleMapper = ruleMapper;
		this.executionLogMapper = executionLogMapper;
		this.categoryMapper = categoryMapper;
		this.paymentAccountMapper = paymentAccountMapper;
		this.dictionaryResolver = dictionaryResolver;
		this.generationService = generationService;
		this.objectMapper = objectMapper;
		this.clock = clock;
	}

	@Override
	public List<RecurringRuleResponse> list(String type) {
		Long familyId = currentFamilyId();
		List<RecurringRule> rules = this.ruleMapper
			.selectList(new LambdaQueryWrapper<RecurringRule>().eq(RecurringRule::getFamilyId, familyId)
				.eq(type != null && !type.isBlank(), RecurringRule::getType, type)
				.orderByDesc(RecurringRule::getCreatedAt)
				.orderByDesc(RecurringRule::getId));
		return toResponses(rules);
	}

	@Override
	@Transactional
	public RecurringRuleResponse create(Long userId, RecurringRuleCreateRequest request) {
		Long familyId = currentFamilyId();
		this.dictionaryResolver.assertAmount(request.amount());
		// 两个 usable 都取 true：不允许建一条指向已停用类别或已停用支付方式的规则，
		// 那样的规则从建成的那一刻起就在生成用户看不懂的流水
		FinanceDictionaryResolver.Dictionary dict = this.dictionaryResolver.resolve(familyId, request.categoryId(),
				request.subCategoryId(), request.accountId(), true, true, true);
		assertPeriod(request.periodType(), request.periodValue());

		LocalDate startDate = request.startDate() != null ? request.startDate() : LocalDate.now(this.clock);
		assertDateRange(startDate, request.endDate());

		RecurringRule rule = new RecurringRule();
		rule.setFamilyId(familyId);
		rule.setName(request.name());
		rule.setType(dict.type());
		rule.setAmount(request.amount());
		rule.setCategoryId(dict.category().getId());
		rule.setSubCategoryId(request.subCategoryId());
		rule.setAccountId(dict.account().getId());
		rule.setPeriodType(request.periodType());
		rule.setPeriodValue(writePeriodValue(request.periodValue()));
		rule.setStartDate(startDate);
		rule.setEndDate(request.endDate());
		rule.setEnabled(1);
		// 游标停在起始日前一天，于是引擎的窗口起点 last_processed_date + 1 恰好等于 start_date
		rule.setLastProcessedDate(startDate.minusDays(1));
		rule.setCreatedBy(userId);
		this.ruleMapper.insert(rule);
		log.info("新建周期规则 familyId={} ruleId={} periodType={} type={} operatorUserId={}", familyId, rule.getId(),
				rule.getPeriodType(), rule.getType(), userId);
		// A4「当月立即生效」：当场把本月的执行日补出来，而不是等明早 00:10。9 月 13 日建一条「每月 1 日 房租」，
		// 不补跑的话界面上什么都不会发生，要等到 10 月才见第一笔——而 9 月的房租其实已经付了，用户会认为功能坏了
		this.generationService.runForRule(rule, LocalDate.now(this.clock));
		// created_at / updated_at 由 DDL 默认值填，insert 之后实体里还是 null，所以回查一次再出参
		return toResponse(requireRule(familyId, rule.getId()));
	}

	@Override
	public RecurringRuleResponse get(Long id) {
		return toResponse(requireRule(currentFamilyId(), id));
	}

	@Override
	@Transactional
	public RecurringRuleResponse update(Long userId, Long id, RecurringRuleUpdateRequest request) {
		Long familyId = currentFamilyId();
		RecurringRule rule = requireRule(familyId, id);
		this.dictionaryResolver.assertAmount(request.amount());
		FinanceDictionaryResolver.Dictionary dict = this.dictionaryResolver.resolve(familyId, request.categoryId(),
				request.subCategoryId(), request.accountId(), true, true, true);
		assertPeriod(request.periodType(), request.periodValue());
		LocalDate startDate = request.startDate() != null ? request.startDate() : rule.getStartDate();
		assertDateRange(startDate, request.endDate());

		// 周期参数或起始日一改，旧游标对新参数就没有意义了：不重置的话窗口起点会停在老配置处理到的那天，
		// 表现为「改了规则但当月没补出新流水」。只改名称与金额时不动游标。
		if (cursorNeedsReset(rule, request, startDate)) {
			rule.setLastProcessedDate(startDate.minusDays(1));
		}
		rule.setName(request.name());
		rule.setType(dict.type());
		rule.setAmount(request.amount());
		rule.setCategoryId(request.categoryId());
		rule.setSubCategoryId(request.subCategoryId());
		rule.setAccountId(request.accountId());
		rule.setPeriodType(request.periodType());
		rule.setPeriodValue(writePeriodValue(request.periodValue()));
		rule.setStartDate(startDate);
		rule.setEndDate(request.endDate());
		this.ruleMapper.overwrite(rule);
		log.info("编辑周期规则 familyId={} ruleId={} operatorUserId={}", familyId, id, userId);
		return toResponse(requireRule(familyId, id));
	}

	@Override
	@Transactional
	public RecurringRuleResponse toggle(Long userId, Long id) {
		Long familyId = currentFamilyId();
		RecurringRule rule = requireRule(familyId, id);
		rule.setEnabled(rule.getEnabled() == 1 ? 0 : 1);
		// 暂停时不动游标：游标停在暂停那天，恢复时窗口起点自然收窄，不会把暂停期整段补出来（§4.3）
		this.ruleMapper.updateById(rule);
		log.info("启停周期规则 familyId={} ruleId={} enabled={} operatorUserId={}", familyId, id, rule.getEnabled(),
				userId);
		if (rule.getEnabled() == 1) {
			// A4 对「恢复」与「新建」一视同仁。必须排在 updateById 之后：引擎用 UPDATE 推进游标，
			// 先跑再 updateById 会拿实体里那份旧游标把推进结果盖回去
			this.generationService.runForRule(rule, LocalDate.now(this.clock));
		}
		return toResponse(rule);
	}

	@Override
	@Transactional
	public void delete(Long userId, Long id) {
		Long familyId = currentFamilyId();
		requireRule(familyId, id);
		// @TableLogic 把这条变成 UPDATE deleted = 1。它生成过的流水保留——那些流水已经是家庭账本的一部分
		this.ruleMapper.deleteById(id);
		log.info("删除周期规则 familyId={} ruleId={} operatorUserId={}", familyId, id, userId);
	}

	@Override
	public List<RecurringExecutionResponse> executions(Long id) {
		Long familyId = currentFamilyId();
		requireRule(familyId, id);
		return this.executionLogMapper.selectByRule(familyId, id)
			.stream()
			.map(RecurringRuleServiceImpl::toExecutionResponse)
			.toList();
	}

	private static RecurringExecutionResponse toExecutionResponse(RecurringExecutionLog row) {
		LocalDate executedDate = row.getCreatedAt().toLocalDate();
		return new RecurringExecutionResponse(row.getId(), row.getBizDate(), row.getTransactionId(), executedDate,
				// 补记的判定口径只在这里定义一次，不让前端拿两个日期自己减
				executedDate.isAfter(row.getBizDate()));
	}

	private boolean cursorNeedsReset(RecurringRule original, RecurringRuleUpdateRequest request,
			LocalDate startDate) {
		// 比的是解析后的对象而不是 JSON 字符串：库里那串的字面形式随序列化配置变，语义相同却字符串不等的
		// 话会白白重置游标，把已经生成过的日期又算一遍
		return !original.getStartDate().equals(startDate) || !original.getPeriodType().equals(request.periodType())
				|| !readPeriodValue(original.getPeriodValue()).equals(request.periodValue());
	}

	private RecurringRule requireRule(Long familyId, Long id) {
		RecurringRule rule = this.ruleMapper
			.selectOne(new LambdaQueryWrapper<RecurringRule>().eq(RecurringRule::getId, id)
				.eq(RecurringRule::getFamilyId, familyId));
		if (rule == null) {
			throw new BizException(ErrorCode.RECURRING_RULE_NOT_FOUND);
		}
		return rule;
	}

	/**
	 * 周期参数的跨字段校验。每种 periodType 只认自己那几个字段，多余的也拒——
	 * 客户端把 WEEKLY 的参数和 daysOfMonth 一起发来，说明它自己就串了配置，放过去只会生成一屏看不懂的流水。
	 * <p>
	 * 结构不合法（缺字段、多字段、空数组）给 PERIOD_VALUE_INVALID，结构合法但数值越界给 PERIOD_RANGE_INVALID：
	 * 前者意味着客户端有 bug，后者意味着用户填错了，前端要分开提示。
	 */
	private void assertPeriod(String periodType, RecurringRuleCreateRequest.PeriodValue value) {
		switch (periodType) {
			case PERIOD_DAILY -> {
				if (value.intervalDays() == null || value.weekdays() != null || value.daysOfMonth() != null
						|| value.month() != null) {
					throw new BizException(ErrorCode.PERIOD_VALUE_INVALID);
				}
				assertInRange("intervalDays", value.intervalDays(), 1, MAX_INTERVAL_DAYS);
			}
			case PERIOD_WEEKLY -> {
				if (value.intervalDays() != null || value.weekdays() == null || value.daysOfMonth() != null
						|| value.month() != null) {
					throw new BizException(ErrorCode.PERIOD_VALUE_INVALID);
				}
				assertDaysInRange(value.weekdays(), 1, MAX_WEEKDAY);
			}
			case PERIOD_MONTHLY -> {
				if (value.intervalDays() != null || value.weekdays() != null || value.daysOfMonth() == null
						|| value.month() != null) {
					throw new BizException(ErrorCode.PERIOD_VALUE_INVALID);
				}
				assertDaysInRange(value.daysOfMonth(), 1, MAX_DAY_OF_MONTH);
			}
			case PERIOD_YEARLY -> {
				if (value.intervalDays() != null || value.weekdays() != null || value.daysOfMonth() == null
						|| value.month() == null) {
					throw new BizException(ErrorCode.PERIOD_VALUE_INVALID);
				}
				assertInRange("month", value.month(), 1, MAX_MONTH);
				assertDaysInRange(value.daysOfMonth(), 1, MAX_DAY_OF_MONTH);
			}
			default -> throw new BizException(ErrorCode.PERIOD_VALUE_INVALID);
		}
	}

	private void assertInRange(String field, Integer value, int min, int max) {
		if (value < min || value > max) {
			throw new BizException(ErrorCode.PERIOD_RANGE_INVALID, field + " 要在 " + min + " 到 " + max + " 之间");
		}
	}

	private void assertDaysInRange(List<Integer> days, int min, int max) {
		if (days.isEmpty()) {
			throw new BizException(ErrorCode.PERIOD_VALUE_INVALID, "日期列表不能为空");
		}
		for (Integer day : days) {
			if (day == null) {
				throw new BizException(ErrorCode.PERIOD_VALUE_INVALID, "日期列表里不能有 null");
			}
			assertInRange("日期", day, min, max);
		}
	}

	private void assertDateRange(LocalDate startDate, LocalDate endDate) {
		if (endDate != null && endDate.isBefore(startDate)) {
			throw new BizException(ErrorCode.PERIOD_RANGE_INVALID, "截止日期不能早于起始日期");
		}
	}

	private String writePeriodValue(RecurringRuleCreateRequest.PeriodValue value) {
		return this.objectMapper.writeValueAsString(value);
	}

	private RecurringRuleCreateRequest.PeriodValue readPeriodValue(String json) {
		return this.objectMapper.readValue(json, RecurringRuleCreateRequest.PeriodValue.class);
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	private RecurringRuleResponse toResponse(RecurringRule rule) {
		return toResponses(List.of(rule)).get(0);
	}

	/**
	 * 出参里的类别名与支付方式名实时解析，所以整页只查两次字典表。
	 * <p>
	 * 解析不到时名称给 null 而不是报错：字典项被规则引用时删不掉（B8），真出现空洞说明数据被绕过接口改过，
	 * 那属于运维要处理的事，不该让列表页打不开。
	 */
	private List<RecurringRuleResponse> toResponses(List<RecurringRule> rules) {
		if (rules.isEmpty()) {
			return List.of();
		}
		Long familyId = rules.get(0).getFamilyId();
		Set<Long> categoryIds = new HashSet<>();
		Set<Long> accountIds = new HashSet<>();
		for (RecurringRule rule : rules) {
			categoryIds.add(rule.getCategoryId());
			if (rule.getSubCategoryId() != null) {
				categoryIds.add(rule.getSubCategoryId());
			}
			accountIds.add(rule.getAccountId());
		}
		Map<Long, Category> categories = this.categoryMapper
			.selectList(new LambdaQueryWrapper<Category>().eq(Category::getFamilyId, familyId)
				.in(Category::getId, categoryIds))
			.stream()
			.collect(Collectors.toMap(Category::getId, Function.identity()));
		Map<Long, PaymentAccount> accounts = this.paymentAccountMapper
			.selectList(new LambdaQueryWrapper<PaymentAccount>().eq(PaymentAccount::getFamilyId, familyId)
				.in(PaymentAccount::getId, accountIds))
			.stream()
			.collect(Collectors.toMap(PaymentAccount::getId, Function.identity()));

		List<RecurringRuleResponse> responses = new ArrayList<>(rules.size());
		for (RecurringRule rule : rules) {
			Category category = categories.get(rule.getCategoryId());
			Category subCategory = (rule.getSubCategoryId() == null) ? null : categories.get(rule.getSubCategoryId());
			PaymentAccount account = accounts.get(rule.getAccountId());
			responses.add(new RecurringRuleResponse(rule.getId(), rule.getName(), rule.getType(), rule.getAmount(),
					rule.getCategoryId(), category == null ? null : category.getName(), rule.getSubCategoryId(),
					subCategory == null ? null : subCategory.getName(), rule.getAccountId(),
					account == null ? null : account.getName(), rule.getPeriodType(),
					readPeriodValue(rule.getPeriodValue()), rule.getStartDate(), rule.getEndDate(),
					rule.getEnabled() == 1, rule.getCreatedAt(), rule.getUpdatedAt()));
		}
		return responses;
	}

}
