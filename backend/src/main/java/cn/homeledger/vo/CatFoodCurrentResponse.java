package cn.homeledger.vo;

/**
 * 总览页的余量卡（§8 的 GET /cat-food-bags/current）。
 * <p>
 * 「一袋都还没开」与「开了袋但推不出来」是两句不同的提示语（§4.3.4），不能让它们共用一个 null，
 * 所以这里只在推算那一栏落 null 而整份 data 仍非 null——§8 那句 data: null 在此只覆盖前者。
 */
public record CatFoodCurrentResponse(CatFoodBagResponse bag, CatFoodEstimateResponse estimate) {

}
