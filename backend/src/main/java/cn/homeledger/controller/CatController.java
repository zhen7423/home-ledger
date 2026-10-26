package cn.homeledger.controller;

import java.io.IOException;
import java.util.List;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import cn.homeledger.common.ApiResponse;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.RequiresFamily;
import cn.homeledger.dto.CatCreateRequest;
import cn.homeledger.dto.CatUpdateRequest;
import cn.homeledger.service.CatService;
import cn.homeledger.vo.CatResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.3.1 猫咪档案。全家共享的一份清单，任何在籍成员可改。
 */
@Tag(name = "猫咪档案", description = "§4.3.1 猫咪档案")
@RestController
@RequestMapping("/api/v1/cats")
@RequiresFamily
public class CatController {

	private final CatService catService;

	public CatController(CatService catService) {
		this.catService = catService;
	}

	@Operation(summary = "猫咪列表", description = "§4.3.1：在册的在前，其后按建档先后。includeArchived 缺省 false，"
			+ "记账与驱虫表单只要在册的猫；档案管理的「全部」视图传 true。没有 GET /cats/{id}——列表已回全字段。")
	@GetMapping
	public ApiResponse<List<CatResponse>> list(@RequestParam(defaultValue = "false") boolean includeArchived) {
		return ApiResponse.ok(this.catService.list(includeArchived));
	}

	@Operation(summary = "猫咪建档", description = "§4.3.1：昵称 ≤ 12 字、去空格后家庭内不可重名；在册满 10 只即拒绝，"
			+ "归档的不占名额；生日不能晚于今天，只知年月时按当月 1 日落库并置 birthdayEstimated。")
	@PostMapping
	public ApiResponse<CatResponse> create(@Valid @RequestBody CatCreateRequest request) {
		return ApiResponse.ok(this.catService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "编辑猫咪档案", description = "§4.3.1：整份表单覆盖，可空栏位不传即清空。"
			+ "不动 enabled——让一只猫从记录选择器里消失是归档那个动作，不是改名字。")
	@PatchMapping("/{id}")
	public ApiResponse<CatResponse> update(@PathVariable Long id, @Valid @RequestBody CatUpdateRequest request) {
		return ApiResponse.ok(this.catService.update(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "归档 / 恢复猫咪", description = "§4.3.1：同一个开关的两端。归档后不再出现在新记录的选择器里，"
			+ "历史那条（猫粮归属与驱虫时间轴）照旧算它，而驱虫完成度与到期倒计时只看在册的猫；"
			+ "恢复时重数在册数，超 10 只同样被拒。")
	@PatchMapping("/{id}/archive")
	public ApiResponse<CatResponse> archive(@PathVariable Long id) {
		return ApiResponse.ok(this.catService.archive(AuthContextHolder.require().userId(), id));
	}

	@Operation(summary = "删除猫咪档案", description = "§4.3.1：软删除。名下有过任何驱虫记录（含已软删的）即拒绝，"
			+ "只能归档——删掉猫会让那些记录的 cat_id 悬空。")
	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@PathVariable Long id) {
		this.catService.delete(AuthContextHolder.require().userId(), id);
		return ApiResponse.ok();
	}

	@Operation(summary = "上传猫咪照片", description = "§4.3.1 / A6：multipart 的 file 字段，单张 ≤ 5 MB，"
			+ "只收 JPEG / PNG / WebP（按魔数判，不信 Content-Type）。落盘后回更新后的档案。")
	@PostMapping(value = "/{id}/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
	public ApiResponse<CatResponse> setPhoto(@PathVariable Long id, @RequestPart("file") MultipartFile file)
			throws IOException {
		return ApiResponse.ok(
				this.catService.setPhoto(AuthContextHolder.require().userId(), id, file.getBytes()));
	}

	@Operation(summary = "删除猫咪照片", description = "§4.3.1 / A6：清掉 photo_url 并删文件，回更新后的档案。")
	@DeleteMapping("/{id}/photo")
	public ApiResponse<CatResponse> clearPhoto(@PathVariable Long id) {
		return ApiResponse.ok(this.catService.clearPhoto(AuthContextHolder.require().userId(), id));
	}

}
