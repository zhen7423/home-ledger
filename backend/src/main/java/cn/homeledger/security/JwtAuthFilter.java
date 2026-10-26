package cn.homeledger.security;

import java.io.IOException;
import java.util.List;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import cn.homeledger.common.ApiResponseWriter;
import cn.homeledger.common.AuthContext;
import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.mapper.AuthContextMapper;
import cn.homeledger.security.JwtService.ParsedToken;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * 无 Bearer 头时不放行也不拒绝，只是不建立认证——由 Security 的 AuthenticationEntryPoint 对受保护路径统一回 401，
 * 这样 permitAll 路径（登录、注册、健康检查）无需令牌即可通过。
 * <p>
 * 刻意不注册为 Spring Bean：Boot 会把任何 Filter 类型的 Bean 额外注册进 Servlet 容器，导致本过滤器执行两次。
 * 由 SecurityConfig 直接 new 出来挂进过滤器链。
 */
public class JwtAuthFilter extends OncePerRequestFilter {

	private static final String BEARER_PREFIX = "Bearer ";

	private static final List<GrantedAuthority> AUTHORITIES = List.of(new SimpleGrantedAuthority("ROLE_USER"));

	private final JwtService jwtService;

	private final TokenVersionService tokenVersionService;

	private final AuthContextMapper authContextMapper;

	private final ApiResponseWriter responseWriter;

	public JwtAuthFilter(JwtService jwtService, TokenVersionService tokenVersionService,
			AuthContextMapper authContextMapper, ApiResponseWriter responseWriter) {
		this.jwtService = jwtService;
		this.tokenVersionService = tokenVersionService;
		this.authContextMapper = authContextMapper;
		this.responseWriter = responseWriter;
	}

	@Override
	protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
			throws ServletException, IOException {
		try {
			String header = request.getHeader("Authorization");
			if (header == null || !header.startsWith(BEARER_PREFIX)) {
				chain.doFilter(request, response);
				return;
			}
			if (!authenticate(header.substring(BEARER_PREFIX.length()).trim(), response)) {
				return;
			}
			chain.doFilter(request, response);
		}
		finally {
			// 线程会被容器复用，登录态与租户上下文必须在此清空，否则下一个请求可能带着上一个用户的 familyId
			AuthContextHolder.clear();
			SecurityContextHolder.clearContext();
		}
	}

	/** 返回 false 表示已就地写出错误响应，调用方应立即结束。 */
	private boolean authenticate(String token, HttpServletResponse response) throws IOException {
		ParsedToken parsed;
		try {
			parsed = this.jwtService.parseAccessToken(token);
		}
		catch (BizException ex) {
			this.responseWriter.write(response, ex.errorCode(), ex.getMessage());
			return false;
		}
		if (parsed.tokenVersion() != this.tokenVersionService.current(parsed.userId())) {
			this.responseWriter.write(response, ErrorCode.TOKEN_REVOKED);
			return false;
		}
		AuthContext context = this.authContextMapper.selectByUserId(parsed.userId());
		if (context == null) {
			this.responseWriter.write(response, ErrorCode.TOKEN_REVOKED, "账号已注销，请重新登录");
			return false;
		}
		AuthContextHolder.set(context);
		SecurityContextHolder.getContext()
			.setAuthentication(new UsernamePasswordAuthenticationToken(context, null, AUTHORITIES));
		return true;
	}

}
