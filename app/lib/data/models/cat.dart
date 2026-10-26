import 'package:freezed_annotation/freezed_annotation.dart';

part 'cat.freezed.dart';
part 'cat.g.dart';

/// 一只猫的档案，对应后端的 CatResponse（§4.3.1）。
///
/// `archived` 是出参字段名，库里那一列叫 `enabled`：翻译发生在服务端一次，
/// 前端不写 `!enabled`。「生日选填」是整条链路的可空（§4.3.1），一只不知道生日的领养猫
/// 很常见，而一个填上去的假生日会让驱虫完成度从错误的起点步进、再也查不出来。
/// `weightKg` 用字符串原样显示两位小数，与金额同一套理由：不落 `double`。
@freezed
abstract class Cat with _$Cat {
  const factory Cat({
    required int id,
    required String name,
    required String gender,
    DateTime? birthday,
    required bool birthdayEstimated,
    String? breed,
    String? weightKg,
    required String neutered,
    String? remark,
    /// S10 档案照片相对路径（§4.3.1 / A6），形如 `/photos/<uuid>.jpg`，读取要带登录态。
    /// 为空 = 还没有照片。展示端拼上服务器基址后经 AuthImage 读取。
    String? photoUrl,
    required bool archived,
    required DateTime createdAt,
  }) = _Cat;

  factory Cat.fromJson(Map<String, dynamic> json) => _$CatFromJson(json);
}
