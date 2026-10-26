package cn.homeledger.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import cn.homeledger.common.StatisticsCache;

/**
 * 流水列表的筛选条件（§4.2.5）。字段为空即该条件不参与筛选；page 从 1 起，size 默认 30、上限 200。
 * <p>
 * 没有 familyId 字段：当前家庭由服务端从登录态取，作为独立的 Mapper 参数传下去。放进这个 record
 * 就等于在 OpenAPI 里挂出一个「你可以传家庭 id」的查询参数，而它必然被忽略——留着一个不收的参数
 * 比没有更糟。
 * <p>
 * source 取 {@code AUTO}（只看周期记账自动生成的）或 {@code MANUAL}（只看手工记的），为空不筛；
 * 传别的值直接 400，不静默当成没筛。出参侧不另设来源字段，{@code TransactionResponse#ruleId} 有没有值
 * 就是这件事的答案。
 */
public record TransactionQueryRequest(LocalDate startDate, LocalDate endDate, String type, Long categoryId,
		Long subCategoryId, Long accountId, Long createdBy, String keyword, BigDecimal amount, String source,
		Integer page, Integer size) {

	/**
	 * 缓存键的条件部分（§5.1）。十个筛选条件按声明顺序拼串，page / size 刻意不参与：
	 * 两个统计端点都不分页，把它们算进来只会让同一份统计因为前端多传一个 page=1 而各存一份。
	 * <p>
	 * amount 用 toPlainString 而不是 toString：后者在负指数时会写成 1E+2，同一个金额的两种写法
	 * 会得到两个键。<b>不做数值归一化</b>（1.0 与 1.00 是两个键），代价是极偶尔多一次未命中，
	 * 换来的是不必在这里复刻一套 BigDecimal 比较语义。
	 */
	public String canonicalConditions() {
		return StatisticsCache.joinConditions(text(startDate), text(endDate), text(type), text(categoryId),
				text(subCategoryId), text(accountId), text(createdBy), text(keyword),
				amount == null ? null : amount.toPlainString(), text(source));
	}

	private static String text(Object value) {
		return value == null ? null : value.toString();
	}

}
