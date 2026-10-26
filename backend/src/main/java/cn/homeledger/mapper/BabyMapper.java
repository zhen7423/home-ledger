package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.Baby;

/**
 * baby 不在租户白名单内（§5.2），family_id 条件由拦截器注入。
 */
@Mapper
public interface BabyMapper extends BaseMapper<Baby> {

	/**
	 * 「这个宝宝名下是否有过任何录入记录」的计数——身高体重、接种记录、里程碑、就诊记录四张表之和，
	 * <b>含已软删除的行</b>，理由与 {@code CatDewormingMapper#countAnyForCat} 相同：逻辑删除会把这部分行
	 * 从自动生成的语句里滤掉，而删掉的记录曾经真实存在过，让它悬空与删猫的后果一样。
	 * <p>
	 * <b>不算 {@code baby_vaccine_plan}</b>：它是出生日期的派生数据、每个宝宝建完档就有 24 行，
	 * 算进去等于任何宝宝都删不掉。四张表合成一条语句而不是各写一个计数，是因为调用方问的是同一个问题。
	 */
	int countUserRecords(@Param("familyId") Long familyId, @Param("babyId") Long babyId);

	/**
	 * 编辑一份宝宝档案：整行覆盖，SET 里把每一个可改列都写出来。
	 * <p>
	 * 不能用 {@code BaseMapper#updateById}——它默认忽略实体里的 null，于是「把出生身高删掉」
	 * 「把备注清空」这两种最正常的操作会静默失效：界面上改成功了，刷新一下又回到原值（§4.4.1）。
	 */
	int overwrite(@Param("baby") Baby baby);

	/**
	 * 只改照片列，语义同 {@code CatMapper#setPhotoUrl}：照片走独立端点，不进整份表单覆盖。
	 */
	int setPhotoUrl(@Param("id") Long id, @Param("photoUrl") String photoUrl);

}
