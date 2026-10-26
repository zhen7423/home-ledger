package cn.homeledger.service.impl;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.PresetFinanceDict;
import cn.homeledger.dto.CategoryCreateRequest;
import cn.homeledger.dto.CategoryRenameRequest;
import cn.homeledger.dto.CategorySortRequest;
import cn.homeledger.entity.Category;
import cn.homeledger.mapper.CategoryMapper;
import cn.homeledger.mapper.RecurringRuleMapper;
import cn.homeledger.service.CategoryService;
import cn.homeledger.vo.CategoryNode;
import cn.homeledger.vo.CategoryResponse;

/**
 * §4.2.2 两级收支类别字典。
 * <p>
 * 一个家庭的类别从 17 + 78 行起步，自定义再多也不过百，所以树、查重、取号一律一次查全再在内存里算，
 * 两级树不值得上递归查询。
 */
@Service
public class CategoryServiceImpl implements CategoryService {

	/** §4.2.2：大类名 ≤ 6、小类名 ≤ 8。这种按层级分叉的长度限制注解表达不了，只能在服务层判。 */
	private static final int TOP_NAME_MAX = 6;

	private static final int SUB_NAME_MAX = 8;

	private static final Logger log = LoggerFactory.getLogger(CategoryServiceImpl.class);

	private final CategoryMapper categoryMapper;

	private final RecurringRuleMapper recurringRuleMapper;

	public CategoryServiceImpl(CategoryMapper categoryMapper, RecurringRuleMapper recurringRuleMapper) {
		this.categoryMapper = categoryMapper;
		this.recurringRuleMapper = recurringRuleMapper;
	}

	@Override
	public List<CategoryNode> tree(String type, boolean enabledOnly) {
		List<Category> rows = this.categoryMapper.selectList(familyScope(currentFamilyId(), type)
			.eq(enabledOnly, Category::getEnabled, 1)
			.orderByAsc(Category::getSortNo)
			.orderByAsc(Category::getId));
		// 查询已按 sort_no 排好，分组时保持遇见顺序，父子两层的兄弟序就都是对的
		Map<Long, List<CategoryNode>> childrenByParent = new LinkedHashMap<>();
		for (Category row : rows) {
			if (row.getParentId() != null) {
				childrenByParent.computeIfAbsent(row.getParentId(), key -> new ArrayList<>())
					.add(toNode(row, List.of()));
			}
		}
		return rows.stream()
			.filter(row -> row.getParentId() == null)
			.map(row -> toNode(row, childrenByParent.getOrDefault(row.getId(), List.of())))
			.toList();
	}

	@Override
	@Transactional
	public CategoryResponse create(Long userId, CategoryCreateRequest request) {
		Long familyId = currentFamilyId();
		String type = request.type();
		Long parentId = request.parentId();
		String name = request.name().trim();
		assertNameLength(name, parentId);
		requireParent(familyId, type, parentId);
		assertNameFree(familyId, type, parentId, name, null);

		Category category = new Category();
		category.setFamilyId(familyId);
		category.setParentId(parentId);
		category.setType(type);
		category.setName(name);
		if (parentId == null) {
			int colorIndex = nextColorIndex(familyId);
			category.setColorIndex(colorIndex);
			category.setIconKey(PresetFinanceDict.ICON_POOL.get(colorIndex));
		}
		category.setSortNo(nextSortNo(familyId, type, parentId));
		category.setEnabled(1);
		category.setIsPreset(0);
		category.setCreatedBy(userId);
		this.categoryMapper.insert(category);
		log.info("新建类别 familyId={} categoryId={} type={} operatorUserId={}", familyId, category.getId(), type,
				userId);
		return toResponse(category);
	}

	@Override
	@Transactional
	public CategoryResponse rename(Long userId, Long id, CategoryRenameRequest request) {
		Long familyId = currentFamilyId();
		Category category = requireCategory(familyId, id);
		String name = request.name().trim();
		assertNameLength(name, category.getParentId());
		assertNameFree(familyId, category.getType(), category.getParentId(), name, id);
		category.setName(name);
		this.categoryMapper.updateById(category);
		log.info("类别改名 familyId={} categoryId={} operatorUserId={}", familyId, id, userId);
		return toResponse(category);
	}

	@Override
	@Transactional
	public CategoryResponse toggle(Long userId, Long id) {
		Long familyId = currentFamilyId();
		Category category = requireCategory(familyId, id);
		boolean enable = category.getEnabled() != 1;
		// 停用方向才检查：被规则引用的类别一停，规则下次生成流水时就会指向一个记账时选不到的类别
		if (!enable && this.recurringRuleMapper.countByCategory(familyId, id) > 0) {
			throw new BizException(ErrorCode.CATEGORY_USED_BY_RECURRING_RULE);
		}
		category.setEnabled(enable ? 1 : 0);
		this.categoryMapper.updateById(category);
		// 只有停用方向级联（§4.2.2）：启用大类时顺手点亮小类，等于替用户恢复他自己特意关掉的东西
		if (!enable && category.getParentId() == null) {
			this.categoryMapper.cascadeDisable(familyId, id);
		}
		log.info("类别启停 familyId={} categoryId={} enabled={} operatorUserId={}", familyId, id, category.getEnabled(),
				userId);
		return toResponse(category);
	}

	@Override
	@Transactional
	public void delete(Long userId, Long id) {
		Long familyId = currentFamilyId();
		Category category = requireCategory(familyId, id);
		if (category.getIsPreset() == 1) {
			throw new BizException(ErrorCode.CATEGORY_PRESET_UNDELETABLE);
		}
		Long childCount = this.categoryMapper.selectCount(familyScope(familyId, category.getType())
			.eq(Category::getParentId, id));
		if (childCount != null && childCount > 0) {
			throw new BizException(ErrorCode.CATEGORY_HAS_CHILDREN);
		}
		if (this.categoryMapper.countAnyTransaction(familyId, id) > 0) {
			throw new BizException(ErrorCode.CATEGORY_HAS_TRANSACTIONS);
		}
		// 类别是物理删除的，规则里的 category_id 会直接悬空；一条还没跑过的规则也不会有流水，挡不住上面那关
		if (this.recurringRuleMapper.countByCategory(familyId, id) > 0) {
			throw new BizException(ErrorCode.CATEGORY_USED_BY_RECURRING_RULE);
		}
		this.categoryMapper.deletePhysically(familyId, id);
		log.info("删除类别 familyId={} categoryId={} name={} operatorUserId={}", familyId, id, category.getName(), userId);
	}

	@Override
	@Transactional
	public void sort(Long userId, CategorySortRequest request) {
		Long familyId = currentFamilyId();
		Set<Long> submitted = new HashSet<>(request.orderedIds());
		Set<Long> actual = this.categoryMapper
			.selectList(siblingScope(familyId, request.type(), request.parentId()))
			.stream()
			.map(Category::getId)
			.collect(Collectors.toSet());
		// 必须给全同一层的每一行：只传一部分会把传到的那几行挤成 1…n，与没传到的行撞号。
		// 比集合相等而不是比长度，顺带挡住列表里重复的 id。
		if (!submitted.equals(actual)) {
			throw new BizException(ErrorCode.SORT_IDS_MISMATCH);
		}
		int sortNo = 1;
		for (Long id : request.orderedIds()) {
			Category update = new Category();
			update.setId(id);
			update.setSortNo(sortNo++);
			this.categoryMapper.updateById(update);
		}
		log.info("类别排序 familyId={} type={} parentId={} 条数={} operatorUserId={}", familyId, request.type(),
				request.parentId(), actual.size(), userId);
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	private Category requireCategory(Long familyId, Long id) {
		Category category = this.categoryMapper
			.selectOne(new LambdaQueryWrapper<Category>().eq(Category::getId, id).eq(Category::getFamilyId, familyId));
		if (category == null) {
			throw new BizException(ErrorCode.CATEGORY_NOT_FOUND);
		}
		return category;
	}

	private void requireParent(Long familyId, String type, Long parentId) {
		if (parentId == null) {
			return;
		}
		Category parent = requireCategory(familyId, parentId);
		if (parent.getParentId() != null) {
			throw new BizException(ErrorCode.CATEGORY_DEPTH_EXCEEDED);
		}
		if (!parent.getType().equals(type)) {
			throw new BizException(ErrorCode.CATEGORY_PARENT_MISMATCH);
		}
		if (parent.getEnabled() != 1) {
			throw new BizException(ErrorCode.CATEGORY_PARENT_DISABLED);
		}
	}

	private void assertNameLength(String name, Long parentId) {
		if (name.length() > (parentId == null ? TOP_NAME_MAX : SUB_NAME_MAX)) {
			throw new BizException(ErrorCode.CATEGORY_NAME_TOO_LONG);
		}
	}

	/**
	 * 同级内查重，excludeId 供改名时排除自己。名称比较交给 MySQL 做：utf8mb4_0900_ai_ci 本就大小写
	 * 不敏感，在 Java 里再转一次小写只会多出一处和数据库口径不一致的比较逻辑。
	 */
	private void assertNameFree(Long familyId, String type, Long parentId, String name, Long excludeId) {
		Long duplicated = this.categoryMapper
			.selectCount(siblingScope(familyId, type, parentId).eq(Category::getName, name)
				.ne(excludeId != null, Category::getId, excludeId));
		if (duplicated != null && duplicated > 0) {
			throw new BizException(ErrorCode.CATEGORY_NAME_DUPLICATED);
		}
	}

	private int nextSortNo(Long familyId, String type, Long parentId) {
		int max = 0;
		for (Category sibling : this.categoryMapper.selectList(siblingScope(familyId, type, parentId))) {
			max = Math.max(max, sibling.getSortNo());
		}
		return max + 1;
	}

	/**
	 * 新大类的配色取号（§4.2.2 第 15 轮）：占用范围按整个家庭算，不按收支类型各算一套——图标与配色共用
	 * 同一个下标，各算一套的话收入侧新建的类别会领到 restaurant、shopping_bag 这类支出意味的图标。
	 */
	private int nextColorIndex(Long familyId) {
		Set<Integer> used = new HashSet<>(this.categoryMapper.selectUsedColorIndexes(familyId));
		for (int index = 0; index < PresetFinanceDict.PALETTE_SIZE; index++) {
			if (!used.contains(index)) {
				return index;
			}
		}
		// 24 个大类全占满才会走到这里，绕回最小索引，好过为它再引入第二套取色规则
		return used.isEmpty() ? 0 : (Collections.max(used) + 1) % PresetFinanceDict.PALETTE_SIZE;
	}

	private static LambdaQueryWrapper<Category> familyScope(Long familyId, String type) {
		return new LambdaQueryWrapper<Category>()
			.eq(Category::getFamilyId, familyId)
			.eq(type != null, Category::getType, type);
	}

	/**
	 * 「同一层」的查询条件。parentId 为 null 时必须走 parent_id IS NULL——写成 parent_id = NULL
	 * 在 SQL 里恒不成立，大类就永远查不出来了。
	 */
	private static LambdaQueryWrapper<Category> siblingScope(Long familyId, String type, Long parentId) {
		LambdaQueryWrapper<Category> scope = familyScope(familyId, type);
		return (parentId == null) ? scope.isNull(Category::getParentId) : scope.eq(Category::getParentId, parentId);
	}

	private CategoryResponse toResponse(Category category) {
		return new CategoryResponse(category.getId(), category.getType(), category.getParentId(), category.getName(),
				category.getIconKey(), category.getColorIndex(), category.getSortNo(), category.getEnabled() == 1,
				category.getIsPreset() == 1);
	}

	private CategoryNode toNode(Category category, List<CategoryNode> children) {
		return CategoryNode.of(toResponse(category), children);
	}

}
