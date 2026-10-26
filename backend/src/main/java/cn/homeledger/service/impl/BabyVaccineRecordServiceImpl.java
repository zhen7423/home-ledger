package cn.homeledger.service.impl;

import java.time.Clock;
import java.time.LocalDate;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BabyVaccineStatus;
import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.StatisticsCache;
import cn.homeledger.dto.BabyVaccineRecordCreateRequest;
import cn.homeledger.dto.BabyVaccineRecordUpdateRequest;
import cn.homeledger.entity.Baby;
import cn.homeledger.entity.BabyVaccinePlan;
import cn.homeledger.entity.BabyVaccineRecord;
import cn.homeledger.mapper.BabyMapper;
import cn.homeledger.mapper.BabyVaccinePlanMapper;
import cn.homeledger.mapper.BabyVaccineRecordMapper;
import cn.homeledger.service.BabyVaccineRecordService;
import cn.homeledger.vo.BabyVaccineRecordResponse;

/**
 * §4.4.4 接种记录。
 * <p>
 * 本服务是应种项状态机唯一的外部驱动力：建记录回写 {@code DONE}，删记录退回 {@code PENDING}，
 * {@code plan_id} 与 {@code record_id} 这对反向指针在同一事务里一起改。三个动作都先把记录本身落库拿到 id
 * 再回写应种项——回写要写的就是这个 id，顺序反过来就没有值可写。
 * <p>
 * 已被手动标为 {@code SKIPPED} / {@code NA} 的行一路放行不改：用户说不打就是不打了，接种记录只是贴在旁边的一条
 * 事实，要改回清单状态得先撤销标记（§4.4.4）。这条贯穿回写与回退两处，是本类最容易写反的地方。
 */
@Service
public class BabyVaccineRecordServiceImpl implements BabyVaccineRecordService {

	private static final Logger log = LoggerFactory.getLogger(BabyVaccineRecordServiceImpl.class);

	private final BabyVaccineRecordMapper babyVaccineRecordMapper;

	private final BabyVaccinePlanMapper babyVaccinePlanMapper;

	private final BabyMapper babyMapper;

	private final StatisticsCache statisticsCache;

	private final Clock clock;

	public BabyVaccineRecordServiceImpl(BabyVaccineRecordMapper babyVaccineRecordMapper,
			BabyVaccinePlanMapper babyVaccinePlanMapper, BabyMapper babyMapper, StatisticsCache statisticsCache,
			Clock clock) {
		this.babyVaccineRecordMapper = babyVaccineRecordMapper;
		this.babyVaccinePlanMapper = babyVaccinePlanMapper;
		this.babyMapper = babyMapper;
		this.statisticsCache = statisticsCache;
		this.clock = clock;
	}

	@Override
	public List<BabyVaccineRecordResponse> list(Long babyId) {
		Long familyId = currentFamilyId();
		return this.babyVaccineRecordMapper
			.selectList(new LambdaQueryWrapper<BabyVaccineRecord>()
				.eq(BabyVaccineRecord::getFamilyId, familyId)
				.eq(babyId != null, BabyVaccineRecord::getBabyId, babyId)
				.orderByDesc(BabyVaccineRecord::getGivenDate)
				.orderByDesc(BabyVaccineRecord::getId))
			.stream()
			.map(BabyVaccineRecordServiceImpl::toResponse)
			.toList();
	}

	@Override
	@Transactional
	public BabyVaccineRecordResponse create(Long userId, BabyVaccineRecordCreateRequest request) {
		Long familyId = currentFamilyId();
		requireBaby(familyId, request.babyId());
		assertGivenDateUsable(request.givenDate());
		assertNextDateUsable(request.givenDate(), request.nextDate());

		BabyVaccineRecord record = new BabyVaccineRecord();
		record.setFamilyId(familyId);
		record.setBabyId(request.babyId());
		record.setVaccineName(request.vaccineName());
		record.setDoseNo(request.doseNo());
		record.setGivenDate(request.givenDate());
		record.setClinic(request.clinic());
		record.setBatchNo(request.batchNo());
		record.setReaction(request.reaction());
		record.setRemark(request.remark());
		record.setCreatedBy(userId);
		this.babyVaccineRecordMapper.insert(record);

		bind(familyId, record, request.planId(), request.vaccineName(), request.doseNo());
		record.setNextDate(request.nextDate() != null ? request.nextDate()
				: nextPendingDueDate(familyId, record.getBabyId(), request.vaccineName()));
		this.babyVaccineRecordMapper.overwrite(record);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("新增接种记录 familyId={} recordId={} babyId={} planId={} vaccineName={} doseNo={} givenDate={} operatorUserId={}",
				familyId, record.getId(), record.getBabyId(), record.getPlanId(), request.vaccineName(),
				request.doseNo(), request.givenDate(), userId);
		return toResponse(record);
	}

	@Override
	@Transactional
	public BabyVaccineRecordResponse update(Long userId, Long id, BabyVaccineRecordUpdateRequest request) {
		Long familyId = currentFamilyId();
		BabyVaccineRecord record = requireRecord(familyId, id);
		requireBaby(familyId, request.babyId());
		assertGivenDateUsable(request.givenDate());
		assertNextDateUsable(request.givenDate(), request.nextDate());
		// 先撤销旧绑定再按新键匹配（§1.4 第 20 条）：不撤销的话旧的应种项会永远停在已接种，
		// 而改疫苗名称的正当理由之一恰恰是「刚才录错了是哪一针」
		releasePlan(familyId, record);

		record.setBabyId(request.babyId());
		record.setVaccineName(request.vaccineName());
		record.setDoseNo(request.doseNo());
		record.setGivenDate(request.givenDate());
		record.setClinic(request.clinic());
		record.setBatchNo(request.batchNo());
		record.setReaction(request.reaction());
		record.setRemark(request.remark());
		bind(familyId, record, request.planId(), request.vaccineName(), request.doseNo());
		record.setNextDate(request.nextDate() != null ? request.nextDate()
				: nextPendingDueDate(familyId, record.getBabyId(), request.vaccineName()));
		this.babyVaccineRecordMapper.overwrite(record);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("修改接种记录 familyId={} recordId={} babyId={} planId={} vaccineName={} doseNo={} operatorUserId={}",
				familyId, id, record.getBabyId(), record.getPlanId(), request.vaccineName(), request.doseNo(),
				userId);
		return toResponse(record);
	}

	@Override
	@Transactional
	public void delete(Long userId, Long id) {
		Long familyId = currentFamilyId();
		BabyVaccineRecord record = requireRecord(familyId, id);
		// 录错了要能改回来：不退回 PENDING 的话一次误录会让那一针永久显示已接种
		releasePlan(familyId, record);
		this.babyVaccineRecordMapper.deleteById(record.getId());
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("删除接种记录 familyId={} recordId={} babyId={} operatorUserId={}", familyId, id, record.getBabyId(),
				userId);
	}

	/**
	 * 与其他四个日期入口同规矩（出生 / 测量 / 发生 / 就诊都挡了未来）：未来的接种日期一旦落库，
	 * {@link #bind} 会立刻把对应应种项回写成 DONE，那一针从此显示「已接种」、完成率分子上涨——
	 * 这是本模块唯一一处「填错日期就把免疫进度算成已完成」的路径（§4.4.4「接种日期不可晚于今天」）。
	 */
	private void assertGivenDateUsable(LocalDate givenDate) {
		if (givenDate != null && givenDate.isAfter(LocalDate.now(this.clock))) {
			throw new BizException(ErrorCode.BAD_REQUEST, "接种日期不能晚于今天");
		}
	}

	/**
	 * 手填的下一针日期必须晚于本次接种日期——与猫驱虫 {@code assertDatesUsable} 同一条规矩：
	 * 倒灌的 nextDate 会让「下一针」的逾期倒计时永久为负并逐日增长，而它是清单展示与提醒共同的输入
	 * （扫描报告 P2-3）。服务端自动推算的值（nextPendingDueDate）不受此限：它取自程序表日期。
	 */
	private void assertNextDateUsable(LocalDate givenDate, LocalDate nextDate) {
		if (nextDate != null && givenDate != null && !nextDate.isAfter(givenDate)) {
			throw new BizException(ErrorCode.BAD_REQUEST, "下一针日期要晚于本次接种日期");
		}
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	/**
	 * 绑定应种项并回写。{@code plan_id} 与 {@code record_id} 是同一件事的两端，故只在这里一起写：
	 * 显式给了 {@code planId} 就以它为准（补种、异地接种、名称写法不同时的落点），
	 * 没给就按「疫苗名称 + 剂次」自动匹配；匹配不到或命中的行已被标记，记录就独立存在（{@code plan_id} 留空）。
	 */
	private void bind(Long familyId, BabyVaccineRecord record, Long planId, String vaccineName, String doseNo) {
		BabyVaccinePlan plan = planId != null ? requirePlan(familyId, record.getBabyId(), planId)
				: findPlanByKey(familyId, record.getBabyId(), vaccineName, doseNo);
		if (plan == null || !writeBack(plan, record.getId())) {
			record.setPlanId(null);
			return;
		}
		record.setPlanId(plan.getId());
	}

	/** @return 真的写回了才 true。标记过的行什么都不写（§4.4.4）：连 {@code record_id} 也不写，那两行要保持标记态 */
	private boolean writeBack(BabyVaccinePlan plan, Long recordId) {
		if (BabyVaccineStatus.of(plan.getStatus()).marked()) {
			return false;
		}
		plan.setStatus(BabyVaccineStatus.DONE.name());
		plan.setRecordId(recordId);
		// 接种即事实：计划日期的使命结束，覆盖层随绑定一起清掉。不清的话 DONE 行带着一个
		// 未来的 planned_date：updatePlannedDate 又因 recordId 非空拒改，完成率分母按
		// effectiveDate 把这针漏到那一天才计入——分子分母与分段条三处口径分叉（复扫 P2）。
		plan.setPlannedDate(null);
		this.babyVaccinePlanMapper.overwrite(plan);
		return true;
	}

	/**
	 * 退回 {@code PENDING} 并清 {@code record_id}。两个守卫缺一不可：{@code record_id} 指向的不是本条记录
	 * 说明这一行已被别的记录接管，标记过的行是用户自己的决定——两种情形下抹掉绑定都是把别人的状态改坏了。
	 */
	private void releasePlan(Long familyId, BabyVaccineRecord record) {
		if (record.getPlanId() == null) {
			return;
		}
		BabyVaccinePlan plan = this.babyVaccinePlanMapper
			.selectOne(new LambdaQueryWrapper<BabyVaccinePlan>().eq(BabyVaccinePlan::getId, record.getPlanId())
				.eq(BabyVaccinePlan::getFamilyId, familyId));
		if (plan == null || !record.getId().equals(plan.getRecordId())) {
			return;
		}
		if (BabyVaccineStatus.of(plan.getStatus()).marked()) {
			return;
		}
		plan.setStatus(BabyVaccineStatus.PENDING.name());
		plan.setRecordId(null);
		this.babyVaccinePlanMapper.overwrite(plan);
	}

	/**
	 * 「该疫苗名称在本宝宝清单里下一个 {@code PENDING} 剂次的应种日期」（§1.4 第 11 条）。
	 * 行已按生效日期（COALESCE(planned_date, due_date)，见 Mapper XML）排好，故第一条命中的就是最近的
	 * 那一针；取值也用 effectiveDate——用户改过计划日期时，「下一针」跟着用户走。没有则留空。
	 */
	private LocalDate nextPendingDueDate(Long familyId, Long babyId, String vaccineName) {
		for (BabyVaccinePlan plan : this.babyVaccinePlanMapper.listByBaby(familyId, babyId)) {
			if (plan.getVaccineName().equals(vaccineName)
					&& BabyVaccineStatus.of(plan.getStatus()) == BabyVaccineStatus.PENDING) {
				return plan.effectiveDate();
			}
		}
		return null;
	}

	private BabyVaccinePlan findPlanByKey(Long familyId, Long babyId, String vaccineName, String doseNo) {
		for (BabyVaccinePlan plan : this.babyVaccinePlanMapper.listByBaby(familyId, babyId)) {
			if (plan.getVaccineName().equals(vaccineName) && plan.getDoseNo().equals(doseNo)) {
				return plan;
			}
		}
		return null;
	}

	/** 显式指定的应种项得属于同一个宝宝：跨宝宝回写会让清单上另一个宝宝的针变成已接种。 */
	private BabyVaccinePlan requirePlan(Long familyId, Long babyId, Long planId) {
		BabyVaccinePlan plan = this.babyVaccinePlanMapper
			.selectOne(new LambdaQueryWrapper<BabyVaccinePlan>().eq(BabyVaccinePlan::getId, planId)
				.eq(BabyVaccinePlan::getFamilyId, familyId)
				.eq(BabyVaccinePlan::getBabyId, babyId));
		if (plan == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		return plan;
	}

	/**
	 * 不查 enabled：归档的宝宝照旧补得起历史接种记录（§4.4.1 的归档 ≠ 删除），这里只拦「不是本家庭的」。
	 */
	private void requireBaby(Long familyId, Long babyId) {
		Baby baby = this.babyMapper
			.selectOne(new LambdaQueryWrapper<Baby>().eq(Baby::getId, babyId).eq(Baby::getFamilyId, familyId));
		if (baby == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
	}

	private BabyVaccineRecord requireRecord(Long familyId, Long id) {
		BabyVaccineRecord record = this.babyVaccineRecordMapper
			.selectOne(new LambdaQueryWrapper<BabyVaccineRecord>().eq(BabyVaccineRecord::getId, id)
				.eq(BabyVaccineRecord::getFamilyId, familyId));
		if (record == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		return record;
	}

	private static BabyVaccineRecordResponse toResponse(BabyVaccineRecord record) {
		return new BabyVaccineRecordResponse(record.getId(), record.getBabyId(), record.getPlanId(),
				record.getVaccineName(), record.getDoseNo(), record.getGivenDate(), record.getClinic(),
				record.getBatchNo(), record.getReaction(), record.getNextDate(), record.getRemark());
	}

}
