package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.BabyMilestone;

/**
 * baby_milestone 不在租户白名单内（§5.2），family_id 条件由拦截器注入。
 */
@Mapper
public interface BabyMilestoneMapper extends BaseMapper<BabyMilestone> {

	/**
	 * 覆盖一条里程碑的可变列。
	 * <p>
	 * 不能用 {@code BaseMapper#updateById}——它默认忽略实体里的 null，而把描述清空是最正常的操作
	 * （§4.4.5 的整份表单覆盖）。
	 */
	int overwrite(@Param("milestone") BabyMilestone milestone);

}
