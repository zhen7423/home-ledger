package cn.homeledger.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.Category;

/**
 * category 不在租户白名单内（§5.2），自定义 SQL 里仍显式写 family_id 条件，与 S2 的
 * {@code FamilyMemberMapper} 保持同一写法——拦截器还会再注入一次，两处都漏不掉。
 * <p>
 * 只有必须绕开逻辑删除、或必须一次改多行的语句才写成自定义 SQL；同级查重、取整棵树这类
 * 用 {@code LambdaQueryWrapper} 就够的走 BaseMapper，交给 {@code @TableLogic} 自动补 deleted = 0。
 */
@Mapper
public interface CategoryMapper extends BaseMapper<Category> {

	/**
	 * 「该类别下是否存在任何流水」的计数，<b>含已软删除的流水</b>（§4.2.2、验收用例 8）。
	 * <p>
	 * XML 里刻意不写 deleted 条件，也不能改用 BaseMapper——逻辑删除会给自动生成的语句追加
	 * {@code deleted = 0}，那正好漏掉判定要的那部分行，把本该只能停用的类别误判为可物理删除。
	 * <p>
	 * 一个 categoryId 同时匹配 category_id 与 sub_category_id 两列即可覆盖大类与小类两种入参：
	 * 流水的大类恒记在 category_id、小类恒记在 sub_category_id，同一个 id 不会出现在两列里。
	 * 于是删大类时，它下面小类的流水也一起算进来了，不需要先捞子级 id。
	 */
	int countAnyTransaction(@Param("familyId") Long familyId, @Param("categoryId") Long categoryId);

	/**
	 * 已被占用的配色索引，用于给新建大类分配 color_index（§4.2.2 第 15 轮）。
	 * <p>
	 * <b>不传 type</b>：索引占用按家庭整体算。按收支类型各算一套的话，收入侧新建的类别会拿到
	 * restaurant、shopping_bag 这类支出意味的图标——图标与配色共用同一个下标。
	 */
	List<Integer> selectUsedColorIndexes(@Param("familyId") Long familyId);

	/** 大类停用时级联停用它下面的小类。重新启用大类不级联，所以这条只有停用方向会用（§4.2.2）。 */
	int cascadeDisable(@Param("familyId") Long familyId, @Param("parentId") Long parentId);

	/** 真删除。逻辑删除的表要物理删掉只有这一条路，写成 XML 是为了让评审一眼看到它。 */
	int deletePhysically(@Param("familyId") Long familyId, @Param("id") Long id);

}
