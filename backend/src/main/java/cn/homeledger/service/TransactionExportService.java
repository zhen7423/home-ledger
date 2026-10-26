package cn.homeledger.service;

import java.io.OutputStream;

import cn.homeledger.common.ExportFormat;
import cn.homeledger.dto.TransactionQueryRequest;

/**
 * §4.2.7 流水明细导出。拆成 prepare 与 write 两步是硬要求，不是为了好看：
 * <p>
 * 成功时这个端点回的是文件字节，失败时回的是统一响应体 + 4xx。两种形状只能靠「所有会失败的判断都在
 * 第一个字节写出去之前跑完」来兼得——一旦响应提交，状态码就改不动了，此后失败只能把文件截断。
 * 所以行数上限、区间合法性、文件名都归 prepare，write 只负责往外吐字节。
 */
public interface TransactionExportService {

	/**
	 * 校验 + 算文件名 + 定响应头。行数超过 {@code homeledger.export.max-rows} 时抛
	 * {@code BAD_REQUEST}，文案要提示用户缩小时间区间（§4.2.7）。
	 */
	Preparation prepare(TransactionQueryRequest query, ExportFormat format);

	/**
	 * 分批读取并写出。批大小取 {@code homeledger.export.batch-size}。
	 * <p>
	 * <b>不标 {@code @Transactional}</b>：一次导出最长要写 5 万行到客户端的网络上，
	 * 包成一个只读事务等于让一个数据库连接被占住整段下载时间；代价是分批读取期间可能有人新记一笔，
	 * 导致 offset 漂移一行——导出是台账快照而不是对账单，这一行漂移可以接受，连接池被拖垮不行。
	 */
	void write(TransactionQueryRequest query, ExportFormat format, OutputStream out);

	/**
	 * @param contentDisposition 已经拼好的整个头值，含 RFC 5987 的 {@code filename*=UTF-8''} 段
	 */
	record Preparation(long rowCount, String filename, String contentType, String contentDisposition) {
	}

}
