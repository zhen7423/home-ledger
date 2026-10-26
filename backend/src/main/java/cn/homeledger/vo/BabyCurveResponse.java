package cn.homeledger.vo;

import java.util.List;

/**
 * 生长曲线的整份响应（§4.4.3）。
 * <p>
 * {@code standard} 随响应下发而不另开端点：前端画百分位带要的就是这张表，而统计两条都不回曲线
 * （§4.4.6）——并进统计会让 §5.4 的离线快照为一条曲线背一整张表。
 * <p>
 * {@code standardMetric} 是服务端实际选中的那张表名（§1.4 第 14 条）：用户选的「体重别身高」对应
 * 两张独立的源表，界面标题要写出「2 岁以下按身长」才解释得清横轴为什么是这个范围。
 */
public record BabyCurveResponse(Long babyId, String metric, String standardMetric, List<BabyCurvePoint> points,
		List<GrowthStandardRowResponse> standard, String disclaimer) {

}
