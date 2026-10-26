package cn.homeledger.vo;

import java.time.LocalDate;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 统计页一次拿全（§8 的 GET /statistics/finance/overview）。
 * <p>
 * 五条查询合成一个接口是有意的：统计页一屏就要这五块，拆成五个端点等于让手机在弱网下串五次往返，
 * 而五块的筛选条件完全相同，服务端一次就能算完。
 * <p>
 * <b>不含预算。</b> 预算执行恒显示当月且不随时间范围变化（§4.2.6），前端直接复用 GET /budgets/progress，
 * 这里重复提供只会多出「两个接口的预算数字不一致」这一类问题。
 * <p>
 * monthlyTrend 恒为最近 12 个自然月、升序、缺月补 0，<b>不随 startDate / endDate 变化</b>。
 */
public record FinanceStatisticsResponse(@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate startDate,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate endDate, List<CategorySlice> categoryBreakdown,
		List<MonthSummary> monthlyTrend, List<DailyPoint> dailyTrend, List<AccountSlice> accountBreakdown,
		List<MemberSlice> memberComparison) {

}
