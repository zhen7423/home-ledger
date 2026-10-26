package cn.homeledger.vo;

/**
 * 品牌占比饼图的一片（§4.3.5 第二块）。
 * <p>
 * 按克数而不是按袋数：两袋 500g 与一袋 2000g 在「哪个牌子吃得多」这个问题下是 1000g 对 2000g。
 * 区间总克数为 0 时整个列表为空，而不是给一片 0% 的扇形。
 */
public record CatBrandSlice(String brand, int grams, int percent) {

}
