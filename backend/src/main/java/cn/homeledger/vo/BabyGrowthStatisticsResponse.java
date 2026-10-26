package cn.homeledger.vo;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonFormat;

/**
 * §4.4.6 宝宝统计的第一条：当前体格与增长情况。
 * <p>
 * 五个百分位档位与三档增量都在读取时算，不落库：口径与 §4.4.2 的「较上次」同源，都是「每天留一条代表行、
 * 按日期链做差」。改一条旧的测量记录，列表页的增量与这里的档位会一起变。
 * <p>
 * 不含生长曲线：曲线响应要带该性别该指标的标准表全量行（前端画百分位带用），并进这里会让 §5.4 的离线快照
 * 为一条曲线背一整张表。统计页要画曲线读的是同一条 {@code GET /baby-growths/curve}（§4.4.6）。
 */
public record BabyGrowthStatisticsResponse(List<BabyGrowthItem> perBaby) {

	/** {@code latest} 为空表示这个宝宝还没有任何一条身高体重记录，「当前体格」整张卡都没有内容可显示。 */
	public record BabyGrowthItem(Long babyId, String name, String ageText, BabyGrowthLatest latest,
			BabyGrowthWindows growth) {

	}

	/** 最新一天的代表行 + 五个指标各自的所处档位。 */
	public record BabyGrowthLatest(@JsonFormat(shape = JsonFormat.Shape.STRING) LocalDate measureDate,
			@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal heightCm,
			@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal weightKg,
			@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal headCm, BabyPercentileBands bands) {

	}

	/**
	 * 五个指标各自落在哪一档（§1.4 第 9 条）。某一档为空有两种原因：这一条没量那个量、或超出标准表覆盖范围
	 * （§4.4.3 不许就近取端点值）。界面两种都出「—」——用户能做的事都一样，要么补录一条，要么什么都不做。
	 */
	public record BabyPercentileBands(String height, String weight, String weightHeight, String bmi,
			String headCircumference) {

	}

	/** {@code sinceLast} 为空的唯一条件是这一条就是首条；后两条另有「窗口内不足两条代表行」这个条件。 */
	public record BabyGrowthWindows(BabyGrowthGain sinceLast, BabyGrowthGain last3Months,
			BabyGrowthGain last12Months) {

	}

	/** 三个数值各自可空：这一次或那一次没量那一项——「没量」与「没变」是两件事（§4.4.2）。 */
	public record BabyGrowthGain(int days, @JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal heightCm,
			@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal weightKg,
			@JsonFormat(shape = JsonFormat.Shape.STRING) BigDecimal headCm) {

	}

}
