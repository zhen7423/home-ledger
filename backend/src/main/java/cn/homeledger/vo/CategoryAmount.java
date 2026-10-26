package cn.homeledger.vo;

import java.math.BigDecimal;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 某个成员在某个大类上的支出（§4.2.6 成员对比的「按大类」视图）。
 * categoryId 为 null 表示落在「其他」那一档里，与 {@link CategorySlice} 的口径一致。
 */
public record CategoryAmount(Long categoryId, @JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal amount) {

}
