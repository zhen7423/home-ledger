package cn.homeledger.entity;

import java.math.BigDecimal;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 生长标准百分位表的一行（WS/T 423—2022 附录 A 转录，§4.4.3）。
 * <p>
 * xValue 一列承担两种横轴：四个年龄别指标存月龄，WEIGHT_LENGTH 存身长 cm、WEIGHT_HEIGHT 存身高 cm。
 * 拆成两列会有「写错的那一半不报错、只算出与表毫无关系的百分位」这条路径（§7.1）。
 * <p>
 * 静态字典：没有 family_id、没有四个通用列、没有 deleted，理由同 {@link VaccineScheduleDict}。
 * 七档是国标档位，来源只用 WS/T 423、不再接受 WHO——WHO 只覆盖 0–5 岁，5–7 岁那三年补不满横轴。
 */
@TableName("growth_standard_dict")
public class GrowthStandardDict {

	@TableId
	private Long id;

	private String standardSource;

	private String sourceVersion;

	private String gender;

	private String metric;

	private BigDecimal xValue;

	private BigDecimal p3;

	private BigDecimal p10;

	private BigDecimal p25;

	private BigDecimal p50;

	private BigDecimal p75;

	private BigDecimal p90;

	private BigDecimal p97;

	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getStandardSource() {
		return this.standardSource;
	}

	public void setStandardSource(String standardSource) {
		this.standardSource = standardSource;
	}

	public String getSourceVersion() {
		return this.sourceVersion;
	}

	public void setSourceVersion(String sourceVersion) {
		this.sourceVersion = sourceVersion;
	}

	public String getGender() {
		return this.gender;
	}

	public void setGender(String gender) {
		this.gender = gender;
	}

	public String getMetric() {
		return this.metric;
	}

	public void setMetric(String metric) {
		this.metric = metric;
	}

	public BigDecimal getXValue() {
		return this.xValue;
	}

	public void setXValue(BigDecimal xValue) {
		this.xValue = xValue;
	}

	public BigDecimal getP3() {
		return this.p3;
	}

	public void setP3(BigDecimal p3) {
		this.p3 = p3;
	}

	public BigDecimal getP10() {
		return this.p10;
	}

	public void setP10(BigDecimal p10) {
		this.p10 = p10;
	}

	public BigDecimal getP25() {
		return this.p25;
	}

	public void setP25(BigDecimal p25) {
		this.p25 = p25;
	}

	public BigDecimal getP50() {
		return this.p50;
	}

	public void setP50(BigDecimal p50) {
		this.p50 = p50;
	}

	public BigDecimal getP75() {
		return this.p75;
	}

	public void setP75(BigDecimal p75) {
		this.p75 = p75;
	}

	public BigDecimal getP90() {
		return this.p90;
	}

	public void setP90(BigDecimal p90) {
		this.p90 = p90;
	}

	public BigDecimal getP97() {
		return this.p97;
	}

	public void setP97(BigDecimal p97) {
		this.p97 = p97;
	}

}
