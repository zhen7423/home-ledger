package cn.homeledger.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.BabyVaccinePlan;

/**
 * baby_vaccine_plan 不在租户白名单内（§5.2），family_id 条件由拦截器注入。
 */
@Mapper
public interface BabyVaccinePlanMapper extends BaseMapper<BabyVaccinePlan> {

	/**
	 * 取某个宝宝的应种清单，按应种日期升序、同日按 id 升序。
	 * <p>
	 * {@code family_id} 手写也得带：自定义 SQL 虽经拦截器改写，但显式带上能让「重算时的对齐范围」
	 * 与「列表读的范围」在代码里就是同一个条件，不依赖读代码的人知道拦截器的存在。
	 */
	List<BabyVaccinePlan> listByBaby(@Param("familyId") Long familyId, @Param("babyId") Long babyId);

	/**
	 * 覆盖一行的可变列：{@code due_date}（改生日重算）、{@code status} / {@code skip_reason} / {@code record_id}
	 * （标记与接种记录的双向回写）。
	 * <p>
	 * 不能用 {@code BaseMapper#updateById}——它默认忽略实体里的 null，而撤销跳过必须能把
	 * {@code skip_reason} 真的清成 NULL、删接种记录必须能把 {@code record_id} 真的清成 NULL。
	 * <p>
	 * {@code vaccine_name} / {@code dose_no} 不在 SET 里：它们是与内置程序表对齐的键，
	 * 允许改会让改生日重算按名称对不上行（§5.2）。
	 */
	int overwrite(@Param("plan") BabyVaccinePlan plan);

}
