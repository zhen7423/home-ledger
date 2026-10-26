package cn.homeledger.service.impl;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionTemplate;

import cn.homeledger.common.AuthContext;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.mapper.FamilyMapper;
import cn.homeledger.mapper.PurgeMapper;
import cn.homeledger.service.FamilyPurgeService;
import cn.homeledger.service.PhotoService;

/**
 * §4.1.6 物理清除任务的执行细节都在这里，job 包那层只剩一行调度（§6.4.1）。
 * <p>
 * 每张表一条真 DELETE、全部塞进一个按家庭的事务里：清除要么完整、要么原封不动，不存在
 * 「账单没了类别还在」的中间态。家庭之间彼此独立——一个家庭的清除失败只记日志、不拖累别的
 * （下一轮任务会重新扫描到它，deleted_at 没变，重试天然幂等）。
 * <p>
 * 照片文件的删除放在事务提交之后：文件系统与数据库不是一个事务。先删文件再删库，
 * 库删失败会把一个「照片没了但家庭还在」的状态交出去——这比孤儿文件严重得多，所以颠倒了必须颠倒的。
 */
@Service
public class FamilyPurgeServiceImpl implements FamilyPurgeService {

	private static final Logger log = LoggerFactory.getLogger(FamilyPurgeServiceImpl.class);

	/** 解散保留期，天数（§4.1.6）。 */
	private static final int RETENTION_DAYS = 30;

	private final FamilyMapper familyMapper;

	private final PurgeMapper purgeMapper;

	private final PhotoService photoService;

	private final TransactionTemplate transactionTemplate;

	public FamilyPurgeServiceImpl(FamilyMapper familyMapper, PurgeMapper purgeMapper, PhotoService photoService,
			TransactionTemplate transactionTemplate) {
		this.familyMapper = familyMapper;
		this.purgeMapper = purgeMapper;
		this.photoService = photoService;
		this.transactionTemplate = transactionTemplate;
	}

	@Override
	public int purgeExpiredFamilies(LocalDateTime now) {
		LocalDateTime cutoff = now.minusDays(RETENTION_DAYS);
		List<Long> familyIds = this.familyMapper.selectDissolvedBefore(cutoff);
		if (familyIds.isEmpty()) {
			return 0;
		}
		int purged = 0;
		for (Long familyId : familyIds) {
			try {
				purgeOneFamily(familyId);
				purged++;
				log.info("物理清除家庭完成 familyId={}", familyId);
			}
			catch (RuntimeException e) {
				// 一个家庭失败不中断整轮：事务已回滚，它仍满足「解散满 30 天」，下一轮照常被扫到
				log.error("物理清除家庭失败 familyId={}，留待下一轮重试", familyId, e);
			}
		}
		return purged;
	}

	private void purgeOneFamily(Long familyId) {
		// 收集与删除都必须在切好上下文的块里做：cat / baby 不在租户白名单里，任务线程没有登录态，
		// 拦截器会注入 -1 哨兵，收集查询会静默落空、19 条删除会静默失效。收集先于删除，
		// 库里还活着的时候文件才有归属；文件删除放在事务提交之后，理由见类注释。
		List<String> photoPaths = new ArrayList<>();

		this.transactionTemplate.executeWithoutResult(status -> {
			AuthContext previous = AuthContextHolder.get();
			AuthContextHolder.set(new AuthContext(0L, familyId, AuthContext.ROLE_MEMBER));
			try {
				photoPaths.addAll(this.purgeMapper.collectCatPhotos(familyId));
				photoPaths.addAll(this.purgeMapper.collectBabyPhotos(familyId));
				this.purgeMapper.deleteExecutionLogByFamily(familyId);
				this.purgeMapper.deleteRuleByFamily(familyId);
				this.purgeMapper.deleteTransactionByFamily(familyId);
				this.purgeMapper.deleteBudgetByFamily(familyId);
				this.purgeMapper.deleteAccountByFamily(familyId);
				this.purgeMapper.deleteCategoryByFamily(familyId);
				this.purgeMapper.deleteCatSettingByFamily(familyId);
				this.purgeMapper.deleteCatFoodBagByFamily(familyId);
				this.purgeMapper.deleteCatDewormingByFamily(familyId);
				this.purgeMapper.deleteCatByFamily(familyId);
				this.purgeMapper.deleteBabyGrowthByFamily(familyId);
				this.purgeMapper.deleteBabyPlanByFamily(familyId);
				this.purgeMapper.deleteBabyRecordByFamily(familyId);
				this.purgeMapper.deleteBabyMilestoneByFamily(familyId);
				this.purgeMapper.deleteBabyMedicalByFamily(familyId);
				this.purgeMapper.deleteBabyFormulaBagByFamily(familyId);
				this.purgeMapper.deleteBabyByFamily(familyId);
				this.purgeMapper.deleteMemberByFamily(familyId);
				this.purgeMapper.deleteFamilyRow(familyId);
				// 删文件逐张注册到 afterCommit（与 setPhoto 换照同一条机制，M1）：
				// 提交阶段才失败时回调不执行，不会交出「照片没了但家庭还在」的状态
				photoPaths.forEach(this.photoService::deleteAfterCommit);
			}
			finally {
				// 任务线程会被复用：previous 几乎总是 null，set(null) 会在 ThreadLocal 里
				// 留一个 null 条目，remove() 才是真清理（S10 审查 I4）
				if (previous == null) {
					AuthContextHolder.clear();
				}
				else {
					AuthContextHolder.set(previous);
				}
			}
		});
	}

}