package cn.homeledger.service.impl;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.BabyAge;
import cn.homeledger.common.BabyVaccineStatus;
import cn.homeledger.entity.Baby;
import cn.homeledger.entity.BabyVaccinePlan;
import cn.homeledger.entity.VaccineScheduleDict;
import cn.homeledger.mapper.BabyVaccinePlanMapper;
import cn.homeledger.mapper.VaccineScheduleDictMapper;
import cn.homeledger.service.BabyVaccinePlanGenerator;

/**
 * §4.4.4 应种清单的生成与整份重算。
 * <p>
 * 重算的关键是<b>一行都不删</b>：按「疫苗名称 + 剂次」对齐老清单，已接种 / 已跳过 / 不适用 / 手动的行原样保留，
 * 只补新增与改期。整表删了重建会把用户的标记与手动行一起抹掉。
 * <p>
 * 程序表随发版升级时<b>不自动重算</b>老宝宝——{@link #realignFor} 只在改了出生日期时被调用。
 * 老宝宝的清单保留生成时那一版的应种日期，新宝宝用新表：两者的应种日期不同是数据事实，
 * 悄悄改期会让已经打过针的记录突然变成「逾期」。
 */
@Service
public class BabyVaccinePlanGeneratorImpl implements BabyVaccinePlanGenerator {

	private static final Logger log = LoggerFactory.getLogger(BabyVaccinePlanGeneratorImpl.class);

	/** 与「疫苗名称 + 剂次」拼键用的分隔符。疫苗名里不会出现 NUL，拼起来不会有两组键撞车。 */
	private static final String KEY_SEPARATOR = "\u0000";

	private final VaccineScheduleDictMapper vaccineScheduleDictMapper;

	private final BabyVaccinePlanMapper babyVaccinePlanMapper;

	public BabyVaccinePlanGeneratorImpl(VaccineScheduleDictMapper vaccineScheduleDictMapper,
			BabyVaccinePlanMapper babyVaccinePlanMapper) {
		this.vaccineScheduleDictMapper = vaccineScheduleDictMapper;
		this.babyVaccinePlanMapper = babyVaccinePlanMapper;
	}

	@Override
	public void generateFor(Long userId, Baby baby) {
		List<VaccineScheduleDict> dict = programTable();
		for (VaccineScheduleDict row : dict) {
			insert(userId, baby, row.getVaccineName(), row.getDoseNo(),
					BabyAge.plusMonths(baby.getBirthDate(), row.getDueAgeMonths()));
		}
		log.info("生成应种清单 familyId={} babyId={} rows={} operatorUserId={}", baby.getFamilyId(), baby.getId(),
				dict.size(), userId);
	}

	@Override
	public void realignFor(Long userId, Baby baby) {
		Map<String, BabyVaccinePlan> aligned = new LinkedHashMap<>();
		Set<String> manualKeys = new HashSet<>();
		for (BabyVaccinePlan plan : this.babyVaccinePlanMapper.listByBaby(baby.getFamilyId(), baby.getId())) {
			String planKey = key(plan.getVaccineName(), plan.getDoseNo());
			if (plan.getManual() != null && plan.getManual() == 1) {
				manualKeys.add(planKey);
			}
			else {
				// 同一个键上有多行时取第一行：正常数据里不会出现，出现了也只对齐其中一行
				aligned.putIfAbsent(planKey, plan);
			}
		}

		int inserted = 0;
		int rescheduled = 0;
		for (VaccineScheduleDict row : programTable()) {
			LocalDate dueDate = BabyAge.plusMonths(baby.getBirthDate(), row.getDueAgeMonths());
			String rowKey = key(row.getVaccineName(), row.getDoseNo());
			BabyVaccinePlan current = aligned.get(rowKey);
			if (current == null) {
				// 手动行不参与对齐（§4.4.4）：应种日期由用户定，跟着出生日期平移等于把用户填的那个日期悄悄改掉。
				// 它已经占着这个键，故不另插一条——插了就是同一 (疫苗名称, 剂次) 两行并存
				if (manualKeys.contains(rowKey)) {
					continue;
				}
				try {
					insert(userId, baby, row.getVaccineName(), row.getDoseNo(), dueDate);
					inserted++;
				}
				catch (DuplicateKeyException ex) {
					// 重算与手动补录并发时，对方刚插的行可能还没进上面的 listByBaby 快照；
					// 键已被占就跳过，唯一索引（V20261026120000）保证清单里仍只有一行
					log.info("重算补插撞上并发占用，跳过 familyId={} babyId={} key={}", baby.getFamilyId(), baby.getId(),
							rowKey.replace(KEY_SEPARATOR, "/"));
				}
				continue;
			}
			if (!dueDate.equals(current.getDueDate())) {
				// 只改 due_date：整行读出来的，status / skip_reason / record_id / manual 原样写回，等于不动。
				// planned_date 同样原样带回（V20261026140000）——重算永不碰用户的计划日期，
				// 否则改一次生日就把用户约好的接种日悄悄平移掉。
				current.setDueDate(dueDate);
				this.babyVaccinePlanMapper.overwrite(current);
				rescheduled++;
			}
		}
		log.info("重算应种清单 familyId={} babyId={} 新增 {} 条 改期 {} 条 手动 {} 条 operatorUserId={}",
				baby.getFamilyId(), baby.getId(), inserted, rescheduled, manualKeys.size(), userId);
	}

	/** 按 due_age_months 升序整表读出（§4.4.4）：清单的默认顺序与「下一针」都依赖它。 */
	private List<VaccineScheduleDict> programTable() {
		return this.vaccineScheduleDictMapper.selectList(new LambdaQueryWrapper<VaccineScheduleDict>()
			.orderByAsc(VaccineScheduleDict::getDueAgeMonths)
			.orderByAsc(VaccineScheduleDict::getId));
	}

	private void insert(Long userId, Baby baby, String vaccineName, String doseNo, LocalDate dueDate) {
		BabyVaccinePlan plan = new BabyVaccinePlan();
		plan.setFamilyId(baby.getFamilyId());
		plan.setBabyId(baby.getId());
		plan.setVaccineName(vaccineName);
		plan.setDoseNo(doseNo);
		plan.setDueDate(dueDate);
		plan.setStatus(BabyVaccineStatus.PENDING.name());
		plan.setManual(0);
		plan.setCreatedBy(userId);
		this.babyVaccinePlanMapper.insert(plan);
	}

	private static String key(String vaccineName, String doseNo) {
		return vaccineName + KEY_SEPARATOR + doseNo;
	}

}
