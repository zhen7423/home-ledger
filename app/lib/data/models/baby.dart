import 'package:freezed_annotation/freezed_annotation.dart';

import 'baby_statistics.dart';

part 'baby.freezed.dart';
part 'baby.g.dart';

/// 一个宝宝的档案，对应后端的 `BabyResponse`（§4.4.1）。
///
/// `archived` 是出参字段名，库里那一列叫 `enabled`：翻译在服务端做一次，前端不写 `!enabled`。
///
/// `ageText` 由服务端下发（§1.4 第 8 条）：月龄算法只有服务端一处实现，前端再算一遍就会与
/// 曲线上的点、清单上的应种日期各按一套口径走。出生身高体重按字符串原样显示，与金额同一条
/// 理由：不落 `double`。
@freezed
abstract class Baby with _$Baby {
  const factory Baby({
    required int id,
    required String name,
    required String gender,
    required DateTime birthDate,
    String? birthHeight,
    String? birthWeight,
    String? remark,
    /// S10 档案照片相对路径（§4.4.1 / A6），读取要带登录态，为空 = 还没有照片。
    String? photoUrl,
    required bool archived,
    required String ageText,
  }) = _Baby;

  factory Baby.fromJson(Map<String, dynamic> json) => _$BabyFromJson(json);
}

/// 总览页离线快照的信封（§5.4）。只走本地文件的读写两条路径，没有任何端点回它：
/// 「最新体格」与「疫苗待办」分别取自两条统计端点。
///
/// 后两段可空不是「文件坏了」：一个宝宝都还没建时它们同时为 null。`babies` 反之必填——
/// 快照整份由我们自己写出去，少一段就是这一份坏了，读侧据此回 null 而不是拿空表冒充。
@freezed
abstract class BabyOverview with _$BabyOverview {
  const factory BabyOverview({
    required DateTime savedAt,
    required List<Baby> babies,
    BabyGrowthStatistics? latestGrowth,
    BabyVaccineStatistics? vaccineTodo,
  }) = _BabyOverview;

  factory BabyOverview.fromJson(Map<String, dynamic> json) =>
      _$BabyOverviewFromJson(json);
}
