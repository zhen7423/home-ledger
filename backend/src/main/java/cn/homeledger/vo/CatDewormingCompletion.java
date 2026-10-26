package cn.homeledger.vo;

/**
 * 驱虫完成度的一格（§4.3.5 第五块）。
 * <p>
 * <b>一只猫两行（内驱 / 外驱各一行）而不是一行四列</b>：{@code overdueDays} 挂在「下次日期」上，
 * 而一只猫有两个下次日期，合成一行就得给 {@code internalOverdueDays} / {@code externalOverdueDays}
 * 两列，前端反要按 type 挑一列——分组交给 {@code type} 字段。
 * <p>
 * {@code rate} 上限是 100：实做次数可以大于应做（提前驱了），一张 130% 的完成度卡看起来像 bug。
 * {@code due == 0} 时给 100 而不是 0——一只三个月前才建档的猫，窗口内一次外驱都不该做，
 * 此时 0% 是在指责用户什么都没干。
 */
public record CatDewormingCompletion(Long catId, String catName, String type, int due, int done, int rate,
		Long overdueDays) {

}
