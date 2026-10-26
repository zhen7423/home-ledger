package cn.homeledger.service;

import java.util.List;

import cn.homeledger.dto.BabyVaccineRecordCreateRequest;
import cn.homeledger.dto.BabyVaccineRecordUpdateRequest;
import cn.homeledger.vo.BabyVaccineRecordResponse;

/**
 * §4.4.4 接种记录。新增与删除是应种项状态机的两个驱动力：建记录回写 {@code DONE}，删记录退回
 * {@code PENDING}，两者都由本服务在同一事务内完成。
 */
public interface BabyVaccineRecordService {

	/**
	 * @param babyId 不传即全家庭。排序按接种日期降序、同日按 id 降序（回看）。
	 */
	List<BabyVaccineRecordResponse> list(Long babyId);

	/** 新建并回写应种项；{@code planId} 以它为准，不给就按「疫苗名称 + 剂次」自动匹配。 */
	BabyVaccineRecordResponse create(Long userId, BabyVaccineRecordCreateRequest request);

	/** 整份覆盖。改疫苗名称或剂次会先撤销旧绑定、再按新键重新匹配。 */
	BabyVaccineRecordResponse update(Long userId, Long id, BabyVaccineRecordUpdateRequest request);

	/** 删除并把对应应种项退回 {@code PENDING}；已被手动标为跳过 / 不适用的行不回退。 */
	void delete(Long userId, Long id);

}
