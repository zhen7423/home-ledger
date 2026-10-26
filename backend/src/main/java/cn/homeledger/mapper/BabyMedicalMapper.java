package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.BabyMedical;

/**
 * baby_medical 不在租户白名单内（§5.2），family_id 条件由拦截器注入。
 */
@Mapper
public interface BabyMedicalMapper extends BaseMapper<BabyMedical> {

	/**
	 * 覆盖一条就诊记录的可变列。
	 * <p>
	 * 不能用 {@code BaseMapper#updateById}——它默认忽略实体里的 null，而医院 / 科室 / 诊断 / 用药 /
	 * 费用 / 备注每一项都要能被清空（§4.4.5 的整份表单覆盖）。
	 */
	int overwrite(@Param("medical") BabyMedical medical);

}
