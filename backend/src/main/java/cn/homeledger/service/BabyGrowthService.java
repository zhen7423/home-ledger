package cn.homeledger.service;

import java.util.List;

import cn.homeledger.dto.BabyGrowthCreateRequest;
import cn.homeledger.dto.BabyGrowthUpdateRequest;
import cn.homeledger.vo.BabyGrowthResponse;

/**
 * §4.4.2 身高体重记录。
 * <p>
 * 这里没有「按 id 取一条」：编辑表单从列表里回填，而列表本来就不分页（一个宝宝到 7 岁几十条）。
 * 多一条端点只是多一处与列表口径可能不一致的答案。
 */
public interface BabyGrowthService {

	/**
	 * @param babyId 可空，空表示全家庭
	 */
	List<BabyGrowthResponse> list(Long babyId);

	BabyGrowthResponse create(Long userId, BabyGrowthCreateRequest request);

	BabyGrowthResponse update(Long userId, Long id, BabyGrowthUpdateRequest request);

	void delete(Long userId, Long id);

}
