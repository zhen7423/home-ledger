package cn.homeledger.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import cn.homeledger.mapper.AuthContextMapper;
import cn.homeledger.security.JwtAuthFilter;
import cn.homeledger.security.JwtService;
import cn.homeledger.security.RestAccessDeniedHandler;
import cn.homeledger.security.RestAuthenticationEntryPoint;
import cn.homeledger.security.TokenVersionService;
import cn.homeledger.common.ApiResponseWriter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

	/**
	 * §5.2 要求 BCrypt cost ≥ 10；2026-10 起按当前硬件提到 12（登录哈希耗时约 +4 倍，家庭应用可接受，
	 * 扫描报告 P2 建议）。存量 cost-10 哈希无需迁移：BCrypt 比对不看 cost，用户下次改密时自然换成 12。
	 */
	private static final int BCRYPT_COST = 12;

	/**
	 * 无需认证即可访问的路径。S1 时刻意没有引入 Security，就是为了让 /actuator/health 能被 Docker
	 * healthcheck 与云监控无凭据探测；这里显式放行以保住该行为。
	 * /error 必须放行：Spring Security 默认也过滤 ERROR 派发，否则真实异常会被二次包装成 401。
	 */
	private static final String[] PERMIT_ALL = { "/api/v1/auth/register", "/api/v1/auth/login",
			"/api/v1/auth/refresh", "/api/v1/auth/password/reset", "/api/v1/auth/wechat/login",
			"/api/v1/auth/sms/code", "/api/v1/auth/sms/login", "/actuator/health", "/actuator/health/*",
			"/actuator/info", "/api-docs", "/api-docs/**", "/swagger-ui/**", "/swagger-ui.html", "/error",
			RestAuthenticationEntryPoint.LOGIN_REQUIRED_PATH };

	@Bean
	public SecurityFilterChain securityFilterChain(HttpSecurity http, JwtService jwtService,
			TokenVersionService tokenVersionService, AuthContextMapper authContextMapper,
			ApiResponseWriter responseWriter, RestAuthenticationEntryPoint authenticationEntryPoint,
			RestAccessDeniedHandler accessDeniedHandler) throws Exception {

		JwtAuthFilter jwtAuthFilter = new JwtAuthFilter(jwtService, tokenVersionService, authContextMapper,
				responseWriter);

		http
			// 无状态 Bearer 令牌、不使用 Cookie，浏览器无从自动附带凭据，CSRF 前提不成立
			.csrf(AbstractHttpConfigurer::disable)
			.sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
			.authorizeHttpRequests(auth -> auth.requestMatchers(HttpMethod.OPTIONS, "/**")
				.permitAll()
				.requestMatchers(PERMIT_ALL)
				.permitAll()
				.anyRequest()
				.authenticated())
			.exceptionHandling(ex -> ex.authenticationEntryPoint(authenticationEntryPoint)
				.accessDeniedHandler(accessDeniedHandler))
			// HSTS 不在这里配：TLS 在 Nginx 终结，应用层看不到 HTTPS，该响应头由 S10 的 Nginx 配置负责
			.addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

		return http.build();
	}

	@Bean
	public PasswordEncoder passwordEncoder() {
		return new BCryptPasswordEncoder(BCRYPT_COST);
	}

}
