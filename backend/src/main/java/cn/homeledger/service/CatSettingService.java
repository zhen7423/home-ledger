package cn.homeledger.service;

import cn.homeledger.dto.CatSettingUpdateRequest;
import cn.homeledger.vo.CatSettingResponse;

/**
 * §4.3.3 的驱虫默认周期与 §4.3.4 的预估日均克数，家庭级共享，每家庭至多一行。
 * <p>
 * 两个方法对「有没有这一行」的态度是<b>相反的</b>，而这不是历史包袱：{@code GET} 在没行时回默认值并且
 * <b>不建那行</b>（§7.1 明写：打开一次设置页不是写入事件，落了库就把「用户没填」与「从没打开过」搅成一锅，
 * 而后者正是预估日均这一栏的判据）；{@code PUT} 才建，走 upsert，因此代码里<b>没有「找不到设置行」的分支</b>。
 */
public interface CatSettingService {

	CatSettingResponse get();

	CatSettingResponse save(Long userId, CatSettingUpdateRequest request);

}
