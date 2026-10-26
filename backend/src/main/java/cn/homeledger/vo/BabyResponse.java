package cn.homeledger.vo;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 一个宝宝的档案（§4.4.1）。
 * <p>
 * archived 是 enabled 取反后的语义字段，理由同 {@code CatResponse}：库里那一列问的是「还参与新记录吗」，
 * 界面要说的是「这个已经归档了」，让前端去写 {@code !enabled} 等于把这句翻译复制多处。
 * <p>
 * ageText 由服务端下发（§1.4 第 8 条）：月龄算法只有 {@code BabyAge} 一处实现，
 * 前端再算一遍就会与曲线上的点、清单上的应种日期各按一套口径走。
 */
public record BabyResponse(Long id, String name, String gender,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate birthDate,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal birthHeight,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal birthWeight, String remark, String photoUrl,
		boolean archived, String ageText) {

}
