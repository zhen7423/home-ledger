package cn.homeledger.service.impl;

import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.toolkit.support.SFunction;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.DewormingType;
import cn.homeledger.common.ModuleKey;
import cn.homeledger.common.RecentActivityType;
import cn.homeledger.dto.TransactionQueryRequest;
import cn.homeledger.entity.Baby;
import cn.homeledger.entity.BabyFormulaBag;
import cn.homeledger.entity.BabyGrowth;
import cn.homeledger.entity.BabyMedical;
import cn.homeledger.entity.BabyMilestone;
import cn.homeledger.entity.BabyVaccineRecord;
import cn.homeledger.entity.Cat;
import cn.homeledger.entity.CatDeworming;
import cn.homeledger.entity.CatFoodBag;
import cn.homeledger.entity.FamilyMember;
import cn.homeledger.entity.Transaction;
import cn.homeledger.mapper.BabyGrowthMapper;
import cn.homeledger.mapper.BabyFormulaBagMapper;
import cn.homeledger.mapper.BabyMapper;
import cn.homeledger.mapper.BabyMedicalMapper;
import cn.homeledger.mapper.BabyMilestoneMapper;
import cn.homeledger.mapper.BabyVaccineRecordMapper;
import cn.homeledger.mapper.CatDewormingMapper;
import cn.homeledger.mapper.CatFoodBagMapper;
import cn.homeledger.mapper.CatMapper;
import cn.homeledger.mapper.FamilyMemberMapper;
import cn.homeledger.mapper.TransactionMapper;
import cn.homeledger.service.BudgetService;
import cn.homeledger.service.HomeService;
import cn.homeledger.service.ModulePreferenceService;
import cn.homeledger.service.StatisticsService;
import cn.homeledger.vo.HomeOverviewResponse;
import cn.homeledger.vo.HomeOverviewResponse.HomeSummary;
import cn.homeledger.vo.HomeOverviewResponse.RecentActivityResponse;
import cn.homeledger.vo.TransactionSummaryResponse;

/**
 * §4.6 首页聚合。
 * <p>
 * 本类一行业务口径都不自己写：本月收支与结余走 {@link StatisticsService#summary}（与统计页、导出页同一个
 * 算法与同一份缓存），预算进度走 {@link BudgetService#progress}，模块可见性走 {@link ModulePreferenceService}。
 * 首页最容易出的错是「同一个数字在两处各算一遍」，所以这里的职责是<b>取数与拼装</b>，不是再算一遍。
 * <p>
 * 最近动态的取法是「每张表各取最新 5 条、在内存里合并再取前 5」。不用 UNION ALL 一条 SQL：
 * 八张表的列各不相同，拼起来要造一个宽到没人看得懂的结果集，而租户拦截器对 UNION 的改写行为
 * 本项目从未验证过——每张表 5 行的读取代价可以忽略，不拿它换那点 SQL 数量。
 */
@Service
public class HomeServiceImpl implements HomeService {

	/** 最近动态取几条（§4.6 第 6 条：最近 5 条）。 */
	private static final int RECENT_LIMIT = 5;

	/** 每张表各取几条候选。取 5 就够：全局前 5 必然落在某一张表的前 5 里，多取只是白读。 */
	private static final int PER_TABLE_LIMIT = RECENT_LIMIT;

	private final StatisticsService statisticsService;

	private final BudgetService budgetService;

	private final ModulePreferenceService modulePreferenceService;

	private final TransactionMapper transactionMapper;

	private final CatFoodBagMapper catFoodBagMapper;

	private final CatDewormingMapper catDewormingMapper;

	private final BabyGrowthMapper babyGrowthMapper;

	private final BabyFormulaBagMapper babyFormulaBagMapper;

	private final BabyVaccineRecordMapper babyVaccineRecordMapper;

	private final BabyMilestoneMapper babyMilestoneMapper;

	private final BabyMedicalMapper babyMedicalMapper;

	private final BabyMapper babyMapper;

	private final CatMapper catMapper;

	private final FamilyMemberMapper familyMemberMapper;

	private final Clock clock;

	public HomeServiceImpl(StatisticsService statisticsService, BudgetService budgetService,
			ModulePreferenceService modulePreferenceService, TransactionMapper transactionMapper,
			CatFoodBagMapper catFoodBagMapper, CatDewormingMapper catDewormingMapper, BabyGrowthMapper babyGrowthMapper,
			BabyFormulaBagMapper babyFormulaBagMapper, BabyVaccineRecordMapper babyVaccineRecordMapper,
			BabyMilestoneMapper babyMilestoneMapper, BabyMedicalMapper babyMedicalMapper, BabyMapper babyMapper,
			CatMapper catMapper, FamilyMemberMapper familyMemberMapper, Clock clock) {
		this.statisticsService = statisticsService;
		this.budgetService = budgetService;
		this.modulePreferenceService = modulePreferenceService;
		this.transactionMapper = transactionMapper;
		this.catFoodBagMapper = catFoodBagMapper;
		this.catDewormingMapper = catDewormingMapper;
		this.babyGrowthMapper = babyGrowthMapper;
		this.babyFormulaBagMapper = babyFormulaBagMapper;
		this.babyVaccineRecordMapper = babyVaccineRecordMapper;
		this.babyMilestoneMapper = babyMilestoneMapper;
		this.babyMedicalMapper = babyMedicalMapper;
		this.babyMapper = babyMapper;
		this.catMapper = catMapper;
		this.familyMemberMapper = familyMemberMapper;
		this.clock = clock;
	}

	@Override
	public HomeOverviewResponse overview(Long userId) {
		Long familyId = AuthContextHolder.require().familyId();
		LocalDate today = LocalDate.now(this.clock);
		return new HomeOverviewResponse(summaryOf(familyId, today), this.budgetService.progress(null),
				recentActivities(familyId, this.modulePreferenceService.enabledKeys(userId)));
	}

	/**
	 * 概要卡的五个数。本月区间取「当月 1 日 → 今天」而不是整月：未来的日子没有流水，
	 * 而结余与已记录天数都只与已经发生的那些事有关。
	 */
	private HomeSummary summaryOf(Long familyId, LocalDate today) {
		LocalDate monthStart = today.withDayOfMonth(1);
		TransactionSummaryResponse month = this.statisticsService.summary(new TransactionQueryRequest(monthStart, today,
				null, null, null, null, null, null, null, null, null, null));
		int autoGeneratedToday = Math.toIntExact(this.transactionMapper
			.selectCount(new LambdaQueryWrapper<Transaction>()
				.eq(Transaction::getFamilyId, familyId)
				.eq(Transaction::getBizDate, today)
				.isNotNull(Transaction::getRuleId)));
		return new HomeSummary(month.income(), month.expense(), month.balance(),
				this.transactionMapper.countRecordedDays(familyId, monthStart, today), autoGeneratedToday);
	}

	/**
	 * 最近动态。按模块开关过滤（§4.6 第 6 条）：关掉猫咪模块的人不该在首页看到猫咪条目，
	 * 而那件事判在服务端更合适——客户端手里只有「这条属于哪个模块」，「哪个模块开着」是偏好表里的事实。
	 */
	private List<RecentActivityResponse> recentActivities(Long familyId, Set<String> modules) {
		List<RecentActivityResponse> rows = new ArrayList<>();
		// 记录人昵称查一次共用：七类记录里凡是要显示名字的都从这里取，逐条查等于每条动态多一次往返
		Map<Long, String> actors = actorNames(familyId);
		if (modules.contains(ModuleKey.FINANCE.name())) {
			for (Transaction row : latest(familyId, Transaction::getFamilyId, Transaction::getCreatedAt,
					Transaction::getId, this.transactionMapper)) {
				rows.add(activity(RecentActivityType.TRANSACTION,
						"INCOME".equals(row.getType()) ? "记了一笔收入" : "记了一笔支出",
						row.getCategoryNameSnapshot() + " · " + row.getAmount().toPlainString() + " 元",
						// 流水自带记录人昵称快照，不必再查名单——它同时兜住了「记录人已退出家庭」
						row.getRecorderNameSnapshot(), row.getCreatedAt(), "/finance/transaction/" + row.getId()));
			}
		}
		if (modules.contains(ModuleKey.CAT.name())) {
			Map<Long, String> cats = catNames(familyId);
			for (CatFoodBag row : latest(familyId, CatFoodBag::getFamilyId, CatFoodBag::getCreatedAt, CatFoodBag::getId,
					this.catFoodBagMapper)) {
				rows.add(activity(RecentActivityType.CAT_FOOD_BAG, "换了一袋猫粮",
						row.getBrand() + " · " + row.getPackGrams() + " g", actors.get(row.getCreatedBy()),
						row.getCreatedAt(), "/cat/food-bags"));
			}
			for (CatDeworming row : latest(familyId, CatDeworming::getFamilyId, CatDeworming::getCreatedAt,
					CatDeworming::getId, this.catDewormingMapper)) {
				DewormingType type = DewormingType.of(row.getType());
				String what = type == null ? "驱虫" : type.label();
				rows.add(activity(RecentActivityType.CAT_DEWORMING,
						"给" + cats.getOrDefault(row.getCatId(), "猫咪") + "做了" + what,
						row.getDoneDate() + (row.getMedicine() == null ? "" : " · " + row.getMedicine()),
						actors.get(row.getCreatedBy()), row.getCreatedAt(), "/cat/dewormings"));
			}
		}
		if (modules.contains(ModuleKey.BABY.name())) {
			Map<Long, String> babies = babyNames(familyId);
			// 奶粉开罐是家庭级的（不挂具体宝宝），与猫粮开袋同一条动态形状（第 32 轮、§4.5.3）
			for (BabyFormulaBag row : latest(familyId, BabyFormulaBag::getFamilyId, BabyFormulaBag::getCreatedAt,
					BabyFormulaBag::getId, this.babyFormulaBagMapper)) {
				rows.add(activity(RecentActivityType.BABY_FORMULA_BAG, "开了一罐奶粉",
						row.getBrand() + " · " + row.getPackGrams() + " g", actors.get(row.getCreatedBy()),
						row.getCreatedAt(), "/baby/formulas"));
			}
			for (BabyGrowth row : latest(familyId, BabyGrowth::getFamilyId, BabyGrowth::getCreatedAt,
					BabyGrowth::getId, this.babyGrowthMapper)) {
				rows.add(activity(RecentActivityType.BABY_GROWTH,
						"给" + babyName(babies, row.getBabyId()) + "量了身高体重", measurement(row),
						actors.get(row.getCreatedBy()), row.getCreatedAt(), "/baby/growths"));
			}
			for (BabyVaccineRecord row : latest(familyId, BabyVaccineRecord::getFamilyId,
					BabyVaccineRecord::getCreatedAt, BabyVaccineRecord::getId, this.babyVaccineRecordMapper)) {
				rows.add(activity(RecentActivityType.BABY_VACCINE,
						babyName(babies, row.getBabyId()) + "接种了疫苗",
						row.getVaccineName() + " 第 " + row.getDoseNo() + " 剂 · " + row.getGivenDate(),
						actors.get(row.getCreatedBy()), row.getCreatedAt(), "/baby/vaccines"));
			}
			for (BabyMilestone row : latest(familyId, BabyMilestone::getFamilyId, BabyMilestone::getCreatedAt,
					BabyMilestone::getId, this.babyMilestoneMapper)) {
				rows.add(activity(RecentActivityType.BABY_MILESTONE,
						"记下了" + babyName(babies, row.getBabyId()) + "的里程碑", row.getTitle(),
						actors.get(row.getCreatedBy()), row.getCreatedAt(), "/baby/records"));
			}
			for (BabyMedical row : latest(familyId, BabyMedical::getFamilyId, BabyMedical::getCreatedAt,
					BabyMedical::getId, this.babyMedicalMapper)) {
				rows.add(activity(RecentActivityType.BABY_MEDICAL,
						babyName(babies, row.getBabyId()) + "有一次就诊",
						row.getHospital() == null ? row.getVisitDate().toString()
								: row.getHospital() + " · " + row.getVisitDate(),
						actors.get(row.getCreatedBy()), row.getCreatedAt(), "/baby/records"));
			}
		}
		// List.sort 是稳定排序：同一时刻写入的两条（一次事务里的批量插入）保持上面那八段的先后，
		// 不另找次级键——动态这一屏没有「谁该在前」的第二条口径
		rows.sort(Comparator.comparing(RecentActivityResponse::occurredAt,
				Comparator.nullsLast(Comparator.reverseOrder())));
		return rows.size() <= RECENT_LIMIT ? List.copyOf(rows) : List.copyOf(rows.subList(0, RECENT_LIMIT));
	}

	/**
	 * 某一类记录里最新的一批。
	 * <p>
	 * {@code LIMIT} 是手写进 wrapper 的：这条查询不是 {@code selectPage}，不经过分页拦截器，
	 * 每张表只取 5 行也不该为它造一个 {@code IPage}（同 {@code TransactionMapper.selectForExport}
	 * 对「手写 LIMIT」的做法）。
	 * <p>
	 * 排序键带 id：同一秒写入的两条 {@code created_at} 相同，只按时间排序时 MySQL 不保证稳定顺序，
	 * 同一个家庭两次请求会看到两条动态互换位置。
	 * <p>
	 * {@code deleted = 0} 不必手写：这是 {@code BaseMapper} 的通用查询，MyBatis-Plus 的 {@code @TableLogic}
	 * 会自动补上（§6.4.2 那条手写要求针对的是自定义 SQL）。
	 */
	private static <T, M extends BaseMapper<T>> List<T> latest(Long familyId, SFunction<T, ?> familyColumn,
			SFunction<T, ?> createdAtColumn, SFunction<T, ?> idColumn, M mapper) {
		return mapper.selectList(new LambdaQueryWrapper<T>()
			.eq(familyColumn, familyId)
			.orderByDesc(createdAtColumn)
			.orderByDesc(idColumn)
			.last("LIMIT " + PER_TABLE_LIMIT));
	}

	/** 在册成员昵称。已退出成员的记录查不到名字，客户端据此显示「已退出的成员」（§4.1.5 只对流水冻结了快照）。 */
	private Map<Long, String> actorNames(Long familyId) {
		Map<Long, String> names = new HashMap<>();
		for (FamilyMember member : this.familyMemberMapper
			.selectList(new LambdaQueryWrapper<FamilyMember>().eq(FamilyMember::getFamilyId, familyId))) {
			names.put(member.getUserId(), member.getNicknameSnapshot());
		}
		return names;
	}

	/** 宝宝名字含归档的：动态是历史，归档只是「不再参与新记录」（§4.4.1）。与待提醒那边的口径相反。 */
	private Map<Long, String> babyNames(Long familyId) {
		Map<Long, String> names = new HashMap<>();
		for (Baby baby : this.babyMapper.selectList(new LambdaQueryWrapper<Baby>().eq(Baby::getFamilyId, familyId))) {
			names.put(baby.getId(), baby.getName());
		}
		return names;
	}

	private Map<Long, String> catNames(Long familyId) {
		Map<Long, String> names = new HashMap<>();
		for (Cat cat : this.catMapper.selectList(new LambdaQueryWrapper<Cat>().eq(Cat::getFamilyId, familyId))) {
			names.put(cat.getId(), cat.getName());
		}
		return names;
	}

	private static String babyName(Map<Long, String> babies, Long babyId) {
		return babies.getOrDefault(babyId, "宝宝");
	}

	/** 「身高 70.0 cm · 体重 8.00 kg」。只量了一项时只写那一项——没量不等于 0（§4.4.2）。 */
	private static String measurement(BabyGrowth row) {
		List<String> parts = new ArrayList<>();
		if (row.getHeightCm() != null) {
			parts.add("身高 " + row.getHeightCm().toPlainString() + " cm");
		}
		if (row.getWeightKg() != null) {
			parts.add("体重 " + row.getWeightKg().toPlainString() + " kg");
		}
		if (row.getHeadCm() != null) {
			parts.add("头围 " + row.getHeadCm().toPlainString() + " cm");
		}
		return String.join(" · ", parts);
	}

	private static RecentActivityResponse activity(RecentActivityType type, String title, String summary,
			String actorName, LocalDateTime occurredAt, String route) {
		return new RecentActivityResponse(type.module().name(), type.name(), title, summary, actorName, occurredAt,
				route);
	}

}
