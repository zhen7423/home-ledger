package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import cn.homeledger.common.AuthContext;

/**
 * 每请求解析登录态。user 与 family_member 都在租户白名单内，故本查询不受 family_id 注入影响。
 * 刻意不做 Redis 缓存：单家庭最多 5 人、两条主键/唯一索引命中的查询约 1ms，缓存换来的收益远小于
 * 「退出家庭 / 转让创建者 / 解散」三处失效点的维护成本与漏失效即越权的风险。
 * <p>
 * 自定义 SQL 外置于 resources/mapper/AuthContextMapper.xml（§6.4.2），本接口只保留签名与设计口径。
 */
@Mapper
public interface AuthContextMapper {

	AuthContext selectByUserId(@Param("userId") Long userId);

}
