package cn.homeledger.service;

import cn.homeledger.vo.BabyCurveResponse;

/**
 * §4.4.3 生长曲线。插值与所处区间的判定都在服务端，标准表整份随响应下发供前端画带。
 */
public interface BabyCurveService {

	/**
	 * @param metric 用户可选的五个指标之一，不传按 {@code HEIGHT}（§1.4 第 23 条）。原样回显在响应的
	 *               {@code metric} 里，服务端按年龄选中的那张表另放在 {@code standardMetric}。
	 */
	BabyCurveResponse curve(Long babyId, String metric);

}
