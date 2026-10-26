package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import cn.homeledger.common.BabyAge;
import cn.homeledger.common.BabyDisclaimers;
import cn.homeledger.config.TimeConfig;
import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.4.3 生长曲线：选表、横轴、档位判定与「取不到值就跳过」四种边界。
 * <p>
 * 验收用例 29 的机器版。标准表不内联进测试（546 行不许出现在测试文件里，§3.13），
 * 断言一律落在「行数」「横轴首末值」「某个具体点的档位」这三类不随表内容变化的东西上，
 * 唯一读库的一处是为了拿一个确定的 P50 当真值——曲线要判的是「等于某档时归到哪一段」，
 * 拿一个自己编的数当输入就测不出这条口径。
 */
class BabyCurveIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	private static final String PHONE_B = "13800000002";

	private static final LocalDate TODAY = LocalDate.now(TimeConfig.ZONE);

	@Test
	@DisplayName("标准表整份下发：该性别该指标的全量行，行数与横轴范围都对")
	void curveReturnsWholeStandardTable() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(30).toString());
		String token = owner.accessToken();

		assertThat(curveOf(token, babyId, "HEIGHT").path("standard")).as("HEIGHT_AGE 44 行").hasSize(44);
		assertThat(curveOf(token, babyId, "WEIGHT").path("standard")).hasSize(44);
		assertThat(curveOf(token, babyId, "BMI").path("standard")).hasSize(44);
		assertThat(curveOf(token, babyId, "HEAD_CIRCUMFERENCE").path("standard")).as("头围表 0–36 月共 29 行")
			.hasSize(29);
		JsonNode weightHeight = curveOf(token, babyId, "WEIGHT_HEIGHT");
		assertThat(weightHeight.path("standard")).as("WEIGHT_HEIGHT 56 行").hasSize(56);
		assertThat(weightHeight.path("standard").get(0).path("xValue").decimalValue()).as("横轴升序，首行是 75.0 cm")
			.isEqualByComparingTo("75.0");
		assertThat(weightHeight.path("standard").get(55).path("xValue").decimalValue()).isEqualByComparingTo("130.0");
	}

	@Test
	@DisplayName("体重别身高按今天月龄选表，24 月是分界")
	void standardMetricSwitchesAt24Months() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		long underTwo = createBaby(token, "小满", "MALE", TODAY.minusMonths(23).toString());
		long overTwo = createBaby(token, "阿圆", "MALE", TODAY.minusMonths(24).toString());

		JsonNode youngCurve = curveOf(token, underTwo, "WEIGHT_HEIGHT");
		JsonNode oldCurve = curveOf(token, overTwo, "WEIGHT_HEIGHT");

		assertThat(youngCurve.path("metric").asText()).as("用户选的那一个原样回显").isEqualTo("WEIGHT_HEIGHT");
		assertThat(youngCurve.path("standardMetric").asText()).isEqualTo("WEIGHT_LENGTH");
		assertThat(oldCurve.path("standardMetric").asText()).isEqualTo("WEIGHT_HEIGHT");
		assertThat(youngCurve.path("standard").get(0).path("xValue").decimalValue())
			.as("身长别体重的横轴从 45 cm 起")
			.isEqualByComparingTo("45.0");
		assertThat(oldCurve.path("standard").get(0).path("xValue").decimalValue()).as("身高别体重从 75 cm 起")
			.isEqualByComparingTo("75.0");
	}

	@Test
	@DisplayName("等于 P50 的点落在 P50–P75 这一段，不是 P25–P50")
	void pointBandInP50ToP75() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		String token = owner.accessToken();
		LocalDate birthDate = TODAY.minusMonths(12);
		long babyId = createBaby(token, "小满", "MALE", birthDate.toString());
		// 拿表里那一行的 p50 当真值：自己编一个数就测不出「等于某档时归到哪一段」
		int ageMonths = BabyAge.monthsBetween(birthDate, TODAY);
		BigDecimal p50 = this.jdbcTemplate.queryForObject(
				"SELECT p50 FROM growth_standard_dict WHERE gender = ? AND metric = ? AND x_value = ?", BigDecimal.class,
				"MALE", "HEIGHT_AGE", BigDecimal.valueOf(ageMonths).setScale(1));
		assertThat(p50).as("该月龄那一行要在标准表里").isNotNull();
		postGrowth(token, babyId, TODAY.toString(), p50.toPlainString(), null, null);

		JsonNode point = curveOf(token, babyId, "HEIGHT").path("points").get(0);

		assertThat(point.path("measured").decimalValue()).isEqualByComparingTo(p50);
		assertThat(point.path("percentileBand").asText()).isEqualTo("P50–P75");
		assertThat(point.path("ageMonths").asInt()).isEqualTo(ageMonths);
	}

	@Test
	@DisplayName("超出标准表上界的点照常返回，档位为空")
	void bandNullWhenAboveTable() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(82).toString());
		postGrowth(owner.accessToken(), babyId, TODAY.toString(), "110.0", null, null);

		JsonNode points = curveOf(owner.accessToken(), babyId, "HEIGHT").path("points");

		assertThat(points).as("省掉这个点会让曲线莫名断一段").hasSize(1);
		assertThat(points.get(0).path("measured").decimalValue()).isEqualByComparingTo("110.0");
		assertThat(points.get(0).path("percentileBand").isNull()).as("82 月超出 0–81 月的表").isTrue();
	}

	@Test
	@DisplayName("头围表到 36 月为止，37 月的点没有档位")
	void headCircumferenceTableEndsAt36Months() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(37).toString());
		// 头围必须跟身高或体重同一条：§4.4.2 不接受只量头围的一行（§3.4）
		postGrowth(owner.accessToken(), babyId, TODAY.toString(), "95.0", "14.00", "48.0");

		JsonNode data = curveOf(owner.accessToken(), babyId, "HEAD_CIRCUMFERENCE");

		assertThat(data.path("standard")).as("头围表是六张里最短的一张").hasSize(29);
		assertThat(data.path("points")).hasSize(1);
		assertThat(data.path("points").get(0).path("xValue").decimalValue()).as("年龄别指标的横轴是月龄")
			.isEqualByComparingTo("37");
		assertThat(data.path("points").get(0).path("percentileBand").isNull()).isTrue();
	}

	@Test
	@DisplayName("低于标准表下界的点照常返回，档位为空")
	void bandNullWhenBelowTable() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(30).toString());
		postGrowth(owner.accessToken(), babyId, TODAY.toString(), "60.0", "6.00", null);

		JsonNode point = curveOf(owner.accessToken(), babyId, "WEIGHT_HEIGHT").path("points").get(0);

		assertThat(point.path("xValue").decimalValue()).as("两个源表的横轴在 75–100 cm 之间重叠，选错表就会给出错档").isEqualByComparingTo("60.0");
		assertThat(point.path("percentileBand").isNull()).as("60 cm 低于身高别体重的 75 cm 起点").isTrue();
	}

	@Test
	@DisplayName("同一天的多条只画 id 最大的那条")
	void sameDayOnlyMaxIdPlotted() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(12).toString());
		createGrowth(owner.accessToken(), babyId, TODAY.toString(), "70.0", null);
		createGrowth(owner.accessToken(), babyId, TODAY.toString(), "71.0", null);

		JsonNode points = curveOf(owner.accessToken(), babyId, "HEIGHT").path("points");

		assertThat(points).as("与列表页的代表行是同一条记录").hasSize(1);
		assertThat(points.get(0).path("measured").decimalValue()).isEqualByComparingTo("71.0");
	}

	@Test
	@DisplayName("体重别身高的横轴是身高 cm，纵轴是体重，月龄照旧给")
	void xValueIsHeightCmForWeightHeight() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(30).toString());
		postGrowth(owner.accessToken(), babyId, TODAY.toString(), "90.0", "12.00", null);

		JsonNode point = curveOf(owner.accessToken(), babyId, "WEIGHT_HEIGHT").path("points").get(0);

		assertThat(point.path("xValue").decimalValue()).isEqualByComparingTo("90.0");
		assertThat(point.path("measured").decimalValue()).as("纵轴是体重").isEqualByComparingTo("12.00");
		assertThat(point.path("ageMonths").asInt()).as("横轴是 cm 也照样给月龄，点详情要显示它").isEqualTo(30);
	}

	@Test
	@DisplayName("点按测量日期升序")
	void pointsAscendingByDate() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(6).toString());
		String token = owner.accessToken();
		createGrowth(token, babyId, TODAY.minusDays(10).toString(), "65.0", null);
		createGrowth(token, babyId, TODAY.minusDays(30).toString(), "63.0", null);
		createGrowth(token, babyId, TODAY.minusDays(20).toString(), "64.0", null);

		JsonNode points = curveOf(token, babyId, "HEIGHT").path("points");

		assertThat(datesOf(points)).containsExactly(TODAY.minusDays(30).toString(), TODAY.minusDays(20).toString(),
				TODAY.minusDays(10).toString());
	}

	@Test
	@DisplayName("零个点与一个点都照常返回，不报错")
	void lessThanTwoPointsStillReturns() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(6).toString());

		JsonNode withoutPoints = curveOf(owner.accessToken(), babyId, "HEIGHT");
		assertThat(withoutPoints.path("points")).isEmpty();
		assertThat(withoutPoints.path("standard")).as("没有实测点不影响标准表").hasSize(44);

		createGrowth(owner.accessToken(), babyId, TODAY.toString(), "66.0", null);

		JsonNode onePoint = curveOf(owner.accessToken(), babyId, "HEIGHT");
		assertThat(onePoint.path("points")).as("一个点是前端不画折线，不是端点报错").hasSize(1);
		assertThat(onePoint.path("points").get(0).path("percentileBand").asText()).isNotBlank();
	}

	@Test
	@DisplayName("BMI 由身高体重现算")
	void bmiComputedFromHeightAndWeight() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(12).toString());
		postGrowth(owner.accessToken(), babyId, TODAY.toString(), "100.0", "15.00", null);

		JsonNode point = curveOf(owner.accessToken(), babyId, "BMI").path("points").get(0);

		assertThat(point.path("measured").decimalValue()).as("15 / 1.00²").isEqualByComparingTo("15.00");
		assertThat(point.path("xValue").decimalValue()).isEqualByComparingTo("12");
		assertThat(point.path("percentileBand").asText()).isNotBlank();
	}

	@Test
	@DisplayName("缺身高或体重的行对 BMI 来说整条没有值，直接跳过")
	void bmiPointSkippedWhenWeightMissing() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(12).toString());
		createGrowth(owner.accessToken(), babyId, TODAY.toString(), "75.0", null);

		assertThat(curveOf(owner.accessToken(), babyId, "BMI").path("points")).as("算不出来就不画这个点，不留空点").isEmpty();
		assertThat(curveOf(owner.accessToken(), babyId, "HEIGHT").path("points")).as("同一行的身高照样成点").hasSize(1);
	}

	@Test
	@DisplayName("响应带免责声明；metric 不传时按 HEIGHT")
	void disclaimerPresent() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(12).toString());

		JsonNode data = curveOf(owner.accessToken(), babyId, null);

		assertThat(data.path("disclaimer").asText()).isEqualTo(BabyDisclaimers.STANDARD);
		assertThat(data.path("babyId").asLong()).isEqualTo(babyId);
		assertThat(data.path("metric").asText()).as("缺省由服务端定").isEqualTo("HEIGHT");
		assertThat(data.path("standardMetric").asText()).isEqualTo("HEIGHT");
	}

	@Test
	@DisplayName("非法 metric 直接 400，不静默降级成空曲线")
	void invalidMetricRejected() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		long babyId = createBaby(owner.accessToken(), "小满", "MALE", TODAY.minusMonths(12).toString());

		Call call = getJson(BABY_GROWTH_CURVE, Map.of("babyId", String.valueOf(babyId), "metric", "BOGUS"),
				owner.accessToken());

		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		assertThat(call.code()).isEqualTo("BAD_REQUEST");
		assertThat(call.message()).contains("不支持的生长指标");
	}

	@Test
	@DisplayName("别的家庭的宝宝取不到曲线")
	void crossFamilyCurveRejected() throws Exception {
		Account ownerA = registerWithFamily(PHONE_A, "张三");
		long babyA = createBaby(ownerA.accessToken(), "小满", "MALE", TODAY.minusMonths(12).toString());
		Account ownerB = registerWithFamily(PHONE_B, "李四");

		Call call = getJson(BABY_GROWTH_CURVE, Map.of("babyId", String.valueOf(babyA)), ownerB.accessToken());

		assertThat(call.status()).isEqualTo(HttpStatus.NOT_FOUND.value());
		assertThat(call.code()).isEqualTo("RESOURCE_NOT_FOUND");
	}

	private JsonNode curveOf(String token, long babyId, String metric) throws Exception {
		Map<String, String> params = new LinkedHashMap<>();
		params.put("babyId", String.valueOf(babyId));
		if (metric != null) {
			params.put("metric", metric);
		}
		Call call = getJson(BABY_GROWTH_CURVE, params, token);
		assertThat(call.code()).isEqualTo("OK");
		return call.data();
	}

	private Call postGrowth(String token, long babyId, String measureDate, String heightCm, String weightKg,
			String headCm) throws Exception {
		Map<String, Object> body = new LinkedHashMap<>();
		body.put("babyId", babyId);
		body.put("measureDate", measureDate);
		body.put("heightCm", heightCm);
		body.put("weightKg", weightKg);
		body.put("headCm", headCm);
		body.values().removeIf(Objects::isNull);
		return postJson(BABY_GROWTHS, body, token);
	}

	private static List<String> datesOf(JsonNode points) {
		List<String> dates = new ArrayList<>();
		points.forEach(point -> dates.add(point.path("measureDate").asText()));
		return dates;
	}

}
