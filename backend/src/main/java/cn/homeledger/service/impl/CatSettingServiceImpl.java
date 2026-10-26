package cn.homeledger.service.impl;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.StatisticsCache;
import cn.homeledger.dto.CatSettingUpdateRequest;
import cn.homeledger.entity.CatSetting;
import cn.homeledger.mapper.CatSettingMapper;
import cn.homeledger.service.CatFoodBagService;
import cn.homeledger.service.CatSettingService;
import cn.homeledger.vo.CatSettingResponse;

/**
 * §4.3.3 / §4.3.4 的家庭级猫咪设置，每家庭至多一行。
 * <p>
 * 三个默认值写在这里而不是从 DDL 的 DEFAULT 读：默认值有两个答案时，改一处就会静默分叉，
 * 而用户看到的是「设置页显示 3 个月、新建记录按 1 个月算」。DDL 那一列的默认值是给
 * 「绕过应用直接写库」兜底的，应用不靠它表达语义。
 */
@Service
public class CatSettingServiceImpl implements CatSettingService {

	private static final Logger log = LoggerFactory.getLogger(CatSettingServiceImpl.class);

	private static final int DEFAULT_INTERNAL_MONTHS = 3;

	private static final int DEFAULT_EXTERNAL_MONTHS = 1;

	private final CatSettingMapper catSettingMapper;

	private final CatFoodBagService catFoodBagService;

	private final StatisticsCache statisticsCache;

	public CatSettingServiceImpl(CatSettingMapper catSettingMapper, CatFoodBagService catFoodBagService,
			StatisticsCache statisticsCache) {
		this.catSettingMapper = catSettingMapper;
		this.catFoodBagService = catFoodBagService;
		this.statisticsCache = statisticsCache;
	}

	@Override
	public CatSettingResponse get() {
		return toResponse(read(currentFamilyId()));
	}

	@Override
	@Transactional
	public CatSettingResponse save(Long userId, CatSettingUpdateRequest request) {
		Long familyId = currentFamilyId();
		CatSetting existing = read(familyId);
		if (existing == null) {
			insert(familyId, userId, request);
		}
		else {
			this.catSettingMapper.overwrite(patch(userId, request, existing.getId()));
		}
		this.statisticsCache.invalidate(StatisticsCache.MODULE_CAT, familyId);
		log.info("保存猫咪设置 familyId={} internalMonths={} externalMonths={} estimatedDailyGrams={} operatorUserId={}",
				familyId, request.internalMonths(), request.externalMonths(), request.estimatedDailyGrams(), userId);
		return toResponse(read(familyId));
	}

	/**
	 * 首次写入。那个 catch 只可能来自两个成员同时首次保存（{@code uk_cat_setting_family} 挡住了第二笔），
	 * 此时对外仍要表现为「保存成功」：给用户一句「已存在」的报错，他会以为自己没权限改设置。
	 * 重读那一行再覆盖，让本次的值真的落进去，语义与整份覆盖一致。
	 */
	private void insert(Long familyId, Long userId, CatSettingUpdateRequest request) {
		CatSetting row = patch(userId, request, null);
		row.setFamilyId(familyId);
		try {
			this.catSettingMapper.insert(row);
		}
		catch (DuplicateKeyException ex) {
			CatSetting winner = read(familyId);
			this.catSettingMapper.overwrite(patch(userId, request, winner.getId()));
		}
	}

	/**
	 * 只带要写的列，不复用查出来的整行（与 {@code ReminderServiceImpl#saveSettings} 同一条坑）：
	 * 实体里的 created_at 一旦非空，写回旧值会让 updated_at 的 ON UPDATE CURRENT_TIMESTAMP 不触发。
	 */
	private static CatSetting patch(Long userId, CatSettingUpdateRequest request, Long id) {
		CatSetting row = new CatSetting();
		row.setId(id);
		row.setCreatedBy(userId);
		row.setInternalMonths(request.internalMonths());
		row.setExternalMonths(request.externalMonths());
		row.setEstimatedDailyGrams(request.estimatedDailyGrams());
		return row;
	}

	private CatSetting read(Long familyId) {
		return this.catSettingMapper.selectOne(new LambdaQueryWrapper<CatSetting>()
			.eq(CatSetting::getFamilyId, familyId));
	}

	private static Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	/**
	 * 无行时按默认值回，且<b>不建那一行</b>（§7.1）。estimateTakenOverByHistory 的判据在这里而不是
	 * 推算结果的 fromHistory：一袋都没开过时后者也是 false，那会让早已接管的输入框重新变成可编辑。
	 */
	private CatSettingResponse toResponse(CatSetting row) {
		List<?> closedBags = this.catFoodBagService.closedBags();
		return new CatSettingResponse(row == null ? DEFAULT_INTERNAL_MONTHS : row.getInternalMonths(),
				row == null ? DEFAULT_EXTERNAL_MONTHS : row.getExternalMonths(),
				row == null ? null : row.getEstimatedDailyGrams(), !closedBags.isEmpty());
	}

}
