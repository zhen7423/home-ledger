package cn.homeledger.common;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;

import org.springframework.stereotype.Component;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.entity.Category;
import cn.homeledger.entity.PaymentAccount;
import cn.homeledger.entity.User;
import cn.homeledger.mapper.CategoryMapper;
import cn.homeledger.mapper.PaymentAccountMapper;
import cn.homeledger.mapper.UserMapper;

/**
 * 记账类请求共用的字典校验（§4.2.1、§4.2.3）。
 * <p>
 * 记一笔流水与建一条周期规则要问的是同一批问题：类别在不在本家庭里、是不是大类、小类认不认这个大类、
 * 支付方式在不在本家庭里、金额能不能收。这两处的规则必须一条命，否则症状会是「规则能建但流水记不进」——
 * 一个 S3 测不到、S4 也测不出来的裂缝，所以从 TransactionServiceImpl 里提出来放在这里。
 */
@Component
public class FinanceDictionaryResolver {

	private static final int MAX_AMOUNT_SCALE = 2;

	/** DECIMAL(12,2) 最多放 10 位整数。超出的输入交给数据库只会得到一条截断异常的 500，不如在这里给句话。 */
	private static final BigDecimal MAX_AMOUNT = new BigDecimal("9999999999.99");

	private final CategoryMapper categoryMapper;

	private final PaymentAccountMapper paymentAccountMapper;

	private final UserMapper userMapper;

	private final Clock clock;

	public FinanceDictionaryResolver(CategoryMapper categoryMapper, PaymentAccountMapper paymentAccountMapper,
			UserMapper userMapper, Clock clock) {
		this.categoryMapper = categoryMapper;
		this.paymentAccountMapper = paymentAccountMapper;
		this.userMapper = userMapper;
		this.clock = clock;
	}

	/**
	 * 校验三个字典项都落在当前家庭里、层级关系正确，并带回要冻结的名称。
	 * <p>
	 * 三个 usable 开关分开而不是合成一个，是因为「编辑一笔历史流水」要按变化分别放宽：挂在已停用大类下的流水
	 * 改个备注就得能保存，但它的小类若是重新挑的，新小类仍必须是启用态（{@code TransactionServiceImpl#update}）。
	 * <p>
	 * 收支类型取自大类而不是客户端传入：让客户端另传一个 type，就会出现「EXPENSE 的类别配一条 INCOME
	 * 流水」这种统计时两头进不去的脏数据（§4.2.1）。
	 */
	public Dictionary resolve(Long familyId, Long categoryId, Long subCategoryId, Long accountId,
			boolean topMustBeUsable, boolean subMustBeUsable, boolean accountMustBeUsable) {
		Category category = requireCategory(familyId, categoryId);
		if (category.getParentId() != null) {
			throw new BizException(ErrorCode.BAD_REQUEST, "categoryId 要填大类，小类请填在 subCategoryId");
		}
		if (topMustBeUsable && category.getEnabled() != 1) {
			throw new BizException(ErrorCode.CATEGORY_DISABLED);
		}
		Category subCategory = null;
		if (subCategoryId != null) {
			subCategory = requireCategory(familyId, subCategoryId);
			if (!category.getId().equals(subCategory.getParentId())) {
				throw new BizException(ErrorCode.CATEGORY_PARENT_MISMATCH);
			}
			if (subMustBeUsable && subCategory.getEnabled() != 1) {
				throw new BizException(ErrorCode.CATEGORY_DISABLED);
			}
		}
		PaymentAccount account = requireAccount(familyId, accountId);
		if (accountMustBeUsable && account.getEnabled() != 1) {
			throw new BizException(ErrorCode.BAD_REQUEST, "该支付方式已停用，不能用于新记录");
		}
		return new Dictionary(category.getType(), category, subCategory, account);
	}

	public void assertAmount(BigDecimal amount) {
		if (amount.scale() > MAX_AMOUNT_SCALE) {
			// 不四舍五入：用户输入 1.005 被静默存成 1.01 是数据错误，不是精度取舍
			throw new BizException(ErrorCode.AMOUNT_SCALE_INVALID);
		}
		if (amount.compareTo(MAX_AMOUNT) > 0) {
			throw new BizException(ErrorCode.BAD_REQUEST, "单笔金额最多 10 位整数");
		}
	}

	/** 允许补记过去，不设下限；晚于今天不行。时区由注入的 Clock 定，写 LocalDate.now() 会被部署机时区污染。 */
	public void assertNotAfterToday(LocalDate bizDate) {
		if (bizDate.isAfter(LocalDate.now(this.clock))) {
			throw new BizException(ErrorCode.BIZ_DATE_IN_FUTURE);
		}
	}

	/** 记录人昵称，用于流水上的快照列。取不到就是令牌已失效，没有第二种可能。 */
	public String nicknameOf(Long userId) {
		User user = this.userMapper.selectById(userId);
		if (user == null) {
			throw new BizException(ErrorCode.UNAUTHORIZED);
		}
		return user.getNickname();
	}

	private Category requireCategory(Long familyId, Long id) {
		Category category = this.categoryMapper
			.selectOne(new LambdaQueryWrapper<Category>().eq(Category::getId, id)
				.eq(Category::getFamilyId, familyId));
		if (category == null) {
			throw new BizException(ErrorCode.CATEGORY_NOT_FOUND);
		}
		return category;
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

	/** 校验通过、准备冻结进流水的三个字典项。subCategory 可以为空，表示只选到大类。 */
	public record Dictionary(String type, Category category, Category subCategory, PaymentAccount account) {

	}

}
