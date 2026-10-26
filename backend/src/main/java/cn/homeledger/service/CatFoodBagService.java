package cn.homeledger.service;

import java.time.LocalDate;
import java.util.List;

import cn.homeledger.common.ConsumptionEstimate;
import cn.homeledger.dto.CatFoodBagCreateRequest;
import cn.homeledger.dto.CatFoodBagUpdateRequest;
import cn.homeledger.vo.CatFoodBagResponse;
import cn.homeledger.vo.CatFoodCurrentResponse;

/**
 * §4.3.2 猫粮袋记录。结束日期与在用状态都不落库，全部由 started_date 推导，所以本接口的三个读方法
 * 是<b>同一份推导的三种投影</b>：{@link #timeline()} 是原始推导，{@link #list()} 是它的出参形状，
 * {@link #closedBags()} 是它折给 {@link ConsumptionEstimate} 的那一小段。
 */
public interface CatFoodBagService {

	/**
	 * 一袋猫粮在时间线上的完整位置（§4.3.2）。给 {@link #list()}、{@link #current()} 与消耗统计的
	 * 克数分摊共用，<b>不给控制器直接出参</b>：{@code endDate} 与 {@code usageDays} 两列对在用袋
	 * 是有内部含义的（今天、含头含尾），而 §8 明确要求列表接口对当前袋回 {@code null}。
	 *
	 * @param current 是否当前在用（开始日期最大的那一袋）
	 * @param endDate 已完成袋为下一袋的开始日；在用袋为今天，<b>只作内部推导用</b>
	 * @param usageDays 已完成袋为 endDate − startedDate；在用袋为今天 − startedDate + 1（含头含尾）
	 * @param remark 随行带出的备注。不参与任何推导，但列表的出参要它——少了这一列 list() 就得为了备注再读一次库
	 */
	record TimelineEntry(Long id, String brand, int packGrams, LocalDate startedDate, LocalDate endDate, long usageDays,
			boolean current, String remark) {

	}

	List<CatFoodBagResponse> list();

	List<TimelineEntry> timeline();

	/**
	 * 参与日均折算的已完成袋，即 {@code usageDays > 0} 的那几袋（§4.3.4 括号里那句「跳过使用天数 ≤ 0
	 * 的异常袋」）。<b>只在这里筛一次</b>：设置页那句「已由历史数据接管」的判据就是本方法返回空与非空，
	 * 各调用方再各自 filter 会出现「统计认为有历史、设置页认为没有」这种两页互相打脸的形状。
	 */
	List<ConsumptionEstimate.ClosedBag> closedBags();

	CatFoodCurrentResponse current();

	CatFoodBagResponse create(Long userId, CatFoodBagCreateRequest request);

	CatFoodBagResponse update(Long userId, Long id, CatFoodBagUpdateRequest request);

	void delete(Long userId, Long id);

}
