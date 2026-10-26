package cn.homeledger.vo;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 曲线上的一个实测点（§4.4.3）。
 * <p>
 * {@code xValue} 与 {@code measured} 按 JSON 数字下发、{@code measureDate} 按字符串：
 * 前两者只喂坐标轴（§1.4 第 15 条），后者是展示用的日期。
 * <p>
 * {@code percentileBand} 为 null 是「实测值超出标准表覆盖范围」而不是「没测」——点照常返回，
 * 前端据此提示；省掉它会让曲线莫名断一段，而那个点本身是真实的测量值。
 */
public record BabyCurvePoint(@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate measureDate, int ageMonths,
		BigDecimal xValue, BigDecimal measured, String percentileBand) {

}
