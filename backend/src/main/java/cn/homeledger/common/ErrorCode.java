package cn.homeledger.common;

import org.springframework.http.HttpStatus;

/**
 * 枚举名即对外 code，前端按 code 分支，不依赖 HTTP status（status 只表达语义类别）。
 */
public enum ErrorCode {

	BAD_REQUEST(HttpStatus.BAD_REQUEST, "请求参数不合法"),
	VALIDATION_FAILED(HttpStatus.BAD_REQUEST, "请求参数校验失败"),
	LOGIN_BAD_CREDENTIAL(HttpStatus.BAD_REQUEST, "登录名或密码错误"),
	PASSWORD_MISMATCH(HttpStatus.BAD_REQUEST, "密码校验未通过"),
	INVITE_CODE_NOT_FOUND(HttpStatus.BAD_REQUEST, "邀请码不存在"),
	INVITE_CODE_EXPIRED(HttpStatus.BAD_REQUEST, "邀请码已过期，请向家庭创建者索取新的邀请码"),
	FAMILY_MEMBER_LIMIT(HttpStatus.BAD_REQUEST, "该家庭成员已满 5 人，无法加入"),
	CANNOT_REMOVE_SELF(HttpStatus.BAD_REQUEST, "不能移除自己"),
	CANNOT_TRANSFER_TO_SELF(HttpStatus.BAD_REQUEST, "不能把创建者身份转让给自己"),
	OWNER_CANNOT_LEAVE(HttpStatus.BAD_REQUEST, "创建者需先转让创建者身份或解散家庭，才能退出"),

	CATEGORY_NAME_TOO_LONG(HttpStatus.BAD_REQUEST, "大类名称最多 6 个字符，小类最多 8 个字符"),
	CATEGORY_DEPTH_EXCEEDED(HttpStatus.BAD_REQUEST, "类别最多两级，不能在小类下面再建小类"),
	CATEGORY_PARENT_MISMATCH(HttpStatus.BAD_REQUEST, "小类必须挂在与它同一收支类型的大类下面"),
	CATEGORY_PARENT_DISABLED(HttpStatus.BAD_REQUEST, "该大类已停用，要先启用它才能在下面新建小类"),
	CATEGORY_HAS_CHILDREN(HttpStatus.BAD_REQUEST, "请先处理该大类下面的小类"),
	CATEGORY_HAS_TRANSACTIONS(HttpStatus.BAD_REQUEST, "该类别下已有流水，只能停用不能删除"),
	CATEGORY_PRESET_UNDELETABLE(HttpStatus.BAD_REQUEST, "系统预置的类别不能删除，可以改名或停用"),
	CATEGORY_DISABLED(HttpStatus.BAD_REQUEST, "该类别已停用，不能用于新记录"),
	PAYMENT_ACCOUNT_IN_USE(HttpStatus.BAD_REQUEST, "该支付方式下已有流水，只能停用不能删除"),
	PAYMENT_ACCOUNT_IS_DEFAULT(HttpStatus.BAD_REQUEST, "默认支付方式不能停用或删除，请先把其他支付方式设为默认"),
	PAYMENT_ACCOUNT_NAME_DUPLICATED(HttpStatus.BAD_REQUEST, "已存在同名的支付方式"),
	AMOUNT_SCALE_INVALID(HttpStatus.BAD_REQUEST, "金额最多两位小数"),
	BIZ_DATE_IN_FUTURE(HttpStatus.BAD_REQUEST, "记账日期不能晚于今天"),
	SORT_IDS_MISMATCH(HttpStatus.BAD_REQUEST, "排序列表与当前家庭的数据对不上，请刷新后重试"),
	PERIOD_VALUE_INVALID(HttpStatus.BAD_REQUEST, "周期参数与周期类型不匹配"),
	PERIOD_RANGE_INVALID(HttpStatus.BAD_REQUEST, "周期参数超出允许范围"),
	BUDGET_SCOPE_INVALID(HttpStatus.BAD_REQUEST, "预算维度与所填的分类 / 成员对不上"),
	BUDGET_CATEGORY_NOT_MAJOR(HttpStatus.BAD_REQUEST, "类别预算只能设在大类上"),

	UNAUTHORIZED(HttpStatus.UNAUTHORIZED, "登录状态无效，请重新登录"),
	TOKEN_EXPIRED(HttpStatus.UNAUTHORIZED, "登录已过期，请重新登录"),
	TOKEN_REVOKED(HttpStatus.UNAUTHORIZED, "登录状态已失效，请重新登录"),
	REFRESH_TOKEN_INVALID(HttpStatus.UNAUTHORIZED, "续期令牌无效，请重新登录"),

	FORBIDDEN(HttpStatus.FORBIDDEN, "无权执行该操作"),
	NO_FAMILY(HttpStatus.FORBIDDEN, "你还没有加入家庭，请先创建家庭或输入邀请码加入"),
	NOT_FAMILY_OWNER(HttpStatus.FORBIDDEN, "仅家庭创建者可执行该操作"),
	ACCOUNT_DEACTIVATED(HttpStatus.FORBIDDEN, "账号已注销"),
	BUDGET_MEMBER_NOT_IN_FAMILY(HttpStatus.FORBIDDEN, "该成员不在当前家庭中，无法为其设置预算"),

	RESOURCE_NOT_FOUND(HttpStatus.NOT_FOUND, "请求的资源不存在"),
	MEMBER_NOT_FOUND(HttpStatus.NOT_FOUND, "该成员不在当前家庭中"),
	CATEGORY_NOT_FOUND(HttpStatus.NOT_FOUND, "类别不存在"),
	PAYMENT_ACCOUNT_NOT_FOUND(HttpStatus.NOT_FOUND, "支付方式不存在"),
	TRANSACTION_NOT_FOUND(HttpStatus.NOT_FOUND, "流水不存在"),
	RECURRING_RULE_NOT_FOUND(HttpStatus.NOT_FOUND, "周期记账规则不存在"),
	BUDGET_NOT_FOUND(HttpStatus.NOT_FOUND, "预算不存在"),

	METHOD_NOT_ALLOWED(HttpStatus.METHOD_NOT_ALLOWED, "请求方法不被支持"),
	UNSUPPORTED_MEDIA_TYPE(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "请求内容类型不被支持"),

	PHONE_ALREADY_REGISTERED(HttpStatus.CONFLICT, "该手机号已注册"),
	ALREADY_IN_FAMILY(HttpStatus.CONFLICT, "你已在一个家庭中，需先退出才能创建或加入其他家庭"),
	CATEGORY_NAME_DUPLICATED(HttpStatus.CONFLICT, "同一收支类型下已有同名类别"),
	CATEGORY_USED_BY_RECURRING_RULE(HttpStatus.CONFLICT, "该类别被周期记账规则使用中，请先删除或改指那些规则"),
	PAYMENT_ACCOUNT_USED_BY_RECURRING_RULE(HttpStatus.CONFLICT, "该支付方式被周期记账规则使用中，请先删除或改指那些规则"),
	BUDGET_DUPLICATED(HttpStatus.CONFLICT, "同一个维度在本次提交里出现了两次"),
	REMINDER_SETTING_DUPLICATED(HttpStatus.CONFLICT, "同一类提醒在本次提交里出现了两次"),

	ACCOUNT_LOCKED(HttpStatus.LOCKED, "密码连续错误次数过多，账号已临时锁定"),
	RATE_LIMITED(HttpStatus.TOO_MANY_REQUESTS, "操作过于频繁，请稍后再试"),

	INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "服务器开小差了，请稍后重试"),
	INVITE_CODE_GENERATION_FAILED(HttpStatus.INTERNAL_SERVER_ERROR, "邀请码生成失败，请重试"),

	NOT_IMPLEMENTED(HttpStatus.NOT_IMPLEMENTED, "该能力本期未开放");

	private final HttpStatus status;

	private final String message;

	ErrorCode(HttpStatus status, String message) {
		this.status = status;
		this.message = message;
	}

	public String code() {
		return name();
	}

	public HttpStatus status() {
		return this.status;
	}

	public String message() {
		return this.message;
	}

}
