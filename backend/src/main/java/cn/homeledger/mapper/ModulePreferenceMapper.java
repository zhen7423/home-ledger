package cn.homeledger.mapper;

import org.apache.ibatis.annotations.Mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import cn.homeledger.entity.ModulePreference;

/**
 * module_preference 在租户白名单里（§5.2，S2 就预置了），拦截器不会替它补任何条件，
 * 所以读写都必须自己带 {@code user_id} 条件——走 {@code LambdaQueryWrapper} 时别漏。
 * <p>
 * 本接口没有任何自定义 SQL：只有一个「按 user_id 全取」的查询和一个 upsert，BaseMapper 够用，
 * 因而不建 XML（§6.4.2 只要求把自定义 SQL 外置，通用 CRUD 照旧）。
 */
@Mapper
public interface ModulePreferenceMapper extends BaseMapper<ModulePreference> {

}
