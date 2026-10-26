package cn.homeledger.service.impl;

import java.time.Clock;
import java.time.LocalDate;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;

import cn.homeledger.common.AuthContextHolder;
import cn.homeledger.common.BabyAge;
import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.common.StatisticsCache;
import cn.homeledger.dto.BabyCreateRequest;
import cn.homeledger.dto.BabyUpdateRequest;
import cn.homeledger.entity.Baby;
import cn.homeledger.entity.BabyVaccinePlan;
import cn.homeledger.mapper.BabyMapper;
import cn.homeledger.mapper.BabyVaccinePlanMapper;
import cn.homeledger.service.BabyService;
import cn.homeledger.service.BabyVaccinePlanGenerator;
import cn.homeledger.service.PhotoService;
import cn.homeledger.vo.BabyResponse;

/**
 * §4.4.1 宝宝档案。
 * <p>
 * 归档与建档上限是同一个开关的两端：5 个名额数的是在册的宝宝（{@code enabled = 1}），归档的不占名额，
 * 所以恢复入册时要重数一次。姓名唯一与名额数同口径——归档的腾出名字（§4.4.1）。
 * <p>
 * 建档与改生日都在同一事务里动应种清单：清单是出生日期的函数，两者分在两个事务里提交，
 * 中间那一刻的清单要么缺行、要么按旧生日排期（§4.4.4）。
 */
@Service
public class BabyServiceImpl implements BabyService {

	private static final Logger log = LoggerFactory.getLogger(BabyServiceImpl.class);

	private static final int MAX_ACTIVE_BABIES = 5;

	private final BabyMapper babyMapper;

	private final BabyVaccinePlanMapper babyVaccinePlanMapper;

	private final BabyVaccinePlanGenerator planGenerator;

	private final StatisticsCache statisticsCache;

	private final PhotoService photoService;

	private final Clock clock;

	public BabyServiceImpl(BabyMapper babyMapper, BabyVaccinePlanMapper babyVaccinePlanMapper,
			BabyVaccinePlanGenerator planGenerator, StatisticsCache statisticsCache, PhotoService photoService,
			Clock clock) {
		this.babyMapper = babyMapper;
		this.babyVaccinePlanMapper = babyVaccinePlanMapper;
		this.planGenerator = planGenerator;
		this.statisticsCache = statisticsCache;
		this.photoService = photoService;
		this.clock = clock;
	}

	@Override
	public List<BabyResponse> list(boolean includeArchived) {
		List<Baby> rows = this.babyMapper.selectList(familyScope(currentFamilyId())
			.eq(!includeArchived, Baby::getEnabled, 1)
			.orderByDesc(Baby::getEnabled)
			.orderByAsc(Baby::getCreatedAt)
			.orderByAsc(Baby::getId));
		return rows.stream().map(this::toResponse).toList();
	}

	@Override
	@Transactional
	public BabyResponse create(Long userId, BabyCreateRequest request) {
		Long familyId = currentFamilyId();
		assertBelowCap(familyId, "一个家庭最多记录 5 个宝宝，可以先归档一个");
		String name = request.name().trim();
		assertNameFree(familyId, name, null);
		assertBirthDateNotFuture(request.birthDate());

		Baby baby = new Baby();
		baby.setFamilyId(familyId);
		baby.setName(name);
		baby.setGender(request.gender());
		baby.setBirthDate(request.birthDate());
		baby.setBirthHeight(request.birthHeight());
		baby.setBirthWeight(request.birthWeight());
		baby.setRemark(request.remark());
		baby.setEnabled(1);
		baby.setCreatedBy(userId);
		this.babyMapper.insert(baby);
		this.planGenerator.generateFor(userId, baby);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("宝宝建档 familyId={} babyId={} name={} operatorUserId={}", familyId, baby.getId(), name, userId);
		return toResponse(baby);
	}

	@Override
	@Transactional
	public BabyResponse update(Long userId, Long id, BabyUpdateRequest request) {
		Long familyId = currentFamilyId();
		Baby baby = requireBaby(familyId, id);
		String name = request.name().trim();
		assertNameFree(familyId, name, id);
		assertBirthDateNotFuture(request.birthDate());
		boolean birthDateChanged = !request.birthDate().equals(baby.getBirthDate());

		baby.setName(name);
		baby.setGender(request.gender());
		baby.setBirthDate(request.birthDate());
		baby.setBirthHeight(request.birthHeight());
		baby.setBirthWeight(request.birthWeight());
		baby.setRemark(request.remark());
		// 整份表单覆盖必须走 overwrite：updateById 会跳过实体里的 null，清空出生身高或备注就会静默失效
		this.babyMapper.overwrite(baby);
		if (birthDateChanged) {
			this.planGenerator.realignFor(userId, baby);
		}
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("更新宝宝档案 familyId={} babyId={} 生日变更={} operatorUserId={}", familyId, id, birthDateChanged, userId);
		return toResponse(baby);
	}

	@Override
	@Transactional
	public BabyResponse archive(Long userId, Long id) {
		Long familyId = currentFamilyId();
		Baby baby = requireBaby(familyId, id);
		boolean restoring = baby.getEnabled() == 0;
		if (restoring) {
			assertBelowCap(familyId, "在册的宝宝已经有 5 个了，先归档一个再恢复它");
		}
		baby.setEnabled(restoring ? 1 : 0);
		this.babyMapper.updateById(baby);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("宝宝归档开关 familyId={} babyId={} enabled={} operatorUserId={}", familyId, id, baby.getEnabled(), userId);
		return toResponse(baby);
	}

	@Override
	@Transactional
	public void delete(Long userId, Long id) {
		Long familyId = currentFamilyId();
		Baby baby = requireBaby(familyId, id);
		// 数的是四张用户录入表、含已软删的行：删掉的记录曾经真实存在过，让它悬空与删猫的后果一样
		if (this.babyMapper.countUserRecords(familyId, id) > 0) {
			throw new BizException(ErrorCode.BAD_REQUEST, "该宝宝已有身高体重、接种、里程碑或就诊记录，只能归档不能删除");
		}
		// 清单是派生数据且不算「记录」，随档案一起软删——没有宝宝的清单行没有含义
		this.babyVaccinePlanMapper
			.delete(new LambdaQueryWrapper<BabyVaccinePlan>().eq(BabyVaccinePlan::getFamilyId, familyId)
				.eq(BabyVaccinePlan::getBabyId, id));
		this.babyMapper.deleteById(id);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("删除宝宝档案 familyId={} babyId={} name={} operatorUserId={}", familyId, id, baby.getName(), userId);
	}

	@Override
	@Transactional
	public BabyResponse setPhoto(Long userId, Long id, byte[] data) {
		Long familyId = currentFamilyId();
		Baby baby = requireBaby(familyId, id);
		String photoUrl = this.photoService.save(data);
		String old = baby.getPhotoUrl();
		try {
			this.babyMapper.setPhotoUrl(id, photoUrl);
		}
		catch (RuntimeException e) {
			// 文件落地了却没被认领：删掉补偿，否则磁盘上多一份谁都不引用的照片
			this.photoService.delete(photoUrl);
			throw e;
		}
		if (old != null && !old.equals(photoUrl)) {
			// 旧照片推迟到提交后再删：事务后段一旦回滚，库里的 photo_url 会退回指向 old，
			// 那时文件必须还在（M1）
			this.photoService.deleteAfterCommit(old);
		}
		log.info("上传宝宝照片 familyId={} babyId={} operatorUserId={}", familyId, id, userId);
		return toResponse(requireBaby(familyId, id));
	}

	@Override
	@Transactional
	public BabyResponse clearPhoto(Long userId, Long id) {
		Long familyId = currentFamilyId();
		Baby baby = requireBaby(familyId, id);
		String old = baby.getPhotoUrl();
		this.babyMapper.setPhotoUrl(id, null);
		if (old != null) {
			this.photoService.deleteAfterCommit(old);
		}
		log.info("删除宝宝照片 familyId={} babyId={} operatorUserId={}", familyId, id, userId);
		return toResponse(requireBaby(familyId, id));
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	private Baby requireBaby(Long familyId, Long id) {
		Baby baby = this.babyMapper
			.selectOne(new LambdaQueryWrapper<Baby>().eq(Baby::getId, id).eq(Baby::getFamilyId, familyId));
		if (baby == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		return baby;
	}

	private void assertBelowCap(Long familyId, String message) {
		Long active = this.babyMapper.selectCount(familyScope(familyId).eq(Baby::getEnabled, 1));
		if (active != null && active >= MAX_ACTIVE_BABIES) {
			throw new BizException(ErrorCode.BAD_REQUEST, message);
		}
	}

	/** 姓名在家庭内唯一，只比在册的：归档的宝宝腾出名字（§4.4.1）。软删的行由逻辑删除自动滤掉。 */
	private void assertNameFree(Long familyId, String name, Long excludeId) {
		Long duplicated = this.babyMapper.selectCount(familyScope(familyId)
			.eq(Baby::getName, name)
			.eq(Baby::getEnabled, 1)
			.ne(excludeId != null, Baby::getId, excludeId));
		if (duplicated != null && duplicated > 0) {
			throw new BizException(ErrorCode.BAD_REQUEST, "本家庭已有一个同名的宝宝，请换一个名字");
		}
	}

	private void assertBirthDateNotFuture(LocalDate birthDate) {
		if (birthDate.isAfter(LocalDate.now(this.clock))) {
			throw new BizException(ErrorCode.BAD_REQUEST, "出生日期不能晚于今天");
		}
	}

	private BabyResponse toResponse(Baby baby) {
		return new BabyResponse(baby.getId(), baby.getName(), baby.getGender(), baby.getBirthDate(),
				baby.getBirthHeight(), baby.getBirthWeight(), baby.getRemark(), baby.getPhotoUrl(),
				baby.getEnabled() == 0, BabyAge.ageText(baby.getBirthDate(), LocalDate.now(this.clock)));
	}

	private static LambdaQueryWrapper<Baby> familyScope(Long familyId) {
		return new LambdaQueryWrapper<Baby>().eq(Baby::getFamilyId, familyId);
	}

}
