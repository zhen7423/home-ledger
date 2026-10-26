package cn.homeledger.mapper;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.GrowthStandardDict;

/**
 * growth_standard_dict 是静态字典，运行期只读。
 * <p>
 * 本表在租户白名单里（§5.2）：它没有 family_id，注入会直接 SQL 报错。
 */
@Mapper
public interface GrowthStandardDictMapper extends BaseMapper<GrowthStandardDict> {

	/**
	 * 取该性别该指标的标准表全量行，按横轴升序——插值要的是相邻两行，排序不能交给调用方。
	 * <p>
	 * 没有 {@code deleted = 0}：这张表没有 deleted 列（§4.3⑤ 的静态字典不带四个通用列），
	 * 照抄别的 XML 顺手带上它会直接 SQL 报错。
	 */
	List<GrowthStandardDict> selectByGenderAndMetric(@Param("gender") String gender, @Param("metric") String metric);

}
