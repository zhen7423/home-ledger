package cn.homeledger.service.impl;

import java.time.Clock;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BizException;
import cn.homeledger.common.DewormingType;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.StatisticsCache;
import cn.homeledger.dto.CatDewormingCreateRequest;
import cn.homeledger.dto.CatDewormingUpdateRequest;
import cn.homeledger.entity.Cat;
import cn.homeledger.entity.CatDeworming;
import cn.homeledger.mapper.CatDewormingMapper;
import cn.homeledger.mapper.CatMapper;
import cn.homeledger.service.CatDewormingService;
import cn.homeledger.service.CatSettingService;
import cn.homeledger.vo.CatDewormingResponse;
import cn.homeledger.vo.CatSettingResponse;

/**
 * §4.3.3 体内外驱虫记录。
 * <p>
 * 下次驱虫日期是这张表唯一有分量的规则，两句话：算的话基准是 {@code done_date} 而不是今天（按今天算会让
 * 一条补录的历史记录指向一个跟这轮药没关系的日子），给了的话照抄不回算（用户手动覆盖就是不想用默认周期）。
 * 周期月数只在「没给」这条分支上才去读，于是设置页改周期只影响以后新建的记录。
 */
@Service
public class CatDewormingServiceImpl implements CatDewormingService {

	private static final Logger log = LoggerFactory.getLogger(CatDewormingServiceImpl.class);

	private final CatDewormingMapper catDewormingMapper;

	private final CatMapper catMapper;

	private final CatSettingService catSettingService;

	private final StatisticsCache statisticsCache;

	private final Clock clock;

	public CatDewormingServiceImpl(CatDewormingMapper catDewormingMapper, CatMapper catMapper,
			CatSettingService catSettingService, StatisticsCache statisticsCache, Clock clock) {
		this.catDewormingMapper = catDewormingMapper;
		this.catMapper = catMapper;
		this.catSettingService = catSettingService;
		this.statisticsCache = statisticsCache;
		this.clock = clock;
	}

	@Override
	public List<CatDewormingResponse> list(Long catId) {
		Long familyId = currentFamilyId();
		List<CatDeworming> rows = this.catDewormingMapper.selectList(familyScope(familyId)
			.eq(catId != null, CatDeworming::getCatId, catId)
			.orderByDesc(CatDeworming::getDoneDate)
			.orderByDesc(CatDeworming::getId));
		// 不带 enabled 条件：归档猫的历史驱虫记录要照常出现（§4.3.1 归档 ≠ 删除）
		Map<Long, String> names = catNames(familyId);
		LocalDate today = LocalDate.now(this.clock);
		return rows.stream().map(row -> toResponse(row, names.get(row.getCatId()), today)).toList();
	}

	@Override
	@Transactional
	public CatDewormingResponse create(Long userId, CatDewormingCreateRequest request) {
		Long familyId = currentFamilyId();
		Cat cat = requireCat(familyId, request.catId());
		if (cat.getEnabled() == 0) {
			throw new BizException(ErrorCode.BAD_REQUEST, "这只猫已归档，可以先恢复在册再记驱虫");
		}
		DewormingType type = requireType(request.type());
		assertDatesUsable(request.doneDate(), request.nextDate());
		LocalDate nextDate = resolveNextDate(type, request.doneDate(), request.nextDate());

		CatDeworming record = new CatDeworming();
		record.setFamilyId(familyId);
		record.setCatId(cat.getId());
		record.setType(type.name());
		record.setDoneDate(request.doneDate());
		record.setMedicine(request.medicine());
		record.setDosage(request.dosage());
		record.setNextDate(nextDate);
		record.setRemark(request.remark());
		record.setCreatedBy(userId);
		this.catDewormingMapper.insert(record);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_CAT, familyId);
		log.info("新增驱虫记录 familyId={} dewormingId={} catId={} type={} nextDate={} operatorUserId={}", familyId,
				record.getId(), cat.getId(), type, nextDate, userId);
		return toResponse(record, cat.getName(), LocalDate.now(this.clock));
	}

	@Override
	@Transactional
	public CatDewormingResponse update(Long userId, Long id, CatDewormingUpdateRequest request) {
		Long familyId = currentFamilyId();
		CatDeworming record = requireRecord(familyId, id);
		DewormingType type = requireType(request.type());
		assertDatesUsable(request.doneDate(), request.nextDate());
		LocalDate nextDate = resolveNextDate(type, request.doneDate(), request.nextDate());
		// 只要这只猫在本家庭、名字给得出，不查它在不在册：改一条写错的记录不该被猫后来的归档挡住
		Cat cat = requireCat(familyId, request.catId());

		record.setCatId(request.catId());
		record.setType(type.name());
		record.setDoneDate(request.doneDate());
		record.setMedicine(request.medicine());
		record.setDosage(request.dosage());
		record.setNextDate(nextDate);
		record.setRemark(request.remark());
		// 整份覆盖必须走 overwrite：updateById 会跳过 null，清空规格/剂量或备注就静默失效
		this.catDewormingMapper.overwrite(record);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_CAT, familyId);
		log.info("修改驱虫记录 familyId={} dewormingId={} catId={} type={} nextDate={} operatorUserId={}", familyId, id,
				request.catId(), type, nextDate, userId);
		return toResponse(record, cat.getName(), LocalDate.now(this.clock));
	}

	@Override
	@Transactional
	public void delete(Long userId, Long id) {
		Long familyId = currentFamilyId();
		CatDeworming record = requireRecord(familyId, id);
		// 没有守卫：驱虫记录可自由删。删掉一条会改倒计时与完成度，所以失效不能省
		this.catDewormingMapper.deleteById(record.getId());
		this.statisticsCache.invalidate(StatisticsCache.MODULE_CAT, familyId);
		log.info("删除驱虫记录 familyId={} dewormingId={} catId={} operatorUserId={}", familyId, id, record.getCatId(),
				userId);
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	private Cat requireCat(Long familyId, Long catId) {
		Cat cat = this.catMapper
			.selectOne(new LambdaQueryWrapper<Cat>().eq(Cat::getId, catId).eq(Cat::getFamilyId, familyId));
		if (cat == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		return cat;
	}

	private CatDeworming requireRecord(Long familyId, Long id) {
		CatDeworming record = this.catDewormingMapper.selectOne(new LambdaQueryWrapper<CatDeworming>()
			.eq(CatDeworming::getId, id)
			.eq(CatDeworming::getFamilyId, familyId));
		if (record == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		return record;
	}

	private static LambdaQueryWrapper<CatDeworming> familyScope(Long familyId) {
		return new LambdaQueryWrapper<CatDeworming>().eq(CatDeworming::getFamilyId, familyId);
	}

	/**
	 * 一次读全猫表建名字表，不在循环里查猫。含归档的猫（历史记录的猫名要跟着档案走，§4.3.3），
	 * 也一定盖得住列表里出现的每个 catId：名下有任何驱虫记录的猫都删不掉，那条守卫在
	 * {@code CatServiceImpl#delete}——它是这两个类之间的契约，改哪一边都得回来确认另一条还成立。
	 */
	private Map<Long, String> catNames(Long familyId) {
		return this.catMapper.selectList(new LambdaQueryWrapper<Cat>().eq(Cat::getFamilyId, familyId))
			.stream()
			.collect(Collectors.toMap(Cat::getId, Cat::getName));
	}

	/** 不认识的类型值给一句和校验同样的话，而不是让 {@code valueOf} 抛成 500。 */
	private static DewormingType requireType(String name) {
		DewormingType type = DewormingType.of(name);
		if (type == null) {
			throw new BizException(ErrorCode.BAD_REQUEST, "驱虫类型只能是内驱或外驱");
		}
		return type;
	}

	private void assertDatesUsable(LocalDate doneDate, LocalDate nextDate) {
		if (doneDate.isAfter(LocalDate.now(this.clock))) {
			throw new BizException(ErrorCode.BAD_REQUEST, "驱虫日期不能晚于今天");
		}
		// 不挡的话一个手滑的过去日期会让倒计时永久停在「逾期 N 天」并逐日增长，而它是完成度与提醒共同的输入
		if (nextDate != null && !nextDate.isAfter(doneDate)) {
			throw new BizException(ErrorCode.BAD_REQUEST, "下次驱虫日期要晚于本次驱虫日期");
		}
	}

	/**
	 * 用户给了就照抄，没给才按周期算。走 {@link CatSettingService#get()} 而不是设置表的 mapper：
	 * 这里要的是「无行时按 3 / 1」那个口径，它正是设置接口对外给的答案。
	 * <p>
	 * 只在真要算的时候读一次设置——{@code GET} 顺带要把预估日均标成「已由历史接管」，多一次猫粮袋的读。
	 */
	private LocalDate resolveNextDate(DewormingType type, LocalDate doneDate, LocalDate manual) {
		if (manual != null) {
			return manual;
		}
		CatSettingResponse setting = this.catSettingService.get();
		return doneDate.plusMonths(type.monthsOf(setting.internalMonths(), setting.externalMonths()));
	}

	private static CatDewormingResponse toResponse(CatDeworming record, String catName, LocalDate today) {
		// next_date 落库侧恒有值（DDL NOT NULL + 服务层恒写入），NULL 只可能来自绕过接口的外部导入；
		// 那时倒计时两格留空而不是让整页 500（扫描报告 P3-2）
		Long daysUntil = null;
		Long overdueDays = null;
		if (record.getNextDate() != null) {
			long days = ChronoUnit.DAYS.between(today, record.getNextDate());
			daysUntil = days < 0 ? null : days;
			overdueDays = days < 0 ? -days : null;
		}
		return new CatDewormingResponse(record.getId(), record.getCatId(), catName, record.getType(),
				record.getDoneDate(), record.getMedicine(), record.getDosage(), record.getNextDate(), daysUntil,
				overdueDays, record.getRemark());
	}

}
