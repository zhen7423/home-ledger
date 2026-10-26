package cn.homeledger.service;

import java.nio.file.Path;
import java.util.Optional;

/**
 * §4.3.1 档案照片的存取。只负责文件本身：谁的照片、归哪个家庭是调用方（Cat/BabyService 与
 * PhotoController）的事，本类不持有任何业务表引用。
 * <p>
 * 存储形状：磁盘目录下一个 UUID 文件名，数据库里只存相对路径 {@code /photos/<uuid>.<ext>}。
 * 文件不需要任何扩展名语义的元数据——格式由魔数判，读取时按扩展名给 Content-Type。
 */
public interface PhotoService {

	/** 数据库里存的是这个前缀 + 文件名（§V8）。相对路径不是可自由拼写的串：读取端先按它判归属再取文件。 */
	String PREFIX = "/photos/";

	/**
	 * 校验并落盘一份照片，返回数据库里要存的那个相对路径。
	 *
	 * @throws cn.homeledger.common.BizException 空文件、超上限、魔数不识别（只收 JPEG / PNG / WebP）
	 */
	String save(byte[] data);

	/**
	 * 删除一份照片文件。相对路径不认（含路径穿越、非 UUID 文件名）或文件不存在时静默返回：
	 * 删除是取值恒定为「尽力而为」的维护动作，失败最坏是磁盘上多一个孤儿文件，不影响业务。
	 * <p>
	 * 同步删只适用于「文件尚未被认领」（写库失败后的补偿）或确认不在事务里的场景；
	 * 删一份数据库仍在引用的照片要用 {@link #deleteAfterCommit(String)}。
	 */
	void delete(String relativePath);

	/**
	 * 事务提交后再删（§4.1.6 / S10 审查 M1）。文件系统不在数据库事务里：先删文件、
	 * 事务后段却回滚，交出去的是一份「库里的 photo_url 指向已删文件」的永久 404。
	 * 注册在 afterCommit 上：事务回滚则回调不执行（库里的引用还活着，文件也必须活着）；
	 * 没有活动事务时退化为立即删除。
	 */
	void deleteAfterCommit(String relativePath);

	/**
	 * 取一份照片供读取。文件不存在或不合法时返回空——调用方把它统一译成 404，
	 * 不让「照片被误删」与「根本没传过照片」在接口层有第二种说法。
	 */
	Optional<StoredPhoto> load(String fileId);

	/** 一块已落盘的照片：文件路径 + 按扩展名猜出的 Content-Type。 */
	record StoredPhoto(Path path, String contentType) {

	}

}