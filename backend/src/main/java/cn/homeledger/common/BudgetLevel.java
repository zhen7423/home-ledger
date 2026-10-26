package cn.homeledger.common;

/**
 * 预算执行档位（§4.2.4）。放 {@code common} 而不是 {@code vo}：它是判定口径本身，前端要按同一套阈值
 * 上色，摆进 vo 会让人以为它只是某个接口的出参形状。
 */
public enum BudgetLevel {

	/** 没到预警线 */
	NORMAL,

	/** 到了 80% 但还没超 */
	WARNING,

	/** 已超支 */
	EXCEEDED

}
