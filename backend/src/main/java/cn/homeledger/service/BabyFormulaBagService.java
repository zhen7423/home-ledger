package cn.homeledger.service;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

import cn.homeledger.common.ConsumptionEstimate;
import cn.homeledger.dto.BabyFormulaBagCreateRequest;
import cn.homeledger.dto.BabyFormulaBagUpdateRequest;
import cn.homeledger.vo.BabyFormulaBagResponse;
import cn.homeledger.vo.BabyFormulaCurrentResponse;

/**
 * §4.5.3 奶粉开罐记录。结束日期与在用状态都不落库，全部由 started_date 推导，所以本接口的三个读方法
 * 是<b>同一份推导的三种投影</b>：{@link #timeline()} 是原始推导，{@link #list()} 是它的出参形状，
 * {@link #closedBags()} 是它折给 {@link ConsumptionEstimate} 的那一小段。与 {@code CatFoodBagService}
 * 同构（§6.4.1：数据是同一个「包装消耗时间线」模型在两个模块的投影）。
 */
public interface BabyFormulaBagService {

	/**
	 * 一罐奶粉在时间线上的完整位置（§4.5.3）。给 {@link #list()}、{@link #current()} 与奶粉统计的
	 * 克数分摊共用，<b>不给控制器直接出参</b>：{@code endDate} 与 {@code usageDays} 两列对在用罐
	 * 是有内部含义的（今天、含头含尾），而列表接口对当前罐回 {@code null}。
	 *
	 * @param current 是否当前在用（开罐日期最大的那一罐）
	 * @param endDate 已完成罐为下一罐的开罐日；在用罐为今天，<b>只作内部推导用</b>
	 * @param usageDays 已完成罐为 endDate − startedDate；在用罐为今天 − startedDate + 1（含头含尾）
	 * @param startedTime 开罐具体时刻，选填；随行带出仅供展示，不参与任何推导（V20261026130000）
	 * @param remark 随行带出的备注。不参与任何推导，但列表的出参要它
	 */
	record TimelineEntry(Long id, String brand, int packGrams, LocalDate startedDate, LocalTime startedTime,
			Integer estimatedDailyGrams, LocalDate endDate, long usageDays, boolean current, String remark) {

	}

	List<BabyFormulaBagResponse> list();

	List<TimelineEntry> timeline();

	/**
	 * 参与日均折算的已完成罐，即 {@code usageDays > 0} 的那几罐。只在这里筛一次：各调用方
	 * 再各自 filter 会出现「推算卡认为有历史、列表页认为没有」这种两页互相打脸的形状。
	 */
	List<ConsumptionEstimate.ClosedBag> closedBags();

	BabyFormulaCurrentResponse current();

	BabyFormulaBagResponse create(Long userId, BabyFormulaBagCreateRequest request);

	BabyFormulaBagResponse update(Long userId, Long id, BabyFormulaBagUpdateRequest request);

	void delete(Long userId, Long id);

}