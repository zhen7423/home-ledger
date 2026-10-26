import 'package:freezed_annotation/freezed_annotation.dart';

import 'cat_food_estimate.dart';

part 'cat_food_bag.freezed.dart';
part 'cat_food_bag.g.dart';

/// 猫粮袋列表的一行，对应后端的 CatFoodBagResponse（§4.3.2）。
///
/// `usageDays` / `dailyAverage` 只有当前袋是 null，那是 §8 的原话：一袋还没吃完，它自己的
/// 「折算日均」就不是一个事实。界面对这两格显示「—」而不是 0——0 会被读成「这袋一天就吃完了」。
/// 当前袋的「已用 N 天」在 [CatFoodEstimate.usedDays] 上，不在这里。
@freezed
abstract class CatFoodBag with _$CatFoodBag {
  const factory CatFoodBag({
    required int id,
    required String brand,
    required int packGrams,
    required DateTime startedDate,
    int? usageDays,
    int? dailyAverage,
    required bool current,
    String? remark,
  }) = _CatFoodBag;

  factory CatFoodBag.fromJson(Map<String, dynamic> json) =>
      _$CatFoodBagFromJson(json);
}

/// 总览页余量卡的数据（§4.3.4），对应后端的 CatFoodCurrentResponse 那三态。
///
/// 两个字段同时为 null 才是「一袋都还没开」；只有 `estimate` 为 null 是「开了袋但推不出」，
/// 界面要在这两种上给两句不同的提示语，所以不能压成一个 null。
@freezed
abstract class CatFoodCurrent with _$CatFoodCurrent {
  const factory CatFoodCurrent({CatFoodBag? bag, CatFoodEstimate? estimate}) =
      _CatFoodCurrent;

  factory CatFoodCurrent.fromJson(Map<String, dynamic> json) =>
      _$CatFoodCurrentFromJson(json);
}
