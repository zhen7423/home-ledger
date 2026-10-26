package cn.homeledger.vo;

/**
 * 逐月消耗趋势的一根柱子（§4.3.5 第三块）。
 * <p>
 * 固定 12 项、缺月补 0，且与请求区间无关：这张图回答的是「食量随月份怎么变」，在一个月的窗口里问不出答案。
 * 月份键形如 {@code 2026-09}，与财务侧的月度趋势同形。
 */
public record CatMonthGrams(String month, int grams) {

}
