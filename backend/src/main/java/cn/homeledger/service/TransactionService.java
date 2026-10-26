package cn.homeledger.service;

import cn.homeledger.dto.TransactionCreateRequest;
import cn.homeledger.dto.TransactionQueryRequest;
import cn.homeledger.dto.TransactionUpdateRequest;
import cn.homeledger.vo.TransactionPageResponse;
import cn.homeledger.vo.TransactionResponse;

/**
 * §4.2.1 记一笔与流水列表。
 * <p>
 * 一笔流水记的是哪一类、走哪个账户，全部由字典行的 id 引用加上写入当时冻结的名称快照组成。
 * 快照的意义是「改名与成员退出不回溯历史」（A3、§4.1.5），所以本 Service 读字典、写字典快照，
 * 但绝不因字典变化去改历史行。
 */
public interface TransactionService {

	/**
	 * 分页 + 筛选（§4.2.5）。响应除 records / total / page / size / pages 外必带 monthSummaries，
	 * 后者是<b>同一套筛选条件下的全量</b>按月小计，不是当前页的小结。
	 */
	TransactionPageResponse page(TransactionQueryRequest query);

	/** 记一笔。收支类型由服务端从所选大类读出，名称快照一并冻结。 */
	TransactionResponse create(Long userId, TransactionCreateRequest request);

	/** 详情。不属于当前家庭的 id 与不存在的 id 一样返回 TRANSACTION_NOT_FOUND。 */
	TransactionResponse get(Long id);

	/**
	 * 整份表单覆盖式编辑。类别或账户相对原值发生变化时才刷新对应的名称快照，没变的保持原值；
	 * 记录人快照恒不动。挂在天上的大类已停用时，只要用户没换类别就仍允许保存。
	 */
	TransactionResponse update(Long userId, Long id, TransactionUpdateRequest request);

	/** 软删除。二次确认在前端做。 */
	void delete(Long userId, Long id);

}
