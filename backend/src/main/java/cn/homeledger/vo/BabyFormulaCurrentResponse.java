package cn.homeledger.vo;

/**
 * 宝宝主页「奶粉」卡的当前罐与余量推算（§4.5.3 的 GET /baby-formula-bags/current）。
 * <p>
 * 「一罐都还没开」与「开了罐但推不出来」是两句不同的提示语，不能让它们共用一个 null，
 * 所以只在推算那一栏落 null 而整份 data 仍非 null。
 */
public record BabyFormulaCurrentResponse(BabyFormulaBagResponse bag, BabyFormulaEstimateResponse estimate) {

}