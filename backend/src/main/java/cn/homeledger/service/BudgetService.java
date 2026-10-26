package cn.homeledger.service;

import java.util.List;

import cn.homeledger.dto.BudgetSaveRequest;
import cn.homeledger.vo.BudgetProgressResponse;
import cn.homeledger.vo.BudgetResponse;

/**
 * §4.2.4 三维度预算：家庭总额、按大类、按成员。
 * <p>
 * 预算只是一份额度配置，本 Service 不存任何「已用金额」——已用是每次现算的，跟着流水走。三个维度的口径
 * 分别是：家庭总预算算本家这个月所有支出，类别预算按<b>大类</b>聚合（小类的钱算在它所属的大类头上），
 * 成员预算按<b>记录人</b>算（A5：本项目没有「消费成员」这个概念）。
 * <p>
 * 保存语义是整体替换，所以每次保存后所有预算行的 id 都会变。前端不能持有预算 id 做任何操作，
 * 也不存在按 id 改单条的接口。
 */
public interface BudgetService {

	/** 当前这版预算配置，按提交顺序回显。 */
	List<BudgetResponse> list();

	/**
	 * 整体替换。items 为 null 或空列表都是合法的「清空」。
	 * <p>
	 * 校验顺序：维度的空值形状 → 字典项与成员归属 → 请求内 bucketKey 去重 → 金额。测试按这个顺序断言错误码。
	 */
	void save(Long userId, BudgetSaveRequest request);

	/**
	 * 某个月份的执行进度。month 形如 {@code 2026-09}，缺省取当月。
	 * <p>
	 * 过去与未来的月份都允许查（用户想看上月执行得怎样，也想确认下月设了额度），只有剩余天数对它们恒为 0。
	 */
	List<BudgetProgressResponse> progress(String month);

}
