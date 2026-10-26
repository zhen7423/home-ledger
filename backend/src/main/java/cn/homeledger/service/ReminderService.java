package cn.homeledger.service;

import java.util.List;

import cn.homeledger.dto.ReminderSettingSaveRequest;
import cn.homeledger.vo.PendingReminderResponse;
import cn.homeledger.vo.ReminderSettingResponse;

/**
 * §4.5.1 提醒框架：用户级开关 + 服务端算出的待提醒项。
 * <p>
 * 这是全项目唯一一组「不要求有家庭」的业务能力。提醒设置跟着账号走而不是跟着家庭走（没家庭的人迟早会加入，
 * 他应该现在就能把通知打开），而 {@code pending} 在没有家庭时返回空列表而不是 403——
 * 「此刻什么都没有」本来就是一个正确的空态。
 * <p>
 * S4 只有预算两类真的产出提醒，其余五类由 S6/S7/S8 往 {@code pending} 里各加一段。
 * 不提前抽 Producer 接口：只有一个实现时接口是纯噪音，第二个实现出现时才知道抽象线该画在哪。
 */
public interface ReminderService {

	/** 全部七类的当前开关，按枚举声明顺序，库里没有的按默认值补齐。 */
	List<ReminderSettingResponse> settings(Long userId);

	/**
	 * 逐项 upsert。type 解析不出枚举报 BAD_REQUEST，同一 type 在一次提交里出现两次报 REMINDER_SETTING_DUPLICATED。
	 * <p>
	 * 不先删后插：这张表没有「整体替换」的语义，而 created_at 有保留价值。
	 */
	void saveSettings(Long userId, ReminderSettingSaveRequest request);

	/** 当前该提醒用户的事项，两档互斥：一个事实只出一条，已超支不会再叠一条「即将超支」。 */
	List<PendingReminderResponse> pending(Long userId);

}
