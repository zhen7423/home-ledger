package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.Cat;

/**
 * cat 不在租户白名单内（§5.2），family_id 条件由拦截器注入。
 */
@Mapper
public interface CatMapper extends BaseMapper<Cat> {

	/**
	 * 编辑一份猫档案：整行覆盖，SET 里把每一个可改列都写出来。
	 * <p>
	 * 不能用 {@code BaseMapper#updateById}——它默认忽略实体里的 null，于是「把生日删掉」「把备注清空」
	 * 这两种最正常的操作会静默失效：界面上改成功了，刷新一下又回到原值（§4.3.1 的整份表单覆盖）。
	 */
	int overwrite(@Param("cat") Cat cat);

	/**
	 * 只改照片列。单独一条而不是塞进 {@code overwrite}：照片不是表单字段，走独立的上传/删除端点，
	 * 不该在「保存档案」时被一起覆盖（那时可能还没选新图，传 null 会把老照片悄悄抹掉）。
	 * 与 overwrite 同一条 null 语义——这里要的就是「传 null = 清掉照片」，必须写进 SET 而不是被忽略。
	 */
	int setPhotoUrl(@Param("id") Long id, @Param("photoUrl") String photoUrl);

}
