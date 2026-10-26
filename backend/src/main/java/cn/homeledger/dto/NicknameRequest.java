package cn.homeledger.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * PATCH /users/me 改名。
 * <p>
 * 改名不回写 family_member.nickname_snapshot：§4.1.5 定义快照是「退出时保存的昵称」，
 * 在籍成员一律显示实时昵称（成员列表用 LEFT JOIN user 取），只有退出/被移除那一刻才定格。
 */
public record NicknameRequest(
		@NotBlank(message = "请填写昵称")
		@Size(min = 1, max = 12, message = "昵称须为 1–12 字符") String nickname) {

}
