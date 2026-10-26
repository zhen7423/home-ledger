package cn.homeledger.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * 续期与登出共用：两者都只需要客户端交出当前持有的 Refresh Token。
 */
public record RefreshTokenRequest(@NotBlank(message = "缺少 refreshToken") String refreshToken) {

}
