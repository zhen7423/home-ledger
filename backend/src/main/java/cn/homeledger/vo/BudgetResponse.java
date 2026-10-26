package cn.homeledger.vo;

import java.math.BigDecimal;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 一条预算（§4.2.4）。
 * <p>
 * bucketKey 不出现在出参里：它是服务端的防重载体，客户端拿到也没有能做什么，多给一个字段就多一个
 * 可能被前端当成主键用的东西——预算没有可寻址的主键，保存永远是整份重提。
 */
public record BudgetResponse(Long id, String scope, Long categoryId, String categoryName, Long memberUserId,
		String memberName, @JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal amount) {

}
