package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.BabyGrowth;

/**
 * baby_growth 不在租户白名单内（§5.2），family_id 条件由拦截器注入。
 */
@Mapper
public interface BabyGrowthMapper extends BaseMapper<BabyGrowth> {

	/**
	 * 修改一条身高体重记录：整行覆盖，SET 里把每一个可改列都写出来。
	 * <p>
	 * 不能用 {@code BaseMapper#updateById}——它默认忽略实体里的 null，于是「把头围删掉」「把备注清空」
	 * 会静默失效：界面上改成功了，刷新一下又回到原值（§4.4.2 的整份表单覆盖）。
	 */
	int overwrite(@Param("growth") BabyGrowth growth);

}
