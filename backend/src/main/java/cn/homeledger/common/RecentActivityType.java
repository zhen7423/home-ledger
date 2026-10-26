package cn.homeledger.common;

/**
 * 首页最近动态能出现的八类记录（§4.6 第 6 条）。
 * <p>
 * 与 {@code ReminderType.module()} 同一条理由：模块归属只有一处定义，客户端按 {@code module} 挑图标，
 * 加记录类型时改这里一行，而不是改前端。
 * <p>
 * 流水只算「记了一笔」，不含编辑与删除：动态是「这个家最近发生了什么」，一条流水被改过三次
 * 不该在动态里出现三次。
 */
public enum RecentActivityType {

	TRANSACTION(ModuleKey.FINANCE),
	CAT_FOOD_BAG(ModuleKey.CAT),
	CAT_DEWORMING(ModuleKey.CAT),
	BABY_GROWTH(ModuleKey.BABY),
	BABY_VACCINE(ModuleKey.BABY),
	BABY_MILESTONE(ModuleKey.BABY),
	BABY_MEDICAL(ModuleKey.BABY),
	/** 第 32 轮：奶粉开罐属于宝宝模块，与猫粮开袋同构（§4.5.3）。 */
	BABY_FORMULA_BAG(ModuleKey.BABY);

	private final ModuleKey module;

	RecentActivityType(ModuleKey module) {
		this.module = module;
	}

	public ModuleKey module() {
		return this.module;
	}

}
