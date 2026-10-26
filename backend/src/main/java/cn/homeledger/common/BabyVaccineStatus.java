package cn.homeledger.common;

/**
 * 应种项的落库状态，只有四态（§4.4.4）。「待接种 / 即将接种 / 逾期」由 due_date 与今天现场算，
 * 不落库——落库就得每天批量回写，跨天后库里还是旧值（见 {@link BabyVaccineDisplay}）。
 * <p>
 * 落库值只在这里出现一次：散落的字符串字面量会在改口径时漏改一处，而这一处的值是写进
 * {@code baby_vaccine_plan.status} 的。
 */
public enum BabyVaccineStatus {

	PENDING, DONE, SKIPPED, NA;

	/** 库里存了不认识的值说明数据被改坏了，不是可忽略的情形。 */
	public static BabyVaccineStatus of(String raw) {
		for (BabyVaccineStatus status : values()) {
			if (status.name().equals(raw)) {
				return status;
			}
		}
		throw new BizException(ErrorCode.BAD_REQUEST, "未知的应种项状态：" + raw);
	}

	/** SKIPPED / NA：用户手动标记过的行，不计入完成率分母，也不被接种记录自动回写覆盖（§4.4.4）。 */
	public boolean marked() {
		return this == SKIPPED || this == NA;
	}

}
