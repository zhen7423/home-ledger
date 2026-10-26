package cn.homeledger.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * §4.1.4 邀请码加入。
 */
public record JoinFamilyRequest(
		@NotBlank(message = "请填写邀请码")
		@Pattern(regexp = "^\\d{6}$", message = "邀请码为 6 位数字") String inviteCode) {

}
