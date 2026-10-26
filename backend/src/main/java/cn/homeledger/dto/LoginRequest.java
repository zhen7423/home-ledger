package cn.homeledger.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * §4.1.2 登录。刻意不加 @Pattern 校验手机号格式：格式校验属于注册，登录时若因格式拒绝，
 * 会把「该账号不存在」与「格式不对」两种情况区分开，反而给遍历探测提供了信号。
 */
public record LoginRequest(@NotBlank(message = "请填写登录名") String phone,
		@NotBlank(message = "请填写密码") String password) {

}
