package cn.homeledger.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import cn.homeledger.security.RestAuthenticationEntryPoint;

/**
 * 浏览器直开后端地址时的提示页（RestAuthenticationEntryPoint 的 302 落点）。
 * <p>
 * 家记没有网页版前端，被浏览器导航到受保护地址只会得到一坨 JSON。这里给出一条人能读懂的说明：
 * 本服务只有接口、没有网页登录入口，请用 App；开发者则按接口文档携带 Bearer 令牌。
 * 必须保持 UTF-8 的 text/html，禁止用 @ResponseBody 转成 JSON——那样等于又回到了原点。
 */
@RestController
public class LoginRequiredController {

	public static final String HTML = """
			<!DOCTYPE html>
			<html lang="zh-CN">
			<head>
			<meta charset="UTF-8">
			<meta name="viewport" content="width=device-width, initial-scale=1">
			<title>家记 · 请先登录</title>
			<style>
			  body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
			         background: #f2f4f7; color: #28313e; font-family: "PingFang SC", "Microsoft YaHei", system-ui, sans-serif; }
			  .card { max-width: 30rem; margin: 2rem; padding: 2.25rem 2.5rem; background: #ffffff;
			          border-radius: 12px; box-shadow: 0 8px 30px rgba(30, 45, 70, .10); line-height: 1.8; }
			  h1 { margin: 0 0 .75rem; font-size: 1.3rem; }
			  p { margin: .5rem 0; font-size: .95rem; }
			  code { background: #eef1f5; padding: .1em .4em; border-radius: 4px; font-size: .85em; }
			  .hint { color: #8a93a2; font-size: .82rem; margin-top: 1.25rem; }
			</style>
			</head>
			<body>
			<main class="card">
			  <h1>这里没有网页，只有接口</h1>
			  <p>这个地址是「家记」的后端服务接口，必须携带登录状态才能访问。</p>
			  <p>请打开手机上的「家记」App 登录后使用；本服务不提供网页版登录入口，直接在浏览器里打开不会看到任何内容。</p>
			  <p class="hint">开发者如需调试接口，请先调用登录接口获取访问令牌，并在请求头中携带 <code>Authorization: Bearer &lt;令牌&gt;</code>。</p>
			</main>
			</body>
			</html>
			""";

	@GetMapping(value = RestAuthenticationEntryPoint.LOGIN_REQUIRED_PATH, produces = "text/html;charset=UTF-8")
	public String loginRequired() {
		return HTML;
	}

}