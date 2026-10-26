package cn.homeledger.service;

import java.util.List;

import cn.homeledger.dto.RecurringRuleCreateRequest;
import cn.homeledger.dto.RecurringRuleUpdateRequest;
import cn.homeledger.vo.RecurringExecutionResponse;
import cn.homeledger.vo.RecurringRuleResponse;

/**
 * §4.2.3 周期性记账规则。
 * <p>
 * 规则家庭级共享：任一成员建的规则，生成的流水全家可见，created_by 只标谁建的、不构成权限。
 * 规则本身不产生流水，产生流水的是 {@code RecurringGenerationService}（B5），本 Service 只管配置的增删改查。
 */
public interface RecurringRuleService {

	/** 列表。type 可空，空则收支两类一起返回，按创建时间倒序。 */
	List<RecurringRuleResponse> list(String type);

	/**
	 * 新建。收支类型由大类派生，客户端不传。
	 * <p>
	 * 建成的同一事务里同步跑一次该规则的当天窗口，让 start_date 落在本月且执行日已过去的规则当场就出流水
	 * （A4「当月立即生效」）。
	 */
	RecurringRuleResponse create(Long userId, RecurringRuleCreateRequest request);

	/** 详情，供编辑页回填。不属于当前家庭的 id 与不存在的 id 一样返回 RECURRING_RULE_NOT_FOUND。 */
	RecurringRuleResponse get(Long id);

	/**
	 * 整体覆盖式编辑。改了周期参数或 start_date 时把 last_processed_date 重置为新的 start_date 前一天，
	 * 否则老游标会让新参数的补记窗口起点错位；只改名称与金额时不动游标。
	 */
	RecurringRuleResponse update(Long userId, Long id, RecurringRuleUpdateRequest request);

	/**
	 * 启用 ↔ 暂停。从暂停切回启用时同样同步跑一次当天窗口（A4 对「恢复」与「新建」一视同仁）；
	 * 从启用切到暂停时不动游标，游标停在暂停那天，恢复时窗口起点自然收窄。
	 */
	RecurringRuleResponse toggle(Long userId, Long id);

	/** 逻辑删除。删规则不删它生成过的流水——那些流水已经是家庭账本的一部分。 */
	void delete(Long userId, Long id);

	/** 某条规则的执行记录，按业务日期倒序。 */
	List<RecurringExecutionResponse> executions(Long id);

}
