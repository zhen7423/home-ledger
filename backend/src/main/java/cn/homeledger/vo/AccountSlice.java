package cn.homeledger.vo;

import java.math.BigDecimal;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 支付方式占比的一条（§4.2.6）。不做 Top N 截断，所以这里不会出现 categoryId 为 null 那种「其他」项。
 */
public record AccountSlice(Long accountId, String name,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal amount, int percent) {

}
