package cn.homeledger.mapper;

import java.time.LocalDate;
import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.RecurringExecutionLog;

/**
 * recurring_execution_log 不在租户白名单内（§5.2），自定义 SQL 照项目约定显式写 family_id，
 * 只有按主键推进游标的那条例外——它靠 id 定位，家庭条件由拦截器注入。
 */
@Mapper
public interface RecurringExecutionLogMapper extends BaseMapper<RecurringExecutionLog> {

	/**
	 * 幂等判定，返回值 &gt; 0 即这个执行日已经生成过，跳过。
	 * <p>
	 * 签名里没有 familyId，因为 rule_id 已经把家庭限定了（一条规则只属于一个家庭）。
	 * 家庭条件靠拦截器注入，与 {@code TransactionMapper#overwrite} 那类按主键定位的语句同一写法。
	 */
	int countByRuleAndDate(@Param("ruleId") Long ruleId, @Param("bizDate") LocalDate bizDate);

	/** 规则详情页的「执行记录」列表，按 biz_date 倒序。 */
	List<RecurringExecutionLog> selectByRule(@Param("familyId") Long familyId, @Param("ruleId") Long ruleId);

	/** 首页「今天自动记了 N 笔」的那个 N（§1.3）。本表冗余了 family_id，所以不必 JOIN 规则表。 */
	int countByFamilyAndDate(@Param("familyId") Long familyId, @Param("bizDate") LocalDate bizDate);

}
