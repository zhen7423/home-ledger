package cn.homeledger.migration;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import com.baomidou.mybatisplus.core.toolkit.IdWorker;

/**
 * 把两份内置字典的 CSV 装进 vaccine_schedule_dict 与 growth_standard_dict（§4.4.3）。CSV 在
 * {@code resources/db/data/} 下，逐条转录自官方 PDF，改数据要连 CSV 一起改。
 * <p>
 * 类名里的 {@code V1_1} 由 BaseJavaMigration 的构造器从 simple name 解析成版本 1.1，紧跟在
 * V1 全量建库之后：它是建库的附属播种，不参与后续版本序列。
 * <p>
 * 三条硬约束：
 * <ul>
 * <li>只能用原生 JDBC。注入 Mapper 会形成 flywayInitializer ↔ sqlSessionTemplate 的循环依赖——
 * MyBatis 的数据源要等 Flyway 跑完，Flyway 又要等 Mapper 就绪。</li>
 * <li>雪花 ID 只能在这里生成（§7.2、A13）。这也是它必须是 Java 迁移而不是 V1 里的 INSERT 的原因，
 * SQL 脚本算不出雪花 ID。绕过租户拦截器这一点在这里不构成风险：两张表都是 §5.2 白名单里的静态字典，
 * 本来就不带 family_id。</li>
 * <li>必须幂等。它每次启动都可能被再次评估，两张表分开判，将来只补其中一张时另一张不会重复装。</li>
 * </ul>
 */
@Component
public class V1_1__SeedBabyDictionaries extends BaseJavaMigration {

	private static final Logger log = LoggerFactory.getLogger(V1_1__SeedBabyDictionaries.class);

	private static final String VACCINE_CSV = "db/data/vaccine-schedule-2026.csv";

	private static final String GROWTH_CSV = "db/data/growth-standard-ws423-2022.csv";

	private static final String VACCINE_TABLE = "vaccine_schedule_dict";

	private static final String GROWTH_TABLE = "growth_standard_dict";

	private static final String VACCINE_SOURCE_VERSION = "2026";

	private static final String GROWTH_STANDARD_SOURCE = "WS/T 423-2022";

	private static final String GROWTH_SOURCE_VERSION = "2022";

	private static final int BATCH_SIZE = 200;

	private static final String INSERT_VACCINE = "INSERT INTO vaccine_schedule_dict"
			+ " (id, vaccine_name, disease, dose_no, due_age_months, remark, source_version)"
			+ " VALUES (?, ?, ?, ?, ?, ?, ?)";

	private static final String INSERT_GROWTH = "INSERT INTO growth_standard_dict"
			+ " (id, standard_source, source_version, gender, metric, x_value, p3, p10, p25, p50, p75, p90, p97)"
			+ " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

	@Override
	public void migrate(Context context) throws Exception {
		// 连接归 Flyway 的事务管，这里不关
		Connection connection = context.getConnection();

		if (countOf(connection, VACCINE_TABLE) == 0) {
			log.info("免疫规划疫苗字典装入 {} 行", seedVaccines(connection));
		}
		if (countOf(connection, GROWTH_TABLE) == 0) {
			log.info("生长标准字典装入 {} 行", seedGrowth(connection));
		}
	}

	private static long countOf(Connection connection, String table) throws Exception {
		try (Statement statement = connection.createStatement();
				ResultSet row = statement.executeQuery("SELECT COUNT(*) FROM " + table)) {
			return row.next() ? row.getLong(1) : 0L;
		}
	}

	private static int seedVaccines(Connection connection) throws Exception {
		List<String[]> rows = readCsv(VACCINE_CSV, 5);
		int inserted = 0;
		try (PreparedStatement statement = connection.prepareStatement(INSERT_VACCINE)) {
			for (String[] row : rows) {
				statement.setLong(1, IdWorker.getId());
				statement.setString(2, row[0]);
				statement.setString(3, row[1]);
				statement.setString(4, row[2]);
				statement.setInt(5, Integer.parseInt(row[3]));
				statement.setString(6, row[4].isEmpty() ? null : row[4]);
				statement.setString(7, VACCINE_SOURCE_VERSION);
				statement.addBatch();
				inserted++;
				if (inserted % BATCH_SIZE == 0) {
					statement.executeBatch();
				}
			}
			statement.executeBatch();
		}
		return inserted;
	}

	private static int seedGrowth(Connection connection) throws Exception {
		List<String[]> rows = readCsv(GROWTH_CSV, 10);
		int inserted = 0;
		try (PreparedStatement statement = connection.prepareStatement(INSERT_GROWTH)) {
			for (String[] row : rows) {
				statement.setLong(1, IdWorker.getId());
				statement.setString(2, GROWTH_STANDARD_SOURCE);
				statement.setString(3, GROWTH_SOURCE_VERSION);
				statement.setString(4, row[0]);
				statement.setString(5, row[1]);
				statement.setBigDecimal(6, new BigDecimal(row[2]));
				// 七档百分位在 CSV 里紧跟在 x_value 后面，顺序与 INSERT 的占位符一致
				for (int i = 0; i < 7; i++) {
					statement.setBigDecimal(7 + i, new BigDecimal(row[3 + i]));
				}
				statement.addBatch();
				inserted++;
				if (inserted % BATCH_SIZE == 0) {
					statement.executeBatch();
				}
			}
			statement.executeBatch();
		}
		return inserted;
	}

	/**
	 * 读类路径下的 CSV：跳过 {@code #} 注释行、空行与表头，要求列数正好等于 {@code columns}。
	 * 用 {@code split(",", -1)}——{@code remark} 是选填列，末尾空列靠它才留得住。
	 */
	private static List<String[]> readCsv(String path, int columns) throws Exception {
		List<String[]> rows = new ArrayList<>();
		try (InputStream in = new ClassPathResource(path).getInputStream();
				BufferedReader reader = new BufferedReader(new InputStreamReader(in, StandardCharsets.UTF_8))) {
			String line;
			int lineNo = 0;
			boolean header = true;
			while ((line = reader.readLine()) != null) {
				lineNo++;
				if (line.isBlank() || line.startsWith("#")) {
					continue;
				}
				if (header) {
					header = false;
					continue;
				}
				String[] cells = line.split(",", -1);
				if (cells.length != columns) {
					throw new IllegalStateException(path + " 第 " + lineNo + " 行有 " + cells.length + " 列，期望 "
							+ columns + " 列：" + line);
				}
				rows.add(cells);
			}
		}
		return rows;
	}

}
