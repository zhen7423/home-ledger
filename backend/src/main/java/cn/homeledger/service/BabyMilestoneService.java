package cn.homeledger.service;

import java.util.List;

import cn.homeledger.dto.BabyMilestoneCreateRequest;
import cn.homeledger.dto.BabyMilestoneUpdateRequest;
import cn.homeledger.vo.BabyMilestoneResponse;

/**
 * §4.4.5 里程碑。时间轴升序返回，与就诊记录的倒序相反——成长轴是从左到右看的。
 */
public interface BabyMilestoneService {

	/** @param babyId 不传即全家庭。排序按发生日期升序、同日按 id 升序。 */
	List<BabyMilestoneResponse> list(Long babyId);

	BabyMilestoneResponse create(Long userId, BabyMilestoneCreateRequest request);

	BabyMilestoneResponse update(Long userId, Long id, BabyMilestoneUpdateRequest request);

	void delete(Long userId, Long id);

}
