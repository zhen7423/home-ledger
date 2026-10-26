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
import cn.homeledger.common.BizException;
import cn.homeledger.common.ErrorCode;
import cn.homeledger.dto.CatCreateRequest;
import cn.homeledger.dto.CatUpdateRequest;
import cn.homeledger.entity.Cat;
import cn.homeledger.mapper.CatDewormingMapper;
import cn.homeledger.mapper.CatMapper;
import cn.homeledger.service.CatService;
import cn.homeledger.service.PhotoService;
import cn.homeledger.vo.CatResponse;

/**
 * §4.3.1 猫咪档案。
 * <p>
 * 归档与建档上限是同一个开关的两端：10 只的名额数的是在册的猫（{@code enabled = 1}），归档的不占名额，
 * 所以恢复入册时要重数一次——「归档 3 只、建 3 只新的、再把归档的恢复回来」这条路径必然走到。
 */
@Service
public class CatServiceImpl implements CatService {

	private static final Logger log = LoggerFactory.getLogger(CatServiceImpl.class);

	private static final int MAX_ACTIVE_CATS = 10;

	private final CatMapper catMapper;

	private final CatDewormingMapper catDewormingMapper;

	private final PhotoService photoService;

	private final Clock clock;

	public CatServiceImpl(CatMapper catMapper, CatDewormingMapper catDewormingMapper, PhotoService photoService,
			Clock clock) {
		this.catMapper = catMapper;
		this.catDewormingMapper = catDewormingMapper;
		this.photoService = photoService;
		this.clock = clock;
	}

	@Override
	public List<CatResponse> list(boolean includeArchived) {
		List<Cat> rows = this.catMapper.selectList(familyScope(currentFamilyId())
			.eq(!includeArchived, Cat::getEnabled, 1)
			.orderByDesc(Cat::getEnabled)
			.orderByAsc(Cat::getCreatedAt)
			.orderByAsc(Cat::getId));
		return rows.stream().map(CatServiceImpl::toResponse).toList();
	}

	@Override
	@Transactional
	public CatResponse create(Long userId, CatCreateRequest request) {
		Long familyId = currentFamilyId();
		assertBelowCap(familyId, "一个家庭最多记录 10 只猫咪，可以先归档一只");
		String name = request.name().trim();
		assertNameFree(familyId, name, null);
		assertBirthdayNotFuture(request.birthday());

		Cat cat = new Cat();
		cat.setFamilyId(familyId);
		cat.setName(name);
		cat.setGender(request.gender());
		cat.setBirthday(request.birthday());
		cat.setBirthdayEstimated(request.birthdayEstimated() ? 1 : 0);
		cat.setBreed(request.breed());
		cat.setWeightKg(request.weightKg());
		cat.setNeutered(request.neutered());
		cat.setRemark(request.remark());
		cat.setEnabled(1);
		cat.setCreatedBy(userId);
		this.catMapper.insert(cat);
		log.info("猫咪建档 familyId={} catId={} name={} operatorUserId={}", familyId, cat.getId(), name, userId);
		return toResponse(requireCat(familyId, cat.getId()));
	}

	@Override
	@Transactional
	public CatResponse update(Long userId, Long id, CatUpdateRequest request) {
		Long familyId = currentFamilyId();
		Cat cat = requireCat(familyId, id);
		String name = request.name().trim();
		assertNameFree(familyId, name, id);
		assertBirthdayNotFuture(request.birthday());

		cat.setName(name);
		cat.setGender(request.gender());
		cat.setBirthday(request.birthday());
		cat.setBirthdayEstimated(request.birthdayEstimated() ? 1 : 0);
		cat.setBreed(request.breed());
		cat.setWeightKg(request.weightKg());
		cat.setNeutered(request.neutered());
		cat.setRemark(request.remark());
		// 整份表单覆盖必须走 overwrite：updateById 会跳过实体里的 null，清空生日或备注就会静默失效
		this.catMapper.overwrite(cat);
		log.info("更新猫咪档案 familyId={} catId={} operatorUserId={}", familyId, id, userId);
		return toResponse(requireCat(familyId, id));
	}

	@Override
	@Transactional
	public CatResponse archive(Long userId, Long id) {
		Long familyId = currentFamilyId();
		Cat cat = requireCat(familyId, id);
		boolean restoring = cat.getEnabled() == 0;
		if (restoring) {
			assertBelowCap(familyId, "在册的猫已经有 10 只了，先归档一只再恢复它");
		}
		cat.setEnabled(restoring ? 1 : 0);
		this.catMapper.updateById(cat);
		log.info("猫咪归档开关 familyId={} catId={} enabled={} operatorUserId={}", familyId, id, cat.getEnabled(),
				userId);
		return toResponse(cat);
	}

	@Override
	@Transactional
	public void delete(Long userId, Long id) {
		Long familyId = currentFamilyId();
		Cat cat = requireCat(familyId, id);
		// 含软删的计数：删掉一条驱虫记录再把猫删掉，会让那条记录的 cat_id 悬空
		if (this.catDewormingMapper.countAnyForCat(familyId, id) > 0) {
			throw new BizException(ErrorCode.BAD_REQUEST, "该猫已有驱虫记录，只能归档不能删除");
		}
		this.catMapper.deleteById(cat.getId());
		log.info("删除猫咪档案 familyId={} catId={} name={} operatorUserId={}", familyId, id, cat.getName(), userId);
	}

	@Override
	@Transactional
	public CatResponse setPhoto(Long userId, Long id, byte[] data) {
		Long familyId = currentFamilyId();
		Cat cat = requireCat(familyId, id);
		String photoUrl = this.photoService.save(data);
		String old = cat.getPhotoUrl();
		try {
			this.catMapper.setPhotoUrl(id, photoUrl);
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
		log.info("上传猫咪照片 familyId={} catId={} operatorUserId={}", familyId, id, userId);
		return toResponse(requireCat(familyId, id));
	}

	@Override
	@Transactional
	public CatResponse clearPhoto(Long userId, Long id) {
		Long familyId = currentFamilyId();
		Cat cat = requireCat(familyId, id);
		String old = cat.getPhotoUrl();
		this.catMapper.setPhotoUrl(id, null);
		if (old != null) {
			this.photoService.deleteAfterCommit(old);
		}
		log.info("删除猫咪照片 familyId={} catId={} operatorUserId={}", familyId, id, userId);
		return toResponse(requireCat(familyId, id));
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	private Cat requireCat(Long familyId, Long id) {
		Cat cat = this.catMapper
			.selectOne(new LambdaQueryWrapper<Cat>().eq(Cat::getId, id).eq(Cat::getFamilyId, familyId));
		if (cat == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		return cat;
	}

	private void assertBelowCap(Long familyId, String message) {
		Long active = this.catMapper.selectCount(familyScope(familyId).eq(Cat::getEnabled, 1));
		if (active != null && active >= MAX_ACTIVE_CATS) {
			throw new BizException(ErrorCode.BAD_REQUEST, message);
		}
	}

	/** 昵称在家庭内唯一，比的是在册 + 已归档，软删的行不算——删掉一只再建一只同名猫要能走通。 */
	private void assertNameFree(Long familyId, String name, Long excludeId) {
		Long duplicated = this.catMapper.selectCount(familyScope(familyId)
			.eq(Cat::getName, name)
			.ne(excludeId != null, Cat::getId, excludeId));
		if (duplicated != null && duplicated > 0) {
			throw new BizException(ErrorCode.BAD_REQUEST, "已经有叫这个名字的猫咪了，昵称在家庭内不能重复");
		}
	}

	private void assertBirthdayNotFuture(LocalDate birthday) {
		if (birthday != null && birthday.isAfter(LocalDate.now(this.clock))) {
			throw new BizException(ErrorCode.BAD_REQUEST, "生日不能晚于今天");
		}
	}

	private static LambdaQueryWrapper<Cat> familyScope(Long familyId) {
		return new LambdaQueryWrapper<Cat>().eq(Cat::getFamilyId, familyId);
	}

	private static CatResponse toResponse(Cat cat) {
		return new CatResponse(cat.getId(), cat.getName(), cat.getGender(), cat.getBirthday(),
				cat.getBirthdayEstimated() == 1, cat.getBreed(), cat.getWeightKg(), cat.getNeutered(), cat.getRemark(),
				cat.getPhotoUrl(), cat.getEnabled() == 0, cat.getCreatedAt());
	}

}
