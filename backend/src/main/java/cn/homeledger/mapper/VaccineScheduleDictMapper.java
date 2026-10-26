package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.VaccineScheduleDict;

/**
 * vaccine_schedule_dict 是静态字典，运行期只读，只用 {@code BaseMapper} 的查询：
 * 生成应种清单时按 due_age_months 升序整表读出（§4.4.4），没有任何自定义 SQL，故没有同名 XML。
 * <p>
 * 本表在租户白名单里（§5.2）：它没有 family_id，注入会直接 SQL 报错。
 */
@Mapper
public interface VaccineScheduleDictMapper extends BaseMapper<VaccineScheduleDict> {

}
