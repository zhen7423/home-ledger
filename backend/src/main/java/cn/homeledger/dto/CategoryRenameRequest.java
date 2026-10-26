package cn.homeledger.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * 类别改名（§4.2.2）。类型与父级不可改——要挪位置只能删了重建，改名带回溯历史快照的歧义。
 * <p>
 * 改名不回溯更新历史流水的名称快照（A3 已定）。
 */
public record CategoryRenameRequest(@NotBlank(message = "类别名称不能为空") @Size(max = 8, message = "类别名称最多 8 个字符") String name) {

}
