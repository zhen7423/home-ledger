package cn.homeledger.dto;

import jakarta.validation.constraints.Size;

/**
 * 创建家庭与家庭改名共用。§4.1.4：名称 1–20 字符，创建时留空则填「XX 的家」，
 * 故这里不加 @NotBlank，空值由 FamilyService 兜默认名。
 */
public record FamilyNameRequest(@Size(max = 20, message = "家庭名称最多 20 字符") String name) {

}
