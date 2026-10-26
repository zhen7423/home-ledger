import 'package:freezed_annotation/freezed_annotation.dart';

part 'baby_growth.freezed.dart';
part 'baby_growth.g.dart';

/// 一条身高体重记录，对应后端的 `BabyGrowthResponse`（§4.4.2 列表的一行）。
///
/// 三个度量列按字符串原样显示，与金额同一条理由：落成 `double` 之后 `9.50` 会在界面上
/// 印成 `9.499999999999998`。三个各自可空——只称体重是常事。
///
/// `percentiles` 五个指标的「百分之多少」（如 `"25%"` / `"<3%"` / `">97%"`，细**不算区间**），
/// 与 `deltaFromPrevious` 一样读时派生，列表中直接写出来；服务端没下发（旧版本）时为 null。
@freezed
abstract class BabyGrowth with _$BabyGrowth {
  const factory BabyGrowth({
    required int id,
    required int babyId,
    required DateTime measureDate,
    String? heightCm,
    String? weightKg,
    String? headCm,
    String? remark,
    BabyGrowthDelta? deltaFromPrevious,
    BabyPercentiles? percentiles,
  }) = _BabyGrowth;

  factory BabyGrowth.fromJson(Map<String, dynamic> json) =>
      _$BabyGrowthFromJson(json);
}

/// 五个指标各自的「百分之多少」，服务端算好下发。
/// 空白有两种原因：这一条没量那个量、或超出标准表覆盖范围（§4.4.3）。
@freezed
abstract class BabyPercentiles with _$BabyPercentiles {
  const factory BabyPercentiles({
    String? height,
    String? weight,
    String? weightHeight,
    String? bmi,
    String? headCircumference,
  }) = _BabyPercentiles;

  factory BabyPercentiles.fromJson(Map<String, dynamic> json) =>
      _$BabyPercentilesFromJson(json);
}

/// 「较上一次的增量」（§4.4.2）。四个字段都可空，两个空各有各的意思：`days` 为空是首条记录、
/// 没有「上一次」；某一档为空是这一次或上一次没量那个量——「较上次没量身高」与「较上次身高没变」
/// 是两件事，后者是 `0.0`。
///
/// `days` 恒 ≥ 1：同一天的多条记录共享同一个「上一次」（每天的代表行是该日 id 最大的那条），
/// 所以同日补录不会算出间隔 0 天。
@freezed
abstract class BabyGrowthDelta with _$BabyGrowthDelta {
  const factory BabyGrowthDelta({
    int? days,
    String? heightCm,
    String? weightKg,
    String? headCm,
  }) = _BabyGrowthDelta;

  factory BabyGrowthDelta.fromJson(Map<String, dynamic> json) =>
      _$BabyGrowthDeltaFromJson(json);
}

/// 生长曲线的一份响应，对应后端的 `BabyCurveResponse`（§4.4.3）。
///
/// `standardMetric` 是服务端实际选中的那张表：用户选「体重别身高」时它按今天落成
/// `WEIGHT_LENGTH` 或 `WEIGHT_HEIGHT`，界面标题据此写「2 岁以下按身长」才解释得清横轴范围。
///
/// `metric` 是用户选的那五个原样回显，前端不另立枚举：它是查询参数的镜像，一处定义就够。
@freezed
abstract class BabyCurve with _$BabyCurve {
  const factory BabyCurve({
    required int babyId,
    required String metric,
    required String standardMetric,
    @Default(<BabyCurvePoint>[]) List<BabyCurvePoint> points,
    @Default(<GrowthStandardRow>[]) List<GrowthStandardRow> standard,
    required String disclaimer,
  }) = _BabyCurve;

  factory BabyCurve.fromJson(Map<String, dynamic> json) =>
      _$BabyCurveFromJson(json);
}

/// 曲线上的一个实测点（§4.4.3）。
///
/// `xValue` 与 `measured` 是全 App 仅有的两个 `double`（§1.4 第 15 条）：它们只喂坐标轴，
/// 不参与展示也不参与金额，其余小数一律字符串。`percentileBand` 为空是「实测值超出标准表
/// 覆盖范围」而不是「没测」——点照常画，界面据此提示。
@freezed
abstract class BabyCurvePoint with _$BabyCurvePoint {
  const factory BabyCurvePoint({
    required DateTime measureDate,
    required int ageMonths,
    required double xValue,
    required double measured,
    String? percentileBand,
  }) = _BabyCurvePoint;

  factory BabyCurvePoint.fromJson(Map<String, dynamic> json) =>
      _$BabyCurvePointFromJson(json);
}

/// 标准表的一行：横轴 + 国标七档（§4.4.3）。八个值都是 `double`，同上：插值与档位判定都在
/// 服务端，这一份只喂百分位带。
@freezed
abstract class GrowthStandardRow with _$GrowthStandardRow {
  const factory GrowthStandardRow({
    required double xValue,
    required double p3,
    required double p10,
    required double p25,
    required double p50,
    required double p75,
    required double p90,
    required double p97,
  }) = _GrowthStandardRow;

  factory GrowthStandardRow.fromJson(Map<String, dynamic> json) =>
      _$GrowthStandardRowFromJson(json);
}
