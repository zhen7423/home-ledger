package cn.homeledger.common;

import java.util.List;

/**
 * 预置收支字典与图标色板（§4.2.2）。
 * <p>
 * 刻意不带任何 Spring 注解：建家庭时装预置字典（{@code PresetFinanceDictService.install}）与
 * 后续新建大类时取色（{@code CategoryServiceImpl}）都读这一份定义，拆成两处就会分叉。
 */
public final class PresetFinanceDict {

	public record PresetCategory(String name, String iconKey, int colorIndex, List<String> children) {
	}

	/** 11 大类 / 58 小类，逐字取自 §4.2.2 的支出表。 */
	public static final List<PresetCategory> EXPENSE = List.of(
			new PresetCategory("餐饮", "restaurant", 0, List.of("早餐", "午餐", "晚餐", "外卖", "零食饮料", "食材采购")),
			new PresetCategory("交通", "directions_bus", 1, List.of("公共交通", "打车", "加油", "停车费", "保养维修", "洗车")),
			new PresetCategory("购物", "shopping_bag", 2, List.of("服饰鞋包", "日用百货", "数码家电", "美妆个护", "家居家具")),
			new PresetCategory("居住", "home", 3, List.of("房租", "房贷", "水费", "电费", "燃气费", "物业宽带")),
			new PresetCategory("医疗", "local_hospital", 4,
					List.of("门诊挂号", "药品", "检查化验", "住院", "保健营养", "牙科眼科")),
			new PresetCategory("教育", "school", 5, List.of("学费", "书本教材", "培训辅导", "考试认证", "文具耗材")),
			new PresetCategory("娱乐", "sports_esports", 6, List.of("电影演出", "旅游度假", "运动健身", "游戏充值", "会员订阅")),
			new PresetCategory("宠物", "pets", 7, List.of("主粮", "零食罐头", "驱虫疫苗", "宠物医疗", "用品玩具", "洗美寄养")),
			new PresetCategory("宝宝", "child_care", 8, List.of("奶粉辅食", "纸尿裤", "婴童服饰", "玩具绘本", "疫苗医疗", "托育教育")),
			new PresetCategory("人情往来", "redeem", 9, List.of("红包", "礼物", "请客吃饭", "孝敬长辈")),
			new PresetCategory("其他", "more_horiz", 10, List.of("手续费", "无法归类", "临时支出")));

	/** 6 大类 / 20 小类，逐字取自 §4.2.2 的收入表。 */
	public static final List<PresetCategory> INCOME = List.of(
			new PresetCategory("工资", "payments", 11, List.of("基本工资", "绩效奖金", "补贴津贴", "加班费")),
			new PresetCategory("奖金", "emoji_events", 12, List.of("年终奖", "项目奖", "季度奖")),
			new PresetCategory("理财收益", "trending_up", 13, List.of("存款利息", "基金收益", "股票收益", "房租收入")),
			new PresetCategory("兼职", "work_outline", 14, List.of("接活外包", "家教", "劳务报酬")),
			new PresetCategory("红包礼金", "card_giftcard", 15, List.of("收到红包", "收到礼金", "节日红包")),
			new PresetCategory("其他", "more_horiz", 16, List.of("退款", "报销", "其他收入")));

	/** 顺序即 sort_no（从 1 起），现金排首位并作为默认项。 */
	public static final List<String> PAYMENT_ACCOUNTS = List.of("现金", "微信", "支付宝", "储蓄卡", "信用卡", "花呗白条", "公司账户",
			"其他");

	public static final String DEFAULT_PAYMENT_ACCOUNT = "现金";

	/**
	 * 下标即 color_index。0–16 已被上面的预置类别占用，17–23 留给自定义大类（§4.2.2 第 15 轮）。
	 * 索引 10 与 16 同为 more_horiz，分别是支出与收入的「其他」——分配按索引算而非按 icon_key 去重。
	 */
	public static final List<String> ICON_POOL = List.of("restaurant", "directions_bus", "shopping_bag", "home",
			"local_hospital", "school", "sports_esports", "pets", "child_care", "redeem", "more_horiz", "payments",
			"emoji_events", "trending_up", "work_outline", "card_giftcard", "more_horiz", "flight", "fitness_center",
			"palette", "build", "local_cafe", "savings", "category");

	/** 取值范围必须与图标池一致，故直接由它推导，避免两处各写一个字面量。 */
	public static final int PALETTE_SIZE = ICON_POOL.size();

	private PresetFinanceDict() {
	}

}
