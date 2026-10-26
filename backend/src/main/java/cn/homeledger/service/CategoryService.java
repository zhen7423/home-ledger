package cn.homeledger.service;

import java.util.List;

import cn.homeledger.dto.CategoryCreateRequest;
import cn.homeledger.dto.CategoryRenameRequest;
import cn.homeledger.dto.CategorySortRequest;
import cn.homeledger.vo.CategoryNode;
import cn.homeledger.vo.CategoryResponse;

/**
 * §4.2.2 两级收支类别字典。
 * <p>
 * 与 {@link FamilyService} 用 userId 回查当前家庭不同，这里直接用登录态里的 familyId：category 不在
 * 租户白名单内（§5.2），拦截器已给每条 SQL 注入了 family_id 条件，服务层再显式带上它，是为了让
 * 「改到别人家的类别」落到明确的 404，而不是靠拦截器把语句改成必然落空的形式。
 * <p>
 * 数据全家共享，任何在籍成员都能增删改（§4.1.5），所以这里没有一处按 userId 做权限判断。
 */
public interface CategoryService {

	/**
	 * 类别树。type 为空时收支两棵一起返回；enabledOnly=true 只给启用中的节点，供记账表单的选择器用，
	 * false 给类别管理页用——停用的类别也得看得见，不然再也启用不回来。
	 */
	List<CategoryNode> tree(String type, boolean enabledOnly);

	/** 新建类别。parentId 为空建大类并分配图标与配色，非空则挂在该大类下建小类。 */
	CategoryResponse create(Long userId, CategoryCreateRequest request);

	/** 改名。收支类型与父级不可改；不回溯历史流水里已冻结的名称快照（A3）。 */
	CategoryResponse rename(Long userId, Long id, CategoryRenameRequest request);

	/** 启用 / 停用互切。停用大类会级联停用其下小类，重新启用大类不自动启用小类（§4.2.2）。 */
	CategoryResponse toggle(Long userId, Long id);

	/**
	 * 物理删除。预置类别、下面还有小类、或名下有任何流水（含已软删除）时一律拒绝，只能停用。
	 */
	void delete(Long userId, Long id);

	/** 拖拽排序：orderedIds 必须给全同一层的每一行，sort_no 按新顺序重写为 1…n。 */
	void sort(Long userId, CategorySortRequest request);

}
