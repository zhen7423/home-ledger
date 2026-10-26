package cn.homeledger.security;

import java.util.regex.Pattern;

import org.springframework.stereotype.Component;

import jakarta.servlet.http.HttpServletRequest;

/**
 * §5.2 限流按「IP + 账号」双维度，这里提供 IP 维度。
 * <p>
 * 只认 X-Real-IP，不认 X-Forwarded-For：后者的标准语义是追加，客户端自带的伪造值会成为链首第一个条目，
 * 直接采信等于把限流键交给攻击者。因此 S10 配置 Nginx 时必须用
 * {@code proxy_set_header X-Real-IP $remote_addr;} 覆盖写入（而非追加），该头才可信。
 * <p>
 * 「可信」分两层（扫描报告 2026-10-26 P0-2）：头只在请求<b>确实来自可信代理</b>——即
 * {@code getRemoteAddr()} 是本机 / 内网网段（Nginx 与后端同处 compose 网络）——时才被读取；
 * 若后端端口被直接暴露、remoteAddr 是公网地址，请求头里的 X-Real-IP 完全由客户端控制，
 * 一律忽略并回落 remoteAddr。这样即使部署时误开了后端端口，限流键也无法被伪造。
 */
@Component
public class ClientIpResolver {

	/**
	 * 后端与 Nginx 之间的一份契约：限流键是否可信，取决于 deploy/nginx.conf 是否用覆盖语义
	 * （{@code proxy_set_header X-Real-IP $remote_addr;}）写入这个确切的头名。
	 * 公开出来让测试引用同一常量，改名时测试会立刻失败，迫使改动者同步 Nginx 配置。
	 */
	public static final String HEADER = "X-Real-IP";

	/** 仅接受 IPv4 / IPv6 字面量字符集，防止把任意字符串写进 Redis 键与日志。 */
	private static final Pattern IP_LITERAL = Pattern.compile("[0-9a-fA-F.:]{1,45}");

	public String resolve(HttpServletRequest request) {
		String remoteAddr = request.getRemoteAddr();
		if (isTrustedProxy(remoteAddr)) {
			String header = request.getHeader(HEADER);
			// 恰好一个冒号 = "IPv4:端口"（真 IPv6 字面量至少两个冒号），剥不掉端口就会把
			// "1.2.3.4:5678" 整串当限流键——同 IP 每次换端口各算一个键，限流形同虚设（复扫 P3）
			if (header != null && IP_LITERAL.matcher(header).matches() && colonCount(header) != 1) {
				return header;
			}
		}
		return (remoteAddr == null) ? "unknown" : remoteAddr;
	}

	private static int colonCount(String value) {
		int count = 0;
		for (int i = 0; i < value.length(); i++) {
			if (value.charAt(i) == ':') {
				count++;
			}
		}
		return count;
	}

	/**
	 * 可信代理 = 本机或内网来源：loopback、RFC1918 三段（10/8、172.16/12、192.168/16，
	 * 覆盖 Docker 默认桥接网段）、IPv6 loopback / ULA(fc00::/7) / 链路本地(fe80::/10)。
	 * 判定只看来源地址本身，不需要配置化：Nginx 永远在内网侧，公网客户端永远不是。
	 */
	private static boolean isTrustedProxy(String remoteAddr) {
		if (remoteAddr == null || remoteAddr.isEmpty()) {
			return false;
		}
		// IPv6 字面量统一小写判断（ULA fc/fd、链路本地 fe8~feb、loopback ::1 及其展开写法）
		String v6 = remoteAddr.toLowerCase();
		if (v6.equals("::1") || v6.equals("0:0:0:0:0:0:0:1") || v6.startsWith("fc") || v6.startsWith("fd")
				|| v6.startsWith("fe8") || v6.startsWith("fe9") || v6.startsWith("fea") || v6.startsWith("feb")) {
			return true;
		}
		// IPv4：按段数值判 RFC1918 与 loopback
		String[] parts = remoteAddr.split("\\.", -1);
		if (parts.length != 4) {
			return false;
		}
		int[] octets = new int[4];
		for (int i = 0; i < 4; i++) {
			try {
				octets[i] = Integer.parseInt(parts[i]);
			}
			catch (NumberFormatException ex) {
				return false;
			}
			if (octets[i] < 0 || octets[i] > 255) {
				return false;
			}
		}
		if (octets[0] == 127 || octets[0] == 10) {
			return true;
		}
		if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) {
			return true;
		}
		return octets[0] == 192 && octets[1] == 168;
	}

}
