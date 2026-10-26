package cn.homeledger.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.ReminderSetting;

/**
 * reminder_setting 在租户白名单里（§5.2，S2 就预置了），拦截器不会替它补任何条件，
 * 所以本接口里每条语句的 user_id 条件是唯一的越权防线，不能省。
 */
@Mapper
public interface ReminderSettingMapper extends BaseMapper<ReminderSetting> {

	/**
	 * 取某用户已显式设置过的开关。
	 * <p>
	 * 没设置过的类型不在结果里，由 service 用枚举默认值补齐——不给每个新用户预插 7 行，
	 * 那样将来加第 8 个类型时存量用户就永远缺那一行。
	 */
	List<ReminderSetting> selectByUser(@Param("userId") Long userId);

}
