package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.BabyVaccineRecord;

/**
 * baby_vaccine_record 不在租户白名单内（§5.2），family_id 条件由拦截器注入。
 */
@Mapper
public interface BabyVaccineRecordMapper extends BaseMapper<BabyVaccineRecord> {

	/**
	 * 覆盖一条接种记录的可变列。
	 * <p>
	 * 不能用 {@code BaseMapper#updateById}——它默认忽略实体里的 null，而 {@code plan_id}（重新绑定后
	 * 匹配不到应种项时）、{@code clinic} / {@code batch_no} / {@code reaction} / {@code remark} 的
	 * 清空、{@code next_date}（该疫苗没有未完成剂次）都要能真的写成 NULL（§4.4.4）。
	 */
	int overwrite(@Param("record") BabyVaccineRecord record);

}
