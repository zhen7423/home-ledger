package cn.homeledger.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * 标记应种项（§4.4.4）。**只有两个字段**：{@code dueDate} / {@code vaccineName} / {@code doseNo} 不在这里，
 * 多传的键被 Jackson 忽略——「只接受标记」这条约束由接口签名本身挡住，不靠手写校验。
 * <p>
 * {@code status} 只接受 {@code SKIPPED} / {@code NA}（标记）与 {@code PENDING}（撤销）。
 * {@code DONE} 由接种记录回写，手工写入即拒——它没有对应的用户输入，允许手写就会出现
 * 「标成已接种但没有任何接种记录」的行。
 * <p>
 * {@code reason} 在标记时必填、撤销时忽略（§4.3③）：撤销之后留着一条原因，下一次标记会带着上一次的字。
 */
public record BabyVaccinePlanUpdateRequest(@NotBlank(message = "请选择状态") String status,

		@Size(max = 50, message = "原因最多 50 个字符") String reason) {

}
