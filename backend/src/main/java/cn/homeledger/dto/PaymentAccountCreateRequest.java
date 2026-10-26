package cn.homeledger.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * 新建支付方式（§4.2.1）。不开放 isDefault：新建时一律不是默认项，要设默认走 PATCH。
 */
public record PaymentAccountCreateRequest(
		@NotBlank(message = "支付方式名称不能为空") @Size(max = 8, message = "支付方式名称最多 8 个字符") String name) {

}
