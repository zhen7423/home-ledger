package cn.homeledger.common;

/**
 * 每次请求实时解析的登录态。刻意不放 familyId / role 进 JWT：令牌里带家庭与角色会产生「已退出家庭的旧令牌
 * 在自然过期前仍能读到原家庭数据」的越权窗口，改为每请求查库后该窗口不存在（见需求文档 §5.2）。
 *
 * @param familyId 当前所属家庭，未加入家庭时为 null
 * @param role     OWNER / MEMBER，未加入家庭时为 null
 */
public record AuthContext(Long userId, Long familyId, String role) {

	public static final String ROLE_OWNER = "OWNER";

	public static final String ROLE_MEMBER = "MEMBER";

	public boolean hasFamily() {
		return this.familyId != null;
	}

	public boolean isOwner() {
		return ROLE_OWNER.equals(this.role);
	}

}
