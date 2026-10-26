package cn.homeledger.controller;

import java.time.Duration;
import java.util.Optional;

import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.RequiresFamily;
import cn.homeledger.config.PhotoProperties;
import cn.homeledger.entity.Baby;
import cn.homeledger.entity.Cat;
import cn.homeledger.mapper.BabyMapper;
import cn.homeledger.mapper.CatMapper;
import cn.homeledger.service.PhotoService;
import cn.homeledger.service.PhotoService.StoredPhoto;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

/**
 * 档案照片的读取（§4.3.1 / A6）。
 * <p>
 * 照片是家庭私密数据，**公开静态目录不可接受**，所以读取必须过鉴权：拿着 {@code fileId} 先反查
 * {@code cat} / {@code baby} 两表里有没有一行的 {@code photo_url} 指向它。这两张表都在租户拦截器的保护下，
 * 跨家庭反查自然落空，于是「不属于调用者的照片」与「不存在的照片」统一回 404，不存在「知道 URL 就能看」。
 * <p>
 * 鉴权通过后的出文件分两路（配置 {@code homeledger.upload.use-nginx-accel}）：走 Nginx 时回
 * {@code X-Accel-Redirect} 由 {@code internal} 位置直出共享卷（生产、compose full，图片不经过 Spring）；
 * 否则由这里流式返回（本地没有 Nginx，图片也要能看）。
 */
@Tag(name = "照片", description = "§4.3.1 档案照片读取（鉴权在服务端）")
@RestController
@RequestMapping("/api/v1")
@RequiresFamily
public class PhotoController {

	private final CatMapper catMapper;

	private final BabyMapper babyMapper;

	private final PhotoService photoService;

	private final PhotoProperties properties;

	public PhotoController(CatMapper catMapper, BabyMapper babyMapper, PhotoService photoService,
			PhotoProperties properties) {
		this.catMapper = catMapper;
		this.babyMapper = babyMapper;
		this.photoService = photoService;
		this.properties = properties;
	}

	@Operation(summary = "读一张档案照片", description = "文件必须被当前家庭的某只猫或某个宝宝引用，否则 404；"
			+ "文件本身由 Nginx internal 直出（生产）或本端点流式返回（本地）。不走统一响应体——它的调用方是 <img>。")
	@GetMapping("/photos/{fileId}")
	public ResponseEntity<Resource> serve(@PathVariable String fileId) {
		String relative = PhotoService.PREFIX + fileId;
		boolean owned = this.catMapper
			.selectCount(new LambdaQueryWrapper<Cat>().eq(Cat::getPhotoUrl, relative)) > 0
			|| this.babyMapper.selectCount(new LambdaQueryWrapper<Baby>().eq(Baby::getPhotoUrl, relative)) > 0;
		if (!owned) {
			// 不存在的照片与「别人家的照片」同一种说法。photo_url 指向孤儿文件时文件还在磁盘上，
			// 但没有任何行引用它，读它没有意义，也一并 404
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		Optional<StoredPhoto> photo = this.photoService.load(fileId);
		if (photo.isEmpty()) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		MediaType mediaType = MediaType.parseMediaType(photo.get().contentType());
		// 文件名是 UUID、同一路径的内容永不变（换照片即换新路径，鉴权每请求照做），
		// 不给 immutable 缓存头的话客户端每次重进列表都要重拉字节（S10 审查 I2）
		CacheControl cacheControl = CacheControl.maxAge(Duration.ofDays(365)).cachePublic().immutable();
		if (this.properties.useNginxAccel()) {
			// 头给出去之后 Nginx 会用 internal 位置的内容替换本次响应；本地没有 Nginx 时这个头
			// 只是多出来的一个响应头，客户端拿不到 body——所以直出模式只在该配置打开时用
			return ResponseEntity.ok()
				.contentType(mediaType)
				.cacheControl(cacheControl)
				.header("X-Accel-Redirect", relative)
				.build();
		}
		return ResponseEntity.ok()
			.contentType(mediaType)
			.cacheControl(cacheControl)
			.body(new FileSystemResource(photo.get().path()));
	}

}