package cn.homeledger.vo;

import java.util.List;

/**
 * 类别树节点（§4.2.2）。大类带 children，小类的 children 恒为空列表而不是 null——
 * 前端渲染时无需判空。
 * <p>
 * 树在 Service 里一次查全表后按 parentId 分组组装，不用递归 SQL：一个家庭最多 17 + 78 行，
 * 递归换来的只是每次展开都要回库。
 */
public record CategoryNode(Long id, String type, String name, String iconKey, Integer colorIndex, int sortNo,
		boolean enabled, boolean preset, List<CategoryNode> children) {

	public static CategoryNode of(CategoryResponse source, List<CategoryNode> children) {
		return new CategoryNode(source.id(), source.type(), source.name(), source.iconKey(), source.colorIndex(),
				source.sortNo(), source.enabled(), source.preset(), children);
	}

}
