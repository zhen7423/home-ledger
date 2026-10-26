package cn.homeledger.mapper;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;

import cn.homeledger.dto.TransactionQueryRequest;
import cn.homeledger.entity.Transaction;
import cn.homeledger.vo.MonthSummary;

/**
 * transaction 不在租户白名单内（§5.2）。表名是 MySQL 的非保留关键字，裸表名可用，
 * 已由 {@code FamilyTenantHandlerTest} 逐形态钉住拦截器能正确改写。
 */
@Mapper
public interface TransactionMapper extends BaseMapper<Transaction> {

	/**
	 * 分页 + 多条件筛选。方法名不叫 {@code selectPage}——BaseMapper 已经注入了同名语句，
	 * 重名会让容器启动时报 Mapped Statements collection already contains value。
	 */
	IPage<Transaction> selectFilteredPage(IPage<Transaction> page, @Param("q") TransactionQueryRequest query,
			@Param("familyId") Long familyId);

	/**
	 * 月度小计，供流水列表按月分组时显示每组的收入 / 支出 / 结余（§4.2.5、§8）。
	 * <p>
	 * 必须按<b>同一套筛选条件的全量结果</b>聚合而不是当前页：单页 30 条跨月时，客户端拿不到
	 * 整月合计。所以它与 {@code selectFilteredPage} 共用同一个 {@code filters} 片段——
	 * 两处各写一份迟早会不一样，而数字对不上是极难查的那类 bug。
	 * <p>
	 * 结余用带符号的同一组 CASE 一次算出（收入为正、支出为负），这样它与 income / expense
	 * 三个数由同一次扫描得到，不会出现「明细对得上、结差错 0.01」。
	 */
	List<MonthSummary> selectMonthSummaries(@Param("q") TransactionQueryRequest query,
			@Param("familyId") Long familyId);

	/**
	 * 编辑一笔流水：整行覆盖，SET 里把每一个可改列都写出来。
	 * <p>
	 * 不能用 {@code BaseMapper#updateById}——它默认忽略实体里的 null，于是「把小类清空」「把备注删干净」
	 * 这两种最正常的操作会静默失效：界面上改成功了，刷新一下又回到原值。
	 */
	int overwrite(@Param("t") Transaction transaction);

	/**
	 * 区间内的支出合计，家庭总预算的已用额度（§4.2.4）。
	 * <p>
	 * 只算 EXPENSE：预算是「花钱的额度」，把收入抵进去会让「这个月花超了没有」变成「这个月挣了多少」，
	 * 两个问题口径完全不同。
	 */
	BigDecimal sumExpenseInRange(@Param("familyId") Long familyId, @Param("from") LocalDate from,
			@Param("to") LocalDate to);

	/**
	 * 区间支出按大类聚合，给 CATEGORY 维度的预算用。
	 * <p>
	 * GROUP BY 只按 {@code category_id}：流水的大类恒记在这一列，填没填小类都不影响，所以
	 * 「小类留空也算进所属大类」是这条 SQL 天然的性质，不需要任何额外处理。
	 * <b>不要</b>再带上 {@code sub_category_id}——那会把同一个大类的钱拆成几份，进度条永远对不上。
	 */
	List<CategorySpend> sumExpenseByCategory(@Param("familyId") Long familyId, @Param("from") LocalDate from,
			@Param("to") LocalDate to);

	/** 区间支出按记录人聚合，给 MEMBER 维度的预算用。成员口径按 {@code created_by}（A5）。 */
	List<MemberSpend> sumExpenseByCreator(@Param("familyId") Long familyId, @Param("from") LocalDate from,
			@Param("to") LocalDate to);

	/**
	 * 区间内「有记录的天数」，首页家庭信息条那一格（§4.6 第 1 条）。
	 * <p>
	 * 同一天记多笔只算一天：那一格说的是「这个月记了几天账」。用 {@code COUNT(DISTINCT biz_date)}
	 * 而不是把 {@code sumFiltered} 的 count 拿来用——后者是笔数，两件事。
	 */
	int countRecordedDays(@Param("familyId") Long familyId, @Param("from") LocalDate from,
			@Param("to") LocalDate to);

	/**
	 * 区间概览的一行合计（§4.2.6 概览卡片）。
	 * <p>
	 * minBizDate 是给「两个日期都不传」用的：此时区间起点就是家里第一笔流水的日期。没有任何行时它是 null，
	 * SUM 也全为 null，所以三个求和都包了 COALESCE——漏了它会让 BigDecimal 字段是 null，
	 * 后面第一次 compareTo 就 NPE，而那发生在用户刚建好家庭、一笔流水都还没有的时候。
	 */
	Totals sumFiltered(@Param("q") TransactionQueryRequest query, @Param("familyId") Long familyId);

	/**
	 * 支出按「大类 + 小类」两级分组（§4.2.6 类别占比与其下钻）。
	 * <p>
	 * 一次查两级而不查两次：Top 8 大类的下钻数据要跟着概览一起返回（§8 的 categoryBreakdown 每项内联
	 * subCategories），分两次查就是 1 + 8 条 SQL，而两级分组的行数上限不过是字典的 24 项。
	 * 大类合计在服务端把小类加起来，不再单独 GROUP BY category_id 一次——两次分组各算一遍总额，
	 * 万一某天口径改了只改了一处，饼图的总数就会与下钻的总数对不上。
	 * <p>
	 * sub_category_id 为 NULL 是一个<b>合法的分组</b>，代表该大类下没被细分的金额，服务端渲染成「未细分」。
	 */
	List<CategorySubSpend> sumExpenseByCategoryAndSubCategoryFiltered(@Param("q") TransactionQueryRequest query,
			@Param("familyId") Long familyId);

	/** 支出按支付方式分组（§4.2.6 支付方式占比）。不做 Top N 截断，一个家庭的支付方式本就有限。 */
	List<AccountSpend> sumExpenseByAccountFiltered(@Param("q") TransactionQueryRequest query,
			@Param("familyId") Long familyId);

	/** 支出按业务日期分组（§4.2.6 区间内每日支出）。没有支出的日子不会出现在结果里，补 0 由服务端做。 */
	List<DailySpend> sumExpenseByDayFiltered(@Param("q") TransactionQueryRequest query,
			@Param("familyId") Long familyId);

	/**
	 * 支出按「记录人 + 大类」分组（§4.2.6 成员支出对比）。
	 * <p>
	 * 带上大类是为了「按大类并排对比」那个视图：各成员的合计能由这份结果直接加出来，不必再查一次。
	 * <b>不做 Top N 截断</b>，理由见 B5。
	 */
	List<MemberCategorySpend> sumExpenseByMemberCategoryFiltered(@Param("q") TransactionQueryRequest query,
			@Param("familyId") Long familyId);

	/**
	 * 导出用的分批读取（§4.2.7）。
	 * <p>
	 * <b>不能复用 {@link #selectFilteredPage}</b>：那条走 {@code PaginationInnerInterceptor}，
	 * 而拦截器上配了 {@code setMaxLimit(200L)}（{@code MybatisPlusConfig}），传 size=2000 会被静默钳到 200，
	 * 于是「5 万行的导出」实际只出 200 行还不报错。这里的 LIMIT 是手写的，不经过分页拦截器。
	 * <p>
	 * 排序是<b>升序</b>（列表页是降序）：导出给的是台账，台账从早往晚读（§4.2.7）。
	 * 次级键带上 id，理由与 selectFilteredPage 相同——同一天多笔时 MySQL 不保证稳定顺序，
	 * 分批读取会因为顺序漂移而漏行或重复行。
	 */
	List<Transaction> selectForExport(@Param("q") TransactionQueryRequest query, @Param("familyId") Long familyId,
			@Param("offset") int offset, @Param("limit") int limit);

	/**
	 * GROUP BY 的结果行。组件名必须与 SQL 里的列别名逐字相同——映射靠的是构造器参数名，
	 * 别名写成 {@code category_id} 会得到一个字段全是 null 的对象而不报错。
	 * <p>
	 * 嵌在本接口而不是 {@code vo/}：它们不出接口，只是 SQL 的形状。
	 */
	record CategorySpend(Long categoryId, BigDecimal amount) {

	}

	/** 同 {@link CategorySpend}，按记录人聚合。 */
	record MemberSpend(Long createdBy, BigDecimal amount) {

	}

	/** 大类 + 小类两级分组的投影。subCategoryId 为 null 表示该大类下未细分的部分。 */
	record CategorySubSpend(Long categoryId, Long subCategoryId, BigDecimal amount) {

	}

	record AccountSpend(Long accountId, BigDecimal amount) {

	}

	record DailySpend(LocalDate bizDate, BigDecimal amount) {

	}

	record MemberCategorySpend(Long createdBy, Long categoryId, BigDecimal amount) {

	}

	/**
	 * 区间合计。days 不在这里算——它取决于「两个日期都不传」时如何补齐区间，那是服务端的口径（见 B5），
	 * SQL 只负责给出它唯一知道的那部分：家里第一笔流水的日期。
	 */
	record Totals(BigDecimal income, BigDecimal expense, long count, LocalDate minBizDate) {

	}

}
