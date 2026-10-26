package cn.homeledger.dto;

import jakarta.validation.constraints.NotNull;

/**
 * §4.1.4（第 33 轮）：邀请开关请求。开 = 签发新 6 位邀请码（24 小时、一次性）；
 * 关 = 清空邀请码并关闭邀请入口。
 */
public record InviteEnableRequest(@NotNull(message = "请指明是否开启邀请") Boolean enabled) {

}