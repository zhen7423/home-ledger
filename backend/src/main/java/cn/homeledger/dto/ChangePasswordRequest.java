package cn.homeledger.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * §4.1.2 修改密码。成功后会递增令牌版本号，因此响应里直接带回一对新令牌，
 * 让执行本次操作的设备无缝续上，而其他设备按 §5.2 的预期副作用被踢下线。
 */
public record ChangePasswordRequest(

		@NotBlank(message = "请填写原密码") String oldPassword,

		@NotBlank(message = "请填写新密码")
		@Size(min = 8, max = 20, message = "密码须为 8–20 位")
		@Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d).+$", message = "密码须同时包含字母与数字") String newPassword) {

}
