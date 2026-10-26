package cn.homeledger.service;

import java.util.List;
import java.util.Set;

import cn.homeledger.dto.ModulePreferenceSaveRequest;
import cn.homeledger.vo.ModulePreferenceResponse;

/**
 * §3.2 的模块开关与 Tab 顺序。用户级偏好，按 {@code user_id} 归属。
 */
public interface ModulePreferenceService {

	/** 恒返回全部三个模块，按 {@code sort_no} 升序；没设置过的按默认值补齐。 */
	List<ModulePreferenceResponse> modules(Long userId);

	/**
	 * 已启用的模块集合。
	 * <p>
	 * 首页聚合要用它过滤最近动态（§4.6 第 6 条：关掉猫咪模块后最近动态不再出现猫咪条目），
	 * 而那是「按模块取数」的地方，不该各自去查一遍偏好表。
	 */
	Set<String> enabledKeys(Long userId);

	/** 按数组顺序整体保存。未提交的模块沿用已存值，没存过就用默认值。 */
	void saveModules(Long userId, ModulePreferenceSaveRequest request);

}
