package cn.homeledger.service;

import cn.homeledger.dto.TransactionQueryRequest;
import cn.homeledger.vo.FinanceStatisticsResponse;
import cn.homeledger.vo.TransactionSummaryResponse;

/**
 * §4.2.6 记账统计。两个方法吃的都是与流水列表完全相同的那一套筛选条件，
 * 因为导出页要复用同一份条件（§4.2.6「接口与页面的筛选能力不对等」）——
 * 页面只暴露时间范围与记录人，接口留全量。
 */
public interface StatisticsService {

	/**
	 * 区间概览（§4.2.6 概览卡片）。
	 * <p>
	 * 两个日期都不传即「全部历史」：区间解析成「家里第一笔流水的日期 → 今天」，366 天上限不生效
	 * （上限只约束同时给出起止日期的请求）。一笔流水都没有时 days 为 0、日均支出为 0。
	 */
	TransactionSummaryResponse summary(TransactionQueryRequest query);

	/**
	 * 统计页一次拿全（§8）。除月度趋势固定最近 12 个自然月、其余四块都按解析后的区间算。
	 * <b>不含预算</b>，前端直接复用 GET /budgets/progress（§4.2.6）。
	 */
	FinanceStatisticsResponse financeOverview(TransactionQueryRequest query);

}
