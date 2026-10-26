package cn.homeledger.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * §5.2「敏感操作二次确认」：解散家庭与注销账号都要求密码校验，共用同一入参形状。
 */
public record PasswordVerifyRequest(@NotBlank(message = "请填写密码以确认本次操作") String password) {

}
