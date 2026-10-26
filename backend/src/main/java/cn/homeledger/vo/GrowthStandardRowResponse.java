package cn.homeledger.vo;

import java.math.BigDecimal;

/**
 * 标准表的一行（§4.4.3）：横轴 + 国标七档。
 * <p>
 * 数值列都不标 {@code @JsonFormat}：它们要直接喂 {@code fl_chart} 的坐标轴，按 JSON 数字下发
 * （§1.4 第 15 条）。Java 侧仍是 {@code BigDecimal}，改成字符串等于让前端在最该只做几何的那一层
 * 先解一遍，而这个端点的唯一理由就是「插值与区间判定都在服务端」。
 */
public record GrowthStandardRowResponse(BigDecimal xValue, BigDecimal p3, BigDecimal p10, BigDecimal p25,
		BigDecimal p50, BigDecimal p75, BigDecimal p90, BigDecimal p97) {

}
