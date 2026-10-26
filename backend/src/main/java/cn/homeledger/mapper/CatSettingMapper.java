package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.CatSetting;

/**
 * cat_setting 不在租户白名单内（§5.2），family_id 条件由拦截器注入。
 * <p>
 * 它与 reminder_setting 长得像而归类不同：那张是用户级偏好，这张每家庭至多一行。
 */
@Mapper
public interface CatSettingMapper extends BaseMapper<CatSetting> {

	/**
	 * 保存设置：三栏连同 created_by 一次写全。
	 * <p>
	 * 不能用 {@code BaseMapper#updateById}——它默认忽略实体里的 null，于是「把预估日均改回空」这一笔
	 * 会静默留着旧数字，而那个数字还在参与余量推算的兜底。
	 */
	int overwrite(@Param("setting") CatSetting setting);

}
