package cn.homeledger.service.impl;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.dto.PaymentAccountCreateRequest;
import cn.homeledger.dto.PaymentAccountSortRequest;
import cn.homeledger.dto.PaymentAccountUpdateRequest;
import cn.homeledger.entity.PaymentAccount;
import cn.homeledger.mapper.PaymentAccountMapper;
import cn.homeledger.mapper.RecurringRuleMapper;
import cn.homeledger.service.PaymentAccountService;
import cn.homeledger.vo.PaymentAccountResponse;

/**
 * §4.2.1 支付方式字典。
 * <p>
 * 「每个家庭恰好一行 is_default = 1」是靠设默认时先清后设维持的，数据库里并没有约束拦着，所以这条不变量
 * 只在事务内成立——所有会动到它的方法都标了 {@code @Transactional}。
 */
@Service
public class PaymentAccountServiceImpl implements PaymentAccountService {

	private static final Logger log = LoggerFactory.getLogger(PaymentAccountServiceImpl.class);

	private final PaymentAccountMapper paymentAccountMapper;

	private final RecurringRuleMapper recurringRuleMapper;

	public PaymentAccountServiceImpl(PaymentAccountMapper paymentAccountMapper,
			RecurringRuleMapper recurringRuleMapper) {
		this.paymentAccountMapper = paymentAccountMapper;
		this.recurringRuleMapper = recurringRuleMapper;
	}

	@Override
	public List<PaymentAccountResponse> list(boolean enabledOnly) {
		List<PaymentAccount> rows = this.paymentAccountMapper.selectList(familyScope(currentFamilyId())
			.eq(enabledOnly, PaymentAccount::getEnabled, 1)
			.orderByAsc(PaymentAccount::getSortNo)
			.orderByAsc(PaymentAccount::getId));
		return rows.stream().map(PaymentAccountServiceImpl::toResponse).toList();
	}

	@Override
	@Transactional
	public PaymentAccountResponse create(Long userId, PaymentAccountCreateRequest request) {
		Long familyId = currentFamilyId();
		String name = request.name().trim();
		assertNameFree(familyId, name, null);

		PaymentAccount account = new PaymentAccount();
		account.setFamilyId(familyId);
		account.setName(name);
		account.setSortNo(nextSortNo(familyId));
		account.setIsDefault(0);
		account.setEnabled(1);
		account.setCreatedBy(userId);
		this.paymentAccountMapper.insert(account);
		log.info("新建支付方式 familyId={} accountId={} operatorUserId={}", familyId, account.getId(), userId);
		return toResponse(account);
	}

	@Override
	@Transactional
	public PaymentAccountResponse update(Long userId, Long id, PaymentAccountUpdateRequest request) {
		Long familyId = currentFamilyId();
		PaymentAccount account = requireAccount(familyId, id);
		if (request.name() != null) {
			String name = request.name().trim();
			// 这里补一道空白校验：DTO 的 name 可空表示「不改」，加 @NotBlank 会连带把 null 也拒了，
			// 于是「传一串空格改名」会绕过校验落成空名称，与类别改名的 @NotBlank 口径不一致。
			if (name.isEmpty()) {
				throw new BizException(ErrorCode.VALIDATION_FAILED, "支付方式名称不能为空");
			}
			assertNameFree(familyId, name, id);
			account.setName(name);
		}
		applyDefault(familyId, account, request.isDefault());
		this.paymentAccountMapper.updateById(account);
		log.info("更新支付方式 familyId={} accountId={} isDefault={} operatorUserId={}", familyId, id,
				account.getIsDefault(), userId);
		return toResponse(account);
	}

	@Override
	@Transactional
	public PaymentAccountResponse toggle(Long userId, Long id) {
		Long familyId = currentFamilyId();
		PaymentAccount account = requireAccount(familyId, id);
		if (account.getIsDefault() == 1) {
			throw new BizException(ErrorCode.PAYMENT_ACCOUNT_IS_DEFAULT);
		}
		boolean disabling = account.getEnabled() == 1;
		// 停用方向才检查：规则下次生成流水时要用的支付方式已经在记账面板上选不到了
		if (disabling && this.recurringRuleMapper.countByAccount(familyId, id) > 0) {
			throw new BizException(ErrorCode.PAYMENT_ACCOUNT_USED_BY_RECURRING_RULE);
		}
		account.setEnabled(disabling ? 0 : 1);
		this.paymentAccountMapper.updateById(account);
		log.info("支付方式启停 familyId={} accountId={} enabled={} operatorUserId={}", familyId, id,
				account.getEnabled(), userId);
		return toResponse(account);
	}

	@Override
	@Transactional
	public void delete(Long userId, Long id) {
		Long familyId = currentFamilyId();
		PaymentAccount account = requireAccount(familyId, id);
		if (account.getIsDefault() == 1) {
			throw new BizException(ErrorCode.PAYMENT_ACCOUNT_IS_DEFAULT);
		}
		if (this.paymentAccountMapper.countAnyTransaction(familyId, id) > 0) {
			throw new BizException(ErrorCode.PAYMENT_ACCOUNT_IN_USE);
		}
		// 支付方式同样是物理删除，规则里的 account_id 会直接悬空
		if (this.recurringRuleMapper.countByAccount(familyId, id) > 0) {
			throw new BizException(ErrorCode.PAYMENT_ACCOUNT_USED_BY_RECURRING_RULE);
		}
		this.paymentAccountMapper.deletePhysically(familyId, id);
		log.info("删除支付方式 familyId={} accountId={} name={} operatorUserId={}", familyId, id, account.getName(),
				userId);
	}

	@Override
	@Transactional
	public void sort(Long userId, PaymentAccountSortRequest request) {
		Long familyId = currentFamilyId();
		Set<Long> submitted = new HashSet<>(request.orderedIds());
		Set<Long> actual = this.paymentAccountMapper.selectList(familyScope(familyId))
			.stream()
			.map(PaymentAccount::getId)
			.collect(Collectors.toSet());
		// 支付方式不分层，整份清单都要给全：少给一行就会被重排出来的 1…n 挤成重号
		if (!submitted.equals(actual)) {
			throw new BizException(ErrorCode.SORT_IDS_MISMATCH);
		}
		int sortNo = 1;
		for (Long id : request.orderedIds()) {
			PaymentAccount update = new PaymentAccount();
			update.setId(id);
			update.setSortNo(sortNo++);
			this.paymentAccountMapper.updateById(update);
		}
		log.info("支付方式排序 familyId={} 条数={} operatorUserId={}", familyId, actual.size(), userId);
	}

	/**
	 * 改名与设默认同一个 PATCH 端点（§8「默认项不单开端点」），所以这里只处理 isDefault 那半个语义。
	 * <p>
	 * {@code false} 分两种情况：本行不是默认，那这一下什么都没发生，放过去；本行正是默认，取消它会让
	 * 全家没有默认项，只能拒绝——换默认的正确做法是把另一行设为默认。
	 */
	private void applyDefault(Long familyId, PaymentAccount account, Boolean isDefault) {
		if (isDefault == null) {
			return;
		}
		if (!isDefault) {
			if (account.getIsDefault() == 1) {
				throw new BizException(ErrorCode.BAD_REQUEST, "家庭必须留一个默认支付方式，请改为把其他支付方式设为默认");
			}
			return;
		}
		if (account.getEnabled() != 1) {
			throw new BizException(ErrorCode.BAD_REQUEST, "该支付方式已停用，要先启用才能设为默认");
		}
		if (account.getIsDefault() == 1) {
			return;
		}
		// 先清后设：反过来会留出一个「全家没有默认项」的中间状态，而记账表单每次都靠它预选
		this.paymentAccountMapper.clearDefault(familyId);
		account.setIsDefault(1);
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	private PaymentAccount requireAccount(Long familyId, Long id) {
		PaymentAccount account = this.paymentAccountMapper
			.selectOne(new LambdaQueryWrapper<PaymentAccount>().eq(PaymentAccount::getId, id)
				.eq(PaymentAccount::getFamilyId, familyId));
		if (account == null) {
			throw new BizException(ErrorCode.PAYMENT_ACCOUNT_NOT_FOUND);
		}
		return account;
	}

	/** 名称比较交给 MySQL 做，utf8mb4_0900_ai_ci 本就大小写不敏感（§4.2.1）。 */
	private void assertNameFree(Long familyId, String name, Long excludeId) {
		Long duplicated = this.paymentAccountMapper.selectCount(familyScope(familyId)
			.eq(PaymentAccount::getName, name)
			.ne(excludeId != null, PaymentAccount::getId, excludeId));
		if (duplicated != null && duplicated > 0) {
			throw new BizException(ErrorCode.PAYMENT_ACCOUNT_NAME_DUPLICATED);
		}
	}

	private int nextSortNo(Long familyId) {
		int max = 0;
		for (PaymentAccount account : this.paymentAccountMapper.selectList(familyScope(familyId))) {
			max = Math.max(max, account.getSortNo());
		}
		return max + 1;
	}

	private static LambdaQueryWrapper<PaymentAccount> familyScope(Long familyId) {
		return new LambdaQueryWrapper<PaymentAccount>().eq(PaymentAccount::getFamilyId, familyId);
	}

	private static PaymentAccountResponse toResponse(PaymentAccount account) {
		return new PaymentAccountResponse(account.getId(), account.getName(), account.getSortNo(),
				account.getIsDefault() == 1, account.getEnabled() == 1);
	}

}
