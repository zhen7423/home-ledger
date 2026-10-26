package cn.homeledger.service.impl;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Clock;
import java.time.LocalDate;
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
import cn.homeledger.dto.CatFoodBagCreateRequest;
import cn.homeledger.dto.CatFoodBagUpdateRequest;
import cn.homeledger.entity.CatFoodBag;
import cn.homeledger.entity.CatSetting;
import cn.homeledger.mapper.CatFoodBagMapper;
import cn.homeledger.mapper.CatSettingMapper;
import cn.homeledger.service.CatFoodBagService;
import cn.homeledger.vo.CatFoodBagResponse;
import cn.homeledger.vo.CatFoodCurrentResponse;
import cn.homeledger.vo.CatFoodEstimateResponse;

/**
 * §4.3.2 猫粮袋记录，全模块「袋子时间线」这份推导的唯一落点。
 * <p>
 * 结束日期与在用状态都不落库，所以列表、总览页的余量卡、消耗统计三处的「使用天数」必须出自
 * {@link #timeline()} 这一个方法——写三遍就是三个可能互相矛盾的数。
 * <p>
 * 这里读 {@link CatSettingMapper} 而不是设置页那个 Service，因为要的是「用户到底填没填预估日均」这个
 * 原始事实（无行 = 没填 = null）；设置接口的 GET 会把缺列翻成默认值，那是给界面用的口径，
 * 拿它来喂推算会让「从来没打开过设置页」与「打开过但留空」变成同一件事（§7.1）。两个 Service 互相依赖
 * 还会成环：设置页那句「已由历史数据接管」读的正是本类的 {@link #closedBags()}。
 */
@Service
public class CatFoodBagServiceImpl implements CatFoodBagService {

	private static final Logger log = LoggerFactory.getLogger(CatFoodBagServiceImpl.class);

	private static final String DUPLICATE_STARTED_DATE = "该日期已有另一袋猫粮，一个家庭同一天只能开一袋";

	private final CatFoodBagMapper catFoodBagMapper;

	private final CatSettingMapper catSettingMapper;

	private final StatisticsCache statisticsCache;

	private final Clock clock;

	public CatFoodBagServiceImpl(CatFoodBagMapper catFoodBagMapper, CatSettingMapper catSettingMapper,
			StatisticsCache statisticsCache, Clock clock) {
		this.catFoodBagMapper = catFoodBagMapper;
		this.catSettingMapper = catSettingMapper;
		this.statisticsCache = statisticsCache;
		this.clock = clock;
	}

	@Override
	public List<CatFoodBagResponse> list() {
		return timeline().stream().map(CatFoodBagServiceImpl::toResponse).toList();
	}

	@Override
	public List<TimelineEntry> timeline() {
		List<CatFoodBag> rows = this.catFoodBagMapper
			.selectList(familyScope(currentFamilyId())
				.orderByAsc(CatFoodBag::getStartedDate)
				.orderByAsc(CatFoodBag::getId));
		LocalDate today = LocalDate.now(this.clock);
		List<TimelineEntry> entries = new ArrayList<>(rows.size());
		for (int i = 0; i < rows.size(); i++) {
			CatFoodBag bag = rows.get(i);
			boolean current = i == rows.size() - 1;
			// 结束日期不落库：已完成袋取下一袋的开始日，最后一袋就是在用袋、按今天截断（§4.3.2、§4.3.5）
			LocalDate endDate = current ? today : rows.get(i + 1).getStartedDate();
			// 已完成袋不含结束日（下一袋开始那天已经在吃新袋了），在用袋含今天。两边都写 +1 或都不写都会错
			long usageDays = ChronoUnit.DAYS.between(bag.getStartedDate(), endDate) + (current ? 1 : 0);
			entries.add(new TimelineEntry(bag.getId(), bag.getBrand(), bag.getPackGrams(), bag.getStartedDate(), endDate,
					usageDays, current, bag.getRemark()));
		}
		return entries;
	}

	@Override
	public List<ConsumptionEstimate.ClosedBag> closedBags() {
		return closedBagsFrom(timeline());
	}

	@Override
	public CatFoodCurrentResponse current() {
		List<TimelineEntry> entries = timeline();
		if (entries.isEmpty()) {
			return new CatFoodCurrentResponse(null, null);
		}
		TimelineEntry bag = entries.get(entries.size() - 1);
		CatSetting setting = this.catSettingMapper.selectOne(new LambdaQueryWrapper<CatSetting>()
			.eq(CatSetting::getFamilyId, currentFamilyId()));
		ConsumptionEstimate.Result result = ConsumptionEstimate.of(bag.packGrams(), bag.usageDays(),
				setting == null ? null : setting.getEstimatedDailyGrams(), closedBagsFrom(entries),
				LocalDate.now(this.clock));
		return new CatFoodCurrentResponse(toResponse(bag), result == null ? null : toEstimateResponse(bag, result));
	}

	@Override
	@Transactional
	public CatFoodBagResponse create(Long userId, CatFoodBagCreateRequest request) {
		Long familyId = currentFamilyId();
		assertNotFuture(request.startedDate());
		assertStartedDateFree(familyId, request.startedDate(), null);

		CatFoodBag bag = new CatFoodBag();
		bag.setFamilyId(familyId);
		bag.setBrand(request.brand().trim());
		bag.setPackGrams(request.packGrams());
		bag.setStartedDate(request.startedDate());
		bag.setRemark(request.remark());
		bag.setCreatedBy(userId);
		try {
			this.catFoodBagMapper.insert(bag);
		}
		catch (DuplicateKeyException ex) {
			// 应用层查重与插入之间的并发开袋由 uk_food_bag_family_active 兜住，对外仍是同一句人话
			throw new BizException(ErrorCode.BAD_REQUEST, DUPLICATE_STARTED_DATE);
		}
		this.statisticsCache.invalidate(StatisticsCache.MODULE_CAT, familyId);
		log.info("新开猫粮袋 familyId={} bagId={} startedDate={} operatorUserId={}", familyId, bag.getId(),
				request.startedDate(), userId);
		return toResponse(requireEntry(bag.getId()));
	}

	@Override
	@Transactional
	public CatFoodBagResponse update(Long userId, Long id, CatFoodBagUpdateRequest request) {
		Long familyId = currentFamilyId();
		CatFoodBag bag = requireBag(familyId, id);
		assertNotFuture(request.startedDate());
		assertStartedDateFree(familyId, request.startedDate(), id);

		bag.setBrand(request.brand().trim());
		bag.setPackGrams(request.packGrams());
		bag.setStartedDate(request.startedDate());
		bag.setRemark(request.remark());
		try {
			// 整份覆盖必须走 overwrite：updateById 会跳过 null，清空备注就静默失效
			this.catFoodBagMapper.overwrite(bag);
		}
		catch (DuplicateKeyException ex) {
			throw new BizException(ErrorCode.BAD_REQUEST, DUPLICATE_STARTED_DATE);
		}
		this.statisticsCache.invalidate(StatisticsCache.MODULE_CAT, familyId);
		log.info("修改猫粮袋 familyId={} bagId={} startedDate={} operatorUserId={}", familyId, id,
				request.startedDate(), userId);
		return toResponse(requireEntry(id));
	}

	@Override
	@Transactional
	public void delete(Long userId, Long id) {
		Long familyId = currentFamilyId();
		CatFoodBag bag = requireBag(familyId, id);
		// 没有「不能删」的规则：软删把 active_started_date 翻成 NULL，前后两袋自动重新闭合，同一天也能重录
		this.catFoodBagMapper.deleteById(bag.getId());
		this.statisticsCache.invalidate(StatisticsCache.MODULE_CAT, familyId);
		log.info("删除猫粮袋 familyId={} bagId={} startedDate={} operatorUserId={}", familyId, id, bag.getStartedDate(),
				userId);
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	private CatFoodBag requireBag(Long familyId, Long id) {
		CatFoodBag bag = this.catFoodBagMapper
			.selectOne(new LambdaQueryWrapper<CatFoodBag>().eq(CatFoodBag::getId, id)
				.eq(CatFoodBag::getFamilyId, familyId));
		if (bag == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		return bag;
	}

	/** 写操作的出参永远是推导后的那一行，而不是刚写进去的那个实体：改一袋的开始日会连带改写别袋的天数。 */
	private TimelineEntry requireEntry(Long id) {
		return timeline().stream()
			.filter(entry -> entry.id().equals(id))
			.findFirst()
			.orElseThrow(() -> new BizException(ErrorCode.RESOURCE_NOT_FOUND));
	}

	private void assertNotFuture(LocalDate startedDate) {
		if (startedDate.isAfter(LocalDate.now(this.clock))) {
			throw new BizException(ErrorCode.BAD_REQUEST, "开始喂养日期不能晚于今天");
		}
	}

	/** 只比没删掉的袋子：这条查询自带 deleted = 0，所以删掉的那袋不占这个开始日（§4.3.2 的补录路径）。 */
	private void assertStartedDateFree(Long familyId, LocalDate startedDate, Long excludeId) {
		Long duplicated = this.catFoodBagMapper.selectCount(familyScope(familyId)
			.eq(CatFoodBag::getStartedDate, startedDate)
			.ne(excludeId != null, CatFoodBag::getId, excludeId));
		if (duplicated != null && duplicated > 0) {
			throw new BizException(ErrorCode.BAD_REQUEST, DUPLICATE_STARTED_DATE);
		}
	}

	private static LambdaQueryWrapper<CatFoodBag> familyScope(Long familyId) {
		return new LambdaQueryWrapper<CatFoodBag>().eq(CatFoodBag::getFamilyId, familyId);
	}

	/** 全模块唯一的「可用历史袋」判据在这里，各调用方一律走 {@link #closedBags()}，不许再各自筛一遍。 */
	private static List<ConsumptionEstimate.ClosedBag> closedBagsFrom(List<TimelineEntry> entries) {
		return entries.stream()
			.filter(entry -> !entry.current() && entry.usageDays() > 0)
			.map(entry -> new ConsumptionEstimate.ClosedBag(entry.packGrams(), entry.usageDays()))
			.toList();
	}

	/**
	 * 当前袋的两个派生列都是 null（§8）：一袋还没吃完，它自己的折算日均不是一个事实。
	 * <p>
	 * 包内可见是给猫咪统计的「每袋用时」用的（§4.3.5 明写那一列与猫粮袋列表那一列必须一模一样），
	 * 两个出参形状各写一份投影，就是让它们在「当前袋给不给 null」上各有答案。
	 */
	static CatFoodBagResponse toResponse(TimelineEntry entry) {
		return new CatFoodBagResponse(entry.id(), entry.brand(), entry.packGrams(), entry.startedDate(),
				entry.current() ? null : entry.usageDays(),
				entry.current() || entry.usageDays() <= 0 ? null : dailyAverage(entry), entry.current(),
				entry.remark());
	}

	/** 使用天数为 0 的异常袋给 null 而不是除以 0。 */
	private static int dailyAverage(TimelineEntry entry) {
		return BigDecimal.valueOf(entry.packGrams())
			.divide(BigDecimal.valueOf(entry.usageDays()), 0, RoundingMode.HALF_UP)
			.intValue();
	}

	private static CatFoodEstimateResponse toEstimateResponse(TimelineEntry entry, ConsumptionEstimate.Result result) {
		return new CatFoodEstimateResponse(entry.usageDays(), result.dailyAverage(), result.consumedGrams(),
				result.remainingGrams(), result.remainingPercent(), result.daysLeft(), result.depletionDate(),
				result.fromHistory(), result.overEstimate());
	}

}
