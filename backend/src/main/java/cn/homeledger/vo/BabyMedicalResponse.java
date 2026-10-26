package cn.homeledger.vo;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 一条就诊记录（§4.4.5）。
 * <p>
 * {@code costAmount} 按字符串下发（§1.4 第 15 条）：它是金额，与流水的口径一致，
 * 走 JSON 数字会在前端被转成二进制浮点，展示时再把 0.1 印成 0.10000000000000001。
 */
public record BabyMedicalResponse(Long id, Long babyId,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate visitDate, String hospital, String department,
		String diagnosis, String medicine, @JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal costAmount,
		String remark) {

}
