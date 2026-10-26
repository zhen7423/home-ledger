package cn.homeledger.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/**
 * 保存猫咪设置（§4.3.3、§4.3.4）。三栏都是「整份表单覆盖」，与 PUT /budgets 同口径，没有局部更新语义。
 * <p>
 * 两个月份字段是包装类型：基本类型下「字段没传」会落成 0，然后被 @Min(1) 报成「内驱周期至少 1 个月」，
 * 而用户什么都没填。上界 12 是因为周期按「月」步进，放开到 60 会让完成度的应做次数算出 0。
 * estimatedDailyGrams 则刻意不带 {@code @NotNull}：留空是一个合法值，含义就是「我没有预估，等第一袋吃完再算」。
 */
public record CatSettingUpdateRequest(
		@NotNull(message = "请填写内驱周期") @Min(value = 1, message = "内驱周期至少 1 个月") @Max(value = 12,
				message = "内驱周期最多 12 个月") Integer internalMonths,
		@NotNull(message = "请填写外驱周期") @Min(value = 1, message = "外驱周期至少 1 个月") @Max(value = 12,
				message = "外驱周期最多 12 个月") Integer externalMonths,
		@Min(value = 1, message = "预估日均克数至少 1 克") @Max(value = 2000,
				message = "预估日均克数最多 2000 克") Integer estimatedDailyGrams) {

}
