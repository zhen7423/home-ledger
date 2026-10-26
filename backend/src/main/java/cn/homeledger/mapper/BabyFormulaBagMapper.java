package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.BabyFormulaBag;

/**
 * baby_formula_bag 不在租户白名单内（§5.2），family_id 条件由拦截器注入。
 */
@Mapper
public interface BabyFormulaBagMapper extends BaseMapper<BabyFormulaBag> {

	/**
	 * 修改一罐奶粉：整行覆盖，SET 里把每一个可改列都写出来。
	 * <p>
	 * 不能用 {@code BaseMapper#updateById}——它默认忽略实体里的 null，于是「把预估日均删掉、备注清空」
	 * 这类动作会静默失效：界面上改成功了，刷新一下又回到原值（§4.5.3 的整份表单覆盖）。
	 */
	int overwrite(@Param("bag") BabyFormulaBag bag);

}