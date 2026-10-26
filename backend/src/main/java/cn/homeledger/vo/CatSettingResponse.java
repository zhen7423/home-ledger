package cn.homeledger.vo;

/**
 * 猫咪设置（§4.3.3）。
 * <p>
 * estimateTakenOverByHistory 是给设置页那一句「已由历史数据接管」用的（§4.3.4、验收用例 23）。
 * 判据是 {@code CatFoodBagService.closedBags()} 非空，而不是「当前推算结果里 fromHistory 为真」：
 * 后者在一袋都没开过时也是 false，那样一来「已经吃完三袋、但三袋都推不出日均」这种极端形状下，
 * 那个早已被历史接管的输入框会重新变成可编辑，改完还不生效。
 * <p>
 * 这个字段由服务端给而不是前端自己判断，是因为前端手里没有「可用历史袋」的定义——
 * 那条筛子在猫粮袋那份推导里只写了一次，判两次就会有两个答案。
 */
public record CatSettingResponse(int internalMonths, int externalMonths, Integer estimatedDailyGrams,
		boolean estimateTakenOverByHistory) {

}
