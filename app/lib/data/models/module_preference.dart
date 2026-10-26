import 'package:freezed_annotation/freezed_annotation.dart';

part 'module_preference.freezed.dart';
part 'module_preference.g.dart';

/// 一个模块的开关与顺序，对应后端的 ModulePreferenceResponse（§3.2）。
///
/// `label` 与 `enabled` / `sortNo` 都来自服务端：中文标签写在服务端，加第四个模块时才不必发一次 App；
/// 顺序也由服务端按 `sortNo` 给全，前端不再自己排一次——两处各排一次，迟早出现「设置页里是 A 在前、
/// 底栏里是 B 在前」。
@freezed
abstract class ModulePreference with _$ModulePreference {
  const factory ModulePreference({
    required String moduleKey,
    required String label,
    required bool enabled,
    required int sortNo,
  }) = _ModulePreference;

  factory ModulePreference.fromJson(Map<String, dynamic> json) =>
      _$ModulePreferenceFromJson(json);
}
