package cn.homeledger.vo;

import java.util.List;

/**
 * 流水分页响应（§8）。
 * <p>
 * 不做泛型 {@code PageResponse<T>}：目前只有流水需要 monthSummaries，抽泛型要额外处理 record 的
 * 类型擦除，而 S5 的分页需求未必与此同形。
 * <p>
 * monthSummaries 覆盖的是<b>整套筛选条件下的全量结果</b>，与 total 同源，不是当前页的小结。
 */
public record TransactionPageResponse(List<TransactionResponse> records, long total, long page, long size, long pages,
		List<MonthSummary> monthSummaries) {

}
