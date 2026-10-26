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
import cn.homeledger.dto.BabyMilestoneCreateRequest;
import cn.homeledger.dto.BabyMilestoneUpdateRequest;
import cn.homeledger.entity.Baby;
import cn.homeledger.entity.BabyMilestone;
import cn.homeledger.mapper.BabyMapper;
import cn.homeledger.mapper.BabyMilestoneMapper;
import cn.homeledger.service.BabyMilestoneService;
import cn.homeledger.vo.BabyMilestoneResponse;

/**
 * §4.4.5 里程碑。title 上没有字典校验：内置常用项是前端一份常量清单，用户点它和自由输入落的是同一列，
 * 服务端连「哪些算内置」都不必知道——多一条服务端的白名单只会让前端加一项时要发版。
 * <p>
 * 增删改都失效 {@link StatisticsCache#MODULE_BABY}：里程碑时间轴挂在统计的 vaccine 那条端点上（§4.4.6），
 * 漏掉这一步的症状是「刚记的里程碑在统计页要等缓存过期才出现」。
 */
@Service
public class BabyMilestoneServiceImpl implements BabyMilestoneService {

	private static final Logger log = LoggerFactory.getLogger(BabyMilestoneServiceImpl.class);

	private final BabyMilestoneMapper babyMilestoneMapper;

	private final BabyMapper babyMapper;

	private final StatisticsCache statisticsCache;

	private final Clock clock;

	public BabyMilestoneServiceImpl(BabyMilestoneMapper babyMilestoneMapper, BabyMapper babyMapper,
			StatisticsCache statisticsCache, Clock clock) {
		this.babyMilestoneMapper = babyMilestoneMapper;
		this.babyMapper = babyMapper;
		this.statisticsCache = statisticsCache;
		this.clock = clock;
	}

	@Override
	public List<BabyMilestoneResponse> list(Long babyId) {
		Long familyId = currentFamilyId();
		return this.babyMilestoneMapper
			.selectList(new LambdaQueryWrapper<BabyMilestone>().eq(BabyMilestone::getFamilyId, familyId)
				.eq(babyId != null, BabyMilestone::getBabyId, babyId)
				.orderByAsc(BabyMilestone::getOccurDate)
				.orderByAsc(BabyMilestone::getId))
			.stream()
			.map(BabyMilestoneServiceImpl::toResponse)
			.toList();
	}

	@Override
	@Transactional
	public BabyMilestoneResponse create(Long userId, BabyMilestoneCreateRequest request) {
		Long familyId = currentFamilyId();
		requireBaby(familyId, request.babyId());
		assertOccurDateUsable(request.occurDate());

		BabyMilestone milestone = new BabyMilestone();
		milestone.setFamilyId(familyId);
		milestone.setBabyId(request.babyId());
		milestone.setOccurDate(request.occurDate());
		milestone.setTitle(request.title());
		milestone.setDescription(request.description());
		milestone.setCreatedBy(userId);
		this.babyMilestoneMapper.insert(milestone);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("新增里程碑 familyId={} milestoneId={} babyId={} occurDate={} operatorUserId={}", familyId,
				milestone.getId(), request.babyId(), request.occurDate(), userId);
		return toResponse(milestone);
	}

	@Override
	@Transactional
	public BabyMilestoneResponse update(Long userId, Long id, BabyMilestoneUpdateRequest request) {
		Long familyId = currentFamilyId();
		BabyMilestone milestone = requireMilestone(familyId, id);
		assertOccurDateUsable(request.occurDate());

		milestone.setOccurDate(request.occurDate());
		milestone.setTitle(request.title());
		milestone.setDescription(request.description());
		// 整份覆盖必须走 overwrite：updateById 会跳过 null，把描述删空就静默失效
		this.babyMilestoneMapper.overwrite(milestone);
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("修改里程碑 familyId={} milestoneId={} babyId={} occurDate={} operatorUserId={}", familyId, id,
				milestone.getBabyId(), request.occurDate(), userId);
		return toResponse(milestone);
	}

	@Override
	@Transactional
	public void delete(Long userId, Long id) {
		Long familyId = currentFamilyId();
		BabyMilestone milestone = requireMilestone(familyId, id);
		// 没有守卫：记错日期的里程碑随时可删。被删的是时间轴上的一个点，所以失效不能省
		this.babyMilestoneMapper.deleteById(milestone.getId());
		this.statisticsCache.invalidate(StatisticsCache.MODULE_BABY, familyId);
		log.info("删除里程碑 familyId={} milestoneId={} babyId={} operatorUserId={}", familyId, id,
				milestone.getBabyId(), userId);
	}

	private Long currentFamilyId() {
		return AuthContextHolder.require().familyId();
	}

	/**
	 * 不查 enabled：归档的宝宝照旧补得起历史里程碑（§4.4.1 的归档 ≠ 删除），这里只拦「不是本家庭的」。
	 */
	private void requireBaby(Long familyId, Long babyId) {
		Baby baby = this.babyMapper
			.selectOne(new LambdaQueryWrapper<Baby>().eq(Baby::getId, babyId).eq(Baby::getFamilyId, familyId));
		if (baby == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
	}

	private BabyMilestone requireMilestone(Long familyId, Long id) {
		BabyMilestone milestone = this.babyMilestoneMapper
			.selectOne(new LambdaQueryWrapper<BabyMilestone>().eq(BabyMilestone::getId, id)
				.eq(BabyMilestone::getFamilyId, familyId));
		if (milestone == null) {
			throw new BizException(ErrorCode.RESOURCE_NOT_FOUND);
		}
		return milestone;
	}

	/** 未来的里程碑没有意义：成长轴上的点是已经发生的事，允许填明天只会让时间轴出现一条不属于任何时刻的记录。 */
	private void assertOccurDateUsable(LocalDate occurDate) {
		if (occurDate.isAfter(LocalDate.now(this.clock))) {
			throw new BizException(ErrorCode.BAD_REQUEST, "发生日期不能晚于今天");
		}
	}

	private static BabyMilestoneResponse toResponse(BabyMilestone milestone) {
		return new BabyMilestoneResponse(milestone.getId(), milestone.getBabyId(), milestone.getOccurDate(),
				milestone.getTitle(), milestone.getDescription());
	}

}
