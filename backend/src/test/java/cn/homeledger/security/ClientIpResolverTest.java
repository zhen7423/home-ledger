package cn.homeledger.security;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

/**
 * X-Real-IP 只有在请求确实来自可信代理（本机 / 内网网段，即 Nginx 所在处）时才可采信；
 * 公网直连暴露端口时该头完全由客户端控制，采信等于把限流键交给攻击者（扫描报告 2026-10-26 P0-2）。
 */
class ClientIpResolverTest {

	private final ClientIpResolver resolver = new ClientIpResolver();

	private MockHttpServletRequest request(String remoteAddr) {
		MockHttpServletRequest request = new MockHttpServletRequest();
		request.setRemoteAddr(remoteAddr);
		return request;
	}

	@Test
	void trustedProxyUsesHeader() {
		for (String proxy : new String[] { "127.0.0.1", "::1", "10.1.2.3", "172.17.0.5", "192.168.1.20" }) {
			MockHttpServletRequest request = request(proxy);
			request.addHeader(ClientIpResolver.HEADER, "203.0.113.7");
			assertThat(resolver.resolve(request)).as("来自 %s 的请求应采信头", proxy).isEqualTo("203.0.113.7");
		}
	}

	@Test
	void publicClientHeaderIsIgnored() {
		for (String spoofed : new String[] { "1.2.3.4", "203.0.113.99" }) {
			MockHttpServletRequest request = request("203.0.113.50");
			request.addHeader(ClientIpResolver.HEADER, spoofed);
			assertThat(resolver.resolve(request)).as("伪造头 %s 应被忽略", spoofed).isEqualTo("203.0.113.50");
		}
	}

	@Test
	void noHeaderFallsBackToRemoteAddr() {
		assertThat(resolver.resolve(request("203.0.113.50"))).isEqualTo("203.0.113.50");
		assertThat(resolver.resolve(request("127.0.0.1"))).isEqualTo("127.0.0.1");
	}

	@Test
	void malformedHeaderIsIgnored() {
		MockHttpServletRequest request = request("10.0.0.9");
		request.addHeader(ClientIpResolver.HEADER, "not an ip; rm -rf /");
		assertThat(resolver.resolve(request)).isEqualTo("10.0.0.9");
	}

	@Test
	void ipv4WithPortIsRejectedAsRateLimitKey() {
		// "IPv4:端口" 恰好一个冒号：整串当限流键会让同 IP 按端口分片，限流失效（复扫 P3）
		MockHttpServletRequest request = request("10.0.0.9");
		request.addHeader(ClientIpResolver.HEADER, "1.2.3.4:5678");
		assertThat(resolver.resolve(request)).isEqualTo("10.0.0.9");
		// 真 IPv6（两个及以上冒号）不受影响
		MockHttpServletRequest v6 = request("10.0.0.9");
		v6.addHeader(ClientIpResolver.HEADER, "2001:db8::1");
		assertThat(resolver.resolve(v6)).isEqualTo("2001:db8::1");
	}

	@Test
	void nullRemoteAddrWithoutTrustedProxyYieldsUnknown() {
		MockHttpServletRequest request = new MockHttpServletRequest();
		request.setRemoteAddr(null);
		request.addHeader(ClientIpResolver.HEADER, "203.0.113.7");
		assertThat(resolver.resolve(request)).isEqualTo("unknown");
	}

}
