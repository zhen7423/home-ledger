package cn.homeledger.vo;

/**
 * 单个类别。扁平结构，供新增 / 改名 / 停用的返回值用；列表页要的是树，见 {@link CategoryNode}。
 */
public record CategoryResponse(Long id, String type, Long parentId, String name, String iconKey, Integer colorIndex,
		int sortNo, boolean enabled, boolean preset) {

}
