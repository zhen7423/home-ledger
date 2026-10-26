package cn.homeledger.dto;

import jakarta.validation.constraints.Size;

/**
 * 改名与设默认合用一个 PATCH 端点（§8「默认项不单开端点」），两个字段都可空，空表示不改。
 * <p>
 * isDefault = true 时服务端在同一事务里清掉本家庭其他行的默认标记，所以「恰好一行为默认」
 * 这个不变量不需要客户端配合做两次请求。
 */
public record PaymentAccountUpdateRequest(@Size(max = 8, message = "支付方式名称最多 8 个字符") String name,
		Boolean isDefault) {

}
