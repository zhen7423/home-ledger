package cn.homeledger.vo;

import java.math.BigDecimal;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 一条记录的「较上一次的增量」（§4.4.2）。四个字段都可空，两个空各有各的意思：
 * <ul>
 * <li>{@code days} 为空表示这是首条记录，没有「上一次」；</li>
 * <li>某一档为空表示这一次或上一次没量那个量——「较上次没量身高」与「较上次身高没变」是两件事，
 * 后者是 {@code 0.0} 而不是空。</li>
 * </ul>
 * <p>
 * 三个差值同样按字符串下发（§7.1）：同一类量在同一个 App 里出现两种 JSON 形态，
 * 前端每写一个模型都要回去查这个端点是哪种。
 */
public record BabyGrowthDelta(Long days,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal heightCm,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal weightKg,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal headCm) {

}
