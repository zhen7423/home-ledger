package cn.homeledger.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

/**
 * 内置免疫规划疫苗程序表的一行（§4.4.4）。
 * <p>
 * 静态字典：没有 family_id（跨家庭共享）、没有 created_by / created_at / updated_at（没有录入人，
 * 出处由 {@link #sourceVersion} 表达）、没有 deleted（不软删，故本类也没有 {@link com.baomidou.mybatisplus.annotation.TableLogic}）。
 * <p>
 * 本表必须在 FamilyTenantHandler 的租户白名单里：给它注入 family_id 会直接 SQL 报错，
 * 于是整张程序表在任何请求里都读不出来。它的行由 Java 迁移 1.1 用原生 JDBC 播种，运行期只读。
 */
@TableName("vaccine_schedule_dict")
public class VaccineScheduleDict {

	@TableId
	private Long id;

	private String vaccineName;

	private String disease;

	private String doseNo;

	private Integer dueAgeMonths;

	private String remark;

	private String sourceVersion;

	public Long getId() {
		return this.id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getVaccineName() {
		return this.vaccineName;
	}

	public void setVaccineName(String vaccineName) {
		this.vaccineName = vaccineName;
	}

	public String getDisease() {
		return this.disease;
	}

	public void setDisease(String disease) {
		this.disease = disease;
	}

	public String getDoseNo() {
		return this.doseNo;
	}

	public void setDoseNo(String doseNo) {
		this.doseNo = doseNo;
	}

	public Integer getDueAgeMonths() {
		return this.dueAgeMonths;
	}

	public void setDueAgeMonths(Integer dueAgeMonths) {
		this.dueAgeMonths = dueAgeMonths;
	}

	public String getRemark() {
		return this.remark;
	}

	public void setRemark(String remark) {
		this.remark = remark;
	}

	public String getSourceVersion() {
		return this.sourceVersion;
	}

	public void setSourceVersion(String sourceVersion) {
		this.sourceVersion = sourceVersion;
	}

}
