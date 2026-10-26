package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.User;

/**
 * 自定义 SQL 外置于 resources/mapper/UserMapper.xml（§6.4.2），本接口只保留签名与设计口径。
 */
@Mapper
public interface UserMapper extends BaseMapper<User> {

	/**
	 * 锁住 user 行，用于串行化同一用户的「创建家庭 / 加入家庭」。
	 * <p>
	 * 「一个用户同一时间只属于一个家庭」无法用唯一索引表达：family_member 软删除的历史行会让
	 * (user_id) 或 (user_id, deleted) 在第二次退出时撞键。故改为事务内行锁 + 应用层校验。
	 * 必须在 @Transactional 方法内调用，否则锁立即释放、形同虚设。
	 * <p>
	 * 自定义 SQL 不经过 MyBatis-Plus 的逻辑删除改写，deleted = 0 必须手写。
	 */
	Long lockById(@Param("userId") Long userId);

}
