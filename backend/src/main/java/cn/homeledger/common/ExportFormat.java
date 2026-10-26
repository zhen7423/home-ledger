package cn.homeledger.common;

/**
 * 导出的两种格式（§4.2.7）。放 {@code common} 与 {@link BudgetLevel} 同理：它是口径本身，
 * 不是某个接口的出参形状，前端要按同一套取值决定扩展名与 MIME。
 */
public enum ExportFormat {

	XLSX("xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
	CSV("csv", "text/csv;charset=UTF-8");

	private final String extension;

	private final String contentType;

	ExportFormat(String extension, String contentType) {
		this.extension = extension;
		this.contentType = contentType;
	}

	public String extension() {
		return this.extension;
	}

	public String contentType() {
		return this.contentType;
	}

	/**
	 * 查询串上的 {@code format} 取值。大小写不敏感（前端可能传 XLSX），认不出来就是 400 而不是
	 * 静默回落成 xlsx——静默回落会让「我明明选了 CSV 怎么下来个 Excel」变成一条查不出来的工单。
	 */
	public static ExportFormat fromParam(String value) {
		if (value != null) {
			for (ExportFormat format : values()) {
				if (format.name().equalsIgnoreCase(value.trim())) {
					return format;
				}
			}
		}
		throw new BizException(ErrorCode.BAD_REQUEST, "导出格式只有 xlsx 与 csv 两种");
	}

}
