package cn.homeledger.service;

import java.time.LocalDateTime;

/**
 * §4.1.6 解散家庭的物理清除（需求 §12 S10）。
 * <p>
 * 语义：家庭解散后保留 30 天（期间可被「撤销解散」以外的任何逻辑读取不到，但数据还在），
 * 到期后由定时任务一次性抹掉该家庭的全部业务数据。30 天保留期是隐私承诺（§4.1.6）——
 * 提前清除会让「刚解散就再也找不回」发生，拖后清除则白白多存用户已放弃的数据。
 * <p>
 * 用户本人数据（user / user_auth_binding / module_preference / reminder_setting）不属于任何家庭，
 * 不参与清除（§5.2：租户隔离只在家庭维度，用户是全局实体）。
 */
public interface FamilyPurgeService {

	/**
	 * 找出所有「解散已满 30 天」的家庭并物理清除，返回成功清除的家庭数。
	 *
	 * @param now 业务时间。由调用方（定时任务）注入而不是内部取时钟，测试可以传固定时刻
	 */
	int purgeExpiredFamilies(LocalDateTime now);

}