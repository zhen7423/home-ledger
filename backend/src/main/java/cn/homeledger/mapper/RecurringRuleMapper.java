package cn.homeledger.mapper;

import java.time.LocalDate;
import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.annotation.InterceptorIgnore;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.RecurringRule;

/**
 * recurring_rule 不在租户白名单内（§5.2），自定义 SQL 里仍显式写 family_id 条件，与 S3 的
 * {@code CategoryMapper} 同一写法——拦截器还会再注入一次，两处都漏不掉。
 * <p>
 * 唯一的例外是 {@link #selectAllEnabledRules}，它必须跨家庭，理由写在那个方法的注释里。
 */
@Mapper
public interface RecurringRuleMapper extends BaseMapper<RecurringRule> {

	/**
	 * 定时任务的跨家庭扫描。
	 * <p>
	 * 这是全项目第二处租户绕过（第一处见 {@code PresetFinanceDictServiceImpl}），
	 * 故 XML 里刻意不写 family_id 条件——写了就把绕过白做一遍。调用方必须按 family_id 逐条切换
	 * {@code AuthContextHolder} 后再写库，切换与恢复的形状照抄 PresetFinanceDictServiceImpl。
	 * <p>
	 * ORDER BY family_id 不是可选的：它让上下文切换每个家庭只发生一次，而不是每条规则一次。
	 */
	@InterceptorIgnore(tenantLine = "true")
	List<RecurringRule> selectAllEnabledRules(@Param("today") LocalDate today);

	/**
	 * 推进游标。写成 UPDATE 而不是「查出来再 updateById」：定时任务里不需要读回整行。
	 * <p>
	 * 按主键定位，故没有显式 family_id 条件，家庭由拦截器注入——调用它之前线程上下文已经切到这个规则所属的家庭。
	 */
	int advanceProcessedDate(@Param("id") Long id, @Param("processedDate") LocalDate processedDate);

	/**
	 * 整体覆盖式编辑（B3 的 PUT）。列名要一个个写出来，不能用 {@code BaseMapper#updateById}：
	 * 它默认忽略实体里的 null（FieldStrategy.NOT_NULL），而编辑表单是整份覆盖提交的——
	 * 用户把截止日期改成「长期有效」或小类清空，就得真的写成 NULL，否则界面上生效、刷新一下又回来了。
	 * <p>
	 * family_id / created_by 不在 SET 里：编辑不改变归属。enabled 在里面，但启停走 toggle。
	 */
	int overwrite(@Param("r") RecurringRule rule);

	/**
	 * 建规则的人退出家庭时，暂停他名下这个家庭的全部规则（§4.2.3、B8）。
	 * <p>
	 * 不删规则：历史流水上的 rule_id 要能反查，而规则本身可能由别人接手继续用。
	 * 暂停而非删除也让「误退出再加入」不至于丢掉配置。
	 */
	int disableByCreator(@Param("familyId") Long familyId, @Param("userId") Long userId);

	/**
	 * 解散家庭时把该家庭的全部周期规则软删（§4.1.6，执行计划 §9 第 13 项）。
	 * <p>
	 * 与 {@link #disableByCreator} 是两回事：退出成员只是离开这个人，规则这个意图还在、可能由别人接手，所以暂停；
	 * 而家庭本身已经不存在，暂停暗示还能恢复，恢复却无从谈起。软删与「用户自己删掉规则」是同一种结局，
	 * 它生成过的流水照旧留着，rule_id 仍能反查。
	 */
	int softDeleteByFamily(@Param("familyId") Long familyId);

	/**
	 * 该类别被多少条规则引用，用于拦截停用与删除（B8）。
	 * <p>
	 * 含已暂停的规则——暂停的规则将来还会恢复，那时它照样要用这个类别生成流水。
	 * 一个 categoryId 同时匹配大类与小类两列，理由同 {@code CategoryMapper#countAnyTransaction}。
	 */
	int countByCategory(@Param("familyId") Long familyId, @Param("categoryId") Long categoryId);

	/** 该支付方式被多少条规则引用，含已暂停的规则，口径同 {@link #countByCategory}。 */
	int countByAccount(@Param("familyId") Long familyId, @Param("accountId") Long accountId);

}
