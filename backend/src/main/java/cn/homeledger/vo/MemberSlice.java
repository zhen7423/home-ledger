package cn.homeledger.vo;

import java.math.BigDecimal;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 成员支出对比的一组（§4.2.6）。
 * <p>
 * byCategory 与同一份响应里的 categoryBreakdown <b>逐项对齐</b>：同长度、同顺序、同 categoryId
 * （含末尾那个 categoryId 为 null 的「其他」档）。前端因此可以直接按下标取颜色与图例，
 * 不必再做一次 id 匹配——两个列表各排各的话，「按大类」视图的柱子会与饼图的颜色对不上。
 * 这条契约由 B9 的一个测试钉住。
 * <p>
 * nickname 对已退出成员取的是 family_member.nickname_snapshot（§4.2.6）。
 */
public record MemberSlice(Long userId, String nickname,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal total, List<CategoryAmount> byCategory) {

}
