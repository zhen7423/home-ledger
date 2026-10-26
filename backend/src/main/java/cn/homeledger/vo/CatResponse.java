package cn.homeledger.vo;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * 一只猫的档案（§4.3.1）。
 * <p>
 * archived 是 enabled 取反后的语义字段：库里那一列叫 enabled 是「还参与新记录吗」，
 * 界面要说的是「这只已经归档了」，让前端去写 {@code !enabled} 等于把这句翻译复制六遍。
 * <p>
 * createdAt 参与「应做次数」的起点计算（§4.3.5），所以它必须出到接口上，不只是审计字段。
 */
public record CatResponse(Long id, String name, String gender,
		@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate birthday, boolean birthdayEstimated, String breed,
		@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal weightKg, String neutered, String remark,
		String photoUrl, boolean archived, LocalDateTime createdAt) {

}
