package cn.homeledger.controller;

import java.io.IOException;

import org.springdoc.core.annotations.ParameterObject;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.common.ExportFormat;
import cn.homeledger.common.RequiresFamily;
import cn.homeledger.dto.TransactionQueryRequest;
import cn.homeledger.service.TransactionExportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletResponse;

/**
 * §4.2.7 流水明细导出。
 */
@Tag(name = "导出", description = "数据导出（§4.2.7）")
@RestController
@RequestMapping("/api/v1/export")
@RequiresFamily
public class ExportController {

	private final TransactionExportService exportService;

	public ExportController(TransactionExportService exportService) {
		this.exportService = exportService;
	}

	/**
	 * 成功时<b>不返回统一响应体</b>，直接是文件字节流；失败时仍是 {code, message, data, traceId} + 4xx（§8）。
	 * 一个方法两种响应形状，靠「prepare 先跑完再写第一个字节」保证：超限、区间非法这类拒绝都发生在
	 * 响应还没提交的时候，全局异常处理器才改得动状态码与响应体。
	 */
	@Operation(summary = "导出流水明细",
			description = "xlsx 或 csv，字段顺序固定为「记账日期 | 收支类型 | 大类 | 小类 | 金额 | 支付方式 | 备注 | 记录人 | 创建时间 | 数据来源」，"
					+ "按记账日期升序、同日按 id 升序，末行附收支合计。超过 homeledger.export.max-rows 返回 400。")
	@GetMapping("/transactions")
	public void transactions(@ParameterObject TransactionQueryRequest query,
			@RequestParam(name = "format", required = false) String format, HttpServletResponse response)
			throws IOException {
		ExportFormat exportFormat = ExportFormat.fromParam(format);
		TransactionExportService.Preparation preparation = this.exportService.prepare(query, exportFormat);
		response.setStatus(HttpStatus.OK.value());
		response.setContentType(preparation.contentType());
		response.setHeader(HttpHeaders.CONTENT_DISPOSITION, preparation.contentDisposition());
		this.exportService.write(query, exportFormat, response.getOutputStream());
	}

}
