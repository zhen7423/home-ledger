package cn.homeledger.service;

import java.util.List;

import cn.homeledger.dto.BabyVaccinePlanCreateRequest;
import cn.homeledger.dto.BabyVaccinePlanPlannedDateRequest;
import cn.homeledger.dto.BabyVaccinePlanUpdateRequest;
import cn.homeledger.vo.BabyVaccinePlanResponse;

/**
 * §4.4.4 应种清单。清单由建档与改生日重算生成，这里只补「手动自费项」「标记」与「设置计划日期」
 * 三个用户动作。
 */
public interface BabyVaccinePlanService {

	/**
	 * @param babyId 不传即全家庭。排序按生效日期（plannedDate ?? dueDate）升序、同日按 id 升序。
	 */
	List<BabyVaccinePlanResponse> list(Long babyId);

	/** 手动新增一条自费项（落 {@code manual = 1}），同宝宝同 (疫苗名称, 剂次) 已存在即拒。 */
	BabyVaccinePlanResponse create(Long userId, BabyVaccinePlanCreateRequest request);

	/** 标记跳过 / 不适用，或撤销回 {@code PENDING}。改期与换疫苗不在这里——那两列是对齐用的键。 */
	BabyVaccinePlanResponse update(Long userId, Long id, BabyVaccinePlanUpdateRequest request);

	/**
	 * 设置 / 清除计划接种日期（2026-10-26 需求②）。{@code plannedDate = null} 表示清除、回到程序表
	 * 应种日期；早于出生日期即拒；已接种的行拒绝——那一针什么时候打的以接种记录为准，计划日期
	 * 已无意义。手动行与字典行统一走这里。
	 */
	BabyVaccinePlanResponse updatePlannedDate(Long userId, Long id, BabyVaccinePlanPlannedDateRequest request);

	/** 只对手动行开放：字典生成的行下次重算会被补回来，静默删掉只会让用户以为删除功能坏了。 */
	void delete(Long userId, Long id);

}
