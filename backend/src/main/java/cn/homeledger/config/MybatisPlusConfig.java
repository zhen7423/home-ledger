package cn.homeledger.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.baomidou.mybatisplus.annotation.DbType;
import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.PaginationInnerInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.TenantLineInnerInterceptor;

@Configuration
public class MybatisPlusConfig {

	/**
	 * 拦截器顺序是硬约束：分页必须排在租户之后。反了的话 PaginationInnerInterceptor 会先按原始 SQL
	 * 生成 COUNT 语句，那条语句里还没有 family_id，于是列表内容正确而总数跨家庭泄漏——功能测试看不出来。
	 */
	@Bean
	public MybatisPlusInterceptor mybatisPlusInterceptor(FamilyTenantHandler familyTenantHandler) {
		MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
		interceptor.addInnerInterceptor(new TenantLineInnerInterceptor(familyTenantHandler));
		PaginationInnerInterceptor pagination = new PaginationInnerInterceptor(DbType.MYSQL);
		// §4.2.5 定的每页 30 条由 DTO 默认值给；这里是兜住 size=100000 这类把库拖垮的请求
		pagination.setMaxLimit(200L);
		interceptor.addInnerInterceptor(pagination);
		return interceptor;
	}

}
