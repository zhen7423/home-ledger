package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.CatDeworming;

/**
 * cat_deworming 不在租户白名单内（§5.2），family_id 条件由拦截器注入。
 */
@Mapper
public interface CatDewormingMapper extends BaseMapper<CatDeworming> {

	/**
	 * 「这只猫名下是否存在任何驱虫记录」的计数，<b>含已软删除的记录</b>，理由与
	 * {@link PaymentAccountMapper#countAnyTransaction} 相同：逻辑删除会把这部分行从自动生成的语句里滤掉。
	 * 归档与删除的判据用它（§4.3.1），漏掉软删行会让一条被删掉的记录不再阻止删猫。
	 */
	int countAnyForCat(@Param("familyId") Long familyId, @Param("catId") Long catId);

	/**
	 * 修改一条驱虫记录：整行覆盖，SET 里把每一个可改列都写出来。
	 * <p>
	 * 不能用 {@code BaseMapper#updateById}——它默认忽略实体里的 null，于是「把规格/剂量删掉」这种最正常的
	 * 操作会静默失效：界面上改成功了，刷新一下又回到原值（§4.3.3 的整份表单覆盖）。
	 */
	int overwrite(@Param("deworming") CatDeworming deworming);

}
