package cn.homeledger.service;

import cn.homeledger.vo.HomeOverviewResponse;

/**
 * §4.6 首页的聚合数据。
 * <p>
 * 这个接口存在的意义是「一次请求」：首页要的概要、预算、最近动态三份数据分散在四个模块里，
 * 让客户端各发一次请求等于首页有四个加载态、四个失败态，而它们本该一起出现或一起重试。
 */
public interface HomeService {

	/**
	 * @param userId 当前登录用户。取它是为了按这个人的模块开关过滤最近动态（§4.6 第 6 条：
	 *        关掉猫咪模块后最近动态不再出现猫咪条目）——预览数据的可见范围跟着「他打开了哪些模块」走
	 */
	HomeOverviewResponse overview(Long userId);

}
