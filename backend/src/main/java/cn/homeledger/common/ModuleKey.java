package cn.homeledger.common;

/**
 * §3.2 的三个可关闭模块。它们既是底部 Tab 的候选，也是首页各区块的显示开关。
 * <p>
 * 记账在最前、宝宝在中间、猫咪在最后是<b>默认顺序</b>（问题单 8：猫咪 Tab 挪到宝宝 Tab 后面），
 * 与 §3.2 那句「按启用情况动态填充」同源；用户拖拽过之后以库里的 {@code sort_no} 为准。
 * <p>
 * 三项默认全开：App 装上就该是完整的，把某个模块关掉是用户的主动选择，不是出厂状态。
 * <p>
 * 首页与设置这两个固定项不在这里：它们不可关闭、不可移动（§3.2），进来了就得在每个「是不是最后一个」
 * 的判断里特殊处理一次。
 */
public enum ModuleKey {

	FINANCE("记账"),
	BABY("宝宝"),
	CAT("猫咪");

	private final String label;

	ModuleKey(String label) {
		this.label = label;
	}

	public String label() {
		return this.label;
	}

	/** 未显式设置过的模块按枚举声明顺序排。 */
	public int defaultSortNo() {
		return ordinal();
	}

	/** 库里存了不认识的模块时返回 null 而不是抛异常：老版本 App 写进去的新模块，不该让整个设置页 500。 */
	public static ModuleKey of(String name) {
		for (ModuleKey key : values()) {
			if (key.name().equals(name)) {
				return key;
			}
		}
		return null;
	}

}
