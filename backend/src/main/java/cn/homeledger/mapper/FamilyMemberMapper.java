package cn.homeledger.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.FamilyMember;
import cn.homeledger.vo.MemberResponse;

/**
 * family_member 在租户白名单内（§5.2），本 Mapper 的每条语句都必须显式带上 family_id 或 user_id 条件。
 * 自定义 SQL 不经过 MyBatis-Plus 的逻辑删除改写，deleted 条件一律手写。
 * <p>
 * 自定义 SQL 外置于 resources/mapper/FamilyMemberMapper.xml（§6.4.2），本接口只保留签名与设计口径。
 */
@Mapper
public interface FamilyMemberMapper extends BaseMapper<FamilyMember> {

	/**
	 * §4.1.5：在籍成员显示实时昵称，用户已注销（LEFT JOIN 落空）时回落到快照，保证列表里不会出现空白记录人。
	 * 列别名须与 MemberResponse 的组件名一致，配合 arg-name-based-constructor-auto-mapping 直接投影成 record。
	 */
	List<MemberResponse> selectMembers(@Param("familyId") Long familyId);

	/**
	 * 成员支出对比要的名字（§4.2.6）。与 {@link #selectMembers} 的区别只有一个：<b>不带 fm.deleted = 0</b>。
	 * <p>
	 * 退出成员记的流水还在家庭账上，把他们从图里剔掉会让「各成员支出合计」与「类别占比的支出合计」对不上
	 * （验收用例 15 明确要核这一条）。退出成员的名字只能取 nickname_snapshot，因为 user 表可能已查不到。
	 * <p>
	 * uk_member_family_user (family_id, user_id) 对软删除行同样生效，revive 是复活原行而不是新插一行，
	 * 所以一个 user_id 在本家庭至多一行，不加 deleted 条件也不会查出重复。
	 */
	List<MemberName> selectAllNamesIncludingLeft(@Param("familyId") Long familyId);

	/** 在籍成员取实时昵称（user 查不到时回落快照），已退出成员一律取快照——那是退出时刻冻结的名字。 */
	record MemberName(Long userId, String nickname) {

	}

	/**
	 * 退出 / 被移除：先把昵称快照刷新为当时的实时昵称，再置 deleted = 1。
	 * 用 JOIN 一次写完，避免「先读昵称、再写快照」两步之间用户改名导致快照与退出时刻不一致。
	 */
	int markLeft(@Param("familyId") Long familyId, @Param("userId") Long userId);

	/** 解散家庭：全体成员一次性按上述口径落快照并置 deleted = 1，保住 30 天窗口内的可恢复性（§4.1.6）。 */
	int markAllLeft(@Param("familyId") Long familyId);

	/**
	 * 重新加入同一家庭时复活原软删除行，而不是新插一行——uk_member_family_user (family_id, user_id)
	 * 对软删除的历史行同样生效，新插会直接撞唯一键。返回 0 表示没有可复活的行，调用方转为 INSERT。
	 */
	int revive(@Param("familyId") Long familyId, @Param("userId") Long userId, @Param("role") String role,
			@Param("nicknameSnapshot") String nicknameSnapshot);

}
