package cn.homeledger.service.impl;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.ModuleKey;
import cn.homeledger.dto.ModulePreferenceSaveRequest;
import cn.homeledger.entity.ModulePreference;
import cn.homeledger.mapper.ModulePreferenceMapper;
import cn.homeledger.service.ModulePreferenceService;
import cn.homeledger.vo.ModulePreferenceResponse;

/**
 * §3.2 的模块开关与 Tab 顺序。
 * <p>
 * 全量读进内存再补齐默认值，不写一条聚合 SQL：一个用户最多三行，而「哪几个模块有行、没行的取什么默认」
 * 这件事在 SQL 里表达不出来（要 LEFT JOIN 一张常量表），只有 Java 侧说得清。
 * <p>
 * 库里存的 {@code module_key} 认不出来时<b>静默跳过</b>而不是抛异常（同 {@code ReminderType.of} 的取舍）：
 * 那行是老版本 App 写下的新模块，让整个设置页 500 是最差的处置，而它会自然地从响应里消失。
 */
@Service
public class ModulePreferenceServiceImpl implements ModulePreferenceService {

	private static final Logger log = LoggerFactory.getLogger(ModulePreferenceServiceImpl.class);

	private final ModulePreferenceMapper modulePreferenceMapper;

	public ModulePreferenceServiceImpl(ModulePreferenceMapper modulePreferenceMapper) {
		this.modulePreferenceMapper = modulePreferenceMapper;
	}

	@Override
	public List<ModulePreferenceResponse> modules(Long userId) {
		return ordered(storedOf(userId));
	}

	@Override
	public Set<String> enabledKeys(Long userId) {
		return ordered(storedOf(userId)).stream()
			.filter(ModulePreferenceResponse::enabled)
			.map(ModulePreferenceResponse::moduleKey)
			.collect(Collectors.toUnmodifiableSet());
	}

	@Override
	@Transactional
	public void saveModules(Long userId, ModulePreferenceSaveRequest request) {
		Map<String, ModulePreference> stored = storedOf(userId);
		// 提交顺序即展示顺序。请求内去重不能省：唯一索引挡不住同一事务里的两行，那时用户看到的是一条 500
		Set<String> seen = new HashSet<>();
		Map<String, Boolean> enabled = new LinkedHashMap<>();
		for (ModulePreferenceSaveRequest.Item item : request.items()) {
			ModuleKey key = ModuleKey.of(item.moduleKey());
			if (key == null) {
				throw new BizException(ErrorCode.BAD_REQUEST, "不认识的模块：" + item.moduleKey());
			}
			if (!seen.add(item.moduleKey())) {
				throw new BizException(ErrorCode.BAD_REQUEST, "同一个模块提交了两次：" + item.moduleKey());
			}
			enabled.put(item.moduleKey(), item.enabled());
		}
		// 提交过的按提交顺序排在最前，没提交的接在后面——沿用它们当前的值与相对顺序。
		// 于是「只提交一项」不会把另外两项挤成同一个 sort_no，也不会静默关掉它们
		List<String> order = new ArrayList<>(enabled.keySet());
		for (ModulePreferenceResponse row : ordered(stored)) {
			if (!enabled.containsKey(row.moduleKey())) {
				enabled.put(row.moduleKey(), row.enabled());
				order.add(row.moduleKey());
			}
		}
		int sortNo = 0;
		for (String moduleKey : order) {
			upsert(userId, stored.get(moduleKey), moduleKey, enabled.get(moduleKey), sortNo++);
		}
		log.info("保存模块开关 userId={} count={}", userId, order.size());
	}

	/**
	 * 有行就改，没行就插。
	 * <p>
	 * 改的时候只带 id / enabled / sort_no 去更新，不复用查出来的那行：实体里的 created_at 一旦非空，
	 * {@code updateById} 会把旧值原样写回去，updated_at 的 ON UPDATE CURRENT_TIMESTAMP 也就不会触发了
	 * （与 {@code ReminderServiceImpl.saveSettings} 同一处坑）。
	 */
	private void upsert(Long userId, ModulePreference stored, String moduleKey, boolean enabled, int sortNo) {
		if (stored == null) {
			ModulePreference row = new ModulePreference();
			row.setUserId(userId);
			row.setModuleKey(moduleKey);
			row.setEnabled(enabled ? 1 : 0);
			row.setSortNo(sortNo);
			this.modulePreferenceMapper.insert(row);
			return;
		}
		ModulePreference patch = new ModulePreference();
		patch.setId(stored.getId());
		patch.setEnabled(enabled ? 1 : 0);
		patch.setSortNo(sortNo);
		this.modulePreferenceMapper.updateById(patch);
	}

	/** 按 user_id 全取。本表在租户白名单里，这个条件是唯一的越权防线，不能省（§5.2）。 */
	private Map<String, ModulePreference> storedOf(Long userId) {
		return this.modulePreferenceMapper
			.selectList(new LambdaQueryWrapper<ModulePreference>().eq(ModulePreference::getUserId, userId))
			.stream()
			.collect(Collectors.toMap(ModulePreference::getModuleKey, row -> row, (first, second) -> first));
	}

	/** 恒返回三个模块：库里的值盖在默认值上，再按 sort_no 排一次。 */
	private static List<ModulePreferenceResponse> ordered(Map<String, ModulePreference> stored) {
		return Arrays.stream(ModuleKey.values())
			.map(key -> {
				ModulePreference row = stored.get(key.name());
				return new ModulePreferenceResponse(key.name(), key.label(),
						row == null || row.getEnabled() == null || row.getEnabled() != 0,
						row == null || row.getSortNo() == null ? key.defaultSortNo() : row.getSortNo());
			})
			// sort_no 相同时按枚举顺序兜底：排序不稳定会让同一份数据两次查询给出两个 Tab 顺序
			.sorted(Comparator.comparingInt(ModulePreferenceResponse::sortNo)
				.thenComparingInt(row -> ModuleKey.of(row.moduleKey()).ordinal()))
			.toList();
	}

}
