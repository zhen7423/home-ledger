package cn.homeledger.dto;

import jakarta.validation.constraints.NotNull;

/**
 * §4.1.6 转让创建者（第 9 轮新增）。
 */
public record TransferOwnerRequest(@NotNull(message = "请选择要转让给的成员") Long targetUserId) {

}
