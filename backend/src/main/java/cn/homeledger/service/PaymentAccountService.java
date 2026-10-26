package cn.homeledger.service;

import java.util.List;

import cn.homeledger.dto.PaymentAccountCreateRequest;
import cn.homeledger.dto.PaymentAccountSortRequest;
import cn.homeledger.dto.PaymentAccountUpdateRequest;
import cn.homeledger.vo.PaymentAccountResponse;

/**
 * §4.2.1 支付方式字典。本期只是给流水打标签，不维护余额、不做账户间转账。
 * <p>
 * familyId 的取法与 {@link CategoryService} 相同：payment_account 不在租户白名单内（§5.2），
 * 拦截器逐条 SQL 注入 family_id，服务层再显式带一次。
 */
public interface PaymentAccountService {

	/**
	 * 列表，按 sort_no 升序。enabledOnly=true 只给启用中的项，供记账表单用；管理页要连停用的
	 * 一起返回，不然停用的那行再也启用不回来。
	 */
	List<PaymentAccountResponse> list(boolean enabledOnly);

	/** 新建。一律不是默认项——设默认走 {@link #update}。 */
	PaymentAccountResponse create(Long userId, PaymentAccountCreateRequest request);

	/**
	 * 改名与设默认合用这一个方法（§8「默认项不单开端点」）。两个字段都可空，空表示不改。
	 * 设新默认时同一事务内先清掉旧默认，保证「每个家庭恰好一行为默认」不需要客户端配合发两次请求。
	 */
	PaymentAccountResponse update(Long userId, Long id, PaymentAccountUpdateRequest request);

	/** 启用 / 停用互切。当前默认项不可停用。 */
	PaymentAccountResponse toggle(Long userId, Long id);

	/** 物理删除。名下有任何流水（含已软删除）时只能停用；当前默认项不可删。预置项可以删。 */
	void delete(Long userId, Long id);

	/** 拖拽排序：orderedIds 必须给全家庭内每一行，sort_no 按新顺序重写为 1…n。 */
	void sort(Long userId, PaymentAccountSortRequest request);

}
