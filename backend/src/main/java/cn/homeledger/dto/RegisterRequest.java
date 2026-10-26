package cn.homeledger.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * §4.1.1 注册。手机号本期仅作账号标识，不做短信验证；密码规则由 Bean Validation 承担第一道，
 * 服务端仍需在 AuthService 内二次确认（§5.2 输入校验）。
 */
public record RegisterRequest(

		@NotBlank(message = "请填写登录名")
		@Pattern(regexp = "^1[3-9]\\d{9}$", message = "登录名须为 11 位中国大陆手机号") String phone,

		@NotBlank(message = "请填写密码")
		@Size(min = 8, max = 20, message = "密码须为 8–20 位")
		@Pattern(regexp = "^(?=.*[A-Za-z])(?=.*\\d).+$", message = "密码须同时包含字母与数字") String password,

		@NotBlank(message = "请填写昵称")
		@Size(min = 1, max = 12, message = "昵称须为 1–12 字符") String nickname) {

}
