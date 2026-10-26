package cn.homeledger.service;

import java.util.List;

import cn.homeledger.dto.BabyMedicalCreateRequest;
import cn.homeledger.dto.BabyMedicalUpdateRequest;
import cn.homeledger.vo.BabyMedicalResponse;

/**
 * §4.4.5 就诊记录。费用只是记录，不同步生成流水——这条约定没有代码，它就是「这里没有记账调用」。
 */
public interface BabyMedicalService {

	/** @param babyId 不传即全家庭。排序按就诊日期降序、同日按 id 降序（就诊是回看）。 */
	List<BabyMedicalResponse> list(Long babyId);

	BabyMedicalResponse create(Long userId, BabyMedicalCreateRequest request);

	BabyMedicalResponse update(Long userId, Long id, BabyMedicalUpdateRequest request);

	void delete(Long userId, Long id);

}
