package cn.homeledger.service;

import cn.homeledger.entity.Baby;

/**
 * 应种清单的生成与重算（§4.4.4）——全项目<b>只此一处</b>把内置疫苗程序表落成某个宝宝的清单。
 * <p>
 * 单独抽成一个接口而不是塞进 {@link BabyService}：建档、改生日、以及日后「程序表升级时按需补建」
 * 三条路径都要它，而它只依赖静态字典与出生日期，与档案本身的表单校验无关。
 */
public interface BabyVaccinePlanGenerator {

	/** 建档：按出生日期整份生成，全部 PENDING / manual = 0。 */
	void generateFor(Long userId, Baby baby);

	/** 改生日：按「疫苗名称 + 剂次」对齐，已接种 / 已跳过 / 不适用 / 手动的行原样保留，只补新增与改期。 */
	void realignFor(Long userId, Baby baby);

}
