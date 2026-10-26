package cn.homeledger.service.impl;

import java.time.Clock;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BabyVaccineDisplay;
import cn.homeledger.common.BabyVaccineStatus;
import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.StatisticsCache;
import cn.homeledger.dto.BabyVaccinePlanCreateRequest;
import cn.homeledger.dto.BabyVaccinePlanPlannedDateRequest;
import cn.homeledger.dto.BabyVaccinePlanUpdateRequest;
import cn.homeledger.entity.Baby;
import cn.homeledger.entity.BabyVaccinePlan;
import cn.homeledger.mapper.BabyMapper;
import cn.homeledger.mapper.BabyVaccinePlanMapper;
import cn.homeledger.service.BabyVaccinePlanService;
import cn.homeledger.vo.BabyVaccinePlanResponse;

/**
 * §4.4.4 应种清单。
 * <p>
 * 本服务管用户能改的三件事：手动补一条自费项、把某行标成跳过 / 不适用或撤销、设置 / 清除计划接种日期
 * （覆盖层，见 {@link BabyVaccinePlan#getPlannedDate()}）。{@code due_date} 仍不由这里改——它是按内置
 * 程序表与出生日期算出来的，改它得改出生日期走整份重算，否则同一个宝宝身上会同时存在两套排期。
 * <p>
 * {@code displayStatus} 读时才算（{@link BabyVaccineDisplay}）：落库的只有四态，「逾期」这类判断跨天就会变，
 * 存进库里必然在跨天后显示成昨天的结论。
 */
@Service
public class BabyVaccinePlanServiceImpl implements BabyVaccinePlanService {

	private static final Logger log = LoggerFactory.getLogger(BabyVaccinePlanServiceImpl.class);

	private final BabyVaccinePlanMapper babyVaccinePlanMapper;

	private final BabyMapper babyMapper;

	private final StatisticsCache statisticsCache;

	private final Clock clock;

	public BabyVaccinePlanServiceImpl(BabyVaccinePlanMapper babyVaccinePlanMapper, BabyMapper babyMapper,
			StatisticsCache statisticsCache, Clock clock) {
		this.babyVaccinePlanMapper = babyVaccinePlanMapper;
		this.babyMapper = babyMapper;
		this.statisticsCache = statisticsCache;
		this.clock = clock;
	}

	@Override
	public List<BabyVaccinePlanResponse> list(Long babyId) {
		Long familyId = currentFamilyId();
		LocalDate today = LocalDate.now(this.clock);
		// 排序键是生效日期（用户改过计划日期的行排到它该在的位置），COALESCE 在 Java 侧做——
		// LambdaQueryWrapper 表达不了，而清单量级（每宝宝 ≤ 程序表行数 + 手动项）撑得起内存排序。
		return this.babyVaccinePlanMapper.selectList(listScope(familyId, babyId))
			.stream()
			.sorted(Comparator.comparing(BabyVaccinePlan::effectiveDate).thenComparing(BabyVaccinePlan::getId))
			.map(row -> toResponse(row, today))
			.toList();
	}

	@Override
	@Transactional
	public BabyVaccinePlanResponse create(Long userId, BabyVaccinePlanCreateRequest request) {
		Long familyId = currentFamilyId();
		Baby baby = requireBaby(familyId, request.babyId());
		assertDueDateNotBeforeBirth(baby, request.dueDate());
		assertKeyFree(familyId, request.babyId(), request.vaccineName(), request.doseNo());

		BabyVaccinePlan plan = new BabyVaccinePlan();
		plan.setFamilyId(familyId);
		plan.setBabyId(request.babyId());
		plan.setVaccineName(request.vaccineName());
		plan.setDoseNo(request.doseNo());
		plan.setDueDate(request.dueDate());
		plan.setStatus(BabyVaccineStatus.PENDING.name());
		// 手动行不参与改生日时的整份对齐（§4.4.4）：应种日期由用户定，跟着出生日期平移等于把用户填的日期悄悄改掉
		plan.setManual(1);
		plan.setCreatedBy(userId);
		try {
			this.babyVaccinePlanMapper.insert(plan);
		}
		catch (DuplicateKeyException ex) {
			// assertKeyFree 与 insert 之间的并发补录由 uk_plan_family_baby_key_active 兜住
			// （V20261026120000），对外仍是同一句人话
			throw new BizException(ErrorCode.BAD_REQUEST, "该疫苗第 " + request.doseNo() + " 剂已在应种清单里");
		}
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("手动新增应种项 familyId={} planId={} babyId={} vaccineName={} doseNo={} operatorUserId={}", familyId,
				plan.getId(), request.babyId(), request.vaccineName(), request.doseNo(), userId);
		return toResponse(plan, LocalDate.now(this.clock));
	}

	@Override
	@Transactional
	public BabyVaccinePlanResponse updatePlannedDate(Long userId, Long id, BabyVaccinePlanPlannedDateRequest request) {
		Long familyId = currentFamilyId();
		BabyVaccinePlan plan = requirePlan(familyId, id);
		// 已接种的行不接受计划日期：那一针什么时候打的以接种记录为准，再改「打算哪天去打」是自相矛盾，
		// 也会让「已接种」行突然出现在清单别的位置上
		if (plan.getRecordId() != null || BabyVaccineStatus.of(plan.getStatus()) == BabyVaccineStatus.DONE) {
			throw new BizException(ErrorCode.BAD_REQUEST, "这一针已接种，计划日期不再有意义");
		}
		if (request.plannedDate() != null) {
			assertDueDateNotBeforeBirth(requireBaby(familyId, plan.getBabyId()), request.plannedDate());
		}
		// null = 清除覆盖、回到程序表应种日期；overwrite 对 null 是真清（XML 里没有 IFNULL 兜底）
		plan.setPlannedDate(request.plannedDate());
		this.babyVaccinePlanMapper.overwrite(plan);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("设置计划接种日期 familyId={} planId={} babyId={} plannedDate={} operatorUserId={}", familyId, id,
				plan.getBabyId(), request.plannedDate(), userId);
		return toResponse(plan, LocalDate.now(this.clock));
	}

	@Override
	@Transactional
	public BabyVaccinePlanResponse update(Long userId, Long id, BabyVaccinePlanUpdateRequest request) {
		Long familyId = currentFamilyId();
		BabyVaccinePlan plan = requirePlan(familyId, id);
		// DONE 由接种记录回写、不在这里接受：手工置它等于让「已接种」指不出任何一条接种记录
		BabyVaccineStatus target = BabyVaccineStatus.of(request.status());

		if (target == BabyVaccineStatus.DONE) {
			throw new BizException(ErrorCode.BAD_REQUEST, "已接种只由接种记录回写，请改为录入接种记录");
		}
		if (target.marked()) {
			String reason = request.reason() == null ? null : request.reason().trim();
			if (reason == null || reason.isEmpty()) {
				throw new BizException(ErrorCode.BAD_REQUEST, "请填写跳过或不适用原因");
			}
			plan.setStatus(target.name());
			plan.setSkipReason(reason);
		}
		else {
			// 撤销与标记是两条对称的路：DONE / 已回写 record_id 的行由接种记录接管，这里撤销会造出
			// status = PENDING 但 record_id 非空的分裂态——展示态仍算 VACCINATED、分段条计入已接种，
			// 完成率分子却掉下去（§4.4.6 两处口径分叉）。加与上方 DONE 拒写同形的守卫，引导去接种记录里改。
			if (plan.getRecordId() != null || BabyVaccineStatus.of(plan.getStatus()) == BabyVaccineStatus.DONE) {
				throw new BizException(ErrorCode.BAD_REQUEST, "这一针由接种记录标记为已接种，请在接种记录里删除或修改");
			}
			// 撤销后留着上一次的原因，下次标记会带着上一次的字：显式清空而不是沿用请求里的值
			plan.setStatus(BabyVaccineStatus.PENDING.name());
			plan.setSkipReason(null);
		}
		this.babyVaccinePlanMapper.overwrite(plan);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("标记应种项 familyId={} planId={} babyId={} status={} operatorUserId={}", familyId, id,
				plan.getBabyId(), plan.getStatus(), userId);
		return toResponse(plan, LocalDate.now(this.clock));
	}

	@Override
	@Transactional
	public void delete(Long userId, Long id) {
		Long familyId = currentFamilyId();
		BabyVaccinePlan plan = requirePlan(familyId, id);
		if (plan.getManual() == null || plan.getManual() != 1) {
			throw new BizException(ErrorCode.BAD_REQUEST, "字典生成的行只能跳过或不适用，下次改出生日期重算会把它补回来");
		}
		this.babyVaccinePlanMapper.deleteById(plan.getId());
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("删除手动应种项 familyId={} planId={} babyId={} operatorUserId={}", familyId, id, plan.getBabyId(),
				userId);
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	/**
	 * 不查 enabled：归档的宝宝照旧改得动历史清单（§4.4.1 的归档 ≠ 删除），这里只拦「不是本家庭的」。
	 */
	private Baby requireBaby(Long familyId, Long babyId) {
		Baby baby = this.babyMapper
			.selectOne(new LambdaQueryWrapper<Baby>().eq(Baby::getId, babyId).eq(Baby::getFamilyId, familyId));
		if (baby == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		return baby;
	}

	private BabyVaccinePlan requirePlan(Long familyId, Long id) {
		BabyVaccinePlan plan = this.babyVaccinePlanMapper
			.selectOne(new LambdaQueryWrapper<BabyVaccinePlan>().eq(BabyVaccinePlan::getId, id)
				.eq(BabyVaccinePlan::getFamilyId, familyId));
		if (plan == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		return plan;
	}

	private static LambdaQueryWrapper<BabyVaccinePlan> listScope(Long familyId, Long babyId) {
		// 排序不在 SQL 里做（生效日期是 COALESCE，见 list()），这里只圈范围
		return new LambdaQueryWrapper<BabyVaccinePlan>().eq(BabyVaccinePlan::getFamilyId, familyId)
			.eq(babyId != null, BabyVaccinePlan::getBabyId, babyId);
	}

	private static void assertDueDateNotBeforeBirth(Baby baby, LocalDate dueDate) {
		if (dueDate.isBefore(baby.getBirthDate())) {
			throw new BizException(ErrorCode.BAD_REQUEST, "应种日期不能早于出生日期");
		}
	}

	/**
	 * 匹配键必须唯一，否则接种记录回写时「回写到哪一行」没有定义（§1.4 第 13 条）。
	 * 应用层先挡一次给出人话；并发窗口由 uk_plan_family_baby_key_active 兜底（V20261026120000）。
	 */
	private void assertKeyFree(Long familyId, Long babyId, String vaccineName, String doseNo) {
		for (BabyVaccinePlan row : this.babyVaccinePlanMapper.listByBaby(familyId, babyId)) {
			if (row.getVaccineName().equals(vaccineName) && row.getDoseNo().equals(doseNo)) {
				throw new BizException(ErrorCode.BAD_REQUEST, "该疫苗第 " + doseNo + " 剂已在应种清单里");
			}
		}
	}

	private static BabyVaccinePlanResponse toResponse(BabyVaccinePlan plan, LocalDate today) {
		return new BabyVaccinePlanResponse(plan.getId(), plan.getBabyId(), plan.getVaccineName(), plan.getDoseNo(),
				plan.getDueDate(), plan.getPlannedDate(), plan.effectiveDate(), plan.getStatus(),
				plan.getSkipReason(), plan.getRecordId(), plan.getManual() != null && plan.getManual() == 1,
				BabyVaccineDisplay.of(BabyVaccineStatus.of(plan.getStatus()), plan.effectiveDate(), today,
						plan.getRecordId() != null)
					.name());
	}

}
