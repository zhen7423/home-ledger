package cn.homeledger.service.impl;

import java.util.List;
import java.util.Objects;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.FinanceDictionaryResolver;
import cn.homeledger.common.StatisticsCache;
import cn.homeledger.dto.TransactionCreateRequest;
import cn.homeledger.dto.TransactionQueryRequest;
import cn.homeledger.dto.TransactionUpdateRequest;
import cn.homeledger.entity.Category;
import cn.homeledger.entity.Transaction;
import cn.homeledger.mapper.TransactionMapper;
import cn.homeledger.service.TransactionService;
import cn.homeledger.vo.MonthSummary;
import cn.homeledger.vo.TransactionPageResponse;
import cn.homeledger.vo.TransactionResponse;

/**
 * §4.2.1 记一笔与 §4.2.5 流水列表。
 */
@Service
public class TransactionServiceImpl implements TransactionService {

	/** §4.2.5 每页 30 条；上限与 {@code PaginationInnerInterceptor.setMaxLimit} 保持一致。 */
	private static final int DEFAULT_PAGE_SIZE = 30;

	private static final int MAX_PAGE_SIZE = 200;

	private static final Logger log = LoggerFactory.getLogger(TransactionServiceImpl.class);

	private final TransactionMapper transactionMapper;

	private final FinanceDictionaryResolver dictionaryResolver;

	private final StatisticsCache statisticsCache;

	public TransactionServiceImpl(TransactionMapper transactionMapper, FinanceDictionaryResolver dictionaryResolver,
			StatisticsCache statisticsCache) {
		this.transactionMapper = transactionMapper;
		this.dictionaryResolver = dictionaryResolver;
		this.statisticsCache = statisticsCache;
	}

	@Override
	public TransactionPageResponse page(TransactionQueryRequest query) {
		Long familyId = currentFamilyId();
		assertSource(query.source());
		int page = (query.page() == null || query.page() < 1) ? 1 : query.page();
		int size = (query.size() == null || query.size() < 1) ? DEFAULT_PAGE_SIZE : Math.min(query.size(), MAX_PAGE_SIZE);
		IPage<Transaction> result = this.transactionMapper.selectFilteredPage(new Page<>(page, size), query, familyId);
		// 月度小计与列表同参数各查一次：它要的是整套筛选下的全量合计，用当前页的 30 条算不出整月
		List<MonthSummary> summaries = this.transactionMapper.selectMonthSummaries(query, familyId);
		return new TransactionPageResponse(
				result.getRecords().stream().map(TransactionServiceImpl::toResponse).toList(), result.getTotal(), page,
				size, result.getPages(), summaries);
	}

	@Override
	@Transactional
	public TransactionResponse create(Long userId, TransactionCreateRequest request) {
		Long familyId = currentFamilyId();
		this.dictionaryResolver.assertAmount(request.amount());
		this.dictionaryResolver.assertNotAfterToday(request.bizDate());
		FinanceDictionaryResolver.Dictionary dict = this.dictionaryResolver.resolve(familyId, request.categoryId(),
				request.subCategoryId(), request.accountId(), true, true, true);

		Transaction transaction = new Transaction();
		transaction.setFamilyId(familyId);
		transaction.setType(dict.type());
		transaction.setAmount(request.amount());
		transaction.setCategoryId(dict.category().getId());
		transaction.setCategoryNameSnapshot(dict.category().getName());
		transaction.setSubCategoryId(idOf(dict.subCategory()));
		transaction.setSubCategoryNameSnapshot(nameOf(dict.subCategory()));
		transaction.setAccountId(dict.account().getId());
		transaction.setAccountNameSnapshot(dict.account().getName());
		transaction.setBizDate(request.bizDate());
		transaction.setRemark(request.remark());
		transaction.setCreatedBy(userId);
		transaction.setRecorderNameSnapshot(this.dictionaryResolver.nicknameOf(userId));
		this.transactionMapper.insert(transaction);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_FINANCE, familyId);
		log.info("记一笔 familyId={} transactionId={} type={} operatorUserId={}", familyId, transaction.getId(),
				dict.type(), userId);
		return toResponse(requireTransaction(familyId, transaction.getId()));
	}

	@Override
	public TransactionResponse get(Long id) {
		return toResponse(requireTransaction(currentFamilyId(), id));
	}

	@Override
	@Transactional
	public TransactionResponse update(Long userId, Long id, TransactionUpdateRequest request) {
		Long familyId = currentFamilyId();
		Transaction original = requireTransaction(familyId, id);
		this.dictionaryResolver.assertAmount(request.amount());
		this.dictionaryResolver.assertNotAfterToday(request.bizDate());

		boolean topChanged = !Objects.equals(original.getCategoryId(), request.categoryId());
		boolean subChanged = !Objects.equals(original.getSubCategoryId(), request.subCategoryId());
		boolean accountChanged = !Objects.equals(original.getAccountId(), request.accountId());
		// 大类启用只在真的换了大类时才要求：挂在已停用大类下的历史流水，改备注或清小类都得能保存。
		// 小类启用则在换了大类或小类时要求——换大类时新小类必然是重新挑的，也得是启用态。
		FinanceDictionaryResolver.Dictionary dict = this.dictionaryResolver.resolve(familyId, request.categoryId(),
				request.subCategoryId(), request.accountId(), topChanged, topChanged || subChanged, accountChanged);

		original.setType(dict.type());
		original.setAmount(request.amount());
		original.setCategoryId(dict.category().getId());
		original.setSubCategoryId(idOf(dict.subCategory()));
		original.setAccountId(dict.account().getId());
		original.setBizDate(request.bizDate());
		original.setRemark(request.remark());
		// 快照只跟着变化刷新。没换类别却把名称重写一遍，等于让改名回溯历史，正是 A3 要挡住的事
		if (topChanged) {
			original.setCategoryNameSnapshot(dict.category().getName());
		}
		if (subChanged) {
			original.setSubCategoryNameSnapshot(nameOf(dict.subCategory()));
		}
		if (accountChanged) {
			original.setAccountNameSnapshot(dict.account().getName());
		}
		// recorderNameSnapshot 恒不动：成员改了昵称，不该改写历史流水上显示的记录人
		this.transactionMapper.overwrite(original);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_FINANCE, familyId);
		log.info("编辑流水 familyId={} transactionId={} operatorUserId={}", familyId, id, userId);
		return toResponse(requireTransaction(familyId, id));
	}

	@Override
	@Transactional
	public void delete(Long userId, Long id) {
		Long familyId = currentFamilyId();
		requireTransaction(familyId, id);
		// @TableLogic 会把这条改成 UPDATE deleted = 1；先查一次是为了让别家的 id 得到 404 而不是静默零行
		this.transactionMapper.deleteById(id);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_FINANCE, familyId);
		log.info("删除流水 familyId={} transactionId={} operatorUserId={}", familyId, id, userId);
	}

	/**
	 * 不认识的取值报 400 而不是当成没筛：XML 里的两个 {@code <if>} 都不命中就等于不筛选，
	 * 静默走这条路的话，前端会以为筛选生效了，看到的却是一份全量列表。
	 */
	private static void assertSource(String source) {
		if (source != null && !source.isBlank() && !"AUTO".equals(source) && !"MANUAL".equals(source)) {
			throw new BizException(ErrorCode.BAD_REQUEST, "来源筛选只有 AUTO 与 MANUAL 两种");
		}
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	private Transaction requireTransaction(Long familyId, Long id) {
		Transaction transaction = this.transactionMapper
			.selectOne(new LambdaQueryWrapper<Transaction>().eq(Transaction::getId, id)
				.eq(Transaction::getFamilyId, familyId));
		if (transaction == null) {
			throw new BizException(ErrorCode.TRANSACTION_NOT_FOUND);
		}
		return transaction;
	}

	private static Long idOf(Category category) {
		return (category == null) ? null : category.getId();
	}

	private static String nameOf(Category category) {
		return (category == null) ? null : category.getName();
	}

	private static TransactionResponse toResponse(Transaction transaction) {
		return new TransactionResponse(transaction.getId(), transaction.getType(), transaction.getAmount(),
				transaction.getCategoryId(), transaction.getCategoryNameSnapshot(), transaction.getSubCategoryId(),
				transaction.getSubCategoryNameSnapshot(), transaction.getAccountId(),
				transaction.getAccountNameSnapshot(), transaction.getBizDate(), transaction.getRemark(),
				transaction.getCreatedBy(), transaction.getRecorderNameSnapshot(), transaction.getRuleId(),
				transaction.getCreatedAt(), transaction.getUpdatedAt());
	}

}
