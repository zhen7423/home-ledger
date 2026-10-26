package cn.homeledger.service.impl;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import cn.homeledger.common.AuthContext;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.PresetFinanceDict;
import cn.homeledger.common.PresetFinanceDict.PresetCategory;
import cn.homeledger.entity.Category;
import cn.homeledger.entity.PaymentAccount;
import cn.homeledger.mapper.CategoryMapper;
import cn.homeledger.mapper.PaymentAccountMapper;
import cn.homeledger.service.PresetFinanceDictService;

@Service
public class PresetFinanceDictServiceImpl implements PresetFinanceDictService {

	private static final Logger log = LoggerFactory.getLogger(PresetFinanceDictServiceImpl.class);

	private final CategoryMapper categoryMapper;

	private final PaymentAccountMapper paymentAccountMapper;

	public PresetFinanceDictServiceImpl(CategoryMapper categoryMapper, PaymentAccountMapper paymentAccountMapper) {
		this.categoryMapper = categoryMapper;
		this.paymentAccountMapper = paymentAccountMapper;
	}

	@Override
	@Transactional
	public void install(Long familyId, Long operatorUserId) {
		// 调用点（创建家庭）所在的请求里，令牌还没带上这个新家庭的 id，不切换上下文的话
		// 租户拦截器会给下面的 INSERT 注入哨兵 -1，撞上 family_id 外键直接失败。
		// 必须用 finally 还原：漏掉就是把一个错误的 familyId 留在 ThreadLocal 上，
		// 同一个 Tomcat 线程接着处理的下一个请求就会看到别人家的数据。
		AuthContext previous = AuthContextHolder.get();
		AuthContextHolder.set(new AuthContext(operatorUserId, familyId, AuthContext.ROLE_OWNER));
		try {
			insertCategories(familyId, operatorUserId, PresetFinanceDict.EXPENSE, "EXPENSE");
			insertCategories(familyId, operatorUserId, PresetFinanceDict.INCOME, "INCOME");
			insertPaymentAccounts(familyId, operatorUserId);
			log.info("预置字典已装入 familyId={}", familyId);
		}
		finally {
			if (previous == null) {
				AuthContextHolder.clear();
			}
			else {
				AuthContextHolder.set(previous);
			}
		}
	}

	private void insertCategories(Long familyId, Long operatorUserId, List<PresetCategory> presets, String type) {
		int sortNo = 1;
		for (PresetCategory preset : presets) {
			Category parent = newCategory(familyId, operatorUserId, type, null, preset.name(), preset.iconKey(),
					preset.colorIndex(), sortNo++);
			this.categoryMapper.insert(parent);
			int childSort = 1;
			for (String child : preset.children()) {
				this.categoryMapper
					.insert(newCategory(familyId, operatorUserId, type, parent.getId(), child, null, null, childSort++));
			}
		}
	}

	private void insertPaymentAccounts(Long familyId, Long operatorUserId) {
		int sortNo = 1;
		for (String name : PresetFinanceDict.PAYMENT_ACCOUNTS) {
			PaymentAccount account = new PaymentAccount();
			account.setFamilyId(familyId);
			account.setName(name);
			account.setSortNo(sortNo++);
			account.setIsDefault(name.equals(PresetFinanceDict.DEFAULT_PAYMENT_ACCOUNT) ? 1 : 0);
			account.setEnabled(1);
			account.setCreatedBy(operatorUserId);
			this.paymentAccountMapper.insert(account);
		}
	}

	private Category newCategory(Long familyId, Long operatorUserId, String type, Long parentId, String name,
			String iconKey, Integer colorIndex, int sortNo) {
		Category category = new Category();
		category.setFamilyId(familyId);
		category.setParentId(parentId);
		category.setType(type);
		category.setName(name);
		category.setIconKey(iconKey);
		category.setColorIndex(colorIndex);
		category.setSortNo(sortNo);
		category.setEnabled(1);
		category.setIsPreset(1);
		category.setCreatedBy(operatorUserId);
		return category;
	}

}
