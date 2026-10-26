package cn.homeledger.service.impl;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BizException;
import cn.homeledger.common.ConsumptionEstimate;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.StatisticsCache;
import cn.homeledger.dto.BabyFormulaBagCreateRequest;
import cn.homeledger.dto.BabyFormulaBagUpdateRequest;
import cn.homeledger.entity.BabyFormulaBag;
import cn.homeledger.mapper.BabyFormulaBagMapper;
import cn.homeledger.service.BabyFormulaBagService;
import cn.homeledger.vo.BabyFormulaBagResponse;
import cn.homeledger.vo.BabyFormulaCurrentResponse;
import cn.homeledger.vo.BabyFormulaEstimateResponse;

/**
 * §4.5.3 奶粉开罐记录，全模块「罐时间线」这份推导的唯一落点。
 * <p>
 * 结束日期与在用状态都不落库，所以列表、宝宝主页的奶粉卡、消耗统计三处的「使用天数」必须出自
 * {@link #timeline()} 这一个方法——写三遍就是三个可能互相矛盾的数。推算本身不在此处实现：
 * 余量 / 日均 / 耗尽日全部由 {@link ConsumptionEstimate} 给出（猫粮与奶粉共用，§6.4.1）。
 * <p>
 * 与猫粮袋的实现逐行同构，差别只有两点（§4.5.3）：预估日均不在家庭级设置表、直接落在每一罐上
 * （{@code estimated_daily_grams}），因此这里不读设置表；统计缓存失效打在
 * {@link StatisticsCache#MODULE_BABY} 段（奶粉消耗卡属于宝宝模块）。
 */
@Service
public class BabyFormulaBagServiceImpl implements BabyFormulaBagService {

	private static final Logger log = LoggerFactory.getLogger(BabyFormulaBagServiceImpl.class);

	private static final String DUPLICATE_STARTED_DATE = "该日期已有一罐奶粉，一个家庭同一天只能开一罐";

	private final BabyFormulaBagMapper babyFormulaBagMapper;

	private final StatisticsCache statisticsCache;

	private final Clock clock;

	public BabyFormulaBagServiceImpl(BabyFormulaBagMapper babyFormulaBagMapper, StatisticsCache statisticsCache,
			Clock clock) {
		this.babyFormulaBagMapper = babyFormulaBagMapper;
		this.statisticsCache = statisticsCache;
		this.clock = clock;
	}

	@Override
	public List<BabyFormulaBagResponse> list() {
		return timeline().stream().map(BabyFormulaBagServiceImpl::toResponse).toList();
	}

	@Override
	public List<TimelineEntry> timeline() {
		List<BabyFormulaBag> rows = this.babyFormulaBagMapper
			.selectList(familyScope(currentFamilyId())
				.orderByAsc(BabyFormulaBag::getStartedDate)
				.orderByAsc(BabyFormulaBag::getId));
		LocalDate today = LocalDate.now(this.clock);
		List<TimelineEntry> entries = new ArrayList<>(rows.size());
		for (int i = 0; i < rows.size(); i++) {
			BabyFormulaBag bag = rows.get(i);
			boolean current = i == rows.size() - 1;
			// 结束日期不落库：已完成罐取下一罐的开罐日，最后一罐就是在用罐、按今天截断（§4.5.3）
			LocalDate endDate = current ? today : rows.get(i + 1).getStartedDate();
			// 已完成罐不含结束日（下一罐开罐那天已经在喝新罐了），在用罐含今天。两边都写 +1 或都不写都会错
			long usageDays = ChronoUnit.DAYS.between(bag.getStartedDate(), endDate) + (current ? 1 : 0);
			entries.add(new TimelineEntry(bag.getId(), bag.getBrand(), bag.getPackGrams(), bag.getStartedDate(),
					bag.getStartedTime(), bag.getEstimatedDailyGrams(), endDate, usageDays, current, bag.getRemark()));
		}
		return entries;
	}

	@Override
	public List<ConsumptionEstimate.ClosedBag> closedBags() {
		return closedBagsFrom(timeline());
	}

	@Override
	public BabyFormulaCurrentResponse current() {
		List<TimelineEntry> entries = timeline();
		if (entries.isEmpty()) {
			return new BabyFormulaCurrentResponse(null, null);
		}
		TimelineEntry bag = entries.get(entries.size() - 1);
		ConsumptionEstimate.Result result = ConsumptionEstimate.of(bag.packGrams(), bag.usageDays(),
				bag.estimatedDailyGrams(), closedBagsFrom(entries), LocalDate.now(this.clock));
		return new BabyFormulaCurrentResponse(toResponse(bag), result == null ? null : toEstimateResponse(bag, result));
	}

	@Override
	@Transactional
	public BabyFormulaBagResponse create(Long userId, BabyFormulaBagCreateRequest request) {
		Long familyId = currentFamilyId();
		assertNotFuture(request.startedDate());
		assertTimeNotFuture(request.startedDate(), request.startedTime());
		assertStartedDateFree(familyId, request.startedDate(), null);

		BabyFormulaBag bag = new BabyFormulaBag();
		bag.setFamilyId(familyId);
		bag.setBrand(request.brand().trim());
		bag.setPackGrams(request.packGrams());
		bag.setStartedDate(request.startedDate());
		bag.setStartedTime(request.startedTime());
		bag.setEstimatedDailyGrams(request.estimatedDailyGrams());
		bag.setRemark(request.remark());
		bag.setCreatedBy(userId);
		try {
			this.babyFormulaBagMapper.insert(bag);
		}
		catch (DuplicateKeyException ex) {
			// 应用层查重与插入之间的并发开罐由 uk_formula_bag_family_active 兜住，对外仍是同一句人话
			throw new BizException(ErrorCode.BAD_REQUEST, DUPLICATE_STARTED_DATE);
		}
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("新开奶粉罐 familyId={} bagId={} startedDate={} operatorUserId={}", familyId, bag.getId(),
				request.startedDate(), userId);
		return toResponse(requireEntry(bag.getId()));
	}

	@Override
	@Transactional
	public BabyFormulaBagResponse update(Long userId, Long id, BabyFormulaBagUpdateRequest request) {
		Long familyId = currentFamilyId();
		BabyFormulaBag bag = requireBag(familyId, id);
		assertNotFuture(request.startedDate());
		assertTimeNotFuture(request.startedDate(), request.startedTime());
		assertStartedDateFree(familyId, request.startedDate(), id);

		bag.setBrand(request.brand().trim());
		bag.setPackGrams(request.packGrams());
		bag.setStartedDate(request.startedDate());
		bag.setStartedTime(request.startedTime());
		bag.setEstimatedDailyGrams(request.estimatedDailyGrams());
		bag.setRemark(request.remark());
		try {
			// 整份覆盖必须走 overwrite：updateById 会跳过 null，清空预估日均或备注就静默失效
			this.babyFormulaBagMapper.overwrite(bag);
		}
		catch (DuplicateKeyException ex) {
			throw new BizException(ErrorCode.BAD_REQUEST, DUPLICATE_STARTED_DATE);
		}
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("修改奶粉罐 familyId={} bagId={} startedDate={} operatorUserId={}", familyId, id,
				request.startedDate(), userId);
		return toResponse(requireEntry(id));
	}

	@Override
	@Transactional
	public void delete(Long userId, Long id) {
		Long familyId = currentFamilyId();
		BabyFormulaBag bag = requireBag(familyId, id);
		// 没有「不能删」的规则：软删把 active_started_date 翻成 NULL，前后两罐自动重新闭合，同一天也能重录
		this.babyFormulaBagMapper.deleteById(bag.getId());
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("删除奶粉罐 familyId={} bagId={} startedDate={} operatorUserId={}", familyId, id, bag.getStartedDate(),
				userId);
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	private BabyFormulaBag requireBag(Long familyId, Long id) {
		BabyFormulaBag bag = this.babyFormulaBagMapper
			.selectOne(new LambdaQueryWrapper<BabyFormulaBag>().eq(BabyFormulaBag::getId, id)
				.eq(BabyFormulaBag::getFamilyId, familyId));
		if (bag == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		return bag;
	}

	/** 写操作的出参永远是推导后的那一行，而不是刚写进去的那个实体：改一罐的开罐日会连带改写别罐的天数。 */
	private TimelineEntry requireEntry(Long id) {
		return timeline().stream()
			.filter(entry -> entry.id().equals(id))
			.findFirst()
			.orElseThrow(() -> new BizException(ErrorCode.RESOURCE_NOT_FOUND));
	}

	private void assertNotFuture(LocalDate startedDate) {
		if (startedDate.isAfter(LocalDate.now(this.clock))) {
			throw new BizException(ErrorCode.BAD_REQUEST, "开罐日期不能晚于今天");
		}
	}

	/**
	 * 当天开罐时具体时刻不得晚于现在——与 {@link #assertNotFuture} 同一句「未来的那一刻还没有奶粉可喝」，
	 * 只是粒度细到时刻（V20261026130000）。回溯补录历史日期的时刻不受限。
	 */
	private void assertTimeNotFuture(LocalDate startedDate, LocalTime startedTime) {
		if (startedTime != null && startedDate.equals(LocalDate.now(this.clock))
				&& startedTime.isAfter(LocalTime.now(this.clock))) {
			throw new BizException(ErrorCode.BAD_REQUEST, "开罐时间不能晚于当前时刻");
		}
	}

	/** 只比没删掉的罐：这条查询自带 deleted = 0，所以删掉的那罐不占这个开罐日（§4.5.3 的补录路径）。 */
	private void assertStartedDateFree(Long familyId, LocalDate startedDate, Long excludeId) {
		Long duplicated = this.babyFormulaBagMapper.selectCount(familyScope(familyId)
			.eq(BabyFormulaBag::getStartedDate, startedDate)
			.ne(excludeId != null, BabyFormulaBag::getId, excludeId));
		if (duplicated != null && duplicated > 0) {
			throw new BizException(ErrorCode.BAD_REQUEST, DUPLICATE_STARTED_DATE);
		}
	}

	private static LambdaQueryWrapper<BabyFormulaBag> familyScope(Long familyId) {
		return new LambdaQueryWrapper<BabyFormulaBag>().eq(BabyFormulaBag::getFamilyId, familyId);
	}

	/** 全模块唯一的「可用历史罐」判据在这里，各调用方一律走 {@link #closedBags()}，不许再各自筛一遍。 */
	private static List<ConsumptionEstimate.ClosedBag> closedBagsFrom(List<TimelineEntry> entries) {
		return entries.stream()
			.filter(entry -> !entry.current() && entry.usageDays() > 0)
			.map(entry -> new ConsumptionEstimate.ClosedBag(entry.packGrams(), entry.usageDays()))
			.toList();
	}

	/**
	 * 当前罐的两个派生列都是 null（§4.5.3）：一罐还没喝完，它自己的折算日均不是一个事实。
	 */
	static BabyFormulaBagResponse toResponse(TimelineEntry entry) {
		return new BabyFormulaBagResponse(entry.id(), entry.brand(), entry.packGrams(), entry.startedDate(),
				entry.startedTime(), entry.estimatedDailyGrams(), entry.current() ? null : entry.usageDays(),
				entry.current() || entry.usageDays() <= 0 ? null : dailyAverage(entry), entry.current(),
				entry.remark());
	}

	/** 使用天数为 0 的异常罐给 null 而不是除以 0。 */
	private static int dailyAverage(TimelineEntry entry) {
		return BigDecimal.valueOf(entry.packGrams())
			.divide(BigDecimal.valueOf(entry.usageDays()), 0, RoundingMode.HALF_UP)
			.intValue();
	}

	private static BabyFormulaEstimateResponse toEstimateResponse(TimelineEntry entry,
			ConsumptionEstimate.Result result) {
		return new BabyFormulaEstimateResponse(entry.usageDays(), result.dailyAverage(), result.consumedGrams(),
				result.remainingGrams(), result.remainingPercent(), result.daysLeft(), result.depletionDate(),
				result.fromHistory(), result.overEstimate());
	}

}