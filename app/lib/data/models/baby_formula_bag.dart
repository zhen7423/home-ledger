import 'package:freezed_annotation/freezed_annotation.dart';

import 'baby_formula_estimate.dart';

part 'baby_formula_bag.freezed.dart';
part 'baby_formula_bag.g.dart';

/// 奶粉开罐列表的一行，对应后端的 BabyFormulaBagResponse（§4.5.3）。
///
/// `usageDays` / `dailyAverage` 只有当前罐是 null（一罐还没喝完，它自己的「折算日均」就不是一个
/// 事实），界面对这两格显示「—」而不是 0。当前罐的「已用 N 天」在 [BabyFormulaEstimate.usedDays] 上。
///
/// `startedTime` 是开罐具体时刻（"HH:mm" / "HH:mm:ss"），选填、纯展示（2026-10-26 需求①）；
/// 刻意用 String 而不是 TimeOfDay：它只是服务端原样回传的文本，不参与任何计算。
@freezed
abstract class BabyFormulaBag with _$BabyFormulaBag {
  const factory BabyFormulaBag({
    required int id,
    required String brand,
    required int packGrams,
    required DateTime startedDate,
    String? startedTime,
    int? estimatedDailyGrams,
    int? usageDays,
    int? dailyAverage,
    required bool current,
    String? remark,
  }) = _BabyFormulaBag;

  factory BabyFormulaBag.fromJson(Map<String, dynamic> json) =>
      _$BabyFormulaBagFromJson(json);
}

/// 宝宝主页奶粉卡的数据（§4.5.3），对应后端的 BabyFormulaCurrentResponse 那三态。
///
/// 两个字段同时为 null 才是「一罐都还没开」；只有 `estimate` 为 null 是「开了罐但推不出」，
/// 界面要在这两种上给两句不同的提示语，所以不能压成一个 null。
@freezed
abstract class BabyFormulaCurrent with _$BabyFormulaCurrent {
  const factory BabyFormulaCurrent({
    BabyFormulaBag? bag,
    BabyFormulaEstimate? estimate,
  }) = _BabyFormulaCurrent;

  factory BabyFormulaCurrent.fromJson(Map<String, dynamic> json) =>
      _$BabyFormulaCurrentFromJson(json);
}