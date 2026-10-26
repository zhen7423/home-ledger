package cn.homeledger.common;

/**
 * §4.5.1 的八类提醒。
 * <p>
 * 八类都已接线：预算两档在 S4，猫咪三档在 S6，疫苗与成长记录待补在 S7/S8，奶粉见底在第 32 轮。
 * 提前把这些定全，是为了让 reminder_setting 的列宽与前端的开关列表不必每阶段改一次。
 * <p>
 * pushed 在本项目里恒等于「会不会发本地通知」——没有远程推送，也不会有（§1.2）。
 * <p>
 * module 是「这一类属于哪个模块」，给客户端的 Tab 角标用（§4.5.2）：那张映射表只有一处，
 * 加提醒类型时改这里一行，而不是改多个前端文件。
 */
public enum ReminderType {

	CAT_DEWORMING_INTERNAL("猫咪体内驱虫到期", ModuleKey.CAT, true, true),
	CAT_DEWORMING_EXTERNAL("猫咪体外驱虫到期", ModuleKey.CAT, true, true),
	CAT_FOOD_LOW("猫粮即将见底", ModuleKey.CAT, true, true),
	VACCINE_UPCOMING("疫苗接种即将到期", ModuleKey.BABY, true, true),
	/** 发通知，但是立即发（fireAt 为空、走 show），不是定时通知——§10 用例 13 要求超支当天能收到一条通知。 */
	BUDGET_OVERRUN("预算已超支", ModuleKey.FINANCE, true, true),
	/** 默认关：一到 80% 就发通知太吵，这正是它只在 App 内出红点、不进通知栏的原因。 */
	BUDGET_WARNING("预算即将超支", ModuleKey.FINANCE, false, false),
	GROWTH_RECORD_DUE("宝宝成长记录待补", ModuleKey.BABY, true, false),
	/** 奶粉见底：与 CAT_FOOD_LOW 同类的「此刻状态」提醒，触发判定见 ReminderServiceImpl。 */
	BABY_FORMULA_LOW("奶粉即将见底", ModuleKey.BABY, true, true);

	private final String label;

	private final ModuleKey module;

	private final boolean defaultEnabled;

	private final boolean pushed;

	ReminderType(String label, ModuleKey module, boolean defaultEnabled, boolean pushed) {
		this.label = label;
		this.module = module;
		this.defaultEnabled = defaultEnabled;
		this.pushed = pushed;
	}

	public String label() {
		return this.label;
	}

	public ModuleKey module() {
		return this.module;
	}

	public boolean defaultEnabled() {
		return this.defaultEnabled;
	}

	public boolean pushed() {
		return this.pushed;
	}

	/** 库里存了不认识的类型时返回 null 而不是抛异常：老版本 App 写进去的新类型，不该让整个设置页 500。 */
	public static ReminderType of(String name) {
		for (ReminderType type : values()) {
			if (type.name().equals(name)) {
				return type;
			}
		}
		return null;
	}

}
