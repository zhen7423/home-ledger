import 'package:freezed_annotation/freezed_annotation.dart';

part 'cat_setting.freezed.dart';
part 'cat_setting.g.dart';

/// 猫咪设置（§4.3.3 的驱虫周期 + §4.3.4 的预估日均），对应后端的 CatSettingResponse。
///
/// 四个字段都有默认值，为的是 `const CatSetting()` 可用：未登录与加载中的守卫分支直接返回它，
/// 不必真去 GET 一个默认值。那两个数字与服务端 `CatSettingServiceImpl` 的常量是同一个，
/// 家庭从没存过设置行时两边给出的才会是同一句话。
///
/// `estimateTakenOverByHistory` 判的是「有没有可用的已完成袋」，由服务端给：前端手里没有那个定义，
/// 自己判一遍就会出现「统计认为有历史、设置页认为没有」。为 true 时预估那一栏置灰。
@freezed
abstract class CatSetting with _$CatSetting {
  const factory CatSetting({
    @Default(3) int internalMonths,
    @Default(1) int externalMonths,
    int? estimatedDailyGrams,
    @Default(false) bool estimateTakenOverByHistory,
  }) = _CatSetting;

  factory CatSetting.fromJson(Map<String, dynamic> json) =>
      _$CatSettingFromJson(json);
}
