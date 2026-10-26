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
import cn.homeledger.dto.BabyCreateRequest;
import cn.homeledger.dto.BabyUpdateRequest;
import cn.homeledger.service.BabyService;
import cn.homeledger.vo.BabyResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

/**
 * §4.4.1 宝宝档案。全家共享的一份清单，任何在籍成员可改。
 */
@Tag(name = "宝宝档案", description = "§4.4.1 宝宝档案")
@RestController
@RequestMapping("/api/v1/babies")
@RequiresFamily
public class BabyController {

	private final BabyService babyService;

	public BabyController(BabyService babyService) {
		this.babyService = babyService;
	}

	@Operation(summary = "宝宝列表", description = "§4.4.1：在册的在前，其后按建档先后。includeArchived 缺省 false，"
			+ "其余各页的记录表单只要在册的宝宝；档案管理的「全部」视图传 true。没有 GET /babies/{id}——列表已回全字段。")
	@GetMapping
	public ApiResponse<List<BabyResponse>> list(@RequestParam(defaultValue = "false") boolean includeArchived) {
		return ApiResponse.ok(this.babyService.list(includeArchived));
	}

	@Operation(summary = "宝宝建档", description = "§4.4.1：姓名 ≤ 12 字、去空格后在册的宝宝里不可重名（归档的腾出名字）；"
			+ "在册满 5 个即拒绝，归档的不占名额；出生日期不能晚于今天。同一事务内按内置程序表生成该宝宝的应种清单。")
	@PostMapping
	public ApiResponse<BabyResponse> create(@Valid @RequestBody BabyCreateRequest request) {
		return ApiResponse.ok(this.babyService.create(AuthContextHolder.require().userId(), request));
	}

	@Operation(summary = "编辑宝宝档案", description = "§4.4.1：整份表单覆盖，可空栏位不传即清空。"
			+ "改了出生日期就在同一事务内整份重算应种清单——按「疫苗名称 + 剂次」对齐，"
			+ "已接种 / 已跳过 / 不适用 / 手动的行原样保留。不动 enabled，归档是另一个动作。")
	@PatchMapping("/{id}")
	public ApiResponse<BabyResponse> update(@PathVariable Long id, @Valid @RequestBody BabyUpdateRequest request) {
		return ApiResponse.ok(this.babyService.update(AuthContextHolder.require().userId(), id, request));
	}

	@Operation(summary = "归档 / 恢复宝宝", description = "§4.4.1：同一个开关的两端。归档后不再出现在其余各页的宝宝选择器里，"
			+ "已有的身高体重、接种、里程碑与就诊记录照旧算在他头上；恢复时重数在册数，超 5 个同样被拒。")
	@PatchMapping("/{id}/archive")
	public ApiResponse<BabyResponse> archive(@PathVariable Long id) {
		return ApiResponse.ok(this.babyService.archive(AuthContextHolder.require().userId(), id));
	}

	@Operation(summary = "删除宝宝档案", description = "§4.4.1：软删除。身高体重 / 接种记录 / 里程碑 / 就诊记录四张表里有过任何记录"
			+ "（含已软删的）即拒绝，只能归档。应种清单是派生数据，随档案一起软删。")
	@DeleteMapping("/{id}")
	public ApiResponse<Void> delete(@PathVariable Long id) {
		this.babyService.delete(AuthContextHolder.require().userId(), id);
		return ApiResponse.ok();
	}

	@Operation(summary = "上传宝宝照片", description = "§4.4.1 / A6：multipart 的 file 字段，单张 ≤ 5 MB，"
			+ "只收 JPEG / PNG / WebP（按魔数判，不信 Content-Type）。落盘后回更新后的档案。")
	@PostMapping(value = "/{id}/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
	public ApiResponse<BabyResponse> setPhoto(@PathVariable Long id, @RequestPart("file") MultipartFile file)
			throws IOException {
		return ApiResponse.ok(
				this.babyService.setPhoto(AuthContextHolder.require().userId(), id, file.getBytes()));
	}

	@Operation(summary = "删除宝宝照片", description = "§4.4.1 / A6：清掉 photo_url 并删文件，回更新后的档案。")
	@DeleteMapping("/{id}/photo")
	public ApiResponse<BabyResponse> clearPhoto(@PathVariable Long id) {
		return ApiResponse.ok(this.babyService.clearPhoto(AuthContextHolder.require().userId(), id));
	}

}
