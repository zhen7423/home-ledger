package cn.homeledger.controller;

import java.util.List;

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.RequiresFamily;
import cn.homeledger.dto.CategoryCreateRequest;
import cn.homeledger.dto.CategoryRenameRequest;
import cn.homeledger.dto.CategorySortRequest;
import cn.homeledger.service.CategoryService;
import cn.homeledger.vo.CategoryNode;
import cn.homeledger.vo.CategoryResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.2.2 两级收支类别字典。
 * <p>
 * 类别全家共享、任何在籍成员可改，所以整类都要求已有家庭，标在类上即可。
 */
@Tag(name = "记账类别", description = "§4.2.2 两级收支类别字典")
@RestController
@RequestMapping("/api/v1/categories")
@RequiresFamily
public class CategoryController {

	private final CategoryService categoryService;

	public CategoryController(CategoryService categoryService) {
		this.categoryService = categoryService;
	}

	@Operation(summary = "类别树", description = "§4.2.2：一次返回两级树。type 省略则收支两棵都给；enabledOnly=true 只返回启用中的节点，"
			+ "供记账表单的选择器用；类别管理页要连停用的类别一起显示，否则没法重新启用。")
	@GetMapping
	public ApiResponse<List<CategoryNode>> tree(@RequestParam(required = false) String type,
			@RequestParam(defaultValue = "false") boolean enabledOnly) {
		return ApiResponse.ok(this.categoryService.tree(type, enabledOnly));
	}

	@Operation(summary = "新建类别", description = "§4.2.2：parentId 为空建大类（名称 ≤ 6 字，自动分配图标与配色），非空则在该大类下建小类"
			+ "（名称 ≤ 8 字）。同级内名称重复返回 CATEGORY_NAME_DUPLICATED；只允许两级，小类下再建小类返回 CATEGORY_DEPTH_EXCEEDED。")
	@PostMapping
	public ApiResponse<CategoryResponse> create(@Valid @RequestBody CategoryCreateRequest request) {
		return ApiResponse.ok(this.categoryService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "类别改名", description = "§4.2.2：收支类型与父级不可改。改名不回溯历史流水中已冻结的名称快照（附录 A A3）。")
	@PatchMapping("/{id}")
	public ApiResponse<CategoryResponse> rename(@PathVariable Long id,
			@Valid @RequestBody CategoryRenameRequest request) {
		return ApiResponse.ok(this.categoryService.rename(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "启用 / 停用类别", description = "§4.2.2：停用大类会级联停用其下全部小类；重新启用大类不自动启用小类，"
			+ "小类要不要回来由用户自己决定。停用的类别不能再用于新记录，历史记录照旧显示。")
	@PatchMapping("/{id}/toggle")
	public ApiResponse<CategoryResponse> toggle(@PathVariable Long id) {
		return ApiResponse.ok(this.categoryService.toggle(AuthContextHolder.require().userId(), id));
	}

	@Operation(summary = "删除类别", description = "§4.2.2：物理删除，三个前置条件任一不满足即拒绝——系统预置类别不可删（可改名可停用）、"
			+ "下面还有小类不可删、名下有任何流水（含已软删除）不可删，只能停用。最后一条是防止软删除流水的类别外键指向一个已消失的行。")
	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@PathVariable Long id) {
		this.categoryService.delete(AuthContextHolder.require().userId(), id);
		return ApiResponse.ok();
	}

	@Operation(summary = "类别拖拽排序", description = "§4.2.2：orderedIds 必须给全同一收支类型、同一父级下的每一行，服务端按数组顺序把 "
			+ "sort_no 重写为 1…n。少给或多给都返回 SORT_IDS_MISMATCH，因为部分重写必然与未提及的行撞号。")
	@PutMapping("/sort")
	public ApiResponse<Void> sort(@Valid @RequestBody CategorySortRequest request) {
		this.categoryService.sort(AuthContextHolder.require().userId(), request);
		return ApiResponse.ok();
	}

}
