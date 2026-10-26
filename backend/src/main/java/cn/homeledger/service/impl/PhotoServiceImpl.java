package cn.homeledger.service.impl;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Optional;
import java.util.UUID;
import java.util.regex.Pattern;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.config.PhotoProperties;
import cn.homeledger.service.PhotoService;

/**
 * 磁盘实现。不上对象存储（§4.3.1 的 A6：云服务器本地磁盘 + Nginx，降低成本与依赖）。
 * <p>
 * 文件名用 UUID（去掉连字符的 32 位十六进制）而不是时间戳或用户输入——时间戳可被枚举猜测
 * （扫描别人的照片只需要撞对毫秒级时间），而 UUID 的不可猜测性是这个私有目录唯一的防线；
 * 至于「文件名不可猜」这件事本身，读取端点还会按归属做第二层校验，两道都不许省。
 * <p>
 * 写文件先落 `.tmp` 再 move 而不是直接写目标名：直接写的话，客户端拿到 200、写入中途崩溃，
 * 会上半截文件留在磁盘上，而读取端只看文件存在与否——用户会看到一张花掉的照片。
 * move 是原子操作，要么全在要么全不在。
 * <p>
 * 任何 IO 失败都包成 {@code BizException} 而不是让用户看到 500 堆栈：写失败对照片这种
 * 「丢了可以重传」的数据，一句人话比一个堆栈更诚实。
 */
@Service
public class PhotoServiceImpl implements PhotoService {

	private static final Logger log = LoggerFactory.getLogger(PhotoServiceImpl.class);

	/** UUID（32 位十六进制）+ 三种允许的扩展名。读取端靠它拦路径穿越。 */
	private static final Pattern SAFE_FILE = Pattern.compile("[0-9a-f]{32}\\.(jpg|png|webp)");

	private final PhotoProperties properties;

	public PhotoServiceImpl(PhotoProperties properties) {
		this.properties = properties;
	}

	@Override
	public String save(byte[] data) {
		if (data.length == 0) {
			throw new BizException(ErrorCode.BAD_REQUEST, "没有收到照片文件");
		}
		if (data.length > this.properties.maxBytes()) {
			// 文案从 maxBytes 派生而不是写死 5 MB：上限是 PHOTO_MAX_BYTES 可配的，
			// 硬编码文案会在运维调大后拒掉合法请求还报一个错的数字（S10 审查 N1）
			throw new BizException(ErrorCode.BAD_REQUEST, "照片不能超过 " + megabytes() + " MB");
		}
		String extension = sniff(data);
		if (extension == null) {
			throw new BizException(ErrorCode.BAD_REQUEST, "只支持 JPG / PNG / WebP 格式的照片");
		}
		String name = UUID.randomUUID().toString().replace("-", "") + "." + extension;
		Path target = root().resolve(name);
		Path temp = root().resolve(name + ".tmp");
		try (OutputStream out = Files.newOutputStream(temp)) {
			out.write(data);
		}
		catch (IOException e) {
			throw new BizException(ErrorCode.INTERNAL_ERROR, "照片保存失败，请稍后重试");
		}
		try {
			// move 是可原子性的重命名：同一文件系统内不会出现「目标盖了一半」
			Files.move(temp, target);
		}
		catch (IOException e) {
			try {
				Files.deleteIfExists(temp);
			}
			catch (IOException ignored) {
				// 清理失败也只是留一个 .tmp，肉眼可见、不影响逻辑
			}
			throw new BizException(ErrorCode.INTERNAL_ERROR, "照片保存失败，请稍后重试");
		}
		return PREFIX + name;
	}

	@Override
	public void delete(String relativePath) {
		if (relativePath == null || !relativePath.startsWith(PREFIX)) {
			return;
		}
		String name = relativePath.substring(PREFIX.length());
		if (!SAFE_FILE.matcher(name).matches()) {
			log.warn("拒绝删除不是本项目命名的文件: {}", relativePath);
			return;
		}
		try {
			Files.deleteIfExists(root().resolve(name));
		}
		catch (IOException e) {
			// 删除失败最坏是磁盘上多一个孤儿文件，不值得让一个删除动作把业务事务一起带崩
			log.warn("照片删除失败 relativePath={}", relativePath, e);
		}
	}

	@Override
	public void deleteAfterCommit(String relativePath) {
		if (relativePath == null) {
			return;
		}
		if (TransactionSynchronizationManager.isSynchronizationActive()) {
			// 只认提交成功：事务回滚时库里的旧引用还活着，文件必须跟着活（M1）
			TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
				@Override
				public void afterCommit() {
					delete(relativePath);
				}
			});
			return;
		}
		delete(relativePath);
	}

	@Override
	public Optional<StoredPhoto> load(String fileId) {
		if (!SAFE_FILE.matcher(fileId).matches()) {
			return Optional.empty();
		}
		Path path = root().resolve(fileId);
		if (!Files.isRegularFile(path)) {
			return Optional.empty();
		}
		return Optional.of(new StoredPhoto(path, contentTypeOf(fileId)));
	}

	/** 魔数判格式而不是信客户端传来的 Content-Type（那个值可以随便写）。 */
	private static String sniff(byte[] data) {
		if (data.length >= 3 && (data[0] & 0xFF) == 0xFF && (data[1] & 0xFF) == 0xD8 && (data[2] & 0xFF) == 0xFF) {
			return "jpg";
		}
		if (data.length >= 8 && (data[0] & 0xFF) == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47
				&& data[4] == 0x0D && data[5] == 0x0A && data[6] == 0x1A && data[7] == 0x0A) {
			return "png";
		}
		if (data.length >= 12 && data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46
				&& data[8] == 0x57 && data[9] == 0x45 && data[10] == 0x42 && data[11] == 0x50) {
			return "webp";
		}
		return null;
	}

	private static String contentTypeOf(String fileId) {
		if (fileId.endsWith(".png")) {
			return "image/png";
		}
		if (fileId.endsWith(".webp")) {
			return "image/webp";
		}
		return "image/jpeg";
	}

	private String megabytes() {
		return String.valueOf(this.properties.maxBytes() / 1024 / 1024);
	}

	private Path root() {
		Path dir = this.properties.dir().toAbsolutePath().normalize();
		try {
			Files.createDirectories(dir);
		}
		catch (IOException e) {
			throw new BizException(ErrorCode.INTERNAL_ERROR, "照片目录不可用，请检查服务器磁盘配置");
		}
		return dir;
	}

}