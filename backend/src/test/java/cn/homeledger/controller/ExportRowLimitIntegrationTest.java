package cn.homeledger.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;

import cn.homeledger.support.ApiTestBase;
import tools.jackson.databind.JsonNode;

/**
 * §4.2.7 的行数上限与分批读取。单独一个类：{@code @SpringBootTest} 的 properties 是类级注解，
 * 把它塞进 {@link ExportIntegrationTest} 会让那二十条全跑在 3 行上限下。
 * <p>
 * 子类不重抄 {@code @AutoConfigureMockMvc} 与 {@code @ActiveProfiles}：基类的那两个靠
 * {@code @Inherited} 的 TYPE_HIERARCHY 查找仍然生效，重抄只会让「改一处忘改另一处」多一个机会。
 * 代价是多一个 Spring 上下文，这是刻意的。
 */
@SpringBootTest(properties = { "homeledger.export.max-rows=3", "homeledger.export.batch-size=2" })
class ExportRowLimitIntegrationTest extends ApiTestBase {

	private static final String PHONE_A = "13800000001";

	@Test
	@DisplayName("验收用例 16：超过上限挡成 400，且响应体是 JSON 不是文件")
	void overTheRowLimitIsRejectedWith400() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		for (int i = 0; i < 4; i++) {
			record(owner, "10.0" + i);
		}

		BinaryCall call = export(owner);
		assertThat(call.status()).isEqualTo(HttpStatus.BAD_REQUEST.value());
		JsonNode body = objectMapper.readTree(new String(call.body(), StandardCharsets.UTF_8));
		assertThat(body.path("code").asText()).isEqualTo("BAD_REQUEST");
		assertThat(body.path("message").asText()).contains("4 笔").contains("3 笔").contains("缩小时间区间");
	}

	@Test
	@DisplayName("上限是「超过」而不是「达到」：正好 3 笔导得出去")
	void exactlyAtTheRowLimitIsAccepted() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		for (int i = 0; i < 3; i++) {
			record(owner, "10.0" + i);
		}
		assertThat(export(owner).status()).isEqualTo(200);
	}

	@Test
	@DisplayName("批大小 2 读 3 笔：最后那批不满的一行都不能少")
	void batchReadingDoesNotLoseRows() throws Exception {
		Account owner = registerWithFamily(PHONE_A, "张三");
		for (int i = 0; i < 3; i++) {
			record(owner, "10.00");
		}

		List<String> lines = csvLines(export(owner));
		assertThat(lines).as("表头 + 三行明细 + 汇总 + 末尾空串").hasSize(6);
		assertThat(lines.get(lines.size() - 2)).isEqualTo("合计,0.00,30.00,-30.00,,,,,,");
	}

	// ---- 请求辅助 ----

	private void record(Account owner, String amount) throws Exception {
		Call call = postJson(TRANSACTIONS,
				Map.of("amount", amount, "categoryId", topCategoryId(owner, "餐饮"), "accountId",
						paymentAccountId(owner, "现金"), "bizDate", "2026-01-10"),
				owner.accessToken());
		assertThat(call.code()).isEqualTo("OK");
	}

	private BinaryCall export(Account owner) throws Exception {
		return getBytes(EXPORT_TRANSACTIONS, Map.of("format", "csv"), owner.accessToken());
	}

	private List<String> csvLines(BinaryCall call) {
		String text = new String(call.body(), StandardCharsets.UTF_8);
		return List.of(text.substring(1).split("\r\n", -1));
	}

}
