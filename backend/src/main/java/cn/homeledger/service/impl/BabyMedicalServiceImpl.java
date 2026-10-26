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
import cn.homeledger.common.StatisticsCache;
import cn.homeledger.dto.BabyMedicalCreateRequest;
import cn.homeledger.dto.BabyMedicalUpdateRequest;
import cn.homeledger.entity.Baby;
import cn.homeledger.entity.BabyMedical;
import cn.homeledger.mapper.BabyMapper;
import cn.homeledger.mapper.BabyMedicalMapper;
import cn.homeledger.service.BabyMedicalService;
import cn.homeledger.vo.BabyMedicalResponse;

/**
 * §4.4.5 就诊记录。
 * <p>
 * costAmount 只是记录，<b>不同步生成流水</b>（§4.4.5）。这是本项目里少数「不需要做」的约定，
 * 值得写在这里：就诊与记账是两件事，种下同步会让删掉就诊记录时那条流水留在账上，或者反过来被删掉，
 * 两边都不该由另一边决定。
 * <p>
 * 增删改都失效 {@link StatisticsCache#MODULE_BABY}：就诊表目前没有统计读者，但缓存粒度到模块为止（§5.1），
 * 与里程碑、身高体重共用同一版版本号，少写一处就是「某一类写操作看起来失效了」。
 */
@Service
public class BabyMedicalServiceImpl implements BabyMedicalService {

	private static final Logger log = LoggerFactory.getLogger(BabyMedicalServiceImpl.class);

	private final BabyMedicalMapper babyMedicalMapper;

	private final BabyMapper babyMapper;

	private final StatisticsCache statisticsCache;

	private final Clock clock;

	public BabyMedicalServiceImpl(BabyMedicalMapper babyMedicalMapper, BabyMapper babyMapper,
			StatisticsCache statisticsCache, Clock clock) {
		this.babyMedicalMapper = babyMedicalMapper;
		this.babyMapper = babyMapper;
		this.statisticsCache = statisticsCache;
		this.clock = clock;
	}

	@Override
	public List<BabyMedicalResponse> list(Long babyId) {
		Long familyId = currentFamilyId();
		return this.babyMedicalMapper
			.selectList(new LambdaQueryWrapper<BabyMedical>().eq(BabyMedical::getFamilyId, familyId)
				.eq(babyId != null, BabyMedical::getBabyId, babyId)
				.orderByDesc(BabyMedical::getVisitDate)
				.orderByDesc(BabyMedical::getId))
			.stream()
			.map(BabyMedicalServiceImpl::toResponse)
			.toList();
	}

	@Override
	@Transactional
	public BabyMedicalResponse create(Long userId, BabyMedicalCreateRequest request) {
		Long familyId = currentFamilyId();
		requireBaby(familyId, request.babyId());
		assertVisitDateUsable(request.visitDate());

		BabyMedical medical = new BabyMedical();
		medical.setFamilyId(familyId);
		medical.setBabyId(request.babyId());
		medical.setVisitDate(request.visitDate());
		medical.setHospital(request.hospital());
		medical.setDepartment(request.department());
		medical.setDiagnosis(request.diagnosis());
		medical.setMedicine(request.medicine());
		medical.setCostAmount(request.costAmount());
		medical.setRemark(request.remark());
		medical.setCreatedBy(userId);
		this.babyMedicalMapper.insert(medical);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("新增就诊记录 familyId={} medicalId={} babyId={} visitDate={} operatorUserId={}", familyId,
				medical.getId(), request.babyId(), request.visitDate(), userId);
		return toResponse(medical);
	}

	@Override
	@Transactional
	public BabyMedicalResponse update(Long userId, Long id, BabyMedicalUpdateRequest request) {
		Long familyId = currentFamilyId();
		BabyMedical medical = requireMedical(familyId, id);
		assertVisitDateUsable(request.visitDate());

		medical.setVisitDate(request.visitDate());
		medical.setHospital(request.hospital());
		medical.setDepartment(request.department());
		medical.setDiagnosis(request.diagnosis());
		medical.setMedicine(request.medicine());
		medical.setCostAmount(request.costAmount());
		medical.setRemark(request.remark());
		// 整份覆盖必须走 overwrite：updateById 会跳过 null，把费用删成空就静默失效
		this.babyMedicalMapper.overwrite(medical);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("修改就诊记录 familyId={} medicalId={} babyId={} visitDate={} operatorUserId={}", familyId, id,
				medical.getBabyId(), request.visitDate(), userId);
		return toResponse(medical);
	}

	@Override
	@Transactional
	public void delete(Long userId, Long id) {
		Long familyId = currentFamilyId();
		BabyMedical medical = requireMedical(familyId, id);
		// 没有守卫，也不去动账本：这里删的只是一条就诊记录，当初也没有替它记过账
		this.babyMedicalMapper.deleteById(medical.getId());
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("删除就诊记录 familyId={} medicalId={} babyId={} operatorUserId={}", familyId, id,
				medical.getBabyId(), userId);
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	/**
	 * 不查 enabled：归档的宝宝照旧补得起历史就诊记录（§4.4.1 的归档 ≠ 删除），这里只拦「不是本家庭的」。
	 */
	private void requireBaby(Long familyId, Long babyId) {
		Baby baby = this.babyMapper
			.selectOne(new LambdaQueryWrapper<Baby>().eq(Baby::getId, babyId).eq(Baby::getFamilyId, familyId));
		if (baby == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
	}

	private BabyMedical requireMedical(Long familyId, Long id) {
		BabyMedical medical = this.babyMedicalMapper
			.selectOne(new LambdaQueryWrapper<BabyMedical>().eq(BabyMedical::getId, id)
				.eq(BabyMedical::getFamilyId, familyId));
		if (medical == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		return medical;
	}

	private void assertVisitDateUsable(LocalDate visitDate) {
		if (visitDate.isAfter(LocalDate.now(this.clock))) {
			throw new BizException(ErrorCode.BAD_REQUEST, "就诊日期不能晚于今天");
		}
	}

	private static BabyMedicalResponse toResponse(BabyMedical medical) {
		return new BabyMedicalResponse(medical.getId(), medical.getBabyId(), medical.getVisitDate(),
				medical.getHospital(), medical.getDepartment(), medical.getDiagnosis(), medical.getMedicine(),
				medical.getCostAmount(), medical.getRemark());
	}

}
