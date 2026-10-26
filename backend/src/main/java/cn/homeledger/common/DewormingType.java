package cn.homeledger.common;

/**
 * 内驱 / 外驱（§4.3.3）。库里落 {@code name()}，与 {@link ReminderType} 的存法一致。
 * <p>
 * 一个类型对应一个提醒类型是这张表的真正作用：CAT_DEWORMING_INTERNAL / CAT_DEWORMING_EXTERNAL 是两个
 * 各自可关的开关（§4.5.1），所以「内驱记录该看哪个开关」必须有一处定义。放在这里而不是在 Service 里写两遍
 * if，是因为驱虫完成度与待提醒项要问的是同一个问题。
 */
public enum DewormingType {

	INTERNAL("内驱", ReminderType.CAT_DEWORMING_INTERNAL),
	EXTERNAL("外驱", ReminderType.CAT_DEWORMING_EXTERNAL);

	private final String label;

	private final ReminderType reminderType;

	DewormingType(String label, ReminderType reminderType) {
		this.label = label;
		this.reminderType = reminderType;
	}

	public String label() {
		return this.label;
	}

	public ReminderType reminderType() {
		return this.reminderType;
	}

	/** 该类型读 cat_setting 的哪一列月数。 */
	public int monthsOf(int internalMonths, int externalMonths) {
		return this == INTERNAL ? internalMonths : externalMonths;
	}

	/** 库里存了不认识的值时返回 null 而不是抛异常，口径同 {@link ReminderType#of}。 */
	public static DewormingType of(String name) {
		for (DewormingType type : values()) {
			if (type.name().equals(name)) {
				return type;
			}
		}
		return null;
	}

}
