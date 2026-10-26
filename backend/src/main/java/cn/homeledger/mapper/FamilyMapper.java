package cn.homeledger.mapper;

import java.time.LocalDateTime;
import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.Family;

/**
 * family 在租户白名单内（§5.2）。自定义 SQL 不经过 MyBatis-Plus 的逻辑删除改写，deleted = 0 必须手写。
 * <p>
 * 自定义 SQL 外置于 resources/mapper/FamilyMapper.xml（§6.4.2），本接口只保留签名与设计口径。
 */
@Mapper
public interface FamilyMapper extends BaseMapper<Family> {

	/**
	 * 按邀请码取「邀请入口开着、未解散且过期时间最晚」的那一个家庭。
	 * <p>
	 * 第 33 轮起只有开着的邀请才会带码，故限定 invite_enabled = 1：关掉的码已经清空，
	 * 只剩「开着但过期」的码还留在表里等 consumeInvite 或 disableInvite 处理。
	 * 过期码不会被清除，因此同一个码值可能同时挂在多个家庭上（旧的已过期、新签发的仍有效）——
	 * §4.1.4 的唯一性只约束「未过期码」这个子集。按过期时间倒序取第一条即可判定：
	 * 若最新的一条都已过期，则同码的其余条目必然也都过期。
	 */
	Family findLatestByInviteCode(@Param("inviteCode") String inviteCode);

	/**
	 * 统计当前仍在有效期内的邀请码数量，用于签发新码时的全局唯一性查重（§4.1.4）。
	 * <p>
	 * 残留竞态：两个家庭在同一瞬间创建且随机取到同一个码时，双方查重都会通过。概率约为
	 * 「并发创建数 × 10^-6」，§4.1.4 已就此明确接受（成员上限 5 人、码 24 小时过期，同时在用的码极少），
	 * 故不为它引入间隙锁或分布式锁。
	 */
	long countUnexpiredByInviteCode(@Param("inviteCode") String inviteCode);

	/**
	 * 一次性使用邀请码（第 33 轮）：条件 UPDATE 把入口关掉并清空码与失效时间。
	 * 返回 0 表示邀请早已被并发消费或已关闭——join 据此回 INVITE_CODE_NOT_FOUND，
	 * 用行锁天然串行化同一码的两个并发加入者，只有一人能拿到 1。
	 */
	int consumeInvite(@Param("id") Long id, @Param("inviteCode") String inviteCode);

	/**
	 * 关闭邀请入口（第 33 轮）：条件 UPDATE 清空码与失效时间。返回 0 表示家庭已解散，
	 * 调用方应把它当作入口不存在处理。
	 */
	int disableInvite(@Param("id") Long id);

	/**
	 * 解散：逻辑删除并记下解散时刻（§4.1.6）。deleted_at 是 30 天物理删除的起点，
	 * 单独的语句而不是 {@code deleteById}——后者只会置 deleted = 1，补不出时间戳。
	 */
	int markDissolved(@Param("id") Long id);

	/**
	 * 已解散且超过保留期的家庭。物理清除任务跨家庭扫描用（§4.1.6 的 S10 部分）；
	 * family 本就在租户白名单里，拦截器不会注入条件，等价于全表扫描，批次限制由 LIMIT 挡。
	 */
	List<Long> selectDissolvedBefore(@Param("cutoff") LocalDateTime cutoff);

}
