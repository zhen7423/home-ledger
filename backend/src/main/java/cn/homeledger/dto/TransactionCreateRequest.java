package cn.homeledger.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * 记一笔（§4.2.1）。记录人、类别与账户的名称快照都由服务端填，客户端没有对应字段。
 * <p>
 * 不含 type 字段：收支类型由服务端从所选大类读出。让客户端另传一个 type，就可能出现 EXPENSE 的类别
 * 配一条 INCOME 流水，统计时既进不了收入也进不了支出，是比直接报错更难查的脏数据。
 * 金额按字符串收发（§4.2.1 第 15 轮），避免经浮点丢精度。这里不加 @Digits：两位小数的超限要返回
 * AMOUNT_SCALE_INVALID 这句人能看懂的话，走 Bean Validation 只会得到一条字段校验失败的拼装文案。
 */
public record TransactionCreateRequest(
		@NotNull(message = "金额不能为空") @DecimalMin(value = "0.01", message = "金额必须大于 0") @JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal amount,
		@NotNull(message = "请选择收支类别") Long categoryId, Long subCategoryId,
		@NotNull(message = "请选择支付方式") Long accountId,
		@NotNull(message = "请选择记账日期") @JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate bizDate,
		@Size(max = 200, message = "备注最多 200 个字符") String remark) {

}
