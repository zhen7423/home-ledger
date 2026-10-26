package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.PaymentAccount;

/**
 * payment_account 不在租户白名单内（§5.2）。
 */
@Mapper
public interface PaymentAccountMapper extends BaseMapper<PaymentAccount> {

	/**
	 * 「该支付方式下是否存在任何流水」的计数，<b>含已软删除的流水</b>，理由与
	 * {@link CategoryMapper#countAnyTransaction} 相同：逻辑删除会把这部分行从自动生成的语句里滤掉。
	 */
	int countAnyTransaction(@Param("familyId") Long familyId, @Param("accountId") Long accountId);

	/**
	 * 清掉本家庭其他行的默认标记。设新默认时在同一个事务里先跑这条再置目标行，
	 * 于是「每个家庭恰好一行 is_default = 1」这个不变量不需要额外的兜底分支（§4.2.1）。
	 */
	int clearDefault(@Param("familyId") Long familyId);

	/** 真删除，理由同 {@link CategoryMapper#deletePhysically}。 */
	int deletePhysically(@Param("familyId") Long familyId, @Param("id") Long id);

}
